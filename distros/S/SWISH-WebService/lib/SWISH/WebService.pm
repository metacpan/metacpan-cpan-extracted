package SWISH::WebService;

use strict;
use warnings;
use Carp;
use Data::Dumper;
use URI::Escape;
use Data::Pageset;
use Template;
use Search::Tools;
use Search::Tools::XML;
use Time::HiRes qw( gettimeofday tv_interval );

use base qw( Class::Accessor::Fast );

our $VERSION = '0.02';
our $Props = 'swishrank,swishreccount,swishdocpath,swishtitle,swishdescription';
our $Server  = 'http://localhost/swished/';
our %Headers = ();                           # cache from index on first connect
our $Index   = 'DEFAULT';
our $Debug   = $ENV{PERL_DEBUG} || 0;
our %Defaults = (
                 q => '',
                 o => '',
                 n => 10,
                 p => 10,
                 s => 1,
                 f => 'html',
                );

our %Content_Types = (
                      xml    => 'application/xml',
                      html   => 'text/html',
                      simple => 'text/plain',
                      rss    => 'application/xml'
                     );

our $XMLDecl = '<?xml version="1.0" encoding="UTF-8"?>';

##################################################################################
# Templates
# could break these into separate files but easier for maintenance to include here
#

our %Templates = ();

########################    XML    ##############################

$Templates{xml} = <<XML;
$XMLDecl
 <search>
  <results>
  [% count = 0;
     WHILE (r = results.NextResult);
     count = count + 1 %]
   <item
        id="[% r.Property('swishreccount') %]" 
        rank="[% r.Property('swishrank') %]">
    <title>[% self.xml.utf8_safe( r.Property('swishtitle') ) %]</title>
    <url>[% r.Property('swishdocpath') | uri %]</url>
    <snip>[% self.hiliter.light( 
                self.xml.utf8_safe( 
                    self.snipper.snip( 
                        r.Property('swishdescription') 
                    )
                ) 
             ) 
           %]</snip>
   </item>
   [% LAST IF count == self.p %]
  [% END %]
  </results>
  <stats 
    start="[% self.s %]" 
    end="[% self.s + self.p - 1 %]" 
    max="[% self.p %]" 
    total="[% results.Hits %]" 
    runtime="[% self.elapsed | format('%0.3f') %]"
    searchtime="[% self.searchtime | format('%0.3f') %]"
    >
   <query>[% results.Query %]</query>
   <stopwords>[% results.Stopwords %]</stopwords>
   <sortedBy>[% self.o %]</sortedBy>
   <WordCharacters>[% self.wordchars %]</WordCharacters>
   <BeginCharacters>[% self.beginchars %]</BeginCharacters>
   <EndCharacters>[% self.endchars %]</EndCharacters>
  </stats>
  <links>
[% UNLESS pager.current_page == pager.first_page %]
  <prev>
   <a href="[% self.page( pager.previous_page ); self.params %]">Prev</a>
  </prev>
 [% IF pager.current_page > pager.first_page %]
  <first>
   <a href="[% self.page( pager.first_page ); self.params %]">[% pager.first_page %]</a>
  </first>
 [% END %]
[% END %]
[% FOR p = pager.pages_in_set %]
 [% IF p == pager.current_page %]
<page id="[% p %]" class='current'>[% p %]</page>
 [% ELSE %]
<page id="[% p %]">
 <a href="[% self.page( p ); self.params %]">[% p %]</a>
</page>
 [% END %]
[% END %]
[% UNLESS pager.current_page == pager.last_page %]
 [% IF pager.current_page < pager.last_page %]
  <last>
   <a href="[% self.page( pager.last_page ); self.params %]">[% pager.last_page %]</a>
  </last>
 [% END %]
  <next><a href="[% self.page( pager.next_page ); self.params %]">Next</a></next>
[% END %]
 </links>
</search>
XML

######################    HTML   ###########################

