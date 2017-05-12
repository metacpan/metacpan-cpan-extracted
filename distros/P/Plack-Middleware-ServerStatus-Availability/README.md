[![Build Status](https://travis-ci.org/tarao/perl5-Plack-Middleware-ServerStatus-Availability.svg?branch=master)](https://travis-ci.org/tarao/perl5-Plack-Middleware-ServerStatus-Availability)
# NAME

Plack::Middleware::ServerStatus::Availability - manually set server status

# SYNOPSIS

    use Plack::Builder;


    builder {
        enable 'ServerStatus::Availability', (
            path => {
                status  => '/server/avail',
                control => '/server/control/avail',
            },
            allow => [ '127.0.0.1', '192.168.0.0/16', '10.0.0.0/8' ],
            file => '/tmp/server-up',
        );
        $app;
    };

    $ curl http://server:port/server/avail
    503 Server is up but is under maintenance

    $ curl -X POST http://server:port/server/control/avail?action=up
    200 Done

    $ curl http://server:port/server/avail
    503 Server is up but is under maintenance

    $ curl http://server:port/server/avail
    200 OK

    $ curl -X POST http://server:port/server/control/avail?action=down
    200 Done

    $ curl http://server:port/server/avail
    503 Server is up but is under maintenance

# DESCRIPTION

This middleware is intended to show a server status which is
controllable by POST requests to the status control endpoint.  This is
useful when you want to manually make a server under maintenance and
automatically detached from a load balancer.

# CONFIGURATIONS

- path

        path => {
            status  => $status,
            control => $control,
        }

    `$status` is a location to display the server status.  `$control` is
    a location to `POST` actions.  An action is specified by `action`
    query parameter.  Its value `up` and `down` makes the server status
    to 'available' and 'unavailable' respectively.

- allow

        allow => '127.0.0.1'
        allow => [ '192.168.0.0/16', '10.0.0.0/8' ]

    Host based access control of the server status and status control
    endpoints.  Supports IPv6 address.

- file

        file => $file

    Specifies a file to remember the availability.  The server is
    indicated to be available if the file exist.

# SEE ALSO

[Plack::Middleware::ServerStatus::Lite](https://metacpan.org/pod/Plack::Middleware::ServerStatus::Lite)

# ACKNOWLEDGMENT

This middleware is ported from [Karasuma::Config::ServerStatus](https://github.com/wakaba/karasuma-config/blob/master/lib/Karasuma/Config/ServerStatus.pm) to `Plack::Middleware`.

# LICENSE

Copyright (C) INA Lintaro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

INA Lintaro <tarao.gnn@gmail.com>
