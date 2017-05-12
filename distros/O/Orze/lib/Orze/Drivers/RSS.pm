package Orze::Drivers::RSS;

use strict;
use warnings;

use Encode;
use XML::RSS;
use XML::Twig;
use DateTime;
use HTML::Entities;

use base "Orze::Drivers";

=head1 NAME

Orze::Drivers::RSS - Create a RSS feed

=head1 DESCRIPTION

Create a RSS feed by parsing a piece of html code. Each <h1> title will
be the title of an entry of the feed, the text until the next <h1> will
become the cotent of the entry. The id attribute of the title prefixed
by a base url will become the permalink of the entry.

Such a design is intended to allow to share content between the feed and
a webpage.

It uses the following variables:

=over

=item feedtitle

The title of the feed

=item description

The description of the feed

=item content

The content.

=item url

The base url for the links

=item webmaster
=item language
=item update
=item content
=item copyright

See L<XML::RSS> for more information on the variables.

=back

=head1 EXAMPLE

    <page name="rss" extension="xml" driver="RSS">
        <var name="feedtitle">Feed title</var>
        <var name="description">Feed description</var>
        <var name="content" src="Include" file="index.html"></var>
        <var
            name="url">http://gnagna.foo</var>
    </page>

index.html looks like:

      <h1 id="foobar">Foo Bar</h1>
      Some text
      <h1 id="hello">Hello world</h1>
      Some other text

=head1 SEE ALSO

Lookt at L<XML::RSS>.

=head1 METHODS

=head2 process

Do the real processing

=cut

sub process {
    my ($self) = @_;

    my $page = $self->{page};
    my $variables = $self->{variables};

#    $variables->{root} = $self->root();

    my $name = $page->att('name');
#    $variables->{page} = $name;

    my $extension = $page->att('extension');
#    $variables->{extension} = $extension;

    my $feedtitle = $variables->{feedtitle};
    $feedtitle = decode('UTF-8', $feedtitle);
    my $description = $variables->{description};
    $description = decode('UTF-8', $description);
    my $url = $variables->{url};
    my $webmaster = $variables->{webmaster};
    my $language = $variables->{language};
    my $update = $variables->{update};
    my $content = $variables->{content};
    my $copyright = $variables->{copyright};

    my $xml = XML::Twig->new(
                             keep_encoding => 1
                             )
        ->parse("<feed>" . $content . "</feed>");
    my $root= $xml->root;

    my $cached = $self->cache($name, $extension);
    my @items = ();
    my $dt = DateTime->now();
    my $date = $dt->strftime("%a, %d %b %Y %H:%M:%S %z");
    my $pubDate = $date;

    if (-r $cached) {
        my $oldrss = new XML::RSS (version => '2.0');
        $oldrss->parsefile($cached);
        @items = @{$oldrss->{'items'}};
        $pubDate = $oldrss->{pubDate};
    }
    my $rss = new XML::RSS (version => '2.0');
    $rss->channel(title          => $feedtitle,
                  link           => $url,
                  language       => $language,
                  description    => $description,
                  copyright      => $copyright,
                  pubDate        => $pubDate,
                  lastBuildDate  => $date,
                  managingEditor => $webmaster,
                  webMaster      => $webmaster,
                  );

    my @h1= $root->children('h1');
    foreach my $h1 (@h1) {
        my $title = $h1->text;
        my $guid = decode("UTF-8", $h1->att('id'));
        my $link = $url . "#" . $guid;
        my $date;

        my @grep = grep {$_->{link} eq $link} @items;
        if (@grep) {
            $date = $grep[0]->{pubDate};
        }
        else {
            my $dt = DateTime->now();
            $date = $dt->strftime("%a, %d %b %Y %H:%M:%S %z");
        }
        my $description;
        my @lines;
        my $next = $h1->next_sibling();
        while (defined($next) && $next->tag ne "h1") {
            push @lines, $next->sprint;
            $next = $next->next_sibling();
        }
        $description = join("", @lines);
        $description = decode('UTF-8', $description);
        $description = decode_entities($description);

        $title = decode('UTF-8', $title);
        $title = decode_entities($title);

        $rss->add_item(
                       title => $title,
                       link  => $link,
                       description => $description,
                       pubDate => $date,
                       );
    }
    $rss->save($cached);
    $rss->save($self->output($name, $extension));
}

1;