$Templates{html} = <<HTML;
<div class="search">
  <div class="results">
  [% count = 0;
     WHILE (r = results.NextResult);
     count = count + 1 %]
   <div
        id="item_[% r.Property('swishreccount') %]"
        class="item" >
    <span class="rank">[% r.Property('swishrank') %]</span>
    <span class="title">
     <a href="[% r.Property('swishdocpath') | uri %]">[% 
        self.xml.utf8_safe(     
            r.Property('swishtitle') 
        ) 
     %]</a>
    </span>
    <span class="url">[% r.Property('swishdocpath') | uri %]</span>
    <span class="snip">[% self.hiliter.light( 
                            self.xml.utf8_safe(
                                self.snipper.snip( 
                                    r.Property('swishdescription') 
                                ) 
                            ) 
                          ) 
                        %]</span>
   </div>
   [% LAST IF count == self.p %]
  [% END %]
  </results>
  <div class="stats"> 
    <span class="stats">
     Results [% self.s %] - [% self.s + self.p - 1 %] 
     of [% results.Hits %]
    </span>
    <span class="query">for <span class="query_words">[% self.snipper.rekw.keywords.join(' ') %]</span></span>
    [% IF results.Stopwords %]
    <span class="stopwords">The following words were automatically removed: 
    <span class="stopwords_words">[% results.Stopwords %]</span>
    </span>
    [% END %]
    [% IF self.o %]
    <span class="sortedBy">Sorted by: <span class="sorted">[% self.o %]</span></span>
    [% END %]
    <span class="times">
     Run time: [% self.elapsed | format('%0.3f') %] sec -
     Search time: [% self.searchtime | format('%0.3f') %] sec
    </span>
  </stats>
  <div class="links">
[% UNLESS pager.current_page == pager.first_page %]
  <span class="prev">
   <a href="[% self.page( pager.previous_page ); self.params %]">&#171;&nbsp;Prev</a>
   &#183;
  </span>
 [% IF pager.current_page > (pager.first_page + (self.n / 2) - 1) %]
  <span class="first">
   <a href="[% self.page( pager.first_page ); self.params %]">[% pager.first_page %]</a>
   [% IF pager.current_page > (pager.first_page + (self.n / 2) ) %]&nbsp;...&nbsp;[% END %]
  </span>
 [% END %]
[% END %]
[% FOR p = pager.pages_in_set %]
 [% IF p == pager.current_page %]
<span id="page_[% p %]" class="current">[% p %]</span>
 [% ELSE %]
<span id="page_[% p %]">
  <a href="[% self.page( p ); self.params %]">[% p %]</a>
</span>
 [% END %]
[% END %]
[% UNLESS pager.current_page == pager.last_page %]
 [% IF pager.current_page < (pager.last_page - (self.n / 2)) %]
  <span class="last">
  [% IF pager.current_page < (pager.last_page - (self.n / 2) - 1) %]&nbsp;...&nbsp;[% END %]
   <a href="[% self.page( pager.last_page ); self.params %]">[% pager.last_page %]</a>
  </span>
 [% END %]
  <span class="next">
  &#183;
   <a href="[% self.page( pager.next_page ); self.params %]">Next&nbsp;&#187;</a>
  </span>
[% END %]
 </div>
</div>
HTML

############################   simple  ##############################

$Templates{simple} = <<SIMPLE;
[%  count = 0;
    WHILE (r = results.NextResult);
    count = count + 1 %]
t:[% r.Property('swishtitle') | uri %]
u:[% r.Property('swishdocpath') | uri %]
r:[% r.Property('swishrank') %]
n:[% r.Property('swishreccount') %]
-[% LAST IF count == self.p %][% END %]
--
SIMPLE

############################  RSS  ###################################

$Templates{rss} = <<RSS;
$XMLDecl
<rss version="2.0">
 <channel>
  <title>[% self.xml.utf8_safe( self.rss.title ) OR self.xml.utf8_safe( self.title ) %]</title>
  <link>[% self.rss.link || self.uri %]</link>
  <description>[% self.xml.utf8_safe( self.rss.description ) OR self.xml.utf8_safe( self.description ) %]</description>
  <language>[% self.rss.lang || 'en-us' %]</language>
  <image>
   <title>[% self.xml.utf8_safe( self.rss.img.title ) %]</title>
   <url>[% self.rss.img.url %]</url>
   <link>[% self.rss.img.link %]</link>
  </image>
  [% count = 0;
     WHILE (r = results.NextResult);
     count = count + 1 %]
   <item id="[% r.Property('swishreccount') %]">
    <title>[% self.xml.utf8_safe( r.Property('swishtitle') ) %]</title>
    <link>[% r.Property('swishdocpath') | uri %]</link>
    <description>[% self.hiliter.light( 
                      self.xml.utf8_safe( 
                        self.snipper.snip( 
                            r.Property('swishdescription') 
                        )
                      )
                    ) 
                  %]</description>
   </item>
   [% LAST IF count == self.p %]
  [% END %]
 </channel>
