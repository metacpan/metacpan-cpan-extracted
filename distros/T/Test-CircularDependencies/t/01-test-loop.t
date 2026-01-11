use strict;
use warnings;

use Test::More tests => 3;
use Test::CircularDependencies qw(test_loops);

ok 1;

TODO: {
	local $TODO = 'This should really fail';
	test_loops( ['t/circular_dependency/my_exe.pl'], ['t/circular_dependency'], 'loop' );
}

TODO: {
	local $TODO = 'This should really fail';
	test_loops( ['t/deep/my_exe.pl'], [ 't/deep', 't/deep/My' ], 'deep' );
}

