use Test::More;
use lib 't/lib';
use Test::SpawnMq qw( mq );
use Sque;

my ( $s, $server ) = mq();

sub END { $s->() if $s }

my ($sque, $worker);

# Make sure we build fine with 2 servers for failover
$sque = new_ok( "Sque" => [( stomp => [ $server, $server ] )],
                    "Build Sque object $server" );

isa_ok( $worker = $sque->worker, 'Sque::Worker' );

# Also make sure it works properly with just one in an array
$sque = new_ok( "Sque" => [( stomp => [ $server ] )],
                    "Build Sque object $server" );

isa_ok( $worker = $sque->worker, 'Sque::Worker' );

done_testing;
