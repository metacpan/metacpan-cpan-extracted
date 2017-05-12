use strict;
use warnings;
use Test::More 0.89;

use NanoMsg::Raw;

# Test IPC transport.

my $socket_address = 'ipc://test.ipc';

{
    # Try closing a IPC socket while it not connected.
    my $sc = nn_socket AF_SP, NN_PAIR;
    ok defined $sc;
    ok defined nn_connect $sc, $socket_address;
    ok nn_close $sc;
}

{
    my $sc = nn_socket AF_SP, NN_PAIR;
    ok defined $sc;
    ok defined nn_connect $sc, $socket_address;

    # Leave enough time for at least on re-connect attempt.
    sleep 1;

    my $sb = nn_socket AF_SP, NN_PAIR;
    ok defined $sb;
    ok defined nn_bind $sb, $socket_address;

    # Ping-pong test.
    for (0 .. 1) {
        my $p = join('' => 0 .. 9) x 4;

        is nn_send($sc, $p, 0), 40;
        is nn_recv($sb, my $buf, 3, 0), 40;
        is $buf, '012';

        is nn_send($sb, $p, 0), 40;
        is nn_recv($sc, $buf, 3, 0), 40;
    }

    # Batch transfer test.
    is nn_send($sc, 'XYZ', 0), 3 for 1 .. 100;
    is nn_recv($sb, my $buf, 3, 0), 3 for 1 .. 100;

    ok nn_close $_ for $sc, $sb;
}

done_testing;
