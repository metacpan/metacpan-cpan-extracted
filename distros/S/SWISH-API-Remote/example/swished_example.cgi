#!/usr/bin/perl -T
#
#	example of how to use SWISHED, SWISH::API::Remote and HTML::HiLiter
#
#	copyright 2004-2006 perl@peknet.com
#
#	this script available under the same terms as Perl itself.
#
################################################################################
#
# TODO
#	fix Perl man page generation to exclude double chars (this seems like a Perl bug)
#   use Data::Pager instead of our pager()

use strict;
use warnings;
use CGI qw/ -newstyle_urls /;
use SWISH::API::Remote;
use HTML::HiLiter;

my $Version = 0.04;

# version history
# =====================
# 0.01 -- initial
# 0.02 -- fixed security hole and pager bug; thanks to moseley@hank.org
# 0.03 -- added comments about sman.conf modifications
# 0.04 -- update to use new FC4 peknet install

# some -T sanity
#

$ENV{'PATH'} = '/bin:/usr/bin:/usr/local/bin';
delete @ENV{'IFS', 'CDPATH', 'ENV', 'BASH_ENV'};

#
#	this example assumes the Sman index via SWISHED at http://yourhost.com/swished/
#	if we have no params, print search form
#	if we have params, check for mode
#
# Assumes Sman version 1.0 or later
# IMPORTANT: sman.conf from 1.0 must be modified from default to include these 3 changes:
#   1. add swishdocpath to the SWISHE_MetaNames line (this has been added in Sman 1.01)
#   2. add this line: SWISHE_MaxWordLimit 200 (why? - joshr)
#   3. add '/' to SWISHE_WordCharacters (this has been added in Sman 1.01 -joshr)
#

my $cgi = CGI->new;    # create CGI object

my $def_start = 0;     # first result
my $Max       = 10;    # default num of results per page
my $swished = 'http://yourhost.com/swished/';     # URL of server
my $CSS     = 'http://yourhost.com/style.css';    # CSS URL
my $index   = 'DEFAULT';                          # which index to search
my $props   =
  "swishrank,swishreccount,swishdocpath,swishtitle,sec,desc"
  ;                                               # properties to return

# always print header and form
print $cgi->header,
  $cgi->start_html(
                   -title => 'SWISHED Example CGI',
                   -style => {src => $CSS}
                  ),
  $cgi->start_form(-method => 'get'), search_form($cgi);

# check for params and act
unless ($cgi->param && $cgi->param('q'))
{

    # a little description
    print <<EOF;
This SWISHED example CGI script uses SWISH::API::Remote and HTML::HiLiter.
<p>
It searches the Sman SWISH-E index at peknet.com, which includes man pages
for a Fedora Core 4 installation.
<p>
You can see the full description of this example, including the source code,
at <a href='http://swishewiki.org/index.php/SWISHED_Demo'>http://swishewiki.org/index.php/SWISHED_Demo</a>

EOF

    exit;
}

my $mode = $cgi->param('mode');
unless ($mode)
{
    print "need mode to run!\n";    # helps keep robots out
    exit;
}

if ($mode eq 'show')
{

    # if we want to display a search result,

    # check for valid file in index
    # NOTE that 'swishdocpath' must be added to this line:
    #  SWISHE_MetaNames
    # in Sman config

    my $file  = $cgi->param('f');
    my $debug = $cgi->param('debug') || 0;    # default is OFF
    my $q     = 'swishdocpath=' . $file;
    my $remote  = SWISH::API::Remote->new($swished, $index, {DEBUG => $debug});
    my $results = $remote->Execute($q);

    if ($results->Error())
    {
        print $results->ErrorString();
        exit;
    }
    elsif (!$results->Hits())
    {
        print "No such file in index: $file";
        exit;
    }

    # convert it to HTML and capture in buffer
    # then hand it to HTML::HiLiter for highlighting and printing

    my $buf     = man2html($file);
    my $hiliter = HTML::HiLiter->new;
    my $query   = $cgi->param('q');
    $hiliter->Queries($query);
    $hiliter->CSS;
    $hiliter->Run(\$buf);

}
elsif ($mode eq 'search')
{

    # run search and display results

    my $q   = $cgi->param('q');
    my $b   = $cgi->param('b') || $def_start; # default is to start at first hit
    my $max = $cgi->param('max') || $Max;
    my $debug = $cgi->param('debug') || 0;    # default is OFF

    my $remote = SWISH::API::Remote->new($swished, $index, {DEBUG => $debug});
    my $results =
      $remote->Execute($q, {BEGIN => $b, PROPERTIES => $props, MAX => $max});

    if ($results->Error())
    {
        print $results->ErrorString();
        exit;
    }

    # Hits are base1
    # results are base0
    # we want to print base1 and search base0

    my $last_hit    = $results->Hits();
    my $first_range = $b + 1;
    my $last_range  = $b + $max;
    $last_range = $last_hit if $last_range > $last_hit;

    printf("Fetched %d - %d of %d hits for search on '%s'\n",
           $first_range, $last_range, $last_hit, $q);

    print $cgi->br, 'Page: ', pager($cgi, $b, $last_range - 1, $max, $last_hit);

    my $hiliter = HTML::HiLiter->new;
    $hiliter->Queries($q);
    $hiliter->Inline;

    while (my $r = $results->NextResult())
    {
        print $hiliter->hilite(myresult($cgi, $r));
    }

}
else
{

    print "no such mode: $mode\n";

}

