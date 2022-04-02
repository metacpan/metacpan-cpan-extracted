use Test::More;
use Test::Exception;
use Test::Mojo;
use Mojolicious::Lite;
use JSON::RPC2::Server;
use MojoX::JSONRPC2::HTTP;

eval { require Mojolicious::Plugin::JSONRPC2 };
plan skip_all => 'Mojolicious::Plugin::JSONRPC2 required' if $@;

$ENV{MOJO_LOG_LEVEL} = 'warn';
app->secrets('test');
plugin 'JSONRPC2';

my $server1 = JSON::RPC2::Server->new();
my $server2 = JSON::RPC2::Server->new();
my $server3 = JSON::RPC2::Server->new();
$server1->register('method', sub { return 'one' });
$server1->register_named('complex', sub { return 'another one' });
$server2->register('method', sub { return undef, 123, 'GET is bad!' });
$server3->register('method', sub { return 'surprise' });

my $r = app->routes;
$r->jsonrpc2('/', $server3)->requires(headers => {'X-Secret'=>42});
$r->jsonrpc2('/', $server1);
$r->jsonrpc2_get('/', $server2);

my $t = Test::Mojo->new(app);

my $client = MojoX::JSONRPC2::HTTP->new;
my $res;

# default attributes
throws_ok { $client->call('method') } qr/->url/,
    'need to set ->url before doing RPC';
is $client->method, 'POST',
    'default ->method';
is $client->type, 'application/json',
    'default ->type';
is_deeply $client->headers, {},
    'default ->headers';
is ref $client->ua, 'Mojo::UserAgent',
    'default ->ua';

# network error
my ($failed,$result,$error) = $client->url('http://no-such-host-qKfdsEsZ./')->call('method');
like $failed, qr/connect|resolve/msi, 'network error';

$client->url('/');

# blocking call/call_named
is_deeply [$client->call('method')],
    [undef, 'one', undef],
    'POST / call';
is_deeply [$client->call('complex')],
    [undef, 'another one', undef],
    'POST / call (named, without params)';
is_deeply [$client->call('complex', 42)],
    [undef, undef, {code=>-32602,message=>'This method expect named params.'}],
    'POST / call (named, with params)';
is_deeply [$client->call_named('complex', key=>42)],
    [undef, 'another one', undef],
    'POST / call_named';
is_deeply [$client->method('GET')->call('method')],
    [undef, undef, {code=>123,message=>'GET is bad!'}],
    'GET  / call';
is_deeply [$client->call('method', 42)],
    [undef, undef, {code=>123,message=>'GET is bad!'}],
    'GET  / call';

# ->headers
is_deeply [$client->method('POST')->headers({'X-Secret'=>42})->call('method')],
    [undef, 'surprise', undef],
    'POST / call with headers';
is_deeply [$client->call('method')],
    [undef, 'surprise', undef],
    'POST / call still with headers';
delete $client->headers->{'X-Secret'};
is_deeply [$client->call('method')],
    [undef, 'one', undef],
    'POST / call';

# blocking notify/notify_named
is_deeply [$client->notify('method', 42)],
    [undef],
    'POST / notify';
is_deeply [$client->notify_named('method', key=>42)],
    ['200 OK'],
    'POST / notify_named';
is_deeply [$client->url('/nosuch')->notify('method', 42)],
    ['404 Not Found'],
    'POST / notify';
$client->url('/');

# non-blocking
$client->call('method', 42, cb());
Mojo::IOLoop->one_tick while !$res;
is_deeply $res, [undef, 'one', undef],
    'POST / call (non-blocking)';
$client->method('GET')->call_named('method', key=>42, cb());
Mojo::IOLoop->one_tick while !$res;
is_deeply $res, [undef, undef, {code=>-32602,message=>'This method expect positional params.'}],
    'POST / call_named (non-blocking)';
$client->notify('method', 42, cb());
Mojo::IOLoop->one_tick while !$res;
is_deeply $res, [undef],
    'POST / notify (non-blocking)';
$client->method('POST')->notify_named('method', key=>42, cb());
Mojo::IOLoop->one_tick while !$res;
is_deeply $res, ['200 OK'],
    'POST / notify_named (non-blocking)';


done_testing();


sub cb {
    undef $res;
    return sub { $res = \@_ };
}