</rss>
RSS

################################################################################

sub new
{
    my $class = shift;
    my $self  = {};
    bless($self, $class);

    $self->mk_accessors(
        qw/
          error
          template
          searchtime
          query
          stopwords
          wordchars
          beginchars
          endchars
          swish
          templates
          debug
          server
          index
          uri
          results
          title
          rss
          hiliter
          snipper
          xml
          /,

        keys %Defaults
    );

    return $self->_init(@_);
}

sub _init
{
    my $self = shift;
    $self->{_start} = [gettimeofday()];
    if (@_ > 1)
    {
        my %extra = @_;
        @$self{keys %extra} = values %extra;
        for (keys %Defaults)
        {
            $self->{$_} ||= $Defaults{$_};
        }
    }
    elsif (@_)
    {
        for (keys %Defaults)
        {
            $self->$_(
                   defined $_[0]->param($_) ? $_[0]->param($_) : $Defaults{$_});
        }
    }
    else
    {
        croak "need name/value pairs or a CGI object";
    }

    # enforce max hits
    if ($self->p > 100)
    {
        $self->p(100);
    }

    unless ($self->q)
    {
        $self->error('Query is required at a minimum');
        return;
    }
    else
    {

        # filter query to match swish convention
        # TODO a filter() callback?
        # TODO build this =/: opt into swish itself
        my $q = $self->q;
        $q =~ s,:,=,g;
        $self->q($q);
    }

    # create template object
    $self->{template} ||= Template->new()
      or croak $Template::ERROR;

    # shortcut to S::T::XML
    $self->xml(Search::Tools::XML->new);

    # defaults
    $self->{templates} ||= \%Templates;
    $self->{index}     ||= $Index;
    $self->{server}    ||= $Server;
    $self->{debug}     ||= $Debug;

    return $self;
}

sub params
{
    my $self = shift;

    # this is not terribly efficient
    # but since we can't really cache how else to do it?
    return $self->uri . '?'
      . join(';', map { $_ . '=' . uri_escape($self->$_) } sort keys %Defaults);
}

sub page
{

    # set the correct s() value based on $page and ->p()
    # example: $page = 3 and ->p = 10, so ->s = 31
    my $self = shift;
    my $page = shift || 1;

    $self->s(($page * $self->p) - $self->p + 1);

    # important to return empty string so template doesn't get value
    return '';
}

sub search
{
    my $self = shift;

    $self->{_startsearch} = [gettimeofday()];

    unless ($self->swish)
    {
        eval "require SWISH::API::Remote";
        if ($@)
        {
            eval "require SWISH::API";

            if ($@)
            {
                croak
                  "SWISH::API::Remote or SWISH::API must be installed to use "
                  . ref $self;
            }
            else
            {
                $self->swish(SWISH::API->new($self->index));
            }

        }
        else
        {
            $self->swish(
                        SWISH::API::Remote->new(
                            $self->server, $self->index, {DEBUG => $self->debug}
                                               )
                        );
        }

    }

    if (ref $self->swish eq 'SWISH::API')
    {

        my $search = $self->swish->new_search_object;
        return $self->error if $self->_check_swish_err;

        $search->set_sort($self->o) if $self->o;
        return $self->error         if $self->_check_swish_err;

        $self->results($search->execute($self->q));
        return $self->error if $self->_check_swish_err;

        $self->results->seek_result($self->s - 1);
        return $self->error if $self->_check_swish_err;

        if (!%Headers)
        {
            my $i = ($self->swish->index_names)[0];
            my @h = $self->swish->header_names;
            for (@h)
            {
                $Headers{$_} = join(' ', $self->swish->header_value($i, $_));
            }
        }

    }
    elsif ($self->swish->isa('SWISH::API::Remote'))
    {

        # TODO order ?
        $self->results(
            $self->swish->Execute(
                $self->q,
                {
                 BEGIN      => $self->s - 1,    # swished is 0-based
                 PROPERTIES => $Props,
                 MAX        => $self->p
                }
            )
        );

        if ($self->results->Error())
        {
            return $self->error($self->results->ErrorString());
        }

        if (!%Headers)
        {
            my @h = $self->swish->HeaderList;
            for (@h)
            {
                $Headers{$_->Name} = $_->Value;
            }
        }

    }

    $self->searchtime(tv_interval($self->{_startsearch}, [gettimeofday()]));

    $self->wordchars($Headers{WordCharacters});
    $self->beginchars($Headers{BeginCharacters});
    $self->endchars($Headers{EndCharacters});

    # create hiliter and snipper
    my $re =
      Search::Tools->regexp(
                            query            => $self->q,
                            word_characters  => $self->wordchars,
                            begin_characters => $self->beginchars,
                            end_characters   => $self->endchars
                           );
    $self->snipper(
                   Search::Tools->snipper(
                                          query   => $re,
                                          context => 12,
                                          occur   => 2
                                         )
                  );
    $self->hiliter(Search::Tools->hiliter(query => $re, class => 'hilite'));

    #carp Dumper \%Headers;

    return $self->render;

}

