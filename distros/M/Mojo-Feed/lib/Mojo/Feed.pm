package Mojo::Feed;
use Mojo::Base '-base';
use Mojo::DOM;
use Mojo::File;
use Mojo::URL;
use Mojo::UserAgent;
use Mojo::Util qw(decode trim);

use Carp qw(croak);
use List::Util;
use HTTP::Date qw(str2time);

use Mojo::Feed::Item;

use overload
  bool     => sub { shift->is_valid },
  '""'     => sub { shift->to_string },
  fallback => 1;

our $VERSION = "0.20";

has charset => 'UTF-8';

has ua            => sub { Mojo::UserAgent->new() };
has max_redirects => sub { $ENV{MOJO_MAX_REDIRECTS} || 3 };
has redirects     => sub { [] };
has related       => sub { [] };

has url  => sub { Mojo::URL->new() };
has file => sub { Mojo::File->new() };
has source => sub {
  my $self = shift;
  return
      ($self->url ne '') ? $self->url
    : (-f $self->file)   ? $self->file
    :                      undef;
};

has body => sub {
  my $self = shift;
  if ($self->url ne '') {
    return $self->_load();
  }
  else {    # skip file tests, just slurp (for Mojo::Asset::File)
    return $self->file->slurp();
  }
};

has text => sub {
  my $self = shift;
  return decode($self->charset, $self->body) || '';
};

has dom => sub {
  my ($self) = @_;
  return Mojo::DOM->new($self->text);
};

has root => sub { shift->dom->children->first };

has feed_type => sub {
  my $top     = shift->root;
  my $tag     = $top->tag;
  my $version = $top->attr('version');
  my $ns      = $top->namespace;
  return
      ($tag =~ /feed/i)
    ? ($version)
      ? 'Atom ' . $version
      : 'Atom 1.0'
    : ($tag =~ /rss/i) ? 'RSS ' . $version
    : ($tag =~ /rdf/i) ? 'RSS 1.0'
    :                    'unknown';
};

has namespaces => sub {
  my $top = shift->root;
  my $namespaces = { atom => $top->namespace };  # only Atom feeds declare a namespace?
  my $attrs = $top->attr;
  for my $at (keys %$attrs) {
    if ($at =~ /xmlns\:(\w+)/) { # extra namespace declaration
      $namespaces->{$1} = $attrs->{$at};
    }
  }
  return $namespaces;
};

my %generic = (
  description => ['description', 'tagline', 'subtitle'],
  published   => [
    'published', 'pubDate', 'dc|date', 'created',
    'issued',    'updated', 'modified'
  ],
  author   => ['author', 'dc|creator', 'webMaster', 'copyright'],
  title    => ['title'],
  subtitle => ['subtitle', 'tagline'],
  link     => ['link:not([rel])', 'link[rel=alternate]'],
);