# always close up
print $cgi->endform, $cgi->end_html;

exit;

############################
# routines

sub man2html
{

    my $f = shift;

    # do some taint checking/sanity on file
    my $clean;

    if ($f =~ m!^([/\w\.\-\:]+)$!)
    {
        $clean = $1;
    }
    else
    {

        print "'$f' doesn't look clean\n";
        exit;

    }

    unless (-r $clean)
    {

        print "$clean is not readable: $!\n";
        exit;

    }

    # work in /tmp

    chdir '/tmp';

    # convert and slurp into buffer

    my $cmd =
      $clean =~ m/\.gz$/
      ? "gunzip -c $clean | groff -Thtml -mandoc -t -e - "
      : "groff -Thtml -mandoc -t -e $clean";

    local $/;
    my $buf = `$cmd`;
    unless ($?)
    {

        return $buf;

    }
    else
    {

        print "conversion error: $!\n";
        exit;

    }

}

sub search_form
{
    my $cgi = shift;

    return $cgi->p(
        $cgi->a({-href => $cgi->url()}, 'Home'),
        $cgi->br,
        'Search Linux man pages: ',
        $cgi->textfield(
                        -name      => 'q',
                        -default   => $cgi->param('q') || '',
                        -override  => 1,
                        -size      => 50,
                        -maxlength => 80
                       ),
        $cgi->submit(
                     -name  => 'mode',
                     -value => 'search'
                    ),
        $cgi->checkbox(
                       -name    => 'debug',
                       -value   => 1,
                       -checked => 0
                      ),

        $cgi->hr
                  );

}

sub myresult
{
    my ($cgi, $result) = @_;

    my $f = $result->Property('swishdocpath');

    return $cgi->p(
        $cgi->font(
                   {-size => '-1'},
                   '[' . $result->Property('swishreccount') . ']'
                  ),
        '&nbsp;',
        $cgi->a(
                {
                     -href => $cgi->url
                   . '?mode=show' . ';f='
                   . $f . ';q='
                   . $cgi->param('q')
                },
                $result->Property('swishtitle'),
                '(' . $result->Property('sec') . ')',
               ),
        '&nbsp;--&nbsp;',

        # if we had a swishdescription, we might snip that here too
        $result->Property('desc'),

        # rank in green
        '&nbsp;&#187;&nbsp;',
        $cgi->font({-color => 'green'}, $result->Property('swishrank')),

                  );

}


sub pager
{
    my $cgi   = shift;
    my $start = shift;
    my $end   = shift;
    my $max   = shift;
    my $hits  = shift;

    # number of pages is hits / max, rounded up
    my $N = $hits / $max;
    $N = int($N) + 1 if $N =~ m/\./;

    my $baseurl = $cgi->url . '?q=' . $cgi->param('q') . ';mode=search';

    # where are we now?
    # page 1 = 0 .. ( $max*1 -1 )
    # page 2 = $max+1 .. ( $max*2 -1 )
    # page 3 = $max*2+1 .. ( $max*3 -1 )
    # only show X pages, with ... to indicate more
    # we want thispage, plus 4 on either side

    my $thispage = int($end / $max + 1);
    my @links;
    my $page = $thispage - 4;
    $page = 0 if $page < 0;
    my $X = 10;

    # always include first page
    if ($thispage > 4)
    {
        push(@links,
             $cgi->a({href => $baseurl . ";max=$max;b=$def_start"}, '1'));
        push(@links, '...') unless $thispage == 5;
    }

    while (scalar(@links) <= $N)
    {
        $page++;
        my $b = $max * ($page - 1);

        # print "Thispage: $thispage  ---  Page: $page <br>\n";
        if ($page == $thispage)
        {
            push(@links, $cgi->b($page));
        }
        else
        {
            push(@links, $cgi->a({href => $baseurl . ";max=$max;b=$b"}, $page));
        }
        last if $page >= $N;
        last if scalar(@links) >= $X;
    }

    # always include last page
    unless ($page == $N)
    {
        my $lastpg = $max * ($N - 1);
        push(@links, '...') unless $thispage == ($N - 5);
        push(@links, $cgi->a({href => $baseurl . ";max=$max;b=$lastpg"}, $N));
    }

    return join '&nbsp;', @links;

}
