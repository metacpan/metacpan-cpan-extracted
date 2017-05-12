package RSSycklr;
use Mouse;
no warnings "uninitialized";
use Carp ( qw/ carp confess croak / );
use YAML ();
use XML::Feed ();
use HTML::Truncate ();
use HTML::TokeParser::Simple ();
use XML::LibXML ();
use DateTime ();
use Scalar::Util "blessed";
use URI ();
use File::ShareDir ();
use Hash::Merge::Simple "merge";
use File::Spec;
use Encode;
use Capture::Tiny "capture";

our $VERSION = "0.15";

has "keep_tags" =>
    is => "rw",
    isa => "HashRef",
    default => sub {
        return { map {; $_ => 1 } qw( del ins i u b em
                                      strong abbr br img dfn
                                      acronym q sub sup cite
                                      code kbd samp strong var
                                      strike s tt a )
               };
    },
    ;

has "debug" =>
    is => "rw",
    isa => "Bool",
    default => sub { 0 },
    ;

has "tt2" =>
    is => "ro",
    lazy => 1, # not always used
    isa => "Template",
    default => sub {
        require Template;
        Template->new({
                       ENCODING => 'UTF-8',
                       DEFAULT_ENCODING => 'UTF-8',
                      });
    },
    handles => [qw( process )],
    ;

# No type so it can take any Template takes
has "template" =>
    is => "rw",
    lazy => 1, # not always used
    default => sub { \<<"TT_TEMPLATE";
<div class="[% css_class || "rssycklr" %]">
[%-FOR feed IN rssycklr.feeds() %]
[%-NEXT UNLESS feed.count %]
  <div>
    <[% feed_title_tag || "h4" %]>
      <a href="[%-feed.link | html %]">[%-FILTER html; feed.title_override || feed.title; END %]</a>
    </[% feed_title_tag || "h4" %]>
  [%~IF feed.entries.0.lede %]
    <dl>
      [%-FOR entry IN feed.entries %]
      <dt><a href="[%-entry.link | html %]">[%-entry.title | html %]</a></dt>
      <dd>
      [% entry.lede %]
        <span class="datetime">[% modified = entry.modified ? entry.modified : entry.feed.modified %]
[% modified.ymd(".") %] [% modified.hour_12 %]:[% modified.min | format('%02d') %][% modified.am_or_pm %]
        </span>
      </dd>
      [%~END %]
    </dl>
    [%~ELSE %]
  <ul>
    [%-FOR entry IN feed.entries %]
      <li><a href="[%-entry.link | html %]">[%-entry.title | html %]</a></li>
    [%~END %]
  </ul>
  [%~END %]
  </div>
[%~END %]
</div>
TT_TEMPLATE
                 },
    ;

has "xml_parser" =>
    is => "rw",
    isa => "XML::LibXML",
    default => sub {
        my $libxml = XML::LibXML->new();
        $libxml->keep_blanks(1);
        $libxml->line_numbers(1);
        $libxml->complete_attributes(1);
        $libxml->clean_namespaces(1);
        $libxml->no_network(1);
        $libxml->recover_silently(1);
        return $libxml;
    },
    handles => [qw( parse_html_string )],
    ;

has "dtd" =>
    is => "rw",
    isa => "XML::LibXML::Dtd",
    ;

has "truncater" =>
    is => "rw",
    isa => "Object", # "HTML::Truncate",
    default => sub {
        HTML::Truncate->new(repair => 1,
                            on_space => 1,
                            chars => 170);
    },
    handles => [ qw( truncate ) ],
    ;

has "feeds" =>
    is => "ro",
    auto_deref => 1,
    isa => "ArrayRef",
    default => sub { [] },
    ;

before "feeds" => sub {
    my $self = shift;
    while ( my $feed = $self->next() )
    {
        push @{$self->{feeds}}, $feed;
    }
};

sub BUILD {
    my ( $self, $args ) = @_;
    $self->config(delete $args->{config}) if $args->{config};
    $self->load_config(delete $args->{load_config}) if $args->{load_config};
}

