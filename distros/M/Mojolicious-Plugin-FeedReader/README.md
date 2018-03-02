# NAME

Mojolicious::Plugin::FeedReader - Mojolicious plugin to find and parse RSS & Atom feeds

# SYNOPSIS

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

# DESCRIPTION

**Mojolicious::Plugin::FeedReader** implements minimalistic helpers for identifying,
fetching and parsing RSS and Atom Feeds.  It has minimal dependencies, relying as
much as possible on Mojolicious components - Mojo::UserAgent for fetching feeds and
checking URLs, Mojo::DOM for XML/HTML parsing.
It is therefore rather fragile and naive, and should be considered Experimental/Toy
code - **use at your own risk**.

# METHODS

[Mojolicious::Plugin::FeedReader](https://metacpan.org/pod/Mojolicious::Plugin::FeedReader) inherits all methods from
[Mojolicious::Plugin](https://metacpan.org/pod/Mojolicious::Plugin) and implements the following new ones.

## register

    $plugin->register(Mojolicious->new);

Register plugin in [Mojolicious](https://metacpan.org/pod/Mojolicious) application. This method will install the helpers
listed below in your Mojolicious application.

# HELPERS

**Mojolicious::Plugin::FeedReader** implements the following helpers.

## find\_feeds

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

A Mojolicious port of [Feed::Find](https://metacpan.org/pod/Feed::Find) by Benjamin Trott. This helper implements feed auto-discovery for finding syndication feeds, given a URI.
If given a callback function as an additional argument, execution will be non-blocking.

## parse\_feed

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

Dates are parsed using [HTTP::Date](https://metacpan.org/pod/HTTP::Date).

If parsing fails (for example, the parser was given an HTML page), the helper will return undef.

On success, the result returned is a hashref with the following keys:

- title
- description (may be filled from subtitle or tagline if absent)
- htmlUrl - web page URL associated with the feed
- items - array ref of feed news items
- subtitle (optional)
- tagline (optional)
- author (name of author field, or dc:creator or webMaster)
- published - time in epoch seconds (may be filled with pubDate, dc:date, created, issued, updated or modified)

Each item in the items array is a hashref with the following keys:

- title
- link
- content (may be filled with content:encoded, xhtml:body or description fields)
- id (will be equal to link or guid if it is undefined and either of those fields exists)
- description (optional) - usually a shorter form of the content (may be filled with summary if description is missing)
- guid (optional)
- published - time in epoch seconds (may be filled with pubDate, dc:date, created, issued, updated or modified)
- author (may be filled from author or dc:creator)
- tags (optional) - array ref of tags, categories or dc:subjects.
- \_raw - XML serialized text of the item's Mojo::DOM node. Note that this can be different from the original XML text in the feed.

## parse\_opml

    my @subscriptions = app->parse_opml( 'mysubs.opml' );
    foreach my $sub (@subscriptions) {
      say 'RSS URL is: ',     $sub->{xmlUrl};
      say 'Website URL is: ', $sub->{htmlUrl};
      say 'categories: ', join ',', @{$sub->{categories}};
    }

Parse an OPML subscriptions file and return the list of feeds as an array of hashrefs.

Each hashref will contain an array ref in the key 'categories' listing the folders (parent nodes) in the OPML tree the subscription item appears in.

# STAND-ALONE USE

[Mojolicious::Plugin::FeedReader](https://metacpan.org/pod/Mojolicious::Plugin::FeedReader) can also be used directly, rather than as a plugin:

    use Mojolicious::Plugin::FeedReader;
    my $fr = Mojolicious::Plugin::FeedReader->new( ua => Mojo::UserAgent->new );
    my ($feed) = $fr->find_feeds($url);
    ...

In the future, the feed-parsing code will probably move into its own module.

# CREDITS

Dotan Dimet

Mario Domgoergen

Some tests adapted from [Feed::Find](https://metacpan.org/pod/Feed::Find) and [XML:Feed](XML:Feed), Feed autodiscovery adapted from [Feed::Find](https://metacpan.org/pod/Feed::Find).

# COPYRIGHT AND LICENSE

Copyright (C) 2014, Dotan Dimet.

This program is free software, you can redistribute it and/or modify it
under the terms of the Artistic License version 2.0.

Test data (web pages, feeds and excerpts) included in this package is intended for testing purposes only, and is not meant in any way
to infringe on the rights of the respective authors.

# SEE ALSO

[Mojolicious](https://metacpan.org/pod/Mojolicious), [Mojolicious::Guides](https://metacpan.org/pod/Mojolicious::Guides), [http://mojolicio.us](http://mojolicio.us)

[XML::Feed](https://metacpan.org/pod/XML::Feed), [Feed::Find](https://metacpan.org/pod/Feed::Find), [HTTP::Date](https://metacpan.org/pod/HTTP::Date)
