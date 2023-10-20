# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Socket-More-Constants.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Socket::More::Constants') };

use Socket::More::Constants;

my $res= AF_INET + SOCK_STREAM + SOCK_DGRAM;
ok $res, "Used some constants";

done_testing;