sub config {
    my $self = shift;
    $self->{_config} ||= $self->_default_config();
    my $hash = shift || return $self->{_config};
    $self->{_config} = merge $self->{_config}, $hash;
    return $self->{_config};
}

sub load_config {
    my $self = shift;
    my $src = shift || return;
    my $info = ref($src) ?
        $src : $src !~ /\n/ ?
        YAML::LoadFile($src) : YAML::Load($src);

    my $feeds = delete $info->{feeds} || [];
    $self->config($info);
    $self->add_feeds($feeds);
    return $self;
}

sub add_feeds {
    my $self = shift;
    my $feeds = shift;
    my $old = scalar @{$self->config->{feeds} || []};
    my $new = scalar @{$feeds};
    for my $info ( @{$feeds} )
    {
        confess "URI is missing from feed data for feed: ", YAML::Dump($info)
            unless $info->{uri};
        push @{$self->config->{feeds}}, $info;
    }
    return ( $old + $new ) == @{$self->config->{feeds}};
}

sub as_string {
    my $self = shift;
    my $out = "";
    $self->process($self->template, { rssycklr => $self }, \$out)
        or confess $self->tt2->error();

    if ( defined wantarray )
    {
        return $out;
    }
    else
    {
        print $out;
        return 1;
    }
}

sub next {
    my $self = shift;
    if ( $self->_maxed_out )
    {
        $self->config->{feeds} = [];
        return;
    }
    my $info = shift @{ $self->config->{feeds} } || return;

    my $uri = blessed($info->{uri}) eq "URI" ? 
        $info->{uri} : URI->new($info->{uri});

    my $xml_feed;
    my $ok = eval {
        local $SIG{ALRM} = sub { die "Feed request timeout: $uri\n" };
        alarm( $info->{timeout} || $self->config->{timeout} || 10 );
        $xml_feed = XML::Feed->parse($uri)
            or croak("Could not parse $uri, ", XML::Feed->errstr);
        alarm(0);
        1;
    };
    alarm(0); # Racing parsing fatals can happen in the XML::Feed space(?).
    unless ( $ok == 1 )
    {
        carp $@ || ( "Unknown error parsing " . $info->{uri} )
            if $self->debug;
        return $self->next;
    }

    my $hours_back = DateTime
        ->now( time_zone => 'floating' )
        ->subtract( hours => $info->{hours_back} || $self->config->{hours_back} || 170 );

    if ( $xml_feed->modified )
    {
        return $self->next unless 1 == DateTime->compare( $xml_feed->modified, $hours_back );
    }

    my $max_display    = $info->{max_display} || $self->config->{max_display} || 10;
    my $excerpt_length = $info->{excerpt_length} || $self->config->{excerpt_length};
    my $title_only     = exists($info->{title_only}) ?
        $info->{title_only} # might be undef on purpose to override self->config setting
        :
        $self->config->{title_only};

    my @entry;
  ENTRY:
    for my $entry ( $xml_feed->entries )
    {
        next ENTRY unless $entry->issued;
        next ENTRY unless 1 == DateTime->compare( $entry->issued, $hours_back );

        my %entry;
        unless ( $title_only )
        {
            next ENTRY if $entry->content->body !~ /\S/;
            my $xhtml = $self->html_to_dom( $entry->content->body )
                or die "Couldn't parse ", $entry->content->body;
            $self->_strip_attributes($xhtml);
            $self->_strip_tags($xhtml);
            $self->_handle_images($xhtml, $entry);

            my ( $body ) = $xhtml->findnodes("body");
            unless ( $xhtml->findnodes("head") )
            {
                my $head = $xhtml->createElement("head");
                my $title = $xhtml->createElement("title");
                my $text = $xhtml->createTextNode(__PACKAGE__ . "/" . $VERSION);
                $title->appendChild($text);
                $head->appendChild($title);
                $xhtml->insertBefore($head,$body);
            }

            # Cache it.
            unless ( $self->dtd )
            {
                $self->config->{dtd} ||= "xhtml1-transitional.dtd";
                my $dtd_file = File::ShareDir::dist_file(__PACKAGE__,
                                                         $self->config->{dtd});
                $/ = undef;
                open my $fh, "<", $dtd_file or croak "Couldn't open '$dtd_file' for reading: $!";
                $self->{ $self->config->{dtd} } = <$fh>;
                close $fh or carp "Trouble closing '$dtd_file': $!";
                $self->dtd( XML::LibXML::Dtd->parse_string($self->{ $self->config->{dtd} }) );
            }

            unless ( eval { $xhtml->validate($self->dtd); 1; } )
            {
                carp $@ || "Uknown error",
                    " - parsing content of '", $entry->title, 
                    "' from ", $xml_feed->link;
                next ENTRY;
            }

            my $content = "";
            $content .= $_->serialize(1) for $body->childNodes();
            my $more = join("",
                            decode_utf8($self->config->{ellipsis}),
                            '<a class="readmore" href="',
                            $entry->link,
                            '">', 
                            decode_utf8($self->config->{read_more}),
                            '</a>'
                            );
            my $output = $self->truncate( $content,
                                          $excerpt_length,
                                          $more );
            $output =~ s/\s\s+/ /g;
            $entry{lede} = $output;
        }
        $entry{xml_feed_entry} = $entry;
        $entry{feed} = $xml_feed;
        push @entry, \%entry;
        last ENTRY if @entry >= $max_display;
    }

    return $self->next unless @entry;

    my $feed = RSSycklr::Feed->new( %{$info},
                                    ellipsis => $self->config->{ellipsis}, # not sure, weak ref to parent instead?
                                    xml_feed => $xml_feed, );

    $feed->{entries} = [ map { $_->{feed} = $feed; RSSycklr::Feed::Entry->new($_) } @entry ];

    $self->{_feeds_returned}++;
    return $feed;
}

