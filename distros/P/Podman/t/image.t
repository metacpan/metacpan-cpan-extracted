## no critic
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use Mock::Podman::Service;

use Podman::Image;

local $ENV{PODMAN_CONNECTION_URL} =
  'http+unix://' . File::Temp::tempdir( CLEANUP => 1 ) . '/podman.sock';

my $service = Mock::Podman::Service->new();
$service->start;

subtest 'Pull image from registry.' => sub {
    my $image =
      Podman::Image::pull( 'docker.io/library/hello-world', 'latest' );
    is( ref $image,   'Podman::Image',                 'Image ok.' );
    is( $image->name, 'docker.io/library/hello-world', 'Image Name ok.' );
};

subtest 'Build image from source.' => sub {
    my $image =
      Podman::Image::build( 'localhost/goodbye',
        "$FindBin::Bin/data/goodbye/Dockerfile" );
    is( ref $image,   'Podman::Image',     'Image ok.' );
    is( $image->name, 'localhost/goodbye', 'Image name ok.' );
};

subtest 'Verify image methods.' => sub {
    my $image = Podman::Image->new( name => 'localhost/goodbye' );
    ok( $image, 'Image constructor ok.' );

    my $expected_data = {
        "Id" =>
          "a76ad2934d4d6b478541c7d7df93c64dc0dcfd780472e85f2b3133fa6ea01ab7",
        "Tag"     => "latest",
        "Created" => "2022-01-26T17:25:47.30940821Z",
        "Size"    => 786563,
    };
    my $actual_data = $image->inspect;
    is( ref $actual_data, 'HASH', 'Inspect ok.' );
    is_deeply( $actual_data, $expected_data, 'Inspect response ok.' );

    $ok = $image->remove;
    ok( $ok, 'Image remove ok.' );
};

$service->stop;

done_testing();
