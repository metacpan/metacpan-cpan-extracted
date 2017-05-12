use strict;
use warnings;
use Test::More 0.89;

use NanoMsg::Raw;

my $socket_address = 'inproc://a';

# Test fan-out.
{
    my $push1 = nn_socket(AF_SP, NN_PUSH);
    ok defined $push1;
    ok defined nn_bind($push1, $socket_address);

    my $pull1 = nn_socket(AF_SP, NN_PULL);
    ok defined $pull1;
    ok defined nn_connect($pull1, $socket_address);

    my $pull2 = nn_socket(AF_SP, NN_PULL);
    ok defined $pull2;
    ok defined nn_connect($pull2, $socket_address);

    # Wait till both connections are established to get messages spread evenly
    # between the two pull sockets.
    sleep 1;

    is nn_send($push1, 'ABC', 0), 3;
    is nn_send($push1, 'DEF', 0), 3;

    is nn_recv($pull1, my $buf, 3, 0), 3;
    is nn_recv($pull2, $buf, 3, 0), 3;

    ok nn_close $_ for $push1, $pull1, $pull2;
}

# Test fan-in.
{
    my $pull1 = nn_socket(AF_SP, NN_PULL);
    ok defined $pull1;
    ok defined nn_bind($pull1, $socket_address);

    my $push1 = nn_socket(AF_SP, NN_PUSH);
    ok defined $push1;
    ok defined nn_connect($push1, $socket_address);

    my $push2 = nn_socket(AF_SP, NN_PUSH);
    ok defined $push2;
    ok defined nn_connect($push2, $socket_address);

    is nn_send($push1, 'ABC', 0), 3;
    is nn_send($push2, 'DEF', 0), 3;

    is nn_recv($pull1, my $buf, 3, 0), 3;
    is nn_recv($pull1, $buf, 3, 0), 3;

    ok nn_close $_ for $pull1, $push1, $push2;
}

done_testing;