sub _check_swish_err
{
    my $self = shift;
    if ($self->swish->critical_error)
    {
        $self->error(
              $self->swish->error_string . ": " . $self->swish->last_error_msg);
        return $self->error;
    }
    return 0;
}

sub format
{
    return $Content_Types{$_[0]->f} . '; charset=utf-8';
}

sub elapsed
{
    return tv_interval($_[0]->{_start}, [gettimeofday()]);
}

# the guts
sub render
{
    my $self   = shift;
    my $method = lc($self->f);

    unless (exists $self->templates->{$method})
    {
        $self->error("no Template format for " . $self->f);
        return;
    }

    my $response = '';

    $self->template->process(
                             \$self->templates->{$method},
                             {
                              results => $self->results,
                              pager   => $self->pager,
                              self    => $self,
                             },
                             \$response
                            )
      or croak $self->template->error;

    return $response;
}

sub pager
{
    my $self = shift;

    return $self->{pager} if $self->{pager};

    my $results   = shift || $self->results;
    my $this_page = (($self->s - 1) / $self->p) + 1;

    $self->{pager} ||=
      Data::Pageset->new(
                         {
                          total_entries    => $results->Hits,
                          entries_per_page => $self->p,
                          current_page     => $this_page,
                          pages_per_set    => $self->n,
                          mode             => 'slide',
                         }
                        );

    return $self->{pager};

}

1;

__END__


=pod

=head1 NAME

SWISH::WebService - provide HTTP access to a Swish-e index

=head1 SYNOPSIS

 #!/usr/bin/perl

 use strict;
 use warnings;
 use CGI qw/ -newstyle_urls /;
 use SWISH::WebService;
 
 # print multi-byte chars correctly
 binmode STDOUT, ":utf8";

 my $cgi = CGI->new;

 unless ($cgi->param)
 {
    print $cgi->header;
    print "no params passed!";
    exit;
 }

 my $search = SWISH::WebService->new(
                    q => $cgi->param('q'),  # 'my query'
                    o => $cgi->param('o'),  # 'results order'
                    n => $cgi->param('n'),  # 10
                    p => $cgi->param('p'),  # 10
                    s => $cgi->param('s'),  # 1
                    f => $cgi->param('f')   # 'xml'
                    );

 # or more simply:
 my $search = SWISH::WebService->new($cgi);

 $search->index('MOVIES');
 $search->uri( $cgi->url() );

 my $response = $search->search
  or croak $search->error;

 print $cgi->header($search->format);

 if ( $search->f eq 'html' )
 {
    print <<STYLE;
    
    <style>
     <!--
      div.search        { font-family: verdana, helvetica, arial }
      div.item          { padding: 6px; }
      span.snip, 
       span.url, 
       span.title, 
       span.times       { display: block }
      span.url          { color: green; font-size: 90% }
      span.query_words  { font-weight: bold }
      div.stats         { padding: 10px }
      a                 { color: blue }
      a:visited         { color: red }
      a:hover           { color: black }
      span.hilite       { font-weight: bold }
     -->
    </style>
    
 STYLE
 }

 print $response;
                    
 
=head1 DESCRIPTION

