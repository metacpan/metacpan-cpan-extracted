package Punk;

use 5.010;
use strict;
use warnings;

our $VERSION;

BEGIN {
    $VERSION = '0.17';
    require XSLoader;
    XSLoader::load('Punk', $VERSION);
}

use Punk::App;
use Punk::RateLimit;   # adds Punk::App::rate_limit + the key strategies

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
restart-on-change. C<punk generate controller|model> adds to an existing
application, C<punk test> runs its suite, and C<punk secret> mints key
material for the session config. See L<Punk::Generate> and
L<Punk::Command>.

The generated test drives the app through L<Punk::Test>: an in-process
client with a cookie jar and chained assertions, so sessions, CSRF,
JSON APIs, server-sent events and websockets are all testable against
the same frozen coderef a server would run.

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

A trailing slash on the request is not a different route: once every
declared route, API operation and mount has been tried and none matched,
C<GET /account/> is retried as C<GET /account>. Nothing that already
matched is affected - a C<*splat> still captures a trailing slash as
part of the remainder, and a mounted app still receives the path it was
sent, since only it knows whether C</docs> and C</docs/> differ.

=head3 Route options

An optional trailing hashref carries route options; unknown keys croak at
boot. Scoped verbs (C<< $scope->get(...) >>) take the same hashref.

    post '/upload' => 'Web::File#create', { max_body => 50_000_000 };

Once a route carries options, the whole declaration may be written as one
hashref instead, with the handler under C<cb>:

    post '/upload' => { cb => 'Web::File#create', max_body => 50_000_000 };

Both forms are supported and produce identical routes; C<cb> takes exactly
what the target position takes, a coderef or C<'Controller#method'>. The
options may go in one place or the other, not both, and a hashref with no
C<cb> croaks at boot. C<websocket> and C<sse> accept the same form.

=over 4

=item * C<cb> - the handler. Only in the one-hashref form, where it is
required.

=item * C<validate> - a JSON Schema, or C<< { schema, source, on_invalid } >>
for the longhand, compiled once at C<to_app> and run before the handler.
Errors collect into a Result that a bare C<< $c->validate >> reads;
failure answers C<< 400 { errors => [...] } >>, or the C<on_invalid>
target. See L<Punk::Validate>.

=item * C<schema> - the schema half of C<validate>, spelled separately.

=item * C<source> - what C<validate> reads (the request body by default).

=item * C<on_invalid> - a target to run instead of the house C<400>.

=item * C<compress> - C<0> opts the route out of response compression.
See below.

=item * C<max_body> - refuse a request whose C<CONTENT_LENGTH> exceeds
this, overriding the application's L</max_body>. C<0> disables the check
for this route.

=back

C<< compress => 0 >> deserves its own note. Punk does not compress -
L<Hyperman> does, because compression belongs to the write path - so this
is spelled as a plain response header, C<< Content-Encoding: identity >>,
which the server honours and strips. That makes it a contract any PSGI
server could adopt rather than a private arrangement, and it is inert on
one that has not. There is no C<< compress => 1 >>: compressing is
already the server's answer for a route that says nothing.

Reach for it when a response contains a CSRF token or a session identifier
B<and> reflects user input - that combination is the BREACH compression
side channel. Every major server compresses anyway, because the
alternative is worse for everyone; this is the escape hatch for the
handful of responses where it matters.

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

=head2 headers

    headers;                                # the safe default set
    headers 'Content-Security-Policy'   => "default-src 'self'",
            'Strict-Transport-Security' => 'max-age=31536000';
    headers 'X-Frame-Options' => undef;     # keep the rest, drop this one

Security response headers on everything the application sends, from the
same place CORS decorates: outside the hook chain, so the C<404>s, C<405>s
and preflight replies carry the policy too. Set-if-absent - a header a
handler already set wins. The bare form is C<X-Content-Type-Options>,
C<X-Frame-Options> and C<Referrer-Policy>; CSP and HSTS are opt-in by
spelling. An C<under> scope can carry its own policy for its prefix:
C<< $scope->headers(...) >>. See L<Punk::Headers>.

=head2 proxy

    proxy;                                  # one proxy in front
    proxy trust => 2;                       # a CDN in front of nginx
    proxy trust => ['10.0.0.0/8', '172.16.0.0/12'];
    proxy trust => 'all';                   # development only
    proxy trust => 1, for_header => 'CF-Connecting-IP';

Declares that the application sits behind a reverse proxy, so the real
client can be recovered from the forwarded headers.

