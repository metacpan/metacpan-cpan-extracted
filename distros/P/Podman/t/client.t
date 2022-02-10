## no critic
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";

use English qw( -no_match_vars );
use File::Temp ();
use Mojo::URL;
use Mock::Podman::Service;

use Podman::Client;

subtest 'Throw error on connection failure.' => sub {
    my $client = Podman::Client->new;

    eval { $client->connection_url('http+unix:///no/such/path/sock')->get('info'); };
    is( ref $EVAL_ERROR, 'Podman::Exception', 'Connection URL failure unix domain socket ok.' );

    eval { $client->connection_url('http://127.0.0.1:1')->get('info'); };
    is( ref $EVAL_ERROR, 'Podman::Exception', 'Connection URL failure tcp port ok.' );

    eval { $client->connection_url('https://127.0.0.1:1')->get('info'); };
    is( ref $EVAL_ERROR, 'Podman::Exception', 'Connection URL failure secure tcp port ok.' );
};

subtest 'Connect via http+unix socket.' => sub {
    local $ENV{PODMAN_CONNECTION_URL} = 'http+unix://' . File::Temp::tempdir( CLEANUP => 1 ) . '/podman.sock';

    my $service = Mock::Podman::Service->new->start;
    my $res = Podman::Client->new()->get('info');
    ok( $res, 'Connection URL unix socket ok.' );
    $service->stop;
};

subtest 'Connect via http.' => sub {
    local $ENV{PODMAN_CONNECTION_URL} = 'http://127.0.0.1:1234';

    my $service = Mock::Podman::Service->new->start;
    my $res = Podman::Client->new()->get('info');
    ok( $res, 'Connection URL tcp port ok.' );
    $service->stop;
};

subtest 'Connect via https.' => sub {
    local $ENV{PODMAN_CONNECTION_URL} = 'https://127.0.0.1:1234';

    my $service = Mock::Podman::Service->new->start;
    my $res = Podman::Client->new()->get('info');
    ok( $res, 'Connection URL secure tcp port ok.' );
    $service->stop;
};

done_testing();
