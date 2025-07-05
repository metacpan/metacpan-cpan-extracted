# NAME

Plack::Test::Agent - OO interface for testing low-level Plack/PSGI apps

# VERSION

version 1.6

## SYNOPSIS

    use Test::More;
    use Plack::Test::Agent;

    my $app          = sub { ... };
    my $local_agent  = Plack::Test::Agent->new( app => $app );
    my $server_agent = Plack::Test::Agent->new(
                        app    => $app,
                        server => 'HTTP::Server::Simple' );

    my $local_res    = $local_agent->get( '/' );
    my $server_res   = $server_agent->get( '/' );

    ok $local_res->is_success,  'local GET / should succeed';
    ok $server_res->is_success, 'server GET / should succeed';

## DESCRIPTION

`Plack::Test::Agent` is an OO interface to test PSGI applications. It can
perform GET, POST, PUT and DELETE requests against PSGI applications either in
process or over HTTP through a [Plack::Handler](https://metacpan.org/pod/Plack%3A%3AHandler) compatible backend.

## CONSTRUCTION

### `new`

The `new` constructor creates an instance of `Plack::Test::Agent`. This
constructor takes one mandatory named argument and several optional arguments.

- `app` is the mandatory argument. You must provide a PSGI application
to test.
- `server` is an optional argument. When provided, `Plack::Test::Agent`
will attempt to start a PSGI handler and will communicate via HTTP to the
application running through the handler. See [Plack::Loader](https://metacpan.org/pod/Plack%3A%3ALoader) for details on
selecting the appropriate server.
- `host` is an optional argument representing the name or IP address for
the server to use. The default is `localhost`.
- `port` is an optional argument representing the TCP port to for the
server to use. If not provided, the service will run on a randomly selected
available port outside of the IANA reserved range. (See [Test::TCP](https://metacpan.org/pod/Test%3A%3ATCP) for
details on the selection of the port number.)
- `ua` is an optional argument of something which conforms to the
[LWP::UserAgent](https://metacpan.org/pod/LWP%3A%3AUserAgent) interface such that it provides a `request` method which
takes an [HTTP::Request](https://metacpan.org/pod/HTTP%3A%3ARequest) object and returns an [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) object. The
default is an instance of `LWP::UserAgent`.
- `jar` is an optional argument for a [HTTP::Cookies](https://metacpan.org/pod/HTTP%3A%3ACookies) instance that
will be used as cookie jar for the requests, by default plain one is created.

## METHODS

This class provides several useful methods:

### `get`

This method takes a URI and makes a `GET` request against the PSGI application
with that URI. It returns an [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) object representing the results
of that request.

### `post`

This method takes a URI and makes a `POST` request against the PSGI
application with that URI. It returns an [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) object representing
the results of that request. As an optional second parameter, pass an array
reference of key/value pairs for the form content:

    $agent->post( '/edit_user',
        [
            shoe_size => '10.5',
            eye_color => 'blue green',
            status    => 'twin',
        ]);

### `put`

This method takes a URI and makes a `PUT` request against the PSGI
application with that URI. It returns an [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) object representing
the results of that request. As an optional second parameter, pass an array
reference of key/value pairs for the form content:

    $agent->put( '/edit_user',
        [
            shoe_size => '10.5',
            eye_color => 'blue green',
            status    => 'twin',
        ]);

### `delete`

This method takes a URI and makes a `DELETE` request against the PSGI
application with that URI. It returns an [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse) object representing
the results of that request.

### `execute_request`

This method takes an [HTTP::Request](https://metacpan.org/pod/HTTP%3A%3ARequest), performs it against the bound app, and
returns an [HTTP::Response](https://metacpan.org/pod/HTTP%3A%3AResponse). This allows you to craft your own requests
directly.

### `get_mech`

Used internally to create a default UserAgent, if none is provided to the
constructor.  Returns a Test::WWW::Mechanize::Bound object.

### `normalize_uri`

Used internally to ensure that all requests use the correct scheme, host and
port.  The scheme and host default to `http` and `localhost` respectively,
while the port is determined by [Test::TCP](https://metacpan.org/pod/Test%3A%3ATCP).

### `start_server`

Starts a test server via [Test::TCP](https://metacpan.org/pod/Test%3A%3ATCP).  If a `server` arg has been provided to
the constructor, it will use this class to load a server.  Defaults to letting
Plack::Loader decide which server class to use.

## CREDITS

Thanks to Zbigniew Łukasiak and Tatsuhiko Miyagawa for suggestions.

# AUTHORS

- chromatic <chromatic@wgz.org>
- Dave Rolsky <autarch@urth.org>
- Ran Eilam <ran.eilam@gmail.com>
- Olaf Alders <olaf@wundercounter.com>

# CONTRIBUTORS

- Andy Beverley <andy@andybev.com>
- Dave Rolsky <drolsky@maxmind.com>
- Olaf Alders <oalders@maxmind.com>
- Ran Eilam <reilam@maxmind.com>
- Syohei YOSHIDA <syohex@gmail.com>
- Torsten Raudssus <torsten@raudss.us>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by chromatic.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