C<REMOTE_ADDR> is B<overwritten> with the resolved client at the top of the
dispatcher, before routing. That is the whole design: C<rate_limit>,
C<< $c->block_ip >>, the access log and C<< $c->req->address >> all read
C<REMOTE_ADDR> and become correct without any of them changing. The address
the connection actually came from is kept as
C<< $c->env->{'punk.peer_addr'} >>, and C<REMOTE_PORT> is dropped when the
address moved, because it described the proxy's socket.

C<X-Forwarded-Proto> sets C<psgi.url_scheme> (and C<HTTPS>),
C<X-Forwarded-Host> sets C<HTTP_HOST>, and C<X-Forwarded-Port> sets
C<SERVER_PORT>, all under the same trust decision.

B<Without this keyword, a limiter behind a proxy is not just approximate -
it is a site-wide outage waiting to happen.> See L</The shared bucket>
below.

=head3 How C<trust> counts

C<X-Forwarded-For> reads C<< client, proxy1, proxy2 >>, and each hop
B<appends> the address it received the connection I<from>. The socket peer
is the last proxy and never appears in the header it forwarded. So with
C<< trust => N >> the client sits at index C<N-1> counting from the
B<right>.

Counting from the left is the spoofable version, because the leftmost entry
is the one the client writes. With one proxy in front and a client sending
C<< X-Forwarded-For: 9.9.9.9 >>, the header arriving here is
C<< 9.9.9.9, <real client> >> - and Punk answers with the real client.

A chain shorter than C<trust> declares is a misconfiguration, or a client
that sent nothing; the answer is then the socket peer, never the leftmost
entry. An entry that is not a valid address ends the walk the same way -
C<REMOTE_ADDR> feeds a shared-memory rate-limit key, so attacker-controlled
bytes must never reach it.

C<< trust => \@cidrs >> walks right to left while each entry is one of the
named networks and takes the first one that is not, having first checked
that the socket peer is itself trusted. C<< trust => 'all' >> takes the
leftmost entry and is refused outside C<PUNK_ENV=development>: with no
proxy actually in front it lets any client claim any address.

Everything is validated at C<to_app> - a mistyped CIDR, a nonsense hop
count, an unknown option or a second C<proxy> declaration all croak at boot.

=head3 The shared bucket

C<rate_limit> keys on C<REMOTE_ADDR>, and because the counters live in
L<Hyperman>'s shared arena a limit is B<exact across the whole worker pool>
rather than per worker. Behind a proxy without this keyword, C<REMOTE_ADDR>
is the proxy for every request, so every client on the internet shares one
bucket and a C<< limit => 100 >> rule throttles the entire site at 100 per
window. C<< $c->block_ip >>, keyed the same way, bans the load balancer.

Reaching for C<< by => 'header:X-Forwarded-For' >> instead is worse, not
better: nothing validates the header, so on an application that is I<not>
behind a proxy any client can set it and step into a fresh bucket at will.

=head3 What this does not fix

L<Hyperman>'s edge denylist drops a connection at C<accept>, before a byte
is read, so it cannot see a header and never will. Behind a proxy it can
only ever match the proxy's own address. C<< $c->block_ip($client) >> still
writes to the arena, but the ban takes effect at dispatch as a C<403>
rather than at the edge - the same outcome, at the cost of a request.

C<< $c->block_ip >> croaks if the address it is about to ban is the one in
C<punk.peer_addr>, because banning the proxy takes the site down. Boot-time
config cannot catch that, and a silent no-op would leave an operator
believing they had banned someone.

=head2 auth

    auth model => 'User',
         roles => sub { my ($c, $user) = @_; $user->{role} };

The authentication battery: a signed-in identity over the session
(C<< $c->login / logout / auth_id / current_user >>), password hashing in C
(L<Punk::Auth::Password>, PBKDF2 over the bundled SHA-256), C<check_password>
with a timing-safe dummy verify, and single-use email tokens
(C<issue_token>/C<take_token>) on a C<token_model>. Needs C<session>.
See L<Punk::Auth>.

=head2 auth_guard

    my $account = under '/account' => auth_guard;
    under '/admin' => auth_guard(role => 'admin');
    under '/staff' => auth_guard(role => 'staff', on_denied => '404');

A guard for C<under>: the bare form admits any signed-in user and runs
entirely in C. Denial negotiates - a browser is redirected to the login page
with a C<?to=> return-to, an API client gets a C<401>. Roles rank on a
ladder ("admin or better") or match exactly when outside it. See
L<Punk::Auth/GUARDS>.

=head2 max_body

    max_body 2_097_152;                          # app-wide, bytes

    post '/upload'  => $t, { max_body => 50_000_000 };
    post '/webhook' => $t, { max_body => 0 };    # no check on this route

