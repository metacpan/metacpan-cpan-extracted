# NAME

Plack::Middleware::StatsPerRequest - Measure HTTP stats on each request

# VERSION

version 0.902

# SYNOPSIS

    use Plack::Builder;
    use Measure::Everything::Adapter;
    Measure::Everything::Adapter->set('InfluxDB::File', {
        file => '/tmp/yourapp.stats',
    });

    builder {
        enable "Plack::Middleware::StatsPerRequest",
            app_name => 'YourApp',
        ;
        $app;
    };

    # curl http://localhost:3000/some/path
    # cat /tmp/yourapp.stats
      http_request,app=YourApp,method=GET,path=/some/path,status=400 hit=1i,request_time=0.02476 1519658691411352000

# DESCRIPTION

`Plack::Middleware::StatsPerRequest` lets you collect stats about all your
HTTP requests via [Measure::Everything](https://metacpan.org/pod/Measure%3A%3AEverything).
`Plack::Middleware::StatsPerRequest` calculates the duration of a
requests and collects some additonal data like request path, HTTP
method and response status.

You can then use this data to plot some nice graps, find bottlenecks
or set up alerts; or do anything else your stats toolkit supports.

## Configuration

    enable "Plack::Middleware::StatsPerRequest",
        metric_name   => 'http',
        app_name      => 'YourApp',
        path_cleanups => [ \&your_custom_cleanup, \&another_cleanup ],
        add_headers   => [ qw( Accept-Language X-Requested-With )],
        long_request  => 3
    ;

### metric\_name

The name of the metric generated. Defaults to `http_request`.

### app\_name

The name of your application. Defaults to `unknown`.

`app_name` will be added to each metric as a tag.

### path\_cleanups

A list of functions to be called to transform / cleanup the request
path. Defaults to `[ 'replace_idish' ]`.

Set to an empty list to do no path cleanups. This is not recommended,
unless your statistic tool can normalize paths which might include a
lot of distinct ids etc; or your app does not include ids in its URLs
(maybe they are all passed via query params?)

See [replace\_idish](https://metacpan.org/pod/replace_idish) for more info on the default path cleanup handler.

### add\_headers

A list of HTTP header fields. Default to `[ ]` (empty list).

If you use `add_headers`, all HTTP headers matching the ones provided
will be added as a tag, with the respective header values as the tag
values.

    enable "Plack::Middleware::StatsPerRequest",
             add_headers => [ 'Accept-Language' ];
    # header_accept-language=Accept-Language

If a header is not sent by a client, a value of `not_set` will be reported.

### has\_headers

A list of HTTP header fields. Default to `[ ]` (empty list).

Checks if a HTTP header is set, and adds a tag containing 1 or 0. This
makes sense if you just what to count if a header was sent, but don't
care about it's content (eg a bearer token):

    enable "Plack::Middleware::StatsPerRequest",
             has_headers => [ 'Authorization' ];
    # has_header_authorization=1

### long\_request

Requests taking longer than `long_request` seconds will be logged as
a `warning`. Defaults to `5` seconds.

Set to `0` to turn off.

    enable "Plack::Middleware::StatsPerRequest",
             long_request => 10;
    # curl http://localhost/very/slow/endpoint
    # cat /log/warnings
      Long request, took 23.042: GET /very/slow/endpoint

# METHODS

## replace\_idish

    my $clean = Plack::Middleware::StatsPerRequest::replace_idish( $dirty );

Takes a URI path and replaces things that look like ids with fixed
strings, so you can calc proper stats on the generic paths.

This is the default [path\_cleanups](https://metacpan.org/pod/path_cleanups) action, so unless you specify
your own, or explicitly set [path\_cleanups](https://metacpan.org/pod/path_cleanups) to an empty array, the
following transformations will be done on the path:

- All path fragments looking like a SHA1 checksum are replaced by
`:sha1`.
- All path fragments looking like a UUID are replaced by `:uuid`.
- Any part of the path consisting of 6 or more digits is
replaced by `:int`.
- A llpath fragments consisting solely of digits are also replaced
by `:int`.
- All path fragments looking like hex are replaced by `:hex`.
- All path fragments longer than 55 characters are replaced by
`:long`.
- A chain of path fragments looking like hex-code is replaced by
`:hexpath`.
- All path fragments looking like an email message id (as generated
by one of our tools) are replaced by `:msgid`.
- All path fragments looking like `300x200` are replaced by
`:imgdim`. (Of course this happens for all formats, not just 300 and 200).

For details, please inspect the source code and
`t/20_replace_idish.t`.

These transformations proved useful in the two years we used
`Plack::Middleware::StatsPerRequest` in house. If you have any
additions or change requests, just tell us!

# SEE ALSO

- [Measure::Everything](https://metacpan.org/pod/Measure%3A%3AEverything) is used to actually report the stats
- [Log::Any](https://metacpan.org/pod/Log%3A%3AAny) is used for logging.

# THANKS

Thanks to

- [validad.com](https://www.validad.com/) for supporting Open Source.

# AUTHOR

Thomas Klausner <domm@plix.at>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2018 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
