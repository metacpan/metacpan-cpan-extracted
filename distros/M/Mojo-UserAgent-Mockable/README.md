# NAME

Mojo::UserAgent::Mockable - A Mojo User-Agent that can record and play back requests without Internet connectivity, similar to LWP::UserAgent::Mockable

# VERSION

version 1.58

# SYNOPSIS

    my $ua = Mojo::UserAgent::Mockable->new( mode => 'record', file => '/path/to/file' );
    my $tx = $ua->get($url);

    # Then later...
    my $ua = Mojo::UserAgent::Mockable->new( mode => 'playback', file => '/path/to/file' );
    
    my $tx = $ua->get($url); 
    # This is the same content as above. The saved response is returned, and no HTTP request is
    # sent to the remote host.
    my $reconstituted_content = $tx->res->body;

# ATTRIBUTES

## mode

Mode to operate in.  One of:

- passthrough

    Operates like [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent) in all respects. No recording or playback happen.

- record

    Records all transactions made with this instance to the file specified by ["file"](#file).

- playback

    Plays back transactions recorded in the file specified by ["file"](#file)

- lwp-ua-mockable

    Works like [LWP::UserAgent::Mockable](https://metacpan.org/pod/LWP%3A%3AUserAgent%3A%3AMockable). Set the LWP\_UA\_MOCK environment variable to 'playback', 
    'record', or 'passthrough', and the LWP\_UA\_MOCK\_FILE environment variable to the recording file.

## file

File to record to / play back from.

## unrecognized

What to do on an unexpected request.  One of:

- exception

    Throw an exception (i.e. die).

- null

    Return a response with empty content

- fallback

    Process the request as if this instance were in "passthrough" mode and perform the HTTP request normally.

## ignore\_headers

Request header names to ignore when comparing a request made with this class to a stored request in 
playback mode. Specify 'all' to remove any headers from consideration. By default, the 'Connection',
'Host', 'Content-Length', and 'User-Agent' headers are ignored.

## ignore\_body

Ignore the request body entirely when comparing a request made with this class to a stored request 
in playback mode.

## ignore\_userinfo 

Ignore the userinfo portion of the request URL's when comparing a request to a potential counterpart in playback mode.

## request\_normalizer

Optional subref. This is for when the requests require a more nuanced comparison (although it will
be used in conjunction with the previous attributes).

The subref takes two parameters: the current Mojo::Message::Request and the recorded one. The subref
should modify these request objects in-place so that they match each other for the parts where your
code doesn't care, e.g. set an id or timestamp to the same value in both requests.

The return value is ignored, so a typical subref to ignore differences in any numerical id parts of
the query path could look like this

    request_normalizer => sub {
        my ($req, $recorded_req) = @_;
        for ($req, $recorded_req) {
            $_->url->path( $_->url->path =~ s|/\d+\b|/123|gr );
        }
    },

# METHODS

## save

In record mode, save the transaction cache to the file specified by ["file"](#file) for later playback.

# THEORY OF OPERATION

## Recording mode

For the life of a given instance of this class, all transactions made using that instance will be 
serialized and stored in memory.  When the instance goes out of scope, or at any time  ["save"](#save) is 
called, the transaction cache will be written to the file specfied by ["file"](#file) in JSON format. 
Transactions are stored in the cache in the order they were made.

The file's contents are pretty-printed and canonicalized (ie hash keys are sorted) so that mocks
are easy to read and diffs are minimized.

## Playback mode

When this class is instantiated, the instance will read the transaction cache from the file 
specified by ["file"](#file). When a request is first made using the instance, if the request matches 
that of the first transaction in the cache, the request URL will be rewritten to that of the local 
host, and the response from the first stored transaction will be returned to the caller. Each 
subsequent request will be handled similarly, and requests must be made in the same order as they 
were originally made, i.e. if orignally the request order was A, B, C, with responses A', B', C',
requests in order A, C, B will NOT return responses A', C', B'. Request A will correctly return 
response A', but request C will trigger an error (behavior configurable by the ["unrecognized"](#unrecognized)
option).

### Request matching

Before comparing the current request with the recorded one, the requests are normalized using the
subref in the request\_normalizer attribute. The default is no normalization. See above for how to
use it.

Two requests are considered to be equivalent if they have the same URL (order of query parameters
notwithstanding), the same body content, and the same headers.

You may also exclude headers from consideration by means of the ["ignore\_headers"](#ignore_headers) attribute. Or,
you may excluse the request body from consideration by means of the ["ignore\_body"](#ignore_body) attribute.

# CAVEATS

## Encryption

The playback file generated by this module is unencrypted JSON.  Treat the playback file as if 
its contents were being transmitted over an unsecured channel.

## Local application server

Using this module against a local app, e.g.: 

    my $app = Mojolicious->new;
    ...

    my $ua = Mojo::UserAgent::Mockable->new;
    $ua->server->app($app);

Doesn't work, because in playback mode, requests are served from an internal Mojolicious instance.
So if you blow that away, the thing stops working, natch.  You should instead instantiate 
[Mojo::Server::Daemon](https://metacpan.org/pod/Mojo%3A%3AServer%3A%3ADaemon) and connect to the app via the server's URL, like so:

    use Mojo::Server::Daemon;
    use Mojo::IOLoop;

    my $app = Mojolicious->new;
    $app->routes->any( ... );

    my $daemon = Mojo::Server::Daemon->new(
        app => $app, 
        ioloop => Mojo::IOLoop->singleton,
        silent => 1,
    );
    
    my $listen = q{http://127.0.0.1};
    $daemon->listen( [$listen] )->start;
    my $port = Mojo::IOLoop->acceptor( $daemon->acceptors->[0] )->port;
    my $url  = Mojo::URL->new(qq{$listen:$port})->userinfo('joeblow:foobar');
    
    my $output_file = qq{/path/to/file.json};
    
    my $mock = Mojo::UserAgent::Mockable->new(ioloop => Mojo::IOLoop->singleton, mode => 'record', file => $output_file);
    my $tx = $mock->get($url);

## Mojolicious::Lite

You will often see tests written using [Mojolicious::Lite](https://metacpan.org/pod/Mojolicious%3A%3ALite) like so:

    use Mojolicious::Lite;

    get '/' => sub { ... };

    post '/foo' => sub { ... };

And then, further down:

    my $ua = Mojo::UserAgent->new;

    is( $ua->get('/')->res->text, ..., 'Text OK' );
Or:

    use Test::Mojo;
    my $t = Test::Mojo->new;
    $t->get_ok('/')->status_is(200)->text_is( ... );

And this is all fine. Where it stops being fine is when you have Mojo::UserAgent::Mockable on board:

    use Mojolicious::Lite;

    get '/' => sub { ... };

    post '/foo' => sub { ... };
    
    use Test::Mojo;
    my $t = Test::Mojo->new;
    my $mock = Mojo::UserAgent::Mockable->new( mode => 'playback', file => ... );
    $t->get_ok('/')->status_is(200)->text_is( ... );

Mojolicious::Lite will replace the current UA's internal application server's application instance 
(["app" in Mojo::UserAgent::Server](https://metacpan.org/pod/Mojo%3A%3AUserAgent%3A%3AServer#app)) with the Mojolicious::Lite application.  This will break the 
playback functionality, as this depends on a custom Mojolicious application internal to the module.
Instead, define your application in a separate package (not necessarily a separate file), like so:

    package MyApp;
    use Mojolicious::Lite;
    get '/' => sub { ... };
    post '/foo' => sub { ... };

    # Actual test application
    package main;

    use Mojo::UserAgent::Mockable;
    use Mojo::Server::Daemon;
    use Mojo::IOLoop;
    use Test::Mojo;

    $app->routes->get('/' => sub { ... });
    $app->routes->post('/foo' => sub { ... });

    my $daemon = Mojo::Server::Daemon->new(
        app    => $app,
        ioloop => Mojo::IOLoop->singleton,
        silent => 1,
    );

    my $listen = q{http://127.0.0.1};
    $daemon->listen( [$listen] )->start;
    my $port = Mojo::IOLoop->acceptor( $daemon->acceptors->[0] )->port;
    my $url  = Mojo::URL->new(qq{$listen:$port})->userinfo('joeblow:foobar');

    my $mock = Mojo::UserAgent::Mockable->new(ioloop => Mojo::IOLoop::singleton, mode => playback, file => ... );
    my $t = Test::Mojo->new;
    $t->ua($mock);
    $mock->get_ok($url->clone->path('/'))->status_is(200)->text_is( ... );

You can also do the following (as seen in t/030\_basic\_authentication.t):

    use Mojolicious;
    use Mojo::Server::Daemon;
    use Mojo::IOLoop;

    my $app = Mojolicious->new;
    $app->routes->get('/' => sub { ... });
    $app->routes->post('/foo' => sub { ... });

    my $daemon = Mojo::Server::Daemon->new(
        app    => $app,
        ioloop => Mojo::IOLoop->singleton,
        silent => 1,
    );

    my $listen = q{http://127.0.0.1};
    $daemon->listen( [$listen] )->start;
    my $port = Mojo::IOLoop->acceptor( $daemon->acceptors->[0] )->port;
    my $url  = Mojo::URL->new(qq{$listen:$port})->userinfo('joeblow:foobar');

    my $mock = Mojo::UserAgent::Mockable->new(ioloop => Mojo::IOLoop::singleton, mode => playback, file => ... );
    my $t = Test::Mojo->new;
    $t->ua($mock);
    $t->get_ok('/')->status_is(200)->content_is( ... );

## Events

The following transaction level events will not be emitted during playback:

- pre\_freeze
- post\_freeze
- resume

# SEE ALSO

- [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent) 
The class being mocked (but not derided, because the whole Mojo thing is really quite clever)

- [Mojo::Transaction::HTTP](https://metacpan.org/pod/Mojo%3A%3ATransaction%3A%3AHTTP) 
Where the magic happens

# CONTRIBUTORS

Mike Eve [https://github.com/ungrim97](https://github.com/ungrim97)

Phineas J. Whoopee [https://github.com/antoniel123](https://github.com/antoniel123)

Marc Murray [https://github.com/marcmurray](https://github.com/marcmurray)

Steve Wagner `<truroot at gmail.com>`

Joel Berger `<joel.a.berger at gmail.com>`

Dan Book `<grinnz at grinnz.com>`

Stefan Adams  `<stefan@borgia.com>`

Mohammad Anwar `mohammad.anwar@yahoo.com`

Johan Lindstrom `johanl@cpan.org`

David Cantrell `david@cantrell.org.uk`

Everyone on #mojo on irc.perl.org

# AUTHOR

Kit Peters <popefelix@gmail.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Kit Peters.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