Refuse a request whose C<CONTENT_LENGTH> exceeds a ceiling, with the same
C<413> an over-large L</api> operation gets. A route's own value wins over
the app-wide one, and C<0> on a route switches the check off there.

The check runs in C after routing and B<before> the hook chain, the guards
and the handler, so an oversize request costs no auth lookup, no
validation, no body parse and no Perl frame.

B<This is policy, not memory protection.> By the time Punk sees a request,
its body is already fully resident in the server's read buffer - the memory
was spent before the application was called. What this buys is the parse,
the guards, the handler, and an honest answer instead of a mysterious
success. The thing that actually bounds a worker's memory is the server's
own ceiling, L<Hyperman/"max_body: the request ceiling">, and this keyword
cannot stand in for it. Set both.

A request with no C<CONTENT_LENGTH> is passed through: that is a chunked
body, which the server has already decoded and bounded against its own
ceiling by the time Punk runs.

=head2 static

    static '/static' => 'root/static';

Serve files from a directory; see L<Punk::Static>.

If C<style.css.gz> (or C<.br>) sits next to C<style.css> and the client
accepts that encoding, the sibling's bytes are served under the original's
identity - its C<Content-Type>, its URL, a C<Content-Encoding> and an
encoding-tagged C<ETag> of its own. Nothing is compressed per request: the
win is a build step's, paid once, so this needs no zlib and costs one
C<stat>. A sibling older than its source is ignored rather than served
stale, and C<Vary: Accept-Encoding> is on every response from the mount
whether or not one was used.

=head2 markdown

    markdown '/docs' => 'docs', title => 'MyApp Guide';

Serve a nested directory of markdown files as a documentation site, with
navigation, per-page contents, syntax highlighting and search. The whole site
is rendered at boot and frozen, so a request is a hash lookup; see
L<Punk::Mount::Markdown>.

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
    model;                    # everything under MyApp::Model::
    model 'Book';             # or just the ones named

Model tier configuration; see L<Punk::Model>. C<database> records the
backend connection options (a C<dsn>, optional C<user>/C<password>/
C<attr>, or C<< backend => 'Class' >> to swap the backend); C<model>
registers model classes by name, resolved against C<< MyApp::Model:: >>
at boot.

The bare form loads and registers everything under C<< MyApp::Model:: >> -
every F<.pm> in that namespace across C<@INC>, plus any model class already
compiled into the symbol table. Naming models normally switches
auto-discovery off; the bare form switches it back on, so C<model;> next
to C<model 'Special'> registers everything and is harmless. Discovery is
also the default when no C<model> keyword appears at all.

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

In the C<development> environment - an opt-in: C<punk dev>, or
C<PUNK_ENV=development>, or the config's C<env>; the default is
C<production> - that default is a debug response instead: an HTML page
with the stack and source snippets for a browser, the same JSON shape
plus a C<trace> array for everything else. A handler registered here
still runs first and its reference return still wins, in every
environment. See L<Punk::DevError>.

Which suggests the branded-page pattern: decline in development so the
debug page stays, take over in production -

    on_error sub {
        my ($c, $err) = @_;
        return if $c->app->env ne 'production';
        $c->log->error("$err");
        return $c->render('error', {}, status => 500);
    };

=head2 on_not_found

    on_not_found sub {
        my ($c) = @_;
        return $c->render('404', { path => $c->req->path }, status => 404);
    };
    on_not_found 'Web::Err#not_found';

Runs when no route, mount or API operation matched - the same contract
as L</on_error>: a reference return becomes the response (after hooks
run, so sessions and flash work on the page; a returned L<Punk::Future>
is awaited), anything else keeps the default
C<404 {"errors":[...]}> byte-identical. A die inside it goes through
L</on_error>. The 405 answer for a known path with the wrong method is
deliberately not covered: its C<Allow> header semantics stay.

=head2 plugin

    plugin 'RequestId';
    plugin '+My::Plugin' => { opt => 1 };

Load and register a plugin; see L<Punk::Plugin>.

=head2 helper

    helper uid => sub { my ($c) = @_; $c->stash->{uid} };

Install a context helper method (usually done from plugins).

Plugins add keywords of their own with
C<< $app->install_kw(name => sub {...}) >>; see L<Punk::Plugin/KEYWORDS OF
YOUR OWN>. They behave exactly like the ones above.

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

L<Punk::Test>, L<Punk::Context>, L<Punk::Router::Scope>, L<Punk::Plugin>,
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
