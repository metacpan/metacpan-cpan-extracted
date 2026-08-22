package Punk;

use 5.010;
use strict;
use warnings;

our $VERSION;

BEGIN {
    $VERSION = '0.28';
    require XSLoader;
    XSLoader::load('Punk', $VERSION);
}

use Punk::App;
use Punk::RateLimit;   # adds Punk::App::rate_limit + the key strategies
use Punk::Upload ();   # ->fh is Perl; the rest of the class is XS

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

    plugin 'RequestId';

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

C<schema>, C<source> and C<on_invalid> are keys of that longhand hashref, not
route options in their own right - C<< { validate => { schema => ..., source
=> 'params' } } >>, never C<< { schema => ..., source => 'params' } >>. A
route option the list below does not name croaks at boot.

=item * C<compress> - C<0> opts the route out of response compression.
See below.

=item * C<max_body> - refuse a request whose C<CONTENT_LENGTH> exceeds
this, overriding the application's L</max_body>. C<0> disables the check
for this route.

=item * C<sitemap> - C<0> keeps the route out of the generated
C<sitemap.xml>; C<1> puts it in despite a guard the plugin would
otherwise have excluded it for. Inert unless
L<Punk::Plugin::Sitemap> is registered.

=item * C<etag> - conditional GET. A coderef returns a validator the
application knows cheaply, and an unchanged one answers C<304> B<without
running the handler>; C<1> hashes the rendered body instead, which saves
the wire but not the server. Inert unless
L<Punk::Plugin::ConditionalGet> is registered.

=item * C<idempotent> - honour an C<Idempotency-Key> on this route, so a
client's retry replays the first response instead of doing the work
twice. Unsafe methods only. Inert unless
L<Punk::Plugin::Idempotency> is registered.

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

=head2 cache

    cache 'file', dir => '/var/cache/myapp', max_bytes => '512M';
    cache sessions => { backend => 'memory', max_bytes => '64M' };

    my $html = $c->cache->compute("profile:$id", 300, sub { ... });
    $c->cache('sessions')->set($sid => $blob, 3600);

A key/value cache with expiry and compute-if-missing. C<compute> is the method
that matters: get, and on a miss run the code, store the result and return it.

A name with a hashref declares a named store - a session cache and a page
cache want different budgets, and sharing one means the big cold thing evicts
the small hot thing.

C<file> is the default backend, and the arithmetic is why: an in-memory store
lives in one process, so C<< workers => 8 >> with a 512M cap is four gigabytes
of RSS with every worker caching the same things separately. The filesystem is
already shared, so a file store is one copy for the pool and survives a
restart.

Everything is validated at C<to_app> - an unknown backend, a C<max_bytes> that
does not parse, an unwritable directory - because a cache that fails on its
first miss fails at three in the morning.

See L<Punk::Cache>.

=head2 publish / subscribe

    $c->publish('cache:bust' => $key);

    # at boot, not per request
    $app->subscribe('cache:bust' => sub {
        my ($topic, $payload) = @_;
        delete $CACHE{$payload};
    });

The cross-worker message bus, for the things one worker learns and the others
need: a cache key changing, a config being re-read, a presence update, an
event to push down every open stream.

A prefork server makes anything held in a worker a lie about the pool. That is
the fault L<Punk::WebSocket::Room> used to have - a broadcast reached the
quarter of a room that happened to share a worker with the sender, succeeded,
and returned a plausible number. Rooms go over this now, and so can anything
else.

=head3 Two delivery modes

Without a C<group>, B<every> worker's subscriber sees B<every> message. That
is fanout, and it is what pushing an event to every connected client wants.

    $app->subscribe('news' => sub { $_->send($_[1]) for @streams });

With C<< group => $name >>, B<exactly one> member of that group sees each
message - work spread across the pool. There is no scheduler: a worker that is
busy is not there to claim, so the free ones take the traffic.

    $app->subscribe('thumbnails' => \&resize, group => 'workers');

=head3 Register at boot, not per request

