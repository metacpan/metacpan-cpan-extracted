package Punk;

use 5.010;
use strict;
use warnings;

our $VERSION;

BEGIN {
    $VERSION = '0.02';
    require XSLoader;
    XSLoader::load('Punk', $VERSION);
}

use Punk::App;

# The application registrars, one per class that says `use Punk`. The C
# import (punk_import.h) keeps them here rather than anywhere private, so a
# second `use Punk` in the same package extends that application instead of
# starting another.
our %APPS;

1;

__END__

=head1 NAME

Punk - a MVC web framework

=head1 SYNOPSIS

    package MyApp;
    use Punk;

    get  '/'          => 'Web::Book#home';
    get  '/books/:id' => 'Web::Book#view';
    post '/books'     => 'Web::Book#create';

    my $admin = under '/admin' => sub {
        my ($c) = @_;
        return $c->redirect('/') unless $c->req->header('authorization');
        return;
    };
    $admin->get('/books' => 'Web::Book#admin_list');

    static '/static' => 'root/static';
    plugin 'RequestId';

    1;

    # app.psgi
    use MyApp;
    MyApp->to_app;

=head1 GETTING STARTED

    punk new MyApp
    cd MyApp
    plackup app.psgi

C<punk new> writes a running application - routes, a controller, Stencil
views, C<config/punk.yml>, a psgi entry point and a test that starts the
app and requests a page. Point it at an OpenAPI document and it mounts
that too, generating a controller of operation stubs per tag:

    punk new MyApp --api ./openapi.json

Once it is running, C<punk routes> prints the compiled table,
C<punk doctor> reports the environment and C ABIs, C<punk config check>
resolves the configuration and its secrets, and C<punk dev> serves with
restart-on-change. See L<Punk::Generate> and L<Punk::Command>.

=head1 DESCRIPTION

Punk resolves and freezes everything - routes, guard chains, handler
coderefs, helpers, mounts - once, at C<to_app> time. Nothing is
interpreted per request: dispatch is a hash lookup or a short bucket
scan, guards are a frozen array walk, and the handler is a plain
coderef call receiving one argument, the L<Punk::Context>.

C<use Punk> turns on strict and warnings, creates the per-application
registry, and exports the DSL keywords below into the calling package.

=head1 KEYWORDS

=head2 get / post / put / patch / del / any

    get '/books/:id' => 'Web::Book#view';
    any '/ping'      => sub { my ($c) = @_; $c->text('pong') };

A route. The target is a coderef, or C<'Controller#method'> resolved
against C<MyApp::Controller::> at boot - typos croak before the app
serves. C<:name> captures one path segment, C<*name> captures the
rest; captures are available as C<< $c->param($name) >>.

=head2 under

    my $scope = under '/admin' => $guard;

A guard scope; see L<Punk::Router::Scope>. Guards receive the context;
a reference return short-circuits the request, anything else
continues. Scopes nest.

=head2 websocket

    websocket '/chat' => 'WS::Chat#join';
    websocket '/feed' => $target, { protocols => ['v1'] };

A WebSocket route. It routes like a C<GET> (upgrade requests are GET) and
sits under the same scopes and guards as any other route, so a guard can
reject a client with an ordinary HTTP response before the upgrade
happens. Once the handshake is validated and answered, the handler is
called with the context B<and> the connection:

    sub join {
        my ($c, $ws) = @_;
        $ws->on(message => sub { $_[0]->send("you said $_[1]") });
    }

It wires the events it wants and returns; the connection then lives on
the server's event loop. See L<Punk::WebSocket> for the events and
L<Punk::WebSocket::Room> for broadcasting.

Options: C<protocols> (an arrayref of acceptable subprotocols - a client
that offers none of them is refused), C<max_message_size> (default 16MB),
C<write_buffer_limit>, and C<blocking>.

WebSocket routes need L<Hyperman> 0.11 or later, whose C<detach> hands
the socket to the application. On other PSGI servers, C<< blocking => 1 >>
runs the connection inside the handler over C<psgix.io> instead, which
works anywhere but pins one worker per connection. Without either,
C<to_app> croaks rather than let the app start with routes it cannot
serve.

=head2 sse

    sse '/events' => 'Live#feed';
    sse '/events' => $target, { heartbeat => 30 };

