use Test::Most;
use Test::Warnings qw/ warnings /;

use Plack::Middleware::Statsd;
use Test::MockObject;

my $client = Test::MockObject->new;
$client->mock( timing  => sub { } );
$client->mock( set_add => sub { } );

my $middleware = Plack::Middleware::Statsd->new( client => $client );

isa_ok $middleware, qw/ Plack::Middleware /;

cmp_deeply
  [ warnings { $middleware->prepare_app } ],
  [ re('No increment method found for client Test::MockObject'), ],
  'expected warnings';

done_testing;
