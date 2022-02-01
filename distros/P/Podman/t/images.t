## no critic
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp ();

use Mock::Podman::Service;

use Podman::Images;
use Podman::Client;

my $Connection =
  'http+unix://' . File::Temp::tempdir( CLEANUP => 1 ) . '/podman.sock';
my $Service = Mock::Podman::Service->new( Listen => $Connection );
$Service->Start();

my $Client = Podman::Client->new( Connection => $Connection );

my $Client = Podman::Client->new( Connection => $Connection );
my $Images = Podman::Images->new( Client     => $Client );
ok( $Images, 'Object ok.' );

subtest 'Get list of images.' => sub {
    my $List = $Images->List();
    is( ref $List,       'ARRAY',         'List ok.' );
    is( scalar @{$List}, 2,               'List length ok.' );
    is( ref $List->[0],  'Podman::Image', 'List item[0] ok.' );
    is( ref $List->[1],  'Podman::Image', 'List item[1] ok.' );
};

$Service->Stop();

done_testing();
