# -*- perl -*-

use strict;
use warnings FATAL => 'all';

# t/002_check.t - check for the device /dev/urandom

use Test::More;

ok( -c '/dev/urandom', 'The device /dev/urandom does not exist' );

done_testing();
