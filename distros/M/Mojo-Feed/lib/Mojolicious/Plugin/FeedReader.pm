package Mojolicious::Plugin::FeedReader;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::Feed::Reader;

our $VERSION = "0.17";

use Scalar::Util qw(blessed);

has feed_reader => sub { Mojo::Feed::Reader->new };

sub new {
  my $self = shift;
  return $self->SUPER::new(feed_reader => Mojo::Feed::Reader->new(@_));
}

sub register {
  my ($self, $app) = @_;
  $self->feed_reader->ua($app->ua);
  $app->helper(parse_feed => sub { shift; $self->parse_rss(@_); });
  $app->helper(parse_rss  => sub { shift; $self->parse_rss(@_); });
  $app->helper(find_feeds => sub { shift; $self->find_feeds(@_); });
  $app->helper(parse_opml => sub { shift; $self->feed_reader->parse_opml(@_) });
}

sub parse_rss {
  my $self = shift;
  my @args = @_;

  # handle deprecated case of using Mojo::DOM as input
  if (ref $args[0] && blessed $args[0] && $args[0]->isa('Mojo::DOM')) {
    $args[0] = $args[0]->to_string();
  }

  # handle special case of being passed a callback - make non-blocking call
  if ( ref $args[0]
    && blessed $args[0]
    && $args[0]->isa('Mojo::URL')
    && ref $args[1]
    && ref $args[1] eq 'CODE')
  {
    $self->feed_reader->ua->get(
      $args[0],
      sub {
        my $tx = pop;
        my $feed = undef;
        my $result = $tx->result;
        if ($result->is_success) {
          my $feed_obj = $self->feed_reader->parse($result->body,
            $result->content->charset);
          if ($feed_obj) {
            $feed = $feed_obj->to_hash;
            $feed->{'htmlUrl'} = delete $feed->{'link'};
            for (keys %$feed) { delete $feed->{$_} if ($feed->{$_} eq '') };
            delete $feed->{'items'} if (scalar @{$feed->{'items'}} == 0);
          }
        }
        $args[1]->($feed);
      }
    );
  }
  else {
    my $feed_obj = $self->feed_reader->parse(@args);
    return undef unless ($feed_obj);
    my $feed = $feed_obj->to_hash;
    $feed->{'htmlUrl'} = delete $feed->{'link'};
    for (keys %$feed) { delete $feed->{$_} if ($feed->{$_} eq '') };
    delete $feed->{'items'} if (scalar @{$feed->{'items'}} == 0);
    return $feed;
  }
}

sub find_feeds {
  my $self = shift;
  my $cb;
  if (ref $_[-1] && ref $_[-1] eq 'CODE') {
    $cb = pop @_;
  }
  my $promise = $self->feed_reader->discover(@_);
  if ($cb) {
    $promise->then($cb);
  }
  else {
    my @res;
    $promise->then(sub { @res = @_; })->wait;
    return @res;
  }
}

1;

__END__

=encoding utf-8

=for stopwords htmlUrl xhtml:body dc:subjects autodiscovery
=head1 NAME

Mojolicious::Plugin::FeedReader - Mojolicious plugin to find and parse RSS & Atom feeds

=head1 SYNOPSIS

        # Mojolicious
         $self->plugin('FeedReader');

         # Mojolicious::Lite
         plugin 'FeedReader';

        # Blocking:
        get '/b' => sub {
          my $self = shift;
          my ($feed) = $self->find_feeds(q{search.cpan.org});
          my $out = $self->parse_feed($feed);
          $self->render(template => 'uploads', items => $out->{items});
        };

        # Non-blocking:
        get '/nb' => sub {
          my $self = shift;
          $self->render_later;
          my $delay = Mojo::IOLoop->delay(
            sub {
              $self->find_feeds("search.cpan.org", shift->begin(0));
            },
            sub {
              my $feed = pop;
              $self->parse_feed($feed, shift->begin);
            },
            sub {
                my $data = pop;
                $self->render(template => 'uploads', items => $data->{items});
            });
          $delay->wait unless Mojo::IOLoop->is_running;
        };

        app->start;

        __DATA__

        @@ uploads.html.ep
        <ul>
        % for my $item (@$items) {
          <li><%= link_to $item->{title} => $item->{link} %> - <%= $item->{description} %></li>
        % }
        </ul>

=head1 DESCRIPTION

B<Mojolicious::Plugin::FeedReader> implements minimalistic helpers for identifying,
fetching and parsing RSS and Atom Feeds.  It has minimal dependencies, relying as
much as possible on Mojolicious components - Mojo::UserAgent for fetching feeds and
checking URLs, Mojo::DOM for XML/HTML parsing.

