package Punk;

use 5.010;
use strict;
use warnings;

our $VERSION;

BEGIN {
    $VERSION = '0.46';
    require XSLoader;
    XSLoader::load('Punk', $VERSION);
}

use Punk::App;
use Punk::RateLimit;   
use Punk::Upload ();   

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
material for the session config. C<punk serve ./public> is the odd one
out - a directory of files over HTTP, with no application anywhere near
it. See L<Punk::Generate> and L<Punk::Command>.

The generated test drives the app through L<Punk::Test>: an in-process
client with a cookie jar and chained assertions, so sessions, CSRF,
JSON APIs, server-sent events and websockets are all testable against
the same frozen coderef a server would run.

L<https://punkperl.com>

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

=item * C<last_modified> - the date validator, for the clients that only
speak C<If-Modified-Since> (feed readers above all). A coderef returns an
epoch, the C<200> carries C<Last-Modified>, and an unchanged one answers
C<304> before the handler runs. Coderef only - a rendered body has no
timestamp to derive, so there is no C<1> form. Inert unless
L<Punk::Plugin::ConditionalGet> is registered.

=item * C<idempotent> - honour an C<Idempotency-Key> on this route, so a
client's retry replays the first response instead of doing the work
twice. Unsafe methods only. Inert unless
L<Punk::Plugin::Idempotency> is registered.

=item * C<rate_limit> - a budget of requests per window for this route
alone, refused with C<429> once it is spent. A count, or C<< { limit,
window, by, tag } >>. See L</A budget for one route>.

=item * C<name> - the route's name, for L</Named routes>. Everything that
points at the route uses the name instead of spelling the path again:
C<< $c->url_for('book', id => 42) >> in code, C<< {% url.book %} >> or the
C<url_for> filter in a template.

A name is an identifier - C<[A-Za-z0-9_]+> - because one name is written
in all of those places and in C<punk routes --name>. A dot is refused with
its own message: a template reads C<< {% url.queue.jobs %} >> as a path
through nested hashes, so a dotted name would be one a handler could build
and a template could not reach. Namespace with an underscore instead:
C<queue_jobs>. C<absolute> and C<query> are refused because C<url_for>
takes them as options.

Names are one namespace for the whole application, and two routes with one
name croak at C<to_app> naming both. A plugin that takes C<index> has taken
it from the application.

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

=head3 Named routes

    get '/books'     => 'Web::Book#list', { name => 'books' };
    get '/books/:id' => 'Web::Book#view', { name => 'book'  };

    $c->url_for('book', id => 42);                 # /books/42
    $c->url_for('book', id => 42, page => 2);      # /books/42?page=2
    $c->url_for('book', id => 42, absolute => 1);  # https://example.com/books/42

A route with a name can be pointed at without its path being written a
second time, which is what makes renaming one a safe edit. Three rules
carry most of it:

=over 4

=item 1.

An argument naming a capture fills that segment; anything left over becomes
the query string, keys sorted so the same call always produces the same
URL. C<< query => \%h >> is the explicit form, for a query key spelled like
a capture; with it, an argument that names no capture is a mistake rather
than a query pair.

=item 2.

A missing capture, an empty one, and a C</> in a C<:param> all croak. The
last is the surprising one: C<PATH_INFO> reaches the router percent-decoded,
so a C<%2F> would be a C</> again by the time it arrived, the path would
have one segment too many, and the request would 404. A value with a slash
in it cannot be expressed on that route, and a URL that cannot work is a
bug at the call site rather than a value to return. C<*splat> is the
segment that does take slashes.

=item 3.

C<< absolute => 1 >> builds on L<Punk::Context/origin>, which is the
canonical L</host> unless the request's C<Host> is on the allowlist, and is
never the raw header. So a link built in a handler and put in an email
cannot be poisoned by a crafted C<Host>. Without a C<host> it croaks rather
than guessing from the request.

=back

Every URL carries the application's prefix, relative or absolute: the path
on L</host> first, then C<SCRIPT_NAME>. Those are layers rather than
alternatives - a proxy strips one, a PSGI mount adds the other, and the
browser sees both - and a relative URL needs the prefix exactly as much as
an absolute one does, because it is resolved against a page that is already
under it.

C<websocket> and C<sse> routes take C<name> too, and so does an OpenAPI
operation: an C<operationId> is a route name in the same namespace, so
C<< $c->url_for('getBook', id => 1) >> builds the mounted path. Those ids
are the spec's rather than Punk's, so they are not held to the identifier
rule above - one that is not an identifier still works with C<url_for> and
is simply absent from the template C<url> hash.

