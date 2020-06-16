package Mojo::Feed::Reader;
use Mojo::Base -base;

use Mojo::UserAgent;
use Mojo::Feed;
use Mojo::File 'path';
use Mojo::Util 'decode', 'trim';
use Carp qw(carp croak);
use Scalar::Util qw(blessed);

has charset => 'UTF-8';

has ua            => sub { Mojo::UserAgent->new };

sub parse {
    my ( $self, $xml, $charset ) = @_;
    return undef unless ($xml);
    my ( $body, $source, $url, $file, $feed );
    if ( $body = $self->_from_string($xml) ) {
        $feed = Mojo::Feed->new( body => $body );
    }
    elsif ( $file = $self->_from_file($xml) ) {
        $feed = Mojo::Feed->new( file => $file );
    }
    elsif ( $url = $self->_from_url($xml) ) {
        $feed = Mojo::Feed->new( url => $url, ua => $self->ua );
    }
    else {
        croak "unknown argument $xml";
    }
    $feed->charset($charset) if ($charset);
    return ( $feed->is_valid ) ? $feed : undef;
}

sub _from_string {
    my ( $self, $xml ) = @_;
    my $str = ( !ref $xml ) ? $xml : ( ref $xml eq 'SCALAR' ) ? $$xml : '';
    return ( $str =~ /^\s*\</s ) ? $str : undef;
}

sub _from_url {
    my ( $self, $xml ) = @_;
    my $url =
        ( blessed $xml && $xml->isa('Mojo::URL') ) ? $xml->clone()
      : ( $xml =~ /^https?\:/ ) ? Mojo::URL->new("$xml")
      :                           undef;
    return $url;
}

sub _from_file {
    my ( $self, $xml ) = @_;
    my $file =
        ( ref $xml )
      ? ( blessed $xml && $xml->can('slurp') )
          ? $xml
          : undef
      : ( -r "$xml" ) ? Mojo::File->new($xml)
      :                 undef;
    return $file;
}

# discover - get RSS/Atom feed URL from argument.
# Code adapted to use Mojolicious from Feed::Find by Benjamin Trott
# Any stupid mistakes are my own
sub discover {
    my ( $self, $url ) = @_;

    #  $self->ua->max_redirects(5)->connect_timeout(30);
    return $self->ua->get_p($url)
      ->catch( sub { my ($err) = shift; croak "Connection Error: $err" } )
      ->then(
        sub {
            my ($tx) = @_;
            if ( $tx->res->is_success && $tx->res->code == 200 ) {
                my $feed = Mojo::Feed->new(url => $tx->req->url);
                return $feed->url if ($feed->is_feed_content_type($tx->res->headers->content_type));
                my @feeds = $feed->find_feed_links($tx->res);
                return @feeds if (@feeds);
                $feed->body($tx->res->body);
                $feed->charset($tx->res->content->charset) if ($tx->res->content->charset);
                return $feed->url if ($feed->is_valid);
            }
            return;
        }
      );
}

sub parse_opml {
    my ( $self, $opml_file ) = @_;
    my $opml_str = decode $self->charset,
      ( ref $opml_file )
      ? $opml_file->slurp
      : Mojo::File->new($opml_file)->slurp;
    my $d = Mojo::DOM->new->parse($opml_str);
    my ( %subscriptions, %categories );
    for my $item ( $d->find(q{outline})->each ) {
        my $node = $item->attr;
        if ( !defined $node->{xmlUrl} ) {
            my $cat = $node->{title} || $node->{text};
            $categories{$cat} =
              $item->children('[xmlUrl]')->map( 'attr', 'xmlUrl' );
        }
        else {    # file by RSS URL:
            $subscriptions{ $node->{xmlUrl} } = $node;
        }
    }

    # assign categories
    for my $cat ( keys %categories ) {
        for my $rss ( $categories{$cat}->each ) {
            next
              unless ( $subscriptions{$rss} )
              ;    # don't auto-vivify for empty "categories"
            $subscriptions{$rss}{'categories'} ||= [];
            push @{ $subscriptions{$rss}{'categories'} }, $cat;
        }
    }
    return ( values %subscriptions );
}