SWISH::WebService implements a front-end search API for a Swish-e index.
It can use either the SWISH::API for a local index
or SWISH::API::Remote to access a SWISHED server.

Multiple output formats are supported, including RSS, XML and HTML. The general
idea is that you can run one or more webservice applications that share
a single swished server and provide a common API. Common features like
results paging, sorting highlighting and contextual snippets are supported.

=head1 API

The supported params are:

=over

=item q

Query. Query may be of the form:

 foo bar        # AND assumed
 foo AND bar
 foo OR bar
 foo NOT bar
 field:foo      # limit search to field

See L<FIELDS> below for more on available fields.

Queries are not case sensitive. C<foo> will match C<FOO> and C<Foo>.

=item o

Sort order. Default is descending by rank. Other default options include:

=over

=item swishtitle

=item swishdocpath

=back

Order must be specified as a string like:

 swishtitle desc
 swishdocpath asc swishtitle desc

Where C<desc> and C<asc> are the sort direction. C<asc> is the default if not specified.

Any property in an index may be sorted on; consult the Swish-e documentation.

=item n

Number of pages for page links. Default is 10.

=item p

Page size. Default is 10 hits per page. The maximum allowed is 100.

=item s

Start at result item. Default is 1.

=item f

Format. The following formats are available. Case is ignored.

=over

=item xml

=item html

=item rss

=item simple

=back

See L<RESPONSE> for more details.

=back

=head1 RESPONSE

Your HTTP response will be in one of the following formats. The default is C<html>.
See the C<f> request param above.

=head2 xml

 <?xml version="1.0" encoding="UTF-8"?>
 <search>
  <results>
   <item id="NNN" rank="XXXX"> <!-- id = sort number, rank = score -->
    <title>result title here</title>
    <url>result url here</url>
    <snip>some contextual snippet here showing query words in context</snip>
   </item>
   .
   .
   .
  </results>
  <stats start="nnn" end="xxx" max="sss" total="yyy" runtime="ttt" searchtime="fff"/>
  <links>
   <prev>http://url_for_prev_sss_results</prev>
   <first>http://url_for_first_page_of_results</first>
   <page id="N">http://url_for_page_N_results</page>
   .
   .
   .
   <last>http://url_for_last_page_of_results</last>
   <next>http://url_for_next_sss_results</next>
  </links>
 </search>

=head2 html

 <div class="search">
  <div class="results">
   <div id="item_NNN" class="item">
    <span class="rank">rank here</span>
    <span class="title">result title here</span>
    <span class="url">result url here</span>
    <snap class="snip">some contextual snippet here showing query words in context</span>
   </div>
   .
   .
   .
  </div>
  <div class="stats"> 
    <span class="stats">
     Results N - M of T
    </span>
    <span class="query">for <span class="query_words">your query</span></span>
    <span class="stopwords">The following words were automatically removed: 
    <span class="stopwords_words">a the an but</span>
    </span>
    <span class="times">
     Run time: 0.100 sec - Search time: 0.020 sec
    </span>
  </stats>

  <div class="links">
   <span class="prev">http://url_for_prev_sss_results</span>
   <span id="pageN">http://url_for_page_N_results</span>
   .
   .
   .
   <span class="next">http://url_for_next_sss_results</span>
  </div>
 </div>

=head2 rss

The default RSS template uses the RSS 2.0 specification.

=head2 simple

 t: title
 u: url
 r: rank
 n: number
 -
 t: ...
 .
 .
 .
 --

B<NOTE:> The C<-> delimits each result. The double C<-> denotes the end of the results.


=head1 METHODS

=head2 new

Instantiate a new Search object. Any of the accessor methods described below
can also be used as a key/value pair param with new().

=head2 error

=head2 template

=head2 searchtime

=head2 query

=head2 stopwords

=head2 wordchars

=head2 beginchars

=head2 endchars

=head2 swish

=head2 templates

=head2 debug

=head2 server

=head2 index

=head2 uri

=head2 results

=head2 title

=head2 rss

=head2 hiliter

=head2 snipper

=head2 xml

=head1 AUTHOR

Peter Karman <perl@peknet.com>. 

Thanks to Atomic Learning for supporting the
development of this module.

=head1 COPYRIGHT

This code is licensed under the same terms as Perl itself.

=cut


