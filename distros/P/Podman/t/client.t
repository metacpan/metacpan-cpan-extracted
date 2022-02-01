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
    my $Connection = 'http+unix://no/such/path/sock';
    throws_ok( sub { Podman::Client->new( Connection => $Connection ); },
        'Podman::Exception', 'Connection failure unix socket ok.' );

    $Connection = 'http://127.0.0.1:1';
    throws_ok( sub { Podman::Client->new( Connection => $Connection ); },
        'Podman::Exception', 'Connection failure tcp port ok.' );

    $Connection = 'https://127.0.0.1:1';
    throws_ok( sub { Podman::Client->new( Connection => $Connection ); },
        'Podman::Exception', 'Connection failure secure tcp port ok.' );
};

subtest 'Connect via http+unix socket.' => sub {
    my $Connection =
      'http+unix://' . File::Temp::tempdir( CLEANUP => 1 ) . '/podman.sock';

    $Service->Listen($Connection)->Start();
    my $Client = Podman::Client->new( Connection => $Connection );
    ok( $Client, 'Connection unix socket ok.' );
    is( $Client->RequestBase, 'http://d/v3.0.1/libpod/',
        'Request URL unix socket ok.' );
    $Service->Stop();
};

subtest 'Connect via http.' => sub {
    my $Connection = 'http://127.0.0.1:1234';

    $Service->Listen($Connection)->Start();
    my $Client = Podman::Client->new( Connection => $Connection );
    ok( $Client, 'Connection tcp port ok.' );
    is(
        $Client->RequestBase,
        $Connection . '/v3.0.1/libpod/',
        'Request URL tcp port ok.'
    );
    $Service->Stop();
};

subtest 'Connect via https.' => sub {
    my $Connection = 'https://127.0.0.1:1234';

    $Service->Listen($Connection)->Start();
    my $Client = Podman::Client->new( Connection => $Connection );
    ok( $Client, 'Connection secure tcp port ok.' );
    is(
        $Client->RequestBase,
        $Connection . '/v3.0.1/libpod/',
        'Request URL secure tcp port ok.'
    );
    $Service->Stop();
};

done_testing();