A Server-Sent Events route: the handler is called with the context B<and> a
stream once Punk has taken the socket over, and pushes C<text/event-stream>
events onto it for a browser's C<EventSource>. Fully non-blocking on a
L<Hyperman> worker (the stream lives on the loop); portable to any
C<psgi.streaming> server; and C<< blocking => 1 >> streams inside the handler
over C<psgix.io>. Options: C<heartbeat> (seconds, default 15), C<retry> (ms),
C<write_buffer_limit>, C<blocking>. See L<Punk::SSE>.

    sub feed {
        my ($c, $stream) = @_;
        my $tick; $tick = sub {
            return unless $stream->is_open;
            $stream->send({ time => time });
            $c->timer(1)->on_done($tick);
        };
        $tick->();
    }

=head2 ua

    ua timeout => 10;                       # the default agent
    ua partner => { timeout => 2 };         # and a named one
    ua \%opts;

Options for the outbound user agent behind C<< $c->ua >>. Every key is handed
to C<< Fetch->new >> as given, so this is L<Fetch>'s own constructor surface
rather than a second vocabulary for it; the event loop is supplied for you.
Also configurable from C<punk.yml>. Optional: an application that never uses it
still gets a default agent the first time a handler asks for one.

The agent is one per worker, not one per request, so that its keep-alive pool
survives between them. C<cookie_jar> is the exception - a jar belongs to the
agent, so C<< cookie_jar => 1 >> gives each request its own (over the same
pool), and C<< cookie_jar => 'shared' >> is the deliberate opt-out for an
upstream that authenticates the application itself. Nothing about the inbound
request is forwarded automatically. See L<Punk::UA>.

=head2 session

    session secret => secret('session_key'), expires => '7d', samesite => 'Lax';

Enable signed cookie sessions: C<< $c->session >> is then a hashref written
back to a HMAC-SHA256-signed cookie when it changes. Source the key from the
L</secret> system. Options: C<secret>, C<cookie> (default C<punk.sid>),
C<expires>, C<path>, C<domain>, C<secure>, C<httponly> (default on),
C<samesite> (default C<Lax>). Also configurable from C<punk.yml>. See
L<Punk::Session>.

=head2 csrf

    csrf;
    csrf keep => 3, exempt => [ '/hooks/' ];

Single-use CSRF tokens over the session: every unsafe request must carry a
live token, and using one spends it. C<< $c->csrf_field >> is the hidden
input for a form, C<< $c->csrf_token >> the value; the token is also
mirrored into a script-readable cookie for C<fetch>. Needs C<session>.
See L<Punk::CSRF>.

=head2 cors

    cors;                                   # a public API: * , no credentials
    cors origins => [ 'https://app.example.com' ], credentials => 1,
         paths   => [ '/api' ];

Cross-origin handling, from inside the dispatcher: preflights are answered
before routing (so no C<OPTIONS> route is needed) and the headers reach
every response, including the C<404>s and C<405>s that never build a
context. C<Access-Control-Allow-Methods> comes from the router, so it
cannot promise a method the application does not serve. See L<Punk::CORS>.

=head2 static

    static '/static' => 'root/static';

Serve files from a directory; see L<Punk::Static>.

=head2 mount

    mount '/legacy' => $psgi_app;

Mount any PSGI app under a prefix (longest prefix wins).

=head2 api

    my $api = api 'openapi.json';
    my $v1  = under '/v1' => $guard;
    my $api = $v1->api('openapi.json' => { security => { key => $checker } });

Mount an OpenAPI 3.1 document: each operation dispatches to the
controller method named after its C<operationId>, with request
validation, security-as-guards and per-prefix guards all resolved at
boot. Returns the mount. Under a scope it inherits the scope's prefix
and guards. See L<Punk::Mount::OpenAPI>.

=head2 docs

    docs '/docs';
    docs '/docs' => $api, { ... };

Serve an API documentation UI (L<Open::API::UI>) for a mounted spec.
With one C<api> mount the mount is implied; name it when several are
mounted. A docs path the spec already declares croaks at boot.

=head2 config

    config 'config/punk.yml';
    config 'config/punk.yml', env => 'production', secrets => 'strict';

Load YAML configuration and apply it. Blocks that mirror a DSL keyword
register for real, so deployment configuration needs no code change:

    views:                       # -> views Stencil => {...}
      Stencil:
        template_dir: root/templates
    database:                    # -> database dsn => ...
      dsn:      dbi:Pg:dbname=myapp
      password: { $env: DB_PASSWORD }
    models:   [ Book ]           # -> model 'Book'
    plugins:                     # -> plugin 'RequestId' => {...}
      RequestId: {}
    static:                      # -> static '/static' => 'root/static'
      /static: root/static

