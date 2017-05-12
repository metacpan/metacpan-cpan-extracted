use Test::More tests => 3;
use Test::Exception;
use Test::MockObject;
use Test::MockModule;
use Riak::Light;
use Test::TCP;

use Socket qw(TCP_NODELAY IPPROTO_TCP);

subtest "should not die if can connect" => sub {
    plan tests => 3;

    my $server = Test::TCP->new(
        code => sub {
            my $port   = shift;
            my $socket = IO::Socket::INET->new(
                Listen    => 5,
                Timeout   => 1,
                Reuse     => 1,
                LocalPort => $port
            ) or die "ops $!";

            while (1) {
                $socket->accept()->close();
            }
        },
    );

    my $client;
    lives_ok {
        $client = Riak::Light->new(
            host             => '127.0.0.1',
            port             => $server->port,
            timeout_provider => undef,
        );
    };

    is $client->tcp_nodelay, 1, 'default, should be enable';
    ok $client->driver->connector->socket->getsockopt( IPPROTO_TCP,
        TCP_NODELAY ), "should set TCP_NODELAY to 1";
};

subtest "should not die if can connect wihout TCP_NODELAY" => sub {
    plan tests => 2;

    my $server = Test::TCP->new(
        code => sub {
            my $port   = shift;
            my $socket = IO::Socket::INET->new(
                Listen    => 5,
                Timeout   => 1,
                Reuse     => 1,
                LocalPort => $port
            ) or die "ops $!";

            while (1) {
                $socket->accept()->close();
            }
        },
    );

    my $client;
    lives_ok {
        $client = Riak::Light->new(
            host             => '127.0.0.1',
            port             => $server->port,
            timeout_provider => undef,
            tcp_nodelay      => 0,
        );
    };

    is $client->driver->connector->socket->getsockopt( IPPROTO_TCP,
        TCP_NODELAY ), 0, "should NOT set TCP_NODELAY to 1";
};

subtest "should die if cant connect" => sub {
    plan tests => 1;

    my $mockmodule = Test::MockModule->new('IO::Socket::INET');
    $mockmodule->mock( new => sub {undef} );

    throws_ok {
        Riak::Light->new(
            host => 'do.not.exist',
            port => 9999
        );
    }
    qr/Error \(.*\), can't connect to do.not.exist:9999/;
};