1;
__END__

=encoding utf-8

=for stopwords tagline pubDate dc:date

=head1 NAME

Mojo::Feed::Reader - Fetch feeds

=head1 SYNOPSIS

    use Mojo::Feed::Reader;

    my $feedr = Mojo::Feed::Reader->new( ua => $ua );
    my $feed = $feedr->parse("atom.xml");
    print $feed->title, "\n",
      $feed->items->map('title')->join("\n");

    # Feed discovery (returns a Promise):
    $feedr->discover("search.cpan.org")->then(sub {
      my (@feeds) = @_;
      if (@feeds) {
        print $_ for (@feeds);
      }
    })->catch(sub { die "Error: ", @_; });

   # 

=head1 DESCRIPTION

L<Mojo::Feed::Reader> is an Object Oriented module for identifying,
fetching and parsing RSS and Atom Feeds.  It relies on
L<Mojo::DOM> for XML/HTML parsing and L<Mojo::UserAgent>
for fetching feeds and checking URLs.

=head1 ATTRIBUTES

L<Mojo::Feed::Reader> implements the following attributes.

=head2 ua

  $feed->ua(Mojo::UserAgent->new());
  $feed->ua->get("http://example.com");

L<Mojo::UserAgent> object used to fetch feeds from the web.

=head1 METHODS

L<Mojo::Feed::Reader> inherits all methods from
L<Mojo::Base> and implements the following new ones.

=head2 new

Construct a new L<Mojo::Feed::Reader> object.

=head2 discover

  my @feeds;
  Mojo::Feed::Reader->new->discover('search.cpan.org')
            ->then(sub { @feeds = @_; })
            ->wait();
  for my $feed in (@feeds) {
    print $feed . "\n";
  }
  # @feeds is a list of Mojo::URL objects

A Mojo port of L<Feed::Find> by Benjamin Trott. This method implements feed
auto-discovery for finding syndication feeds, given a URL.
Returns a Mojo::Promise, which is fulfilled with a list of feeds (Mojo::URL
objects)

=head2 parse

  my $feedr = Mojo::Feed::Reader->new;
  # parse an RSS/Atom feed
  my $url = Mojo::URL->new('http://rss.slashdot.org/Slashdot/slashdot');
  my $feed = $feedr->parse($url);

  # parse a file
  $feed2 = $feedr->new->parse('/downloads/foo.rss');

  # parse a string
  my $str = Mojo::File->new('atom.xml')->slurp;
  $feed3 = $feedr->parse($str);

A minimalist liberal RSS/Atom parser, using Mojo::DOM queries.

If the parsed object is not a feed (for example, the parser was given an HTML page),
the method will return undef.

=head2 parse_opml

  my @subscriptions = Mojo::Feed::Reader->new->parse_opml( 'mysubs.opml' );
  foreach my $sub (@subscriptions) {
    say 'RSS URL is: ',     $sub->{xmlUrl};
    say 'Website URL is: ', $sub->{htmlUrl};
    say 'categories: ', join ',', @{$sub->{categories}};
  }

Parse an OPML subscriptions file and return the list of feeds as an array of hashrefs.

Each hashref will contain an array ref in the key 'categories' listing the folders (parent nodes) in the OPML tree the subscription item appears in.

=head1 CREDITS

Dotan Dimet

Mario Domgoergen

Some tests adapted from L<Feed::Find> and L<XML:Feed>, Feed auto-discovery adapted from L<Feed::Find>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Dotan Dimet E<lt>dotan@corky.netE<gt>.

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

Test data (web pages, feeds and excerpts) included in this package is intended
for testing purposes only, and is not meant in any way to infringe on the
rights of the respective authors.

=head1 AUTHOR

Dotan Dimet E<lt>dotan@corky.netE<gt>

=cut

1;
