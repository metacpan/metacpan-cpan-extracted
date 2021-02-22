use Test::More;
use Test::Exception;
use Test::Mojo;
use Mojolicious::Lite;
use JSON::RPC2::Server;
use JSON::RPC2::Client;

$ENV{MOJO_LOG_LEVEL} = 'warn';
app->secrets('test');
plugin 'JSONRPC2';

my $server_full = JSON::RPC2::Server->new();
my $server_safe = JSON::RPC2::Server->new();
my $server_slow = JSON::RPC2::Server->new();
$server_full->register('method', sub { return 'full' });
$server_safe->register('method', sub { return 'safe' });
$server_slow->register_nb('method', sub {
    my $cb = shift;
    Mojo::IOLoop->timer(0.5 => sub { $cb->('slow') });
});

my $r = app->routes;
$r->jsonrpc2('/', $server_full);
$r->jsonrpc2_get('/safe', $server_safe)->requires(headers => { app->jsonrpc2_headers });
$r->jsonrpc2_get('/only', $server_safe);
$r->jsonrpc2('/only', $server_full);
$r->jsonrpc2('/slow', $server_slow);
$r->get('/',        {text=>'Full API'});
$r->get('/safe',    {text=>'Safe API'});
$r->get('/only',    {text=>'Only Safe API'});
$r->post('/only',   {text=>'Only Full API'});

my $t = Test::Mojo->new(app);

my %headers = (
    'Content-Type'  => 'application/json',
    'Accept'        => 'application/json',
);
my $body    = '{"jsonrpc":"2.0","id":0,"method":"method"}';
my $query   = 'jsonrpc=2.0&id=0&method=method';

# * wrong params
#   - no $server
#   - bad $server
throws_ok { $r->jsonrpc2()                  } qr/usage.*jsonrpc2\(/,
    'no $server';
throws_ok { $r->jsonrpc2_get('/path')       } qr/usage.*jsonrpc2_get\(/,
    'no $server';
throws_ok { $r->jsonrpc2('/path', undef, 1) } qr/usage/,
    'no $server';
throws_ok { $r->jsonrpc2('/path', $r)       } qr/usage/,
    'bad $server';

# * jsonrpc2() use POST:
#   GET  / → text
#   POST /
#   - bad headers → 415
#   - good headers → RPC (full)
$t->get_ok('/')
    ->status_is(200)
    ->content_is('Full API');
$t->post_ok('/', $body)
    ->status_is(415);
$t->post_ok('/', {%headers, 'Content-Type'=>q{}}, $body)
    ->status_is(415);
$t->post_ok('/', {%headers, 'Content-Type'=>'text/plain'}, $body)
    ->status_is(415);
$t->post_ok('/', {%headers, 'Accept'=>q{}}, $body)
    ->status_is(415);
$t->post_ok('/', {%headers, 'Accept'=>'text/plain'}, $body)
    ->status_is(415);
$t->post_ok('/', \%headers, $body)
    ->status_is(200)
    ->json_is('/result' => 'full');

# * jsonrpc2_get() with jsonrpc2_headers() use GET with good headers and separate $server
#   GET  /safe
#   - bad headers → text
#   - good headers → RPC (safe)
#   POST /safe → 404
$t->get_ok("/safe?$query")
    ->status_is(200)
    ->content_is('Safe API');
$t->get_ok("/safe?$query", \%headers)
    ->status_is(200)
    ->json_is('/result' => 'safe');
$t->post_ok('/safe', \%headers, $body)
    ->status_is(404);

# * jsonrpc2() and jsonrpc2_get() use format=>0
#   GET  /only
#   - bad headers → 415
#   - good headers → RPC (safe)
#   GET  /only.txt → text
#   POST /only
#   - bad headers → 415
#   - good headers → RPC (full)
#   POST /only.txt → text
$t->get_ok("/only?$query")
    ->status_is(415);
$t->get_ok("/only?$query&params=[42]",\%headers)
    ->status_is(200)
    ->json_is('/result' => 'safe');
$t->get_ok("/only.txt?$query")
    ->status_is(200)
    ->content_is('Only Safe API');
$t->post_ok('/only', $body)
    ->status_is(415);
$t->post_ok('/only', \%headers, $body)
    ->status_is(200)
    ->json_is('/result' => 'full');
$t->post_ok('/only.txt', \%headers, $body)
    ->status_is(200)
    ->content_is('Only Full API');

# * reply format
#   - Content-Type
#   - Status: 200, 204
$t->post_ok('/', \%headers, $body)
    ->status_is(200)
    ->content_type_is('application/json')
    ->content_isnt(q{});
my $body2 = '{"jsonrpc":"2.0","method":"method"}';
$t->post_ok('/', \%headers, $body2)
    ->status_is(204)
    ->content_type_is('application/json')
    ->content_is(q{});

# * timeout
$t->post_ok('/slow', \%headers, $body)
    ->status_is(200)
    ->content_type_is('application/json')
    ->json_is('/result' => 'slow');
app->defaults('jsonrpc2.timeout' => 0.1);
my $tx = $t->ua->post('/slow', \%headers, $body);
is $tx->error->{message}, 'Premature connection close', 'timeout';

done_testing();
# app->start('routes','-v');
