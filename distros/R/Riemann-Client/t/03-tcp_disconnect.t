use strict;
use warnings;

use Test::TCP;
use Test::More;
use Test::Exception;

BEGIN { use_ok 'Riemann::Client'; }

# Declared here so it can be cleaned up in END
my $server;
my $port = 5555;

SKIP: {
    skip '$ENV{RIEMANN_COMMAND} not defined', 3
        unless defined $ENV{RIEMANN_COMMAND};

    $server = Test::TCP->new(
        code => sub {
            exec $ENV{RIEMANN_COMMAND};
            die "Couldn't execute $ENV{RIEMANN_COMMAND}: $!";
        },
        port => $port,
    );

    # Wait for the server to be available
    wait_port($port);

    # Send some stuff to it
    my $r   = Riemann::Client->new;
    my $msg = { metric => rand(10), state => 'ok' };
    lives_ok { $r->send($msg) } "Message sent";

    # Stop it to reuse the client and check for exception
    $server->stop;
    my $msg2 = { metric => rand(10), state => 'ok' };
    throws_ok { $r->send($msg2) } qr/Did not receive a response/,
        "Send to stopped server dies";

    # Restart to reuse the client and see it reconnect
    $server->start;
    wait_port($port);
    my $msg3 = { metric => rand(10), state => 'ok' };
    lives_ok { $r->send($msg3) } "Send to restarted server lives";

    undef $server;
}

done_testing();

