use strict;
use warnings;
use Test::More 0.89;

use NanoMsg::Raw;

# Tests inproc transport.

my $socket_address = 'inproc://test';

{
    my $sc = nn_socket AF_SP, NN_PAIR;
    ok defined $sc;
    ok defined nn_connect $sc, $socket_address;

    my $sb = nn_socket AF_SP, NN_PAIR;
    ok defined $sb;
    ok defined nn_bind $sb, $socket_address;

    # Try a duplicate bind. It should fail.
    ok !defined nn_bind $sc, $socket_address;
    ok nn_errno == EADDRINUSE;

    # Ping-pong test.
    for (1 .. 100) {
        is nn_send($sc, 'ABC', 0), 3;
        is nn_recv($sb, my $buf, 256, 0), 3;
        is nn_send($sb, 'DEFG', 0), 4;
        is nn_recv($sc, $buf, 256, 0), 4;
    }

    # Batch transfer test.
    is nn_send($sc, 'XYZ', 0), 3 for 1 .. 100;
    is nn_recv($sb, my $buf, 256, 0), 3 for 1 .. 100;

    ok nn_close $_ for $sc, $sb;
}

{
    # Test whether queue limits are observed.
    my $sb = nn_socket AF_SP, NN_PAIR;
    ok defined $sb;
    ok nn_setsockopt $sb, NN_SOL_SOCKET, NN_RCVBUF, 200;
    ok defined nn_bind $sb, $socket_address;

    my $sc = nn_socket AF_SP, NN_PAIR;
    ok defined $sc;
    ok defined nn_connect $sc, $socket_address;
    ok nn_setsockopt $sc, NN_SOL_SOCKET, NN_SNDTIMEO, 200;

    my $i = 0;
    while (1) {
        my $ret = nn_send $sc, '0123456789', 0;
        if (!defined $ret) {
            ok ( nn_errno == EAGAIN or nn_errno == ETIMEDOUT );
            last;
        }
        is $ret, 10;
        $i++;
    }
    is $i, 20;

    is nn_recv($sb, my $buf, 256, 0), 10;
    is nn_send($sc, '0123456789', 0), 10;
    ok !defined nn_send($sc, '0123456789', 0);
    ok ( nn_errno == EAGAIN or nn_errno == ETIMEDOUT );

    is nn_recv($sb, $buf, 256, 0), 10 for 1 .. 20;

    # Make sure that even a message that doesn't fit into the buffers gets
    # across.
    is nn_send($sc, 'A' x 256, 0), 256;
    is nn_recv($sb, $buf, 256, 0), 256;

    ok nn_close $_ for $sc, $sb;
}

done_testing;
