use Test::Most;
use Test::Warnings qw/ warnings /;

use Plack::Middleware::Statsd;
use Test::MockObject;

my $client = Test::MockObject->new;
$client->mock( timing    => sub { } );
$client->mock( set_add   => sub { } );

my $middleware = Plack::Middleware::Statsd->new(
    client => $client,
    increment => 'Ouch',
);

isa_ok $middleware, qw/ Plack::Middleware /;

throws_ok {
    $middleware->prepare_app
} qr/increment is not a coderef/, 'expected error';

done_testing;
