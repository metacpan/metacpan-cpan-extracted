## no critic
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp ();

use Mock::Podman::Service;

use Podman::Containers;
use Podman::Client;

my $Connection =
  'http+unix://' . File::Temp::tempdir( CLEANUP => 1 ) . '/podman.sock';

my $Service = Mock::Podman::Service->new( Listen => $Connection );
$Service->Start();

my $Client     = Podman::Client->new( ConnectionURI => $Connection );
my $Containers = Podman::Containers->new( Client => $Client );
ok( $Containers, 'Containers ok.' );

subtest 'Get list of containers.' => sub {
    my $List = $Containers->List();
    is( ref $List,       'ARRAY',             'List ok.' );
    is( scalar @{$List}, 1,                   'List length ok.' );
    is( ref $List->[0],  'Podman::Container', 'List item[0] ok.' );
};

$Service->Stop();

done_testing();
