use Test::More tests => 1;
use Test::Exception;
use Test::MockObject;
use Riak::Light;
use Test::TCP;

subtest "should reconnect if PID changes" => sub {
    plan tests => 3;

    my $pid = $$;

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

    my $client = Riak::Light->new(
        pid              => $pid - 1,
        host             => '127.0.0.1',
        port             => $server->port,
        timeout_provider => undef,
    );
    my $old_socket = $client->driver->connector->socket;
    my $old_pid    = $client->pid;

    eval { $client->ping() };

    my $new_socket = $client->driver->connector->socket;
    my $new_pid    = $client->pid;

    isnt $old_socket, $new_socket, 'should not be the same socket';
    isnt $old_pid,    $new_pid,    'pid must be updated';
    is $new_pid,      $pid,        'must actualize pid with current pid';
};
