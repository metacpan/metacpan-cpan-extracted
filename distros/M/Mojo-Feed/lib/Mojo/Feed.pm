package Mojo::Feed;
use Mojo::Base '-base';

use overload
  bool     => sub { shift->is_valid },
  '""'     => sub { shift->to_string },
  fallback => 1;

our $VERSION = "0.17";

use Mojo::Feed::Item;
use Mojo::DOM;
use HTTP::Date;
use Scalar::Util 'weaken';

has body => '';
has 'source';

has dom => sub {
  my ($self) = @_;
  my $body = $self->body;
  return if !$body;
  return Mojo::DOM->new($body);
};
has feed_type => sub {
  my $top     = shift->dom->children->first;
  my $tag     = $top->tag;
  my $version = $top->attr('version');
  my $ns = $top->attr('namespace');
  return
      ($tag =~ /feed/i) ? ($version) ? 'Atom ' . $version : 'Atom 1.0'
    : ($tag =~ /rss/i)  ? 'RSS ' . $version
    : ($tag =~ /rdf/i)  ? 'RSS 1.0'
    :                     'unknown';
};


my %generic = (
  description => ['description', 'tagline', 'subtitle'],
  published   => [
    'published', 'pubDate', 'dc\:date', 'created',
    'issued',    'updated', 'modified'
  ],
  author   => ['author', 'dc\:creator', 'webMaster'],
  title    => ['title'],
  subtitle => ['subtitle', 'tagline'],
  link     => ['link:not([rel])', 'link[rel=alternate]'],
);

foreach my $k (keys %generic) {
  has $k => sub {
    my $self = shift;
    for my $generic (@{$generic{$k}}) {
      if (my $p = $self->dom->at("channel > $generic, feed > $generic")) {
        if ($k eq 'author' && $p->at('name')) {
          return $p->at('name')->text;
        }
        my $text = $p->text || $p->content || $p->attr('href');
        if ($k eq 'published') {
          return str2time($text);
        }
        return $text;
      }
    }
    return;
  };
}

has items => sub {
  my $self = shift;
  $self->dom->find('item, entry')
    ->map(sub { Mojo::Feed::Item->new(dom => $_, feed => $self) })
    ->each(sub { weaken $_->{feed} });
};

sub is_valid {
  shift->dom->children->first->tag =~ /^(feed|rss|rdf|rdf:rdf)$/i;
}

sub to_hash {
  my $self = shift;
  my $hash = {map { $_ => '' . ($self->$_ || '') } (keys %generic)};
  $hash->{items} = $self->items->map('to_hash')->to_array;
  return $hash;
}

sub to_string {
  shift->dom->to_string;
}

1;
__END__

=encoding utf-8

=for stopwords tagline pubDate dc:date dc:creator webMaster

=head1 NAME

Mojo::Feed - Mojo::DOM-based parsing of RSS & Atom feeds

=head1 SYNOPSIS

    use Mojo::Feed::Reader;
    use Mojo::Feed;

    my $feed = Mojo::Feed::Reader->new->parse("atom.xml");
    print $feed->title, "\n",
      $feed->items->map('title')->join("\n");

    $feed = Mojo::Feed->new( body => $string );

=head1 DESCRIPTION

L<Mojo::Feed> is an Object Oriented module for identifying,
fetching and parsing RSS and Atom Feeds.  It relies on
L<Mojo::DOM> for XML/HTML parsing. Date parsing is done with L<HTTP::Date>.

L<Mojo::Feed> represents the parsed RSS/Atom feed; you can construct it
by setting an XML string as the C<body>, or by using a L<Mojo::Feed::Reader> object.

=head1 ATTRIBUTES

L<Mojo::Feed> implements the following attributes.

=head2 body

The original decoded string of the feed.

=head2 dom

The parsed feed as <Mojo::DOM> object.

=head2 source

The source of the feed; either a L<Mojo::Path> or L<Mojo::URL> object, or
undef if the feed source was a string.

=head2  title

Returns the feed's title.

=head2  description

Description of the feed, filled from channel description (RSS), subtitle (Atom 1.0) or tagline (Atom 0.3)

=head2  link

Web page URL associated with the feed

=head2  items

L<Mojo::Collection> of L<Mojo::Feed::Item> objects representing feed news items

=head2  subtitle

Optional feed description

=head2  author

Name from C<author>, C<dc:creator> or C<webMaster> field

=head2  published

Time in epoch seconds (may be filled with pubDate, dc:date, created, issued, updated or modified)

=head1 METHODS

L<Mojo::Feed> inherits all methods from
L<Mojo::Base> and implements the following new ones.

=head2 new

  my $feed = Mojo::Feed->new;
  my $feed = Mojo::Feed->new( body => $string);

Construct a new L<Mojo::Feed> object.

=head2 to_hash

  my $hash = $feed->to_hash;
  print $hash->{title};

Return a hash reference representing the feed.

=head2 to_string

Return a XML serialized text of the feed's Mojo::DOM node. Note that this can be different from the original XML text in the feed.

=head2 is_valid

Returns true if the top-level element of the DOM is a valid RSS (0.9x, 1.0, 2.0) or Atom tag. Otherwise, returns false.

=head2 feed_type

Detect type of feed - returns one of "RSS 1.0", "RSS 2.0", "Atom 0.3", "Atom 1.0" or "unknown"

=head1 CREDITS

Dotan Dimet

Mario Domgoergen

Some tests adapted from L<Feed::Find> and L<XML:Feed>, Feed auto-discovery adapted from L<Feed::Find>.

=head1 LICENSE

Copyright (C) Dotan Dimet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Dotan Dimet E<lt>dotan@corky.netE<gt>

Mario Domgoergen

=cut

