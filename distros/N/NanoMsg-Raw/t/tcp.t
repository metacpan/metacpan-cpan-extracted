use strict;
use warnings;
use Test::More 0.89;
use Test::TCP;

use NanoMsg::Raw;

my $host = '127.0.0.1';
my $port = empty_port;
my $socket_address = "tcp://$host:$port";

{
    my $sb = nn_socket(AF_SP, NN_PAIR);
    ok defined $sb;
    ok defined nn_bind($sb, $socket_address);
    ok nn_close($sb);
}

{
    my $sb = nn_socket(AF_SP, NN_PAIR);
    ok defined $sb;
    ok defined nn_connect($sb, "tcp://$host;$host:$port");
    ok nn_close($sb);
}

{
    my $sc = nn_socket(AF_SP, NN_PAIR);
    ok defined $sc;

    is unpack('I', nn_getsockopt($sc, NN_TCP, NN_TCP_NODELAY)), 0;

    ok !nn_setsockopt($sc, NN_TCP, NN_TCP_NODELAY, 2);
    ok nn_errno == EINVAL;

    ok nn_setsockopt($sc, NN_TCP, NN_TCP_NODELAY, 1);
    is unpack('I', nn_getsockopt($sc, NN_TCP, NN_TCP_NODELAY)), 1;

    my %invalid_connect_addresses = (
        'tcp://*:'                      => EINVAL,
        'tcp://*:1000000'               => EINVAL,
        'tcp://*:some_port'             => EINVAL,
        'tcp://eth10000;127.0.0.1:5555' => ENODEV,
        'tcp://127.0.0.1'               => EINVAL,
    );

    my %invalid_bind_addresses = (
        'tcp://127.0.0.1:'              => EINVAL,
        'tcp://127.0.0.1:1000000'       => EINVAL,
        'tcp://eth10000:5555'           => ENODEV,
    );

    for my $t ([\&nn_connect, \%invalid_connect_addresses],
               [\&nn_bind,    \%invalid_bind_addresses]) {
        for my $addr (keys %{ $t->[1] }) {
            is $t->[0]->($sc, $addr), undef;
            ok nn_errno == $t->[1]->{$addr};
        }
    }

    ok defined nn_connect($sc, $socket_address);

    sleep 1;

    my $sb = nn_socket(AF_SP, NN_PAIR);
    ok defined $sb;
    ok defined nn_bind($sb, $socket_address);

    for (1 .. 100) {
        is nn_send($sc, 'ABC', 0), 3;
        is nn_recv($sb, my $buf, 3, 0), 3;
        is nn_send($sb, 'DEF', 0), 3;
        is nn_recv($sc, $buf, 3, 0), 3;
    }

    is nn_send($sc, join('' => 0 .. 9) x 4, 0), 40 for 0 ..99;
    is nn_recv($sb, my $buf, 3, 0), 40 for 0 .. 99;

    ok nn_close $_ for $sc, $sb;
}

done_testing;