foreach my $k (keys %generic) {
  has $k => sub {
    my $self = shift;
    for my $generic (@{$generic{$k}}) {
      if (my $p = $self->dom->at("channel > $generic, feed > $generic", %{$self->namespaces})) {
        if ($k eq 'author' && $p->at('name')) {
          return trim $p->at('name')->text;
        }
        my $text = trim($p->text || $p->content || $p->attr('href') || '');
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
    ->map(sub { Mojo::Feed::Item->new(dom => $_, feed => $self) });
};

# alias
sub entries { shift->items() };

has is_valid => sub {
  shift->dom->children->first->tag =~ /^(feed|rss|rdf|rdf:rdf)$/i;
};

sub is_feed_content_type {
  my ($self, $content_type) = @_;
  # use split to remove charset attribute from content_type header
  ($content_type) = split(/[; ]+/, $content_type);
# feed mime-types:
  my @feed_types = (
    'application/x.atom+xml', 'application/atom+xml',
    'application/xml',        'text/xml',
    'application/rss+xml',    'application/rdf+xml'
  );
  return List::Util::first { $_ eq $content_type } @feed_types;
}


sub _load {
  my ($self) = @_;
  my $tx     = $self->ua->get($self->url);
  my $result = $tx->result;                  # this will croak on network errors

  if ($result->is_error) {
    $self->is_valid(undef);
    croak "Error getting feed from url ", $self->url, ": ", $result->message;
  }

  # Redirect:
  elsif ($result->code == 301 || $result->code == 302) {
    my $new_url = Mojo::URL->new($result->headers->location);
    push @{$self->redirects}, $self->url;
    $self->url($new_url);
    if (@{$self->redirects} > $self->max_redirects) {
      $self->is_valid(undef);
      croak "Number of redirects exceeded when loading feed"
    }
    return $self->_load();
  }

  # Is this a feed (by content type)?
  if ($self->is_feed_content_type($result->headers->content_type)) {
    $self->charset($result->content->charset) if ($result->content->charset);
    return $result->body;
  }
  else {
    # we are in a web page. PHEAR.

    # Set real (absolute) URL (is this only relevant for testing?):
    if ($self->url ne $tx->req->url) {
      push @{$self->redirects}, $self->url;  # for logging?
      $self->url($tx->req->url);
    }
    my @feeds = $self->find_feed_links($result);

    if (@feeds) {
      push @{$self->redirects}, $self->url; # not really a redirect, but save it
      $self->url(shift @feeds);

      # save any remaining feed links as related
      push @{$self->related}, @feeds if (@feeds);
      return $self->_load();
    }
   else {
        # call me crazy, but maybe this is just a feed served as HTML?
        my $test = Mojo::Feed->new( url => $self->url, body => $result->body );
        $test->charset($result->content->charset) if ($result->content->charset);
        if ($test->is_valid) {
          # can't avoid parsing twice;
          # body is probably being called in the dom initializer
          # :(
          # $self->dom($test->dom);
          $self->charset($test->charset) if ($test->charset);
          return $test->body;
        }
        else {
          $self->is_valid(undef);
          croak "No valid feed found at ", $self->url;
        }
   }
  }
}

sub find_feed_links {
  my ($self, $result) = @_;
  my @feeds;

  # Find feed link elements in HEAD:
  my $base
    = Mojo::URL->new(
    $result->dom->find('head base')->map('attr', 'href')->join('') || $self->url)
    ->to_abs($self->url);
  my $title
    = $result->dom->find('head > title')->map('text')->join('') || $self->url;
  $result->dom->find('head link')->each(sub {
    my $attrs = $_->attr();
    return unless ($attrs->{'rel'});
    my %rel = map { $_ => 1 } split /\s+/, lc($attrs->{'rel'});
    my $type = ($attrs->{'type'}) ? lc trim $attrs->{'type'} : undef;
    if ($type && $self->is_feed_content_type($type)
      && ($rel{'alternate'} || $rel{'service.feed'}))
    {
      push @feeds, Mojo::URL->new($attrs->{'href'})->to_abs($base);
    }
  });

  # Find feed links (<A HREF="...something feed-like">)
  state $feed_exp = qr/((\.(?:rss|xml|rdf)$)|(\/feed\/*$)|(feeds*\.))/;
  $result->dom->find('a')->grep(sub {
    $_->attr('href') && $_->attr('href') =~ /$feed_exp/io;
  })->each(sub {
    push @feeds, Mojo::URL->new($_->attr('href'))->to_abs($base);
  });
  return @feeds;
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

    use Mojo::Feed;
    use Mojo::File qw(path);

    my $feed = Mojo::Feed->new->parse(file => path("atom.xml"));
    print $feed->title, "\n",
      $feed->items->map('title')->join("\n");

    $feed = Mojo::Feed->new( body => $string );
    $feed = Mojo::Feed->new( url => $rss_url );

    my $feed = Mojo::Feed->new(
      url => "https://github.com/dotandimet/Mojo-Feed/commits/master.atom");
    say $feed->title;
    $feed->items->each(
      sub { say $_->title, q{ }, Mojo::Date->new($_->published); });

=head1 DESCRIPTION

L<Mojo::Feed> is an Object Oriented module for identifying,
fetching and parsing RSS and Atom Feeds.  It relies on
L<Mojo::DOM> for XML/HTML parsing. Date parsing is done with L<HTTP::Date>.

L<Mojo::Feed> represents the parsed RSS/Atom feed; you can construct it
by setting an XML string as the C<body> attribute, by setting the C<file> or C<url>
attributes to a L<Mojo::File> or L<Mojo::URL> respectively, or by using a
L<Mojo::Feed::Reader> object.

=head1 ATTRIBUTES

L<Mojo::Feed> implements the following attributes.

=head2 body

The original decoded string of the feed.

=head2 dom

The parsed feed as L<Mojo::DOM> object.

=head2 source

The source of the feed; either a L<Mojo::File> or L<Mojo::URL> object, or
undef if the feed source was a string.

=head2  title

Returns the feed's title.

=head2  description

Description of the feed, filled from channel description (RSS), subtitle (Atom 1.0) or tagline (Atom 0.3)

=head2  link

Web page URL associated with the feed

=head2  items

L<Mojo::Collection> of L<Mojo::Feed::Item> objects representing feed news items

=head2  entries

Alias name for C<items>.

=head2  subtitle

Optional feed description

=head2  author

Name from C<author>, C<dc:creator> or C<webMaster> field

=head2  published

Time in epoch seconds (may be filled with pubDate, dc:date, created, issued, updated or modified)

=head2 url

A L<Mojo::URL> object from which to load the file. If set, it will set C<source>. The C<url> attribute
may change when the feed is loaded if the user agent receives a redirect.

=head2 file

A L<Mojo::File> object from which to read the file. If set, it will set C<source>.

=head2 is_valid

True if the top-level element of the DOM is a valid RSS (0.9x, 1.0, 2.0) or Atom tag. Otherwise, false.

=head2 feed_type

Detect type of feed - returns one of "RSS 1.0", "RSS 2.0", "Atom 0.3", "Atom 1.0" or "unknown"

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

=head2 is_feed_content_type

Accepts a mime type string as an argument; returns true if it is one
of the accepted mime-types for RSS/Atom feeds, undef otherwise.

=head2 find_feed_links

Accepts a Mojo::Message::Response returned from an HTML page, uses its dom() method to find either LINK elements in the HEAD or links (A elements) that link to a possible RSS/Atom feed.

=head1 CREDITS

Dotan Dimet

Mario Domgoergen

Some tests adapted from L<Feed::Find> and L<XML:Feed>, Feed auto-discovery adapted from L<Feed::Find>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) Dotan Dimet E<lt>dotan@corky.netE<gt>.

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

Test data (web pages, feeds and excerpts) included in this package is intended
for testing purposes only, and is not meant in any way to infringe on the
rights of the respective authors.

=head1 AUTHOR

Dotan Dimet E<lt>dotan@corky.netE<gt>

=cut

