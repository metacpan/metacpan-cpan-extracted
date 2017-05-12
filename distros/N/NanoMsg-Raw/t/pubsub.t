use strict;
use warnings;
use Test::More 0.89;

use NanoMsg::Raw;

my $socket_address = 'inproc://a';

my $pub = nn_socket(AF_SP, NN_PUB);
ok defined $pub;
ok defined nn_bind($pub, $socket_address);

my $sub1 = nn_socket(AF_SP, NN_SUB);
ok defined $sub1;
ok nn_setsockopt($sub1, NN_SUB, NN_SUB_SUBSCRIBE, '');
ok defined nn_connect($sub1, $socket_address);

my $sub2 = nn_socket(AF_SP, NN_SUB);
ok defined $sub2;
ok nn_setsockopt($sub2, NN_SUB, NN_SUB_SUBSCRIBE, '');
ok defined nn_connect($sub2, $socket_address);

# Wait till connections are established to prevent message loss.
sleep 1;

is nn_send($pub, join('' => 0 .. 9) x 4, 0), 40;

is nn_recv($sub1, my $buf, 3, 0), 40;
is nn_recv($sub2, $buf, 3, 0), 40;

ok nn_close $_ for $pub, $sub1, $sub2;

done_testing;
