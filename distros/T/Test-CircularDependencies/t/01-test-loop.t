use strict;
use warnings;

use Test::More tests => 2;
use Test::CircularDependencies qw(test_loops);

ok 1;

TODO: {
	local $TODO = 'This should really fail';
	test_loops(['t/circular_dependency/my_exe.pl'], ['t/circular_dependency'], 'circle');
}