The feed parsing code has been restructured as a stand-alone module, L<Mojo::Feed>.
The current version of the plugin (packaged inside the L<Mojo::Feed> distribution)
maintains backwards-compatibility but uses L<Mojo::Feed::Reader> internally.

=head1 METHODS

L<Mojolicious::Plugin::FeedReader> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application. This method will install the helpers
listed below in your Mojolicious application.

=head1 HELPERS

B<Mojolicious::Plugin::FeedReader> implements the following helpers.

=head2 find_feeds

  # Call blocking
  my (@feeds) = app->find_feeds('search.cpan.org');
  # @feeds is a list of Mojo::URL objects

  # Call non-blocking
  $self->find_feeds('http://example.com', sub {
    my (@feeds) = @_;
    unless (@feeds) {
      $self->render_exception("no feeds found, " . $info->{error});
    }
    else {
      ....
    }
  });

A Mojolicious port of L<Feed::Find> by Benjamin Trott. This helper implements feed auto-discovery for finding syndication feeds, given a URI.
If given a callback function as an additional argument, execution will be non-blocking.

=head2 parse_feed

  # parse an RSS/Atom feed
  # blocking
  my $url = Mojo::URL->new('http://rss.slashdot.org/Slashdot/slashdot');
  my $feed = $self->parse_feed($url);
  for my $item (@{$feed->{items}}) {
    say $_ for ($item->{title}, $item->{description}, 'Tags: ' . join q{,}, @{$item->{tags}});
  }

  # non-blocking
  $self->parse_feed($url, sub {
    my ($feed) = @_;
    $c->render(text => "Feed tagline: " . $feed->{tagline});
  });

  # parse a file
  $feed2 = $self->parse_feed('/downloads/foo.rss');

  # parse response
  $self->ua->get($feed_url, sub {
    my ($ua, $tx) = @_;
    my $feed = $self->parse_feed($tx->res);
  });

A minimalist liberal RSS/Atom parser, using Mojo::DOM queries.

Dates are parsed using L<HTTP::Date>.

If the parsed object is not a feed (for example, the parser was given an HTML page), the helper will return undef.

On success, the result returned is a hashref with the following keys:

=over 4

=item * title

=item * description (may be filled from subtitle or tagline if absent)

=item * htmlUrl - web page URL associated with the feed

=item * items - array ref of feed news items

=item * subtitle (optional)

=item * tagline (optional)

=item * author (name of author field, or dc:creator or webMaster)

=item * published - time in epoch seconds (may be filled with pubDate, dc:date, created, issued, updated or modified)

=back

Each item in the items array is a hashref with the following keys:

=over 4

=item * title

=item * link

=item * content (may be filled with content:encoded, xhtml:body or description fields)

=item * id (will be equal to link or guid if it is undefined and either of those fields exists)

=item * description (optional) - usually a shorter form of the content (may be filled with summary if description is missing)

=item * guid (optional)

=item * published - time in epoch seconds (may be filled with pubDate, dc:date, created, issued, updated or modified)

=item * author (may be filled from author or dc:creator)

=item * tags (optional) - array ref of tags, categories or dc:subjects.

=item * _raw - XML serialized text of the item's Mojo::DOM node. Note that this can be different from the original XML text in the feed.

=back

=head2 parse_opml

  my @subscriptions = app->parse_opml( 'mysubs.opml' );
  foreach my $sub (@subscriptions) {
    say 'RSS URL is: ',     $sub->{xmlUrl};
    say 'Website URL is: ', $sub->{htmlUrl};
    say 'categories: ', join ',', @{$sub->{categories}};
  }

Parse an OPML subscriptions file and return the list of feeds as an array of hashrefs.

Each hashref will contain an array ref in the key 'categories' listing the folders (parent nodes) in the OPML tree the subscription item appears in.

=head1 STAND-ALONE USE

L<Mojolicious::Plugin::FeedReader> can also be used directly, rather than as a plugin:

  use Mojolicious::Plugin::FeedReader;
  my $fr = Mojolicious::Plugin::FeedReader->new( ua => Mojo::UserAgent->new );
  my ($feed) = $fr->find_feeds($url);
  ...

However, it is recommended you use L<Mojo::Feed::Reader> directly instead.


=head1 CREDITS

Dotan Dimet

Mario Domgoergen

Some tests adapted from L<Feed::Find> and L<XML:Feed>, Feed autodiscovery adapted from L<Feed::Find>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014, Dotan Dimet.

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

Test data (web pages, feeds and excerpts) included in this package is intended for testing purposes only, and is not meant in any way
to infringe on the rights of the respective authors.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>

L<XML::Feed>, L<Feed::Find>, L<HTTP::Date>

=cut
