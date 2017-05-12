use strict;
use warnings;
use Test::More 0.89;
use Test::TCP;

use NanoMsg::Raw;

# This test checks whether blocking on send/recv works as expected.

test_tcp(
    server => sub {
        my ($port) = @_;

        my $sb = nn_socket(AF_SP, NN_PAIR);
        cmp_ok $sb, '>=', 0, 'new socket';
        cmp_ok nn_bind($sb, "tcp://127.0.0.1:$port"), '>=', 0, 'bind';

        is nn_recv($sb, my $buf, 3, 0), 3, 'recv 1';
        is $buf, 'ABC', 'right buffer contents';

        is nn_recv($sb, $buf, 3, 0), 3, 'recv 2';
        is $buf, 'ABC', 'right buffer contents';

        ok nn_close($sb), 'close';
    },
    client => sub {
        my ($port) = @_;

        my $sc = nn_socket(AF_SP, NN_PAIR);
        cmp_ok $sc, '>=', 0, 'new socket in worker';
        cmp_ok nn_connect($sc, "tcp://127.0.0.1:$port"), '>=', 0, 'worker connect';

        # Wait for the main process to block.
        sleep 1;

        is nn_send($sc, 'ABC', 0), 3, 'worker send 1';

        # Wait for the main thread to process the previous message and block
        # once again.
        sleep 1;

        is nn_send($sc, 'ABC', 0), 3, 'worker send 2';

        ok nn_close($sc), 'close';
    },
);

done_testing;