sub html_to_dom {
    my $self = shift;
    my $html = shift || return;
    my $renew = "";
    my $p = HTML::TokeParser::Simple->new(\$html);
    no warnings "uninitialized";
    while ( my $token = $p->get_token )
    {
        if ( $token->is_text
             or not $HTML::Tagset::isKnown{ $token->get_tag } )
        {
            my $txt = HTML::Entities::decode_entities($token->as_is);
            $txt =~ s/[^[:print:]]+/ /g; # kill unprintables for a space.
            $renew .= $txt;
        }
        elsif ( $token->get_tag =~ /\Abr\b/i )
        {
            $renew .= "\n";
        }
        elsif ( $HTML::Tagset::canTighten{ $token->get_tag } )
        {
            # Replace block-like tags with \n if we have content
            # already and not more than twice consecutively.
            $renew .= $token->as_is;
        }
        else
        {
            $renew .= $token->as_is;
        }
    }

    # XML::LibXML is noisy even with recover_silently, so-
    my $dom;
    my ( $out, $err ) = capture {
        $dom = $self->parse_html_string(<<"HTML");
<html><head><title>Untitled</title></head><body>$renew</body></html>
HTML
    };
    $dom;
}

sub _maxed_out {
    my $self = shift;
    if ( $self->config->{max_feeds}
         and
         $self->config->{max_feeds} <= $self->{_feeds_returned} )
    {
        return 1;
    }
    return;
}

sub _strip_attributes {
    my ( $self, $root ) = @_;

    for my $node ( $root->findnodes("//*") )
    {
        for my $attr ( $node->attributes )
        {
            next if $node->nodeName eq 'a' and $attr->name eq 'href';
            next if $node->nodeName eq 'img' and $attr->name eq 'src';

            next if $attr->name eq 'title'
                and $node->nodeName =~ /\A(?:acronym|abbr|dfn|a)\z/;

            $node->removeAttribute($attr->name);
        }
    }
}