C<punk routes> shows a C<NAME> column, and C<punk routes --name X> selects
one. In templates, see L<Punk::View::Stencil/Named routes>.

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
that offers none of them is refused), C<origin> (L</Which origins may
open a socket>), C<max_message_size> (default 16MB),
C<write_buffer_limit>, C<blocking>, and C<name> (L</Named routes>; the
route is a GET route, so C<< $c->url_for >> and C<< {% url.chat %} >> give
its path, and an application that wants C<wss://> does the scheme swap
itself).

=head3 Which origins may open a socket

An upgrade carries the user's cookies, gets no preflight, and is not
covered by the same-origin policy: the browser sends it wherever the page
came from and delivers the answer. So the handshake refuses a request
whose C<Origin> is not one this application answers as, with a C<403>
before the socket is taken over. Without that, any page anywhere could
open an authenticated socket to your application and read and write as
whoever is looking at it.

What counts as this application, by default and with no configuration:

=over 4

=item * The request's own C<Host>. That is what same-origin means, and it
is sound against the attack - a page cannot set C<Host>, the browser sends
the target's. The comparison is on host and port, not scheme.

=item * The origin C<host> declares, this time including its scheme,
along with the hosts its C<allow> list names. The pages an application
serves are the pages that may talk back to it.

=back

A request that sends no C<Origin> at all is not refused. Browsers always
send one on an upgrade; a client that does not send one - a mobile
application, a daemon, C<Punk::Test> - has no ambient cookies to be used
against it, and refusing it would break every non-browser client to stop
an attack it cannot be the subject of.

The option widens or replaces that:

    websocket '/chat' => $target, { origin => 'app.example.com' };
    websocket '/chat' => $target, { origin => [ 'app.example.com',
                                                '*.example.net' ] };
    websocket '/hub'  => $target, { origin => sub { ... } };
    websocket '/pub'  => $target, { origin => 0 };

A hostname or an arrayref of them is B<added> to the same-origin rule, in
the syntax C<host>'s C<allow> takes: labels of C<[a-z0-9-]>, an optional
leading C<*.> and an optional C<:port>, matched whole rather than as a
pattern, so a typo croaks at the keyword instead of never matching. Use it
for a front end served from a host of its own.

A coderef is called with the context and the origin, and decides. C<0>
turns the check off, which is the right answer for a socket API meant to
be called from anywhere and the wrong one for anything a session reaches.
C<undef> is refused rather than read as C<0>, because that value usually
arrives from configuration and a missing key must not quietly take the
check away.

C<sse> has no such option: an C<EventSource> is an ordinary cross-origin
request, so the browser applies CORS to it and L</cors> already says who
may read one.

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
C<write_buffer_limit>, C<blocking>, and C<name> (L</Named routes>).
See L<Punk::SSE>.

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

=head2 rate_limit

    rate_limit limit => 100, window => 60;
    rate_limit limit => 20,  window => 60, for => '/api';
    rate_limit limit => 1000, window => 3600, by => 'header:X-Api-Key';
    rate_limit limit => 10,  window => 60, by => sub { $_[0]->auth_id };

A budget of C<limit> requests per C<window> seconds for each caller, refused
with C<429> and C<Retry-After> once it is spent. Counters live in
L<Hyperman>'s shared arena, so the limit is exact across the whole worker
pool rather than per worker, and the check costs no Perl frame.

C<by> names the caller: C<ip> (the default, C<REMOTE_ADDR> - read
L</The shared bucket> first if anything sits in front of the application),
C<header:NAME>, or a coderef returning an identity, which is how a limit
follows a signed-in user rather than their address. C<for> narrows the rule
to a path prefix, and C<tag> names the counter, which two rules must differ
in if they are not to spend each other's budget; by default the header, the
coderef or the address supplies it. Declare it more than once for layered
limits.

A rule declared here applies to every request under its prefix. For a
budget belonging to one route, see the C<rate_limit> B<route option> below.

=head3 A budget for one route

    post '/login' => 'Web::Auth#login', { rate_limit => 5 };

    post '/login' => 'Web::Auth#login',
         { rate_limit => { limit => 5, window => 60 } };

The keyword is one policy for a path prefix, which is the right shape for
"the whole API" and the wrong one for "five tries a minute at the password
form". The route option is the second: a budget belonging to one route,
compiled into a guard at C<to_app> so a route that declares nothing pays
nothing.

It takes the same C<limit>, C<window>, C<by> and C<tag> the keyword takes
(C<for> is refused - the route is the scope), or a bare count as shorthand
for that many in the default window. C<< rate_limit => 0 >> is what a route
says by saying nothing.

