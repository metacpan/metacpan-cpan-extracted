# NAME

Mojolicious::Plugin::Ical - Generate .ical documents

# VERSION

0.05

# SYNOPSIS

## Application

    use Mojolicious::Lite;
    plugin ical => {
      properties => {
        calscale      => "GREGORIAN"         # default GREGORIAN
        method        => "REQUEST",          # default PUBLISH
        prodid        => "-//ABC Corporation//NONSGML My Product//EN",
        version       => "1.0",              # default to 2.0
        x_wr_caldesc  => "Some description",
        x_wr_calname  => "My calender",
        x_wr_timezone => "EDT",              # default to timezone for localhost
      }
    };

    get '/calendar' => sub {
      my $c = shift;
      $c->reply->ical({
        events => [
          {
            created       => $date,
            description   => $str,   # http://www.kanzaki.com/docs/ical/description.html
            dtend         => $date,
            dtstamp       => $date,  # UTC time format, defaults to "now"
            dtstart       => $date,
            last_modified => $date,  # defaults to "now"
            location      => $str,   # http://www.kanzaki.com/docs/ical/location.html
            sequence      => $int,   # default 0
            status        => $str,   # default CONFIRMED
            summary       => $str,   # http://www.kanzaki.com/docs/ical/summary.html
            transp        => $str,   # default OPAQUE
            uid           => $str,   # default to md5 of the values @hostname
          },
          ...
        ],
      });
    };

    # or using respond_to()
    get '/events' => sub {
      my $c = shift;
      my $ical = { events => [...] };
      $c->respond_to(
        ical => {handler => 'ical', ical => $ical},
        json => {json => $ical}
      );
    };

# DESCRIPTION

[Mojolicious::Plugin::Ical](https://metacpan.org/pod/Mojolicious%3A%3APlugin%3A%3AIcal) is a [Mojolicious](https://metacpan.org/pod/Mojolicious) plugin for generating
[iCalendar](http://www.kanzaki.com/docs/ical/) documents.

This plugin will...

- Add the helper ["reply.ical"](#reply-ical).
- Add ".ical" type to ["types" in Mojolicious](https://metacpan.org/pod/Mojolicious#types).
- Add a handler "ical" to ["renderer" in Mojolicious](https://metacpan.org/pod/Mojolicious#renderer).

# HELPERS

## reply.ical

    $c = $c->reply->ical({ events => [...], properties => {...} });

Will render a iCal document with the Content-Type "text/calender".

`events` is an array ref of calendar events.
`properties` will override the defaults given to ["register"](#register).

See ["SYNOPSIS"](#synopsis) for more details.

# METHODS

## register

    plugin ical => {properties => {...}};

Register ["reply.ical"](#reply-ical) helper.

# COPYRIGHT AND LICENSE

Copyright (C) 2014, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# AUTHOR

Jan Henning Thorsen - `jhthorsen@cpan.org`
