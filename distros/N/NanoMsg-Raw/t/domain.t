use strict;
use warnings;
use Test::More 0.89;

use NanoMsg::Raw;

my $s = nn_socket AF_SP, NN_PAIR;

is unpack('I', nn_getsockopt($s, NN_SOL_SOCKET, NN_DOMAIN)), AF_SP;
is unpack('I', nn_getsockopt($s, NN_SOL_SOCKET, NN_PROTOCOL)), NN_PAIR;

done_testing;