The counter is namespaced to the route, so C</login> and C</forgot> do not
spend each other's budget. Naming a C<tag> is how they deliberately share
one:

    my %auth = ( limit => 5, window => 60, tag => 'auth' );
    post '/login'    => 'Web::Auth#login',    { rate_limit => \%auth };
    post '/register' => 'Web::Auth#register', { rate_limit => \%auth };
    post '/forgot'   => 'Web::Auth#forgot',   { rate_limit => \%auth };

The guard runs before the route's C<validate>, so a request over its budget
is refused without its body being parsed. Layers compose: an application-wide
rule and a route's own both apply, and the tighter one is reached first if it
is the route's.

Everything about the spec is checked where it is written - an unknown option,
a C<by> that is not C<ip>, C<header:NAME> or a coderef, a window of zero -
so a typo croaks at boot rather than limiting nothing.

Like the keyword, this needs L<Hyperman> and its arena. Without one there is
nowhere to count, and every request is allowed: a rate limit that cannot see
its counters must not refuse traffic it has no evidence about.

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

What the application can still avoid is a B<second> copy of those bytes.
C<< $c->req->body >> puts the whole request in one scalar; for a large one,
L<Punk::Request/body_each> and L<Punk::Request/body_to> read it a window at a
time instead, which is what the multipart parser has always done with
uploads.

=head2 host

    host 'https://example.com';

The application's canonical origin, declared once. Anything that needs an
absolute URL for the application defaults to this instead of asking for
its own copy, and an explicit option on the plugin still wins -
L<Punk::Plugin::Sitemap>'s C<base> is the first consumer, so

    host 'https://example.com';
    plugin 'Sitemap';

is the whole sitemap configuration.

The value must be an absolute C<http://> or C<https://> origin. A path is
allowed, for an application deployed under a prefix, and trailing slashes
are trimmed so a consumer joining a rooted path onto it produces one
slash; a query, a fragment, whitespace or a backslash croaks at the
keyword. Declared twice, the last declaration wins.

This is configuration, deliberately. The tempting alternative - reading
the request's Host header - hands every consumer attacker-supplied bytes,
which is exactly why those plugins refuse to guess. Also configurable
from C<punk.yml>. With no argument it reads the stored value back, which
is how a plugin reaches it: C<< $app->host >>.

=head3 Several hosts: the allowlist

    host 'https://example.com', allow => [ '*.example.com', 'shop.tld' ];

One application serving several tenants by Host header has an origin per
request, and the request's Host is attacker-supplied. C<allow> names the
hosts that may stand in for the canonical one, and C<< $c->origin >> is
then the request's scheme and host B<only> when that host is the canonical
one or matches an entry - the canonical origin otherwise, and never the
raw header. C<< $c->host_allowed >> says which of those happened, for an
application that would rather refuse an unknown host than answer for it.

An entry is a hostname, optionally with a C<:port>, or a leading C<*.>
for every host under a suffix; anything else croaks at the keyword.
Matching is case-insensitive and ignores the request's port unless the
entry names one. The canonical host needs no entry.

L<Punk::Plugin::Sitemap> is the first consumer: an allowlisted host is
handed a sitemap and C<robots.txt> naming itself, rendered from the same
route table. In C<punk.yml> the block becomes a mapping:

    host:
      origin: https://example.com
      allow:  [ '*.example.com', shop.tld ]

=head2 static

    static '/static' => 'root/static';
    static '/static' => 'root/static', max_age => 3600;
    static '/static' => 'root/static', fingerprint => 1;
    static '/docs'   => 'root/docs',   index => 'index.html';

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

A directory is a 404 on its own. C<index> names the file it resolves to -
which is what makes a tree of F<index.html> files servable - and answers
for both C</docs/guide> and C</docs/guide/> where they were asked for,
with no redirect between them. C<list> renders a listing for a directory
that has no index file. Both are off unless asked for.

Small files are held in memory per worker after their first read, so a hit
does no file syscall at all - the syscalls were two thirds of the cost of
serving one. Files above half a megabyte, and C<Range> requests, stream from
disk as they always did.

Two things are cached, and they keep different promises.

The B<content> is exact. It is re-read whenever the file's inode,
modification time or size changes, so publishing a new file by any ordinary
means - a rename into place, an install, a build step - is picked up at once.
The only case it cannot see is a file rewritten IN PLACE that keeps both its
modification time and its exact size.

The B<stat> is held for one second, which is also how long a change can go
unnoticed: within that second the file is not looked at, so a file edited and
reloaded may serve its old bytes once. C<PUNK_STATIC_STAT_TTL> sets the
window, and C<PUNK_STATIC_STAT_TTL=0> removes it - every request stats, the
content cache still applies, and the result is exactly correct at most of the
speed. C<PUNK_NO_STATIC_FILE_CACHE=1> turns off both.

