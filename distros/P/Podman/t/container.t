## no critic
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp ();
use Mock::Podman::Service;

use Podman::Container;

local $ENV{PODMAN_CONNECTION_URL} =
  'http+unix://' . File::Temp::tempdir( CLEANUP => 1 ) . '/podman.sock';

my $service = Mock::Podman::Service->new();
$service->start;

subtest 'Create container.' => sub {
    my $container =
      Podman::Container::create( 'debian', 'docker.io/library/debian' );
    is( ref $container,   'Podman::Container', 'Container object ok.' );
    is( $container->name, 'debian',            'Container name ok.' );
};

my $container = Podman::Container->new( name => 'hello' );
ok( $container, 'Containers object ok.' );

my $expected_data = {
    "Id" => "12c18c554c9087de0fc7584db27e9f621eb6534001881f7276ffabee5e359234",
    "Created" => "2022-01-26T22:49:15.906680921+01:00",
    "Status"  => "created",
    "Cmd"     => ["/hello"],
    "Ports"   => undef,
};
my $actual_data = $container->inspect;
is( ref $actual_data,          'HASH',          'Container inspect ok.' );
is( ref $actual_data->{Image}, 'Podman::Image', 'Container image ok.' );
delete $actual_data->{Image};
is_deeply( $actual_data, $expected_data, 'Container inspect response ok.' );

$expected_data = {
    "BlockIO"    => "0 / 0",
    "CpuPercent" => 1.2368915569887e-09,
    "MemPercent" => 0.0439310676171934,
    "MemUsage"   => 7217152,
    "NetIO"      => "0 / 0",
    "PIDs"       => 9,
};
$actual_data = $container->stats;
is_deeply( $actual_data, $expected_data, 'Container stats response ok.' );

ok( $container->start,  'Container start ok.' );
ok( $container->stop,   'Container stop ok.' );
ok( $container->kill,   'Container kill ok.' );
ok( $container->remove, 'Container remove ok.' );

$service->stop;

done_testing();
