use strict;
use warnings;
use Test::More 0.89;
use Test::TCP;

use NanoMsg::Raw;

my $socket_address_inproc = 'inproc://a';
my $socket_address_ipc = 'ipc://test-separation.ipc';
my $socket_address_tcp = 'tcp://127.0.0.1:' . empty_port;

{
    my $pair = nn_socket(AF_SP, NN_PAIR);
    ok defined $pair;
    ok defined nn_bind($pair, $socket_address_inproc);

    my $pull = nn_socket(AF_SP, NN_PULL);
    ok defined $pull;
    ok defined nn_connect($pull, $socket_address_inproc);

    ok nn_setsockopt($pair, NN_SOL_SOCKET, NN_SNDTIMEO, 100);

    is nn_send($pair, 'ABC', 0), undef;
    ok ( nn_errno == EAGAIN or nn_errno == ETIMEDOUT );

    ok nn_close $_ for $pull, $pair;
}

{
    my $pull = nn_socket(AF_SP, NN_PULL);
    ok defined $pull;
    ok defined nn_connect($pull, $socket_address_inproc);

    my $pair = nn_socket(AF_SP, NN_PAIR);
    ok defined $pair;
    ok defined nn_bind($pair, $socket_address_inproc);

    ok nn_setsockopt($pair, NN_SOL_SOCKET, NN_SNDTIMEO, 100);

    is nn_send($pair, 'ABC', 0), undef;
    ok ( nn_errno == EAGAIN or nn_errno == ETIMEDOUT );

    ok nn_close $_ for $pull, $pair;
}

{
    my $pair = nn_socket(AF_SP, NN_PAIR);
    ok defined $pair;
    ok defined nn_bind($pair, $socket_address_ipc);

    my $pull = nn_socket(AF_SP, NN_PULL);
    ok defined $pull;
    ok defined nn_connect($pull, $socket_address_ipc);

    ok nn_setsockopt($pair, NN_SOL_SOCKET, NN_SNDTIMEO, 100);

    is nn_send($pair, 'ABC', 0), undef;
    ok ( nn_errno == EAGAIN or nn_errno == ETIMEDOUT );

    ok nn_close $_ for $pull, $pair;
}

{
    my $pair = nn_socket(AF_SP, NN_PAIR);
    ok defined $pair;
    ok defined nn_bind($pair, $socket_address_tcp);

    my $pull = nn_socket(AF_SP, NN_PULL);
    ok defined $pull;
    ok defined nn_connect($pull, $socket_address_tcp);

    ok nn_setsockopt($pair, NN_SOL_SOCKET, NN_SNDTIMEO, 100);

    is nn_send($pair, 'ABC', 0), undef;
    ok ( nn_errno == EAGAIN or nn_errno == ETIMEDOUT );

    ok nn_close $_ for $pull, $pair;
}

done_testing;
