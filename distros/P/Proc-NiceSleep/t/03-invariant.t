# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';
	
use Test;
BEGIN { plan tests => 1 };	# not needed by Test::Simple, only by Test

use Proc::NiceSleep qw( maybe_sleep );	# Invariant is 'private'

ok(1, Proc::NiceSleep::Invariant()); # does it return 1?