A subscription made inside a request lands in one worker and lasts as long as
that process - which is the same mistake the bus exists to fix. Register where
the application is built, or from L<Hyperman>'s C<on_worker_start>.

=head3 What publish tells you

    1   on the ring: every worker in the pool will see it
    0   local only - there is no pool, so nobody else will
   -1   refused: too big for a bus slot

Three outcomes rather than true or false, because "the pool got it" and "only
I got it" are different facts, and an application that cannot tell them apart
cannot work out why the other workers stayed quiet.

C<0> is an ordinary answer, not a failure: under a server that is not
L<Hyperman>, on Windows, or on a compiler without the atomics the shared ring
needs, there is no pool and a message reaches this process alone. That is what
the behaviour was before the bus existed.

=head3 What it is not

B<Delivery is at-most-once and nothing survives a restart.> A worker that
takes a message and then dies loses it, and the loss is counted rather than
retried. If losing it matters - an email, a payment, an upload somebody paid
to have resized - this is the wrong tool and L<Punk::Queue> is the right one:
durable, at-least-once, and still there after a restart.

The bus is for what is worth microseconds and not worth a database.

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
    session secret => secret('session_key'), store => 'cache';   # server-side

Enable sessions: C<< $c->session >> is then a hashref written back when it
changes - to a HMAC-SHA256-signed cookie, or to a store if you name one. Source
the key from the L</secret> system. Options: C<secret>, C<cookie> (default
C<punk.sid>), C<expires>, C<path>, C<domain>, C<secure>, C<httponly> (default
on), C<samesite> (default C<Lax>), and C<store> with its C<sliding>, C<tier>
and C<allow_unshared>. An option it does not understand is a boot croak. Also
configurable from C<punk.yml>.

C<store> puts the payload on any L<Punk::Cache> backend and leaves an opaque id
in the cookie, which takes the ~4KB ceiling away and makes
C<< $c->session_expire >> a revocation rather than a request to the browser.
See L<Punk::Session>, and L<Punk::Session::Store> for the store half.

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

A B<static> C<Content-Security-Policy> belongs here. The policy that actually
stops cross-site scripting is C<script-src 'nonce-...'>, and a nonce is per
request - see L<Punk::Plugin::CSP>, which mints one, splices it into the
policy, and threads it into your templates.

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
    static '/static' => 'root/static', max_age => 3600;
    static '/static' => 'root/static', fingerprint => 1;

Serve files from a directory; see L<Punk::Static>.

A static file carries C<ETag> and C<Last-Modified> but no freshness
lifetime, so a browser revalidates it on every page load. C<max_age> (or a
verbatim C<cache_control>) gives a plain URL one.

C<fingerprint> asks for content-addressed URLs instead:
C<< $c->asset('/static/app.css') >> returns
C</static/app.9f3a1c2b0d4e5f60.css>, which serves with a year and
C<immutable> - checked against the file's current digest first, so a URL
from an older deploy revalidates rather than lying. It is opt-in because it
changes what a path means. Templates on the shipped Stencil engine reach
C<asset> as a filter: C<< {% "/static/app.css" | asset %} >>.

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
      RequestId: { header: X-Request-Id }
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

    hook before_request  => sub { my ($c) = @_; ...; return };
    hook before_dispatch => sub { my ($c) = @_; ...; return };
    hook after_dispatch  => sub { my ($c, $resp) = @_; ... };

C<before_request> runs B<before routing>; C<before_dispatch> runs after
routing and before guards (in both, a reference return short-circuits);
C<after_dispatch> sees the finalized PSGI triplet and may mutate it or
return a replacement.

All three take a coderef or a C<'Controller#method'> target, run in
registration order, and stop at the first reference return. A die goes
through L</on_error>, and a returned Future is awaited.

=head3 before_request vs before_dispatch

They differ only in when they run, and therefore in what they can see:

=over 4

=item *

C<before_request> is the only phase that runs for a request that does not
match a route: a B<404>, a B<405>, and anything answered by a PSGI or
static B<mount> - none of which reach C<before_dispatch> at all.

