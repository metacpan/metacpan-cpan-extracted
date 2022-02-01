## no critic
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Mock::Podman::Service;

use Podman::Image;
use Podman::Client;

my $Connection =
  'http+unix://' . File::Temp::tempdir( CLEANUP => 1 ) . '/podman.sock';
my $Service = Mock::Podman::Service->new( Listen => $Connection );
$Service->Start();

my $Client = Podman::Client->new( Connection => $Connection );

subtest 'Pull image from registry.' => sub {
    my $Image =
      Podman::Image->Pull( 'docker.io/library/hello-world', 'latest', $Client );
    is( ref $Image, 'Podman::Image', 'Image ok.' );
    is( $Image->Name, 'docker.io/library/hello-world:latest',
        'Image Name ok.' );
};

subtest 'Build image from source.' => sub {
    my $Image =
      Podman::Image->Build( 'localhost/goodbye',
        "$FindBin::Bin/data/goodbye/Dockerfile", $Client );
    is( ref $Image,   'Podman::Image',     'Image ok.' );
    is( $Image->Name, 'localhost/goodbye', 'Image name ok.' );

};

my $Image =
  Podman::Image->new( Name => 'localhost/goodbye', Client => $Client );
ok( $Image, 'Object ok.' );

my $ExpectedData = {
    "Id" => "a76ad2934d4d6b478541c7d7df93c64dc0dcfd780472e85f2b3133fa6ea01ab7",
    "Tag"     => "latest",
    "Created" => "2022-01-26T17:25:47.30940821Z",
    "Size"    => 786563,
};
my $ActualData = $Image->Inspect();
is( ref $ActualData, 'HASH', 'Inspect ok.' );
is_deeply( $ActualData, $ExpectedData, 'Inspect response ok.' );

$Result = $Image->Remove();
ok( $Result, 'Image remove ok.' );

$Service->Stop();

done_testing();