The same cache remembers that a file is B<absent>, which is what makes the
precompressed-sibling lookup free: every browser sends C<Accept-Encoding>, so
without it every request would go looking for a C<.br> and a C<.gz> that most
sites have never had.

=head2 favicon

    favicon 'root/static/favicon.ico';
    favicon 'root/static/favicon.ico', max_age => 3600;

Serve C<GET /favicon.ico> from this file. A browser and a search engine's
favicon crawler both request it at the site ROOT, where a C</static>
mount does not answer - without a root route the request is a 404 and
search results fall back to the generic globe. This keyword is that
route, replacing the C<send_file> handler every application was writing
by hand.

The bytes are read once, at C<to_app>, and served from memory with a
C<Cache-Control> (C<public, max-age=86400> unless C<max_age> says
otherwise) and a strong C<ETag>; a request carrying the tag back is
answered C<304> without a body. A file that cannot be read croaks at
boot rather than 404ing for as long as nobody notices, and C<punk dev>
picks up a replaced icon on its restart. The content type follows the
file's extension, so a C<.png> or C<.svg> serves as itself.

The route stays out of L<Punk::Plugin::Sitemap>'s document, and it is a
route like any other - an application adopting the keyword must delete
its hand-rolled C<< get '/favicon.ico' >>, or boot croaks a duplicate.
Also configurable from C<punk.yml>: a path, or a mapping with C<path>
and C<max_age>.

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
    config 'config/punk.yml', env => 'production';

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
    host: https://myapp.example  # -> host 'https://myapp.example'
    favicon: root/static/favicon.ico   # -> favicon '...'

Everything else in the file is yours, through C<< $app->config >>.

Applied where the keyword sits, so put it first and the routes after it
can rely on what it registered. Layers: C<punk.yml>, then
C<punk.$PUNK_ENV.yml>, then the gitignored C<punk.local.yml>.

B<Secrets never belong in the file.> A value written
C<< { $env: NAME } >>, C<< { $file: PATH } >> or C<< { $exec: [...] } >>
is resolved at boot from outside it; C<< $app->config >> shows
C<[redacted]> in its place and C<< $app->secret('database.password') >>
reaches the real thing. Whether a value is written into the file in
plaintext instead is the decision of whoever writes the file. See
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
    hook after_response  => sub { my ($c, $resp) = @_; ... };

C<before_request> runs B<before routing>; C<before_dispatch> runs after
routing and before guards (in both, a reference return short-circuits);
C<after_dispatch> sees the finalized PSGI triplet and may mutate it or
return a replacement; C<after_response> runs once that response has been
handed to the server, and cannot change it.

The first three take a coderef or a C<'Controller#method'> target, run in
registration order, and stop at the first reference return. A die goes
through L</on_error>, and a returned Future is awaited.

=head3 after_response

C<after_dispatch> can replace the triplet, which is exactly why it has to
run B<before> the response is written. C<after_response> is the phase after
that: the work a request generates but the client is not waiting for - an
audit row, a cache warm, a counter, an enqueue.

    hook after_response => sub {
        my ($c, $resp) = @_;
        $c->model('Audit')->create({ path => $c->req->path,
                                     status => $resp->[0] });
    };

A single request can add its own, which is usually the more useful half
because the work is the handler's:

    post '/orders' => sub {
        my ($c) = @_;
        my $order = $c->model('Order')->create($c->validate->data);
        $c->after_response(sub { warm_the_dashboard($order) });
        $c->json({ id => $order->{id} }, 201);
    };

The application's hooks run first, then whatever the request queued, each in
registration order. Both are given the context and the response that was
sent. A return value has nowhere to go and is discarded, and a die is logged
through the application's logger while the rest still run: there is no
response left to turn into a C<500>, and a die that vanished silently here
would be worse than one that is written down.

B<Where "after" is depends on what is underneath>, and it is worth knowing
which of the three you have:

=over 4

=item * On a server offering C<psgix.cleanup> - the PSGI extension - the
callbacks are handed to it and it runs them once the response is complete.

=item * On a L<Hyperman> worker, they run on the next pass of the event loop,
so the response has already been written to the socket and the worker is free
to take other requests in the meantime.

=item * Anywhere else they run B<inline>, immediately after the response is
final and before it is returned to the server. The phase still runs in the
right order and everything above still holds, but there is no loop to hand
the work to, so a slow callback does delay the client. This is what a plain
PSGI server and L<Punk::Test> do.

=back

None of the three is a job queue: nothing is persisted, nothing is retried,
and a worker that dies takes its pending callbacks with it. Work that must
happen belongs in L<Punk::Plugin::Queue>; work that would merely be nice to
have off the request's path belongs here.

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
