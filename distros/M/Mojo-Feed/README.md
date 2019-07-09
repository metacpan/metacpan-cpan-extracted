[![Build Status](https://travis-ci.org/dotandimet/Mojo-Feed.svg?branch=master)](https://travis-ci.org/dotandimet/Mojo-Feed)
# NAME

Mojo::Feed - Mojo::DOM-based parsing of RSS & Atom feeds

# SYNOPSIS

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

# DESCRIPTION

[Mojo::Feed](https://metacpan.org/pod/Mojo::Feed) is an Object Oriented module for identifying,
fetching and parsing RSS and Atom Feeds.  It relies on
[Mojo::DOM](https://metacpan.org/pod/Mojo::DOM) for XML/HTML parsing. Date parsing is done with [HTTP::Date](https://metacpan.org/pod/HTTP::Date).

[Mojo::Feed](https://metacpan.org/pod/Mojo::Feed) represents the parsed RSS/Atom feed; you can construct it
by setting an XML string as the `body` attribute, by setting the `file` or `url`
attributes to a [Mojo::File](https://metacpan.org/pod/Mojo::File) or [Mojo::URL](https://metacpan.org/pod/Mojo::URL) respectively, or by using a
[Mojo::Feed::Reader](https://metacpan.org/pod/Mojo::Feed::Reader) object.

# ATTRIBUTES

[Mojo::Feed](https://metacpan.org/pod/Mojo::Feed) implements the following attributes.

## body

The original decoded string of the feed.

## dom

The parsed feed as <Mojo::DOM> object.

## source

The source of the feed; either a [Mojo::File](https://metacpan.org/pod/Mojo::File) or [Mojo::URL](https://metacpan.org/pod/Mojo::URL) object, or
undef if the feed source was a string.

## title

Returns the feed's title.

## description

Description of the feed, filled from channel description (RSS), subtitle (Atom 1.0) or tagline (Atom 0.3)

## link

Web page URL associated with the feed

## items

[Mojo::Collection](https://metacpan.org/pod/Mojo::Collection) of [Mojo::Feed::Item](https://metacpan.org/pod/Mojo::Feed::Item) objects representing feed news items

## subtitle

Optional feed description

## author

Name from `author`, `dc:creator` or `webMaster` field

## published

Time in epoch seconds (may be filled with pubDate, dc:date, created, issued, updated or modified)

## url

A [Mojo::URL](https://metacpan.org/pod/Mojo::URL) object from which to load the file. If set, it will set `source`. The `url` attribute
may change when the feed is loaded if the user agent receives a redirect.

## file

A [Mojo::File](https://metacpan.org/pod/Mojo::File) object from which to read the file. If set, it will set `source`.

# METHODS

[Mojo::Feed](https://metacpan.org/pod/Mojo::Feed) inherits all methods from
[Mojo::Base](https://metacpan.org/pod/Mojo::Base) and implements the following new ones.

## new

    my $feed = Mojo::Feed->new;
    my $feed = Mojo::Feed->new( body => $string);

Construct a new [Mojo::Feed](https://metacpan.org/pod/Mojo::Feed) object.

## to\_hash

    my $hash = $feed->to_hash;
    print $hash->{title};

Return a hash reference representing the feed.

## to\_string

Return a XML serialized text of the feed's Mojo::DOM node. Note that this can be different from the original XML text in the feed.

## is\_valid

Returns true if the top-level element of the DOM is a valid RSS (0.9x, 1.0, 2.0) or Atom tag. Otherwise, returns false.

## feed\_type

Detect type of feed - returns one of "RSS 1.0", "RSS 2.0", "Atom 0.3", "Atom 1.0" or "unknown"

# CREDITS

Dotan Dimet

Mario Domgoergen

Some tests adapted from [Feed::Find](https://metacpan.org/pod/Feed::Find) and [XML:Feed](XML:Feed), Feed auto-discovery adapted from [Feed::Find](https://metacpan.org/pod/Feed::Find).

# LICENSE

Copyright (C) Dotan Dimet.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Dotan Dimet <dotan@corky.net>
