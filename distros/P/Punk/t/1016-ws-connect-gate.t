#!perl
use 5.010;
use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Punk::Test;

# An Extended CONNECT is answerable by a websocket route and by nothing else.
#
# On HTTP/2 and HTTP/3 a websocket handshake is a CONNECT with :protocol
# websocket, and punk_serve.h routes it as the GET it stands in for because
# that is how a `websocket` route is registered. The rewrite happens before
# the route is known, so matching as GET reaches every GET route, every API
# operation and every mount, while the origin check lives in the handshake
# and runs only once a `ws` route has matched.
#
# That is the hole this pins. A 2xx IS the acceptance on this transport,
# written as :status on the CONNECT stream, so a page anywhere could open a
# socket at any path and read open-or-error as that path's status - with the
# user's cookies, and on paths a browser otherwise refuses to let it see.
#
# No live server is needed. A gated CONNECT answers 404 before any handler
# runs, and one that passes the gate runs on to the 403 the origin check
# gives a stranger or to the 501 that says this transport cannot carry a
# socket in-process. 404 means gated, anything else means it got through.

my @ran;

{
    package GateApp;
    use Punk;

    websocket '/chat' => sub { my ($c, $ws) = @_; push @ran, 'chat'; return };

    get  '/public'  => sub { push @ran, 'public'; $_[0]->text('public') };
    get  '/admin'   => sub { my $c = shift; push @ran, 'admin';
                             $c->text('denied', 403) };
    post '/submit'  => sub { push @ran, 'submit'; $_[0]->text('saved') };
    get  '/trail'   => sub { push @ran, 'trail'; $_[0]->text('trail') };

    mount '/inner' => sub { my $env = shift;
        push @ran, "mount:$env->{REQUEST_METHOD}";
        [ 200, [ 'Content-Type', 'text/plain' ], [ 'from the mount' ] ] };

    on_not_found sub { my $c = shift; push @ran, 'notfound';
                       $c->text('the app own 404', 404) };
}

my $t  = Punk::Test->new('GateApp');
my %WS = ('psgix.connect_protocol' => 'websocket');

sub connect_to {
    my ($path, %o) = @_;
    @ran = ();
    my %env = (%WS, %{ $o{env} || {} });
    $env{HTTP_ORIGIN} = $o{origin} if $o{origin};
    return $t->request_ok('CONNECT', $path, env => \%env,
                          name => $o{name} // "CONNECT $path");
}

# ---- the baseline: these routes work, and say different things ---------------

$t->get_ok('/public')->status_is(200, 'a plain route answers 200 on a GET');
$t->get_ok('/admin')->status_is(403, 'and a guarded one answers 403');

# ---- an Extended CONNECT reaches none of them --------------------------------

connect_to('/public', origin => 'https://evil.example')
  ->status_is(404, 'a cross-origin CONNECT does not reach a plain GET route');
is_deeply(\@ran, [], '...and the handler never ran');

connect_to('/admin', origin => 'https://evil.example')
  ->status_is(404, 'nor a guarded one');
is_deeply(\@ran, [], '...and that handler never ran either');

connect_to('/nowhere', origin => 'https://evil.example')
  ->status_is(404, 'a path with no route at all answers the same 404');

# The whole point of one status: the refusal must not vary with what is
# behind the path, or it is the same oracle in a smaller font.
connect_to('/submit', origin => 'https://evil.example')
  ->status_is(404, 'a POST-only path answers 404, not 405 with an Allow');
is($t->header('Allow'), undef, '...and names no methods');

connect_to('/trail/', origin => 'https://evil.example')
  ->status_is(404, 'the trailing-slash rescue is gated too');
is_deeply(\@ran, [], '...and that handler never ran');

connect_to('/inner/anything', origin => 'https://evil.example')
  ->status_is(404, 'a mount is not delegated to on an Extended CONNECT');
is_deeply(\@ran, [],
    '...so a mounted app never sees a CONNECT it would answer on path alone');

# on_not_found is deliberately bypassed: an application 404 that answered
# something other than 404 would put the status back under the app control.
unlike($t->body // '', qr/the app own 404/,
    'the gate answers the house 404, not on_not_found');

# ---- a CONNECT that is not a websocket handshake is untouched ----------------
#
# No rewrite, so no gate: it routes as the CONNECT it is, matches nothing, and
# gets the ordinary 405 for a path that exists under another method. That is
# not a way back to the oracle - a page cannot issue a bare CONNECT, only the
# extended form a WebSocket produces.

$t->request_ok('CONNECT', '/public', name => 'CONNECT with no :protocol')
  ->status_is(405, 'an ordinary CONNECT is not rewritten and matches nothing');

$t->request_ok('CONNECT', '/public',
    env  => { 'psgix.connect_protocol' => 'webtransport' },
    name => 'CONNECT :protocol=webtransport')
  ->status_is(405, 'and nor is another protocol');

# ---- the websocket route still gets through ----------------------------------

connect_to('/chat', origin => 'https://evil.example')
  ->status_is(403, 'a real websocket route reaches the origin check');
$t->content_like(qr/origin not allowed/, '...which refuses a stranger');

connect_to('/chat', origin => 'http://localhost')
  ->status_isnt(404,
    'and a same-origin handshake passes the gate to the handshake proper');

connect_to('/chat')
  ->status_isnt(404, 'a client that sends no Origin passes it as well');

# ---- HTTP/1.1 is not on this path at all ------------------------------------

$t->get_ok('/chat', headers => {
    'Upgrade'               => 'websocket',
    'Connection'            => 'Upgrade',
    'Sec-WebSocket-Key'     => 'dGhlIHNhbXBsZSBub25jZQ==',
    'Sec-WebSocket-Version' => 13,
    'Origin'                => 'http://localhost',
}, name => 'the HTTP/1.1 upgrade')
  ->status_isnt(404, 'a GET upgrade never had a method rewrite to gate');

# ---- an API operation is not a websocket route ------------------------------

SKIP: {
    skip 'the Open::API C ABI is not available', 2
        unless Punk->can('_oa_available') && Punk::_oa_available();

    my $spec = {
        openapi => '3.1.0',
        info    => { title => 'Gate', version => '1' },
        paths   => { '/pets' => { get => {
            operationId => 'listPets',
            responses   => { 200 => { description => 'ok' } },
        } } },
    };

    {
        package GateApi;
        use Punk;
        api $spec => { handlers => {
            listPets => sub { push @ran, 'listPets'; { pets => [] } },
        } };
    }

    my $a = Punk::Test->new('GateApi');
    $a->get_ok('/pets')->status_is(200, 'the operation answers a GET');

    @ran = ();
    $a->request_ok('CONNECT', '/pets',
        env  => { %WS, HTTP_ORIGIN => 'https://evil.example' },
        name => 'CONNECT /pets')
      ->status_is(404, 'and is not reachable by an Extended CONNECT');
    is_deeply(\@ran, [], '...with its handler never run');
}

done_testing;
