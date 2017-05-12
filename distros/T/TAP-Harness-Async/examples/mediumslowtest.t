use strict;
use warnings;
use Time::HiRes qw(sleep);

use Test::More tests => 2000;

for (0..1000) {
	pass("This is good");
	sleep 0.173 * rand;
	fail("This is not");
}
done_testing();
