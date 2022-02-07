## no critic
use Test::More;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/lib";

use File::Temp ();

use Mock::Podman::Service;

use Podman::Client;

my $Service = Mock::Podman::Service->new();

subtest 'Throw error on connection failure.' => sub {
    my $ConnectionURI = 'http+unix://no/such/path/sock';
    throws_ok( sub { Podman::Client->new( ConnectionURI => $ConnectionURI ); },
        'Podman::Exception', 'ConnectionURI failure unix socket ok.' );

    $ConnectionURI = 'http://127.0.0.1:1';
    throws_ok( sub { Podman::Client->new( ConnectionURI => $ConnectionURI ); },
        'Podman::Exception', 'ConnectionURI failure tcp port ok.' );

    $ConnectionURI = 'https://127.0.0.1:1';
    throws_ok( sub { Podman::Client->new( ConnectionURI => $ConnectionURI ); },
        'Podman::Exception', 'ConnectionURI failure secure tcp port ok.' );
};

subtest 'Connect via http+unix socket.' => sub {
    my $ConnectionURI =
      'http+unix://' . File::Temp::tempdir( CLEANUP => 1 ) . '/podman.sock';

    $Service->Listen($ConnectionURI)->Start();
    my $Client = Podman::Client->new( ConnectionURI => $ConnectionURI );
    ok( $Client, 'ConnectionURI unix socket ok.' );
    is( $Client->BaseURI, 'http://d/v3.0.1/libpod/',
        'Request URL unix socket ok.' );
    $Service->Stop();
};

subtest 'Connect via http.' => sub {
    my $ConnectionURI = 'http://127.0.0.1:1234';

    $Service->Listen($ConnectionURI)->Start();
    my $Client = Podman::Client->new( ConnectionURI => $ConnectionURI );
    ok( $Client, 'ConnectionURI tcp port ok.' );
    is(
        $Client->BaseURI,
        $ConnectionURI . '/v3.0.1/libpod/',
        'Request URL tcp port ok.'
    );
    $Service->Stop();
};

subtest 'Connect via https.' => sub {
    my $ConnectionURI = 'https://127.0.0.1:1234';

    $Service->Listen($ConnectionURI)->Start();
    my $Client = Podman::Client->new( ConnectionURI => $ConnectionURI );
    ok( $Client, 'ConnectionURI secure tcp port ok.' );
    is(
        $Client->BaseURI,
        $ConnectionURI . '/v3.0.1/libpod/',
        'Request URL secure tcp port ok.'
    );
    $Service->Stop();
};

done_testing();
