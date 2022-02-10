## no critic
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp ();
use Mock::Podman::Service;

use Podman::Containers;

local $ENV{PODMAN_CONNECTION_URL} =
  'http+unix://' . File::Temp::tempdir( CLEANUP => 1 ) . '/podman.sock';

my $service = Mock::Podman::Service->new();
$service->start;

my $containers = Podman::Containers->new();
ok( $containers, 'Containers object ok.' );

subtest 'Get list of containers.' => sub {
    my $list = $containers->list;
    is( ref $list,      'Mojo::Collection',  'List ok.' );
    is( $list->size,    1,                   'List length ok.' );
    is( ref $list->[0], 'Podman::Container', 'List item[0] ok.' );
};

$service->stop();

done_testing();