sub _handle_images {
    my ( $self, $root, $entry ) = @_;

    for my $node ( $root->findnodes("//img") )
    {
        if ( $node->getAttribute("src") !~ m,\Ahttp://, )
        {
            $node->parentNode->removeChild($node);
            return;
        }
        # Don't put a link on images that already have one.
        next if $node->parentNode->tagName eq "a";

        my $link = $node->getOwner->createElement("a");
        $link->setAttribute("href", $entry->link);
        $link->setAttribute("title", $entry->title);
        $node->setAttribute("alt", $entry->title);
        $link->appendChild( $node->cloneNode );
        $node->parentNode->replaceChild( $link, $node );
        return 1; # Just do one for now.
    }
}

sub _strip_tags {
    my ( $self, $root ) = @_;

    my $doc = $root->getOwnerDocument;
    my $keep = $self->keep_tags;

    # Special case, we must have this and don't want it mucking the interface.
    $keep->{body} = 1;

    my @nodes = $root->findnodes("//*");
    for my $node ( @nodes )
    {
        next unless $node;
        next if $keep->{$node->nodeName};

        my $frag = $doc->createDocumentFragment();

        for my $n ( $node->childNodes )
        {
            $frag->appendChild($n);
        }
        $node->replaceNode($frag);
    }

    return 1 unless $keep->{br};

    my @outer = $root->findnodes("body/*");

  FORWARD:
    for my $br ( @outer ) {
        last FORWARD unless $br and $br->tagName eq "br";
        $br->parentNode->removeChild($br);
    }

  BACKWARD:
    for my $br ( reverse @outer ) {
        last BACKWARD unless $br and $br->tagName eq "br";
        $br->parentNode->removeChild($br);
    }
    return 1;
}

sub _default_config {
    return {
        excerpt_length => 150,
        ellipsis => "\x{2026}", # chr(8230),
        read_more => "[more]",
        title_only  => undef,
        hours_back  => 72,
        max_feeds   => 10,
#        max_entries => 10,
        max_display => 3,
        timeout => 30,
        css_class => "rssycklr",
#        title_length => undef,
#        excerpt_style => dl|p|br|ul
#        title_style => ul|p|br      # not implemented, ul/li happens now
#        max_images => 1             # this is hardcoded for now
        feed_title_tag => "h4",
        dtd => "xhtml1-transitional.dtd",
    };
}

__PACKAGE__->meta->make_immutable();

package RSSycklr::Feed;
use Mouse;
use HTML::Entities qw( decode_entities );
use Encode qw( decode_utf8 );

has "xml_feed" =>
    is => "ro",
    required => 1,
    isa => "Object",
    handles => [qw( tagline link copyright modified
                    author generator language )],
    ;

has "entries" =>
    is => "ro",
    lazy => 1,
    default => sub { [] },
    required => 1,
    auto_deref => 1,
    isa => "ArrayRef",
    ;

has "title_override" =>
    is => "ro",
    isa => "Str",
    default => sub { "" },
    ;

sub count {
    scalar @{+shift->entries};
}

sub title {
    my $self = shift;
    return $self->{_title} if $self->{_title};
    # Try to guarantee it doesn't return entities.
    $self->{_title} = decode_entities(decode_entities($self->xml_feed->title));
    $self->{_title} = decode_utf8( $self->{_title} );
}

__PACKAGE__->meta->make_immutable();

package RSSycklr::Feed::Entry;
use Mouse;
use DateTime;

has "xml_feed_entry" => ( is => "ro",
                          required => 1,
                          isa => "Object", # ::Atom/RSS
                          handles => [qw( title link content category id author issued modified )],
                        );

has "lede" => ( is => "ro",
                isa => "Str",
                default => sub { "" },
              );

has "feed" => ( is => "ro",
                weak_ref => 1,
                isa => "RSSycklr::Feed",
              );

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

RSSycklr - (beta) Highly configurable recycling of syndication (RSS/Atom) feeds into tailored, guaranteed XHTML fragments.

=head1 SYNOPSIS

 use strict;
 use warnings;
 use RSSycklr;
 use Encode;
 
 my @feeds = ({ uri => "http://www.xkcd.com/atom.xml",
                max_display => 1 },
              { uri => "http://green.yahoo.com/rss/blogs/all" },
              { uri => "http://www.mnn.com/rss/all-mnn-content" },
              { uri => "http://feeds.grist.org/rss/gristfeed" },
              { uri => "http://green.yahoo.com/rss/featured" },
              { uri => "http://feeds.nationalgeographic.com/ng/NGM/NGM_Magazine" },
              { uri => "http://feeds.feedburner.com/greenlivingarticles" },
              { uri => "http://www.ecosherpa.com/feed/" },
              { uri => "http://www.groovygreen.com/groove/?feed=atom" },
              { uri => "http://blog.epa.gov/blog/feed/"},
              { uri => "http://www.unep.org/newscentre/rss/rss.asp?rss-id=pr&l=en" },
              { uri => "http://feeds.feedburner.com/treehuggersite" },
              { uri => "http://redgreenandblue.org/feed/" },
              { uri => "http://green.yahoo.com/rss/news" },
              { uri => "http://news.cnet.com/8300-11128_3-54.xml" },
              { uri => "http://news.google.com/news?rls=en-us&oe=UTF-8&um=1&tab=wn&hl=en&q=Environmental&ie=UTF-8&output=atom" },
              { title_override => "O NOES, IZ TEH DED",
                uri => "http://rss.news.yahoo.com/rss/obits", });
 
 my $rsklr = RSSycklr->new();
 
 binmode STDOUT, ":encoding(UTF-8)";
 $rsklr->config({ feeds => \@feeds,
                  title_only => 1 });

 # print $rsklr->as_string;
 
 while ( my $feed = $rsklr->next() )
 {
     print $feed->title_override || $feed->title;
     print "\n";
     for my $entry ( $feed->entries )
     {
         print " * ", $entry->title, "\n";
     }
 }

=head1 DESCRIPTION

This is a more of a mini-app engine than a pure module. RSSycklr is a package that wraps up the best parts of L<XML::Feed> and L<HTML::Truncate> then filters it through L<XML::LibXML> to guarantee valid XHTML and adds a side of L<Template> for auto-formatted output of XHTML fragments should you so desire.

This is probably easier to show with examples than explain. This is the part where I show, or maybe explain, someday. For now, take a look at the L</CONFIGURATION> sample below and the source for the tool 'rssycklr' that comes with this distribution.
 
XHTML validation is currently based on "-//W3C//DTD XHTML 1.0 Transitional//EN" and errors are B<not fatal>. You will be able to pick your DTD eventually and decide if errors are fatals or skip the entry or just complain.

=head1 METHODS

=over 4

=item B<new>

Create an L<RSSycklr> object.

=item B<load_config>

Takes a L<YAML> file name or string. It must conform to the configuration format. No validation of input is done at this point. More config options will be probably be added soon. As it calls L</config> underneath, loading configuration options will be add them to what's already there, not reset them.

=item B<config>

Set/get hash reference of the configuration and raw feed data. Setting config is additive, each new hash reference is merged with the current config hash reference.

=item B<add_feeds>

Takes an array ref of hash refs of feed info. C<uri> is the only required key in the hash ref. Other possible keys are shown in L</CONFIGURATION> below.

=item B<next>

Iteration through feeds with delayed execution. Feeds are only fetched and cleaned-up as they are called. L</next> is destructive and can be used in a while loop.

    while ( my $feed = $rssycklr->new() ) {
        print "Title: ", $feed->title, "\n";
    }

=item B<feeds>

If you prefer to get your feeds at once in a list or an array ref, use L</feeds>. It iterates on L</next> under the hood, therefore L</next> will be empty after L</feeds> has been called though L</feeds> may be called repeatedly without refetching or parsing. If you L</add_feeds> to add new feeds, next will able to iterate on those and L</feeds> will add them to those already parsed and fetched.

Remember that each feed is a web request and they aren't done in any kind of parallel nature so you could expect a list of 20 feeds to return slowly, maybe very slowly.

=item B<as_string>

Sort of does this-

 $rssycklr->process($rssycklr->template, { rssycklr => $rssycklr })
       or confess $rssycklr->tt2->error();

Can also be called for a return value, like so-

 my $output = $rssycklr->as_string;

In void context, it processes/prints to STDOUT.

 $rssycklr->as_string;

=item B<keep_tags>

The list (stored as a hash ref) of tags which will be kept when creating ledes from entry bodies. The default list generally comprises the phrasal tags; e.g., C<< <i/> >>, C<< <q/> >>, C<< <del/> >>, C<< <dfn/> >>, C<< <sup/> >>, et cetera.

 perl -MRSSycklr -MYAML -le '$rsklr = RSSycklr->new; print Dump $rsklr->keep_tags'

Example: dropping images-

 delete $rsklr->keep_tags->{img};

Example: drop all tags-

 $rsklr->keep_tags({});

=item B<tt2>

The L<Template> object we may create to do output. It's deferred so if you never ask for it, and never call its methods, it's never created.

=item B<template>

The C<template> that will be passed to L<Template/process>. It can be a string (scalar ref), a file, or a file handle. The default is a string ref.

 perl -MRSSycklr -le '$rsklr = RSSycklr->new; print ${$rsklr->template}'

=item B<xml_parser>

The L<XML::LibXML> object.

=item B<html_to_dom>

Passes an HTML fragment through some L<HTML::TokeParser::Simple> sanity cleanup and returns an L<XML::LibXML::Document>. This is an 

=item B<truncater>

The L<HTML::Truncate> object.

=item B<BUILD>

Internal method. To allow C<config> and C<load_config> to be passed as arguments. C<BUILD> runs the methods at initialization if you do.

=back

=head2 DELEGATED METHODS

As noted above, an L<RSSycklr> object has a collection of objects it wrangles. You may call methods on it which get delegated t its objects. All the methods below belong to the indicated classes and may be treated exactly as the relevant documents show.

=over 4

=item B<process>

This is L<Template/process>.

=item B<parse_html_string>

L<XML::LibXML/parse_html_string>. You also have access to L<XML::LibXML::Parser/recover> and L<XML::LibXML::Parser/recover_silently> which are set to "1" by default.

=item B<truncate>

L<HTML::Truncate/truncate>.

=back

=head1 INTERNAL PACKAGES

=head2 RSSycklr::Feed

Calls from L<RSSyckler> objects to L</feeds> and L</next> return C<RSSycklr::Feed> objects. They are based on L<XML::Feed> objects.

=head2 SELECT CONFIGURATION SETTINGS

More configuration settings are shown in the config example.

=over 4

=item B<title_override>

For some feeds, like say a search generated feed from Google, you might get back a title in the XML which is ridiculous for display; e.g., B<"bingo cards" +tacos site:example.org>. In cases likes this it would be nice to provide your own title.

=back

=head2 METHODS

=over 4

=item B<entries>

The processed entries from the feed which passed configuration filters.

=item B<count>

The number of entries a feed has. Note, this is not the number of entries in the actual L<XML::Feed>, but the number of entries which passed your configuration filters.

=back    

=head2 DELEGATED METHODS

The following delegate to the underlying L<XML::Feed> object.

=over 4

=item B<title>

=item B<tagline>

=item B<link>

=item B<copyright>

=item B<author>

=item B<generator>

=item B<language>

=back

=head2 RSSycklr::Feed::Entry

=over 4

=item B<lede>

The excerpted portion of the feed entry's content.

=item B<feed>

The parent L</RSSyckler::Feed> object.

=back

=head2 DELEGATED METHODS

The following delegate to the underlying L<XML::Feed::Entry> object.

=over 4

=item B<title>

This will eventually be replaced by a native method.

=item B<link>

=item B<content>

=item B<category>

=item B<id>

=item B<author>

=item B<issued>

=item B<modified>

=back

=head1 CONFIGURATION

Configuration is a hash in two levels. The top level contains defaults. The key C<feeds> contains per feed settings. You can have C<< max_display => 3 >> in the top, for example, but have C<< max_display => 1 >> and C<< max_display => 10 >> in individual feed data. Leaving C<max_display> out of feed data would mean a feed would fall back to the top default setting C<3>.

 ---
 # length of entry excerpt to keep as "lede"
 excerpt_length: 110
 # don't do excerpts, titles, only
 title_only: ~
 # master setting for oldest entry age
 hours_back: 30
 # stop fetching at this point
 max_feeds: 10
 # master setting for entries to keep per feed
 max_display: 3
 # seconds to try a feed fetch before skipping
 timeout: 10
 # ellipsis on truncated ledes/titles
 ellipsis: " "
 # text for "read more" link
 read_more: [more]
 # css class for top <div> wrapper
 css_class: rssycklr
 # not implemented
 title_length: ~
 # not implemented, dl/dt/dd happens now
 excerpt_style: dl|p|br|ul
 # not implemented, ul/li happens now
 title_style: ul|p|br
 # this is hardcoded for now
 max_images: 1
 feed_title_tag: h4
 dtd: xhtml1-transitional.dtd
 feeds:
   - uri: http://green.yahoo.com/rss/blogs/all
     max_display: 5
     hours_back: 24
   - uri: http://sedition.com/feed/atom
     title_only: 1
     hours_back: 105
     timeout: 3
   - uri: http://dd.pangyre.org/dd.atom
     excerpt_length: 300
     hours_back: 48

Caveat: the C<ellipsis> default is utf8 so set it to "..." (three periods) or C<&hellip>; if it's going to cause a problem in your handling.

=over 4

=item B<excerpt_length>

How long to make C<lede>s. This is passed through L<HTML::Truncate> so it tries to count displayed characters, not real real characters; i.e., C<< <p>Oh, Hai!</p> >> is counted as 8 characters, not 15. Default is at 170.

=item B<title_only>

If true, don't do excerpts, only pull titles.

=item B<hours_back>

Maximum age of feed entries to include.

=item B<max_display>

How many entries from a feed to parse and keep.

=item B<timeout>

How many seconds to wait for a feed fetch to return before skipping it.

=item B<ellipsis>

=item B<read_more>

Text for "read more" link.

=item B<css_class>

The CSS class for the top C<< <div/> >> wrapper.

=item B<max_images>

Maximum images to keep in a C<lede>. Hardcoded to 1 right now.

=item B<dtd>

=item B<max_feeds>

Stop fetching at this point.

=item B<dtd>

The DTD to validate feed snippets against. The default is C<xhtml1-transitional.dtd>. Also available: C<xhtml1-frameset.dtd>, C<xhtml1-strict.dtd>, and C<xhtml11.dtd>. Because we use L<XML::LibXML> to parse our snippets we cannot, and frankly wouldn't want to, support HTML 4 and earlier.

=item B<title_length>

Not implemented.

=item B<excerpt_style>

Not implemented, dl/dt/dd happens in template now.

=item B<title_style>

Not implemented, ul/li happens now.

=item B<feed_title_tag>

Settable; C<h4> in template now.

=back

=head2 SAMPLE CSS

The image handling is probably the most important part. Feeds might return huge images or several images.

 .rssycklr {
   font-family: helvetica, sans-serif;
 }
 .rssycklr h4 {
   border-bottom: 1px solid #ccc;
   line-height: 100%;
 }
 .rssycklr h4 a {
   color:#039!important;
   text-decoration:none;
 }
 .rssycklr .datetime {
   color: #445;
   font-size: 80%;
 }
 .rssycklr a.readmore {
   text-decoration:none;
   font-size: 90%;
 }
 .rssycklr img {
   float: right;
   clear: right;
   width: 60px;
   margin: -3px 0 0 3px;
 }

=head1 AUTHOR

Ashley Pond V, C<< <ashley@cpan.org> >>.

=head1 TODO

Collect errors for inspection in the object.

C<as_is> flag?

Pass through the Pod to make it a bit more useful and less redundant on config stuff.

If abutting tags stripped tags are flow level, insert a newline...? Define the behavior in the config so even a E<para> or something could be inserted. Turn C<< <br/>s >> into newlines? Use C<canTighten> and C<isPhraseMarkup> from L<HTML::Tagset> to make these choices. Maybe this is where the DTDs should live too...?

Test timed out feeds.

C<next> should be putting feeds aside for C<feeds>?

Translate tags? To drop blockquote to q and h* to bold, etc?

Text only option for ledes? Makes it easier to work on that setting C<keep_tags> to empty.

Put a name field for feeds to override the feed supplied title.

Make the validation controllable.

Make a master timeout vs a feed level timeout? No...

Make utf8 a settable...?

Move all the DTD handling, and all the other historical ones, HTML 1 and up, into a real distribution...? Ikegami's catalog stuff?

Make attribute filter configurable.

More tests.

Throw errors for extraneous or malformed config data.

Implement anything in the configuration example which reads, "not implemented." E.g., make the style/tags configurable for titles/ledes; e.g., dl|p|br|ul.

Submit a patch, or ticket, to Benjamin for a content_type L<XML::Feed::Entry>. We're just assuming it's HTML.

C<< Template-E<gt>process >> should probably have a C<before> call to allow the config to be merged into the top of the template data.

Make image count configurable.

Regex filters?

Chance of inclusion: a decimal so that a list of feeds 100 feeds with a level of 0.1 would only load (or rather try to) approximately 10 feeds.

=head1 BUGS AND LIMITATIONS

I love good feedback and bug reports. Please report any bugs or feature requests directly to me via email or through the web interface at L<http://rt.cpan.org/Public/Dist/Display.html?Name=RSSycklr>.

=head1 THANKS TO

Stevan Little, Shawn M Moore, and Benjamin Trott. I had no idea how cool L<Moose> and L<Mouse> were before I put this together. They make very complicated interactions seem quite natural. I changed design and features three or four times putting this together and if the code had all been by hand it probably would have made me dump the project since I already had a perfectly serviceable program doing what it does. Instead, with L<Mouse>, fairly deep changes were nearly trivial.

=head1 SEE ALSO

L<XML::Feed>, L<XML::Feed::Entry>, L<Mouse>/L<Moose>, L<XML::LibXML>, L<Template>, L<YAML>, L<HTML::Truncate>, L<DateTime>, L<Scalar::Util>, L<URI>, L<Encode>.

=head1 COPYRIGHT & LICENSE

Copyright (E<copy>) 2008-2010 Ashley Pond V.

This program is free software; you can redistribute it or modify it or both under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except
when otherwise stated in writing the copyright holders or other
parties provide the software "as is" without warranty of any kind,
either expressed or implied, including, but not limited to, the
implied warranties of merchantability and fitness for a particular
purpose. The entire risk as to the quality and performance of the
software is with you. Should the software prove defective, you assume
the cost of all necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be liable
to you for damages, including any general, special, incidental, or
consequential damages arising out of the use or inability to use the
software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of such
damages.

=cut


Save for title_length stuff...

has "title_length" => ( is => "ro",
                        isa => "Int",
                        default => sub { 0 },
                        );

has "ellipsis" => ( is => "ro",
                    isa => "Str",
                    default => sub { "" },
                    );

    if ( $self->title_length and length($self->{_title}) > $self->title_length )
    {
        $self->{_title} = substr($self->{_title}, 0, $self->title_length);
        $self->{_title} =~ s/[\s[:punc:]]+\z//; # Trim punctuation and spaces off end.
        $self->{_title} .= $self->ellipsis;
    }
