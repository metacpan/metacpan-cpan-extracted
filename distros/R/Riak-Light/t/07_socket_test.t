use Test::More tests => 2;
use Test::Exception;
use Test::MockObject;
use Test::MockModule;
use Riak::Light;
use Test::TCP;


subtest "should not die if can connect" => sub {
    plan tests => 1;

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

    lives_ok {
        Riak::Light->new(
            host => '127.0.0.1',
            port => $server->port
        );
    };
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