Everything else in the file is yours, through C<< $app->config >>.

Applied where the keyword sits, so put it first and the routes after it
can rely on what it registered. Layers: C<punk.yml>, then
C<punk.$PUNK_ENV.yml>, then the gitignored C<punk.local.yml>.

B<Secrets never belong in the file.> A value written
C<< { $env: NAME } >>, C<< { $file: PATH } >> or C<< { $exec: [...] } >>
is resolved at boot from outside it; C<< $app->config >> shows
C<[redacted]> in its place and C<< $app->secret('database.password') >>
reaches the real thing. A plaintext value under a secret-shaped key
warns by default (C<< secrets => 'strict' >> refuses to start). See
L<Punk::Config>.

YAML parsing is one L<YAML::XS> call per file; it is loaded only when
this keyword is used, so an application that declares everything in Perl
never touches it.

=head2 secret

    my $password = secret 'database.password';

A resolved secret, by dotted path. Boot-time; handlers that need one
should close over it or reach it through a plugin helper.

=head2 views

    views Stencil => { template_dir => 'root/templates' };

Register a view engine; the first registered is the default. See
L<Punk::Views>.

=head2 database / model

    database dsn => 'dbi:SQLite:dbname=myapp.db';
    model    'Book';

Model tier configuration; see L<Punk::Model>. C<database> records the
backend connection options (a C<dsn>, optional C<user>/C<password>/
C<attr>, or C<< backend => 'Class' >> to swap the backend); C<model>
registers model classes by name, resolved against C<< MyApp::Model:: >>
at boot.

Several databases may be configured by giving each a name and an options
hashref; a model then names the one it lives in with its own C<database>
declaration (see L<Punk::Model>), defaulting to the unnamed one:

    database dsn => 'dbi:SQLite:dbname=myapp.db';        # the default
    database analytics => { dsn => 'dbi:Pg:dbname=warehouse' };

Every model on one database shares a single connection per worker.

=head2 hook

    hook before_dispatch => sub { my ($c) = @_; ...; return };
    hook after_dispatch  => sub { my ($c, $resp) = @_; ... };

C<before_dispatch> runs after routing and before guards (a reference
return short-circuits); C<after_dispatch> sees the finalized PSGI
triplet and may mutate it or return a replacement.

=head2 middleware

    middleware sub { my ($app) = @_; sub { my ($env) = @_; ... } };

An outer PSGI wrap, applied at C<to_app>.

=head2 on_error

    on_error sub { my ($c, $err) = @_; ... };

Runs when a guard or handler dies; a reference return becomes the
response, otherwise the 500 C<{"errors":[...]}> default is served.

=head2 plugin

    plugin 'RequestId';
    plugin '+My::Plugin' => { opt => 1 };

Load and register a plugin; see L<Punk::Plugin>.

=head2 helper

    helper uid => sub { my ($c) = @_; $c->stash->{uid} };

Install a context helper method (usually done from plugins).

=head2 to_app

Compile and freeze everything; returns the PSGI coderef. Callable as
C<< MyApp->to_app >>. Each call builds an independent app from the
configuration at that moment.

=head2 punk_app

The underlying L<Punk::App> registry (the registrar surface plugins
receive).

=head1 ASYNC

A handler may hand back a future instead of a response: Punk awaits any
future-compatible return (C<then> / C<on_ready> / C<get>). L<Punk::Future> is
the native one - C<< $c->promise >>, C<< $c->timer($secs) >> and
C<< $c->await($f) >> create and drive it. On a L<Hyperman> worker it runs on
the loop and the worker serves other requests while it is pending; anywhere
else it blocks. So

    get '/slow' => sub {
        my ($c) = @_;
        $c->timer(2)->then(sub { $c->json({ waited => 2 }) });
    };

answers two seconds later without pinning a worker.

=head1 SEE ALSO

L<Punk::Context>, L<Punk::Router::Scope>, L<Punk::Plugin>,
L<Punk::CSRF>, L<Punk::CORS>, L<Punk::UA>,
L<Punk::Controller>, L<Open::API>, L<Template::Stencil>, L<Hyperman>.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 BUGS

Please report any bugs or feature requests to C<bug-punk at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Punk>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Punk

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION <email@lnation.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
