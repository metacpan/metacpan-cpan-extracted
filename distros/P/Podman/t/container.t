## no critic
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp ();

use Mock::Podman::Service;

use Podman::Container;
use Podman::Client;

my $Connection =
  'http+unix://' . File::Temp::tempdir( CLEANUP => 1 ) . '/podman.sock';
my $Service = Mock::Podman::Service->new( Listen => $Connection );
$Service->Start();

my $Client = Podman::Client->new( ConnectionURI => $Connection );

subtest 'Create container.' => sub {
    my $Container =
      Podman::Container->Create( 'debian', 'docker.io/library/debian',
        $Client );
    is( ref $Container,   'Podman::Container', 'Container ok.' );
    is( $Container->Name, 'debian',            'Container Name ok.' );
};

my $Container = Podman::Container->new( Name => 'hello', Client => $Client );

my $ExpectedData = {
    "Id" => "12c18c554c9087de0fc7584db27e9f621eb6534001881f7276ffabee5e359234",
    "Created" => "2022-01-26T22:49:15.906680921+01:00",
    "Status"  => "created",
    "Cmd"     => ["/hello"],
    "Ports"   => undef,
};
my $ActualData = $Container->Inspect();
is( ref $ActualData,          'HASH',          'Inspect ok.' );
is( ref $ActualData->{Image}, 'Podman::Image', 'Container image ok.' );
delete $ActualData->{Image};
is_deeply( $ActualData, $ExpectedData, 'Inspect response ok.' );

ok( $Container->Start(),  'Container start ok.' );
ok( $Container->Stop(),   'Container stop ok.' );
ok( $Container->Kill(),   'Container kill ok.' );
ok( $Container->Delete(), 'Container delete ok.' );

$Service->Stop();

done_testing();
