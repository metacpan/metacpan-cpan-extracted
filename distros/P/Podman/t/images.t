## no critic
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp ();
use Mock::Podman::Service;

use Podman::Images;

local $ENV{PODMAN_CONNECTION_URL} =
  'http+unix://' . File::Temp::tempdir( CLEANUP => 1 ) . '/podman.sock';

my $service = Mock::Podman::Service->new();
$service->start;

my $images = Podman::Images->new();
ok( $images, 'Images object ok.' );

subtest 'Get list of images.' => sub {
    my $list = $images->list;
    is( ref $list,      'Mojo::Collection', 'List ok.' );
    is( $list->size,    2,                  'List length ok.' );
    is( ref $list->[0], 'Podman::Image',    'List item[0] ok.' );
    is( ref $list->[1], 'Podman::Image',    'List item[1] ok.' );
};

$service->stop;

done_testing();