=item *

C<< $c->match >> is empty inside C<before_request> (there is no matched
route yet). It is a real hashref with empty captures, so C<< $c->match >>
and C<< $c->param >> behave rather than croak; it is populated by the time
the handler or API operation runs.

=item *

B<Both hooks get the same context.> A stash written in C<before_request>
is there in the handler and in C<after_dispatch>, which is what makes it
useful for timing and annotating a request.

=back

The cost of running first is that C<before_request> is ahead of three
things that refuse requests:

    hook before_request => sub { ... };   # runs even when the request is
                                          # about to be refused by:
    csrf;                                 #   the csrf check
    rate_limit ...;                       #   the rate limiter
    max_body 1_000_000;                   #   the max_body ceiling

For a hook that measures or records - a span, a request id, an access
count - that is exactly right: a refused request is still a request, and
you want it. For a hook that does work on the client's behalf, it is
wrong, and C<before_dispatch> remains the correct phase. (The C<max_body>
case costs no memory that was not already spent: the body is resident in
the server's buffer before Punk is called at all.)

An application with no C<before_request> hook pays nothing for the phase
existing - the chain is omitted from the compiled state entirely, and no
context is built before routing.

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

=head2 upload_dir

    upload_dir '/var/lib/myapp/incoming';

Where a large C<multipart/form-data> part is written while the request runs.
Defaults to C<TMPDIR>, else F</tmp>.

Worth naming, for two reasons that are not obvious. It decides the
B<filesystem>, and that decides whether C<< $upload->save >> is a rename or
another whole copy of a large file. And it decides what shares a filesystem
with attacker-controlled bytes.

See L<Punk::Upload>.

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

=head1 C ABI

Punk publishes a C ABI, C<pk_abi.h>, installed through L<ExtUtils::Depends>
and reached at runtime through C<< Punk::_abi_ptr >> - the same function-pointer
table Punk itself uses to reach L<Open::API>, L<Hyperman> and L<DBIx::Loop>.
It exists for the one thing a Perl hook cannot do cheaply: B<observe> every
request, on every path, without paying a C<call_sv> per request for the
privilege.

    #include "pk_abi.h"

    static void on_req(pTHX_ SV *c, void *ud) { ... }
    static void on_res(pTHX_ SV *c, SV *response, void *ud) { ... }

    A->on_request(aTHX_ on_req, NULL);
    A->on_response(aTHX_ on_res, NULL);

C<on_request> fires before routing - so before the csrf check, before
C<rate_limit> and before the C<max_body> ceiling, the same trade
L</before_request> makes. C<on_response> fires B<exactly once> per request, on
every path: a matched route, an API operation, a mount, a 404, a 405, a 413,
and an asynchronous answer, where it fires when the future settles rather than
when the handler returned it. Both are handed the same context, so state left
in its stash by one is there for the other.

The table also gives a consumer the request's C<route_pattern_of> - the route
as B<declared>, C<"/users/:id"> - which is the thing anything grouping by route
needs and which nothing outside the router could previously ask for.

C<on_query> (v2) observes statements run by the shipped L<Punk::Model::DBI>
backend. Note that there are B<two> database paths here: L<DBIx::Loop> has its
own observer, in C<dbil_abi>, and an application using the default C<model>
backend generates no DBIx::Loop traffic at all. A consumer wanting to see every
query an application makes registers with both. Neither is given the bind
B<values> - only the statement text, which carries placeholders exactly where
the literal data would have been.

Registration is B<process-global>, not per application, which is the opposite
of every other hook here: an app is a compiled artifact and a process may hold
several, while an observer is a property of the process. Register at boot;
there is no deregistration. Registering nothing costs nothing.

The table only grows at the end, C<PK_ABI_VERSION> bumps on any append, and a
consumer checks C<abi_version> before use. Nothing in it mutates a request or a
response: L</hook> already does that, in Perl, where a reader can see
it.

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
