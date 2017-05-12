#!/usr/bin/env perl

use strict;
use warnings;

use FindBin ();
use lib "$FindBin::Bin/../lib";

use Test::Most tests => 27;

my $class = 'Sub::IsEqual';
use_ok $class, 'is_equal';
#
#sub is_equal { $_[0] ~~ $_[1] }

ok is_equal(undef, undef), 'Undef equals itself';
ok ! is_equal(undef, 'some defined value'), 'Undef does not equals a defined value';
ok ! is_equal('some defined value', undef), 'A defined value does not equal undef';
ok is_equal('some defined value', 'some defined value'), 'A defined value equals itself';
ok ! is_equal('0x0', '0E0'), 'Numerical equivalence is not considered';
ok is_equal((\*STDIN) x 2), 'A defined reference equals itself';
ok ! is_equal([], ''), 'A reference does not equal a non-reference';
ok ! is_equal('', []), 'A non-reference does not equal a reference';
ok ! is_equal([], {}), 'Different types of references are not equal';
ok is_equal(\"mom", \"mom"), 'A scalar reference equals a scalar reference with the same content';
ok ! is_equal(\"mom", \"dad"), 'A scalar reference does not equal a scalar reference with differing content';
ok is_equal([], []), 'An empty list equals an empty list';
ok is_equal([1 .. 3], [1 .. 3]), 'A list equals a list with the same elements';
ok ! is_equal([1 .. 3], [1 .. 4]), 'A list does not equal a list with a different number of elements';
ok ! is_equal([1 .. 3], [1, 2, 4]), 'A list does not equal a list with different values';
ok is_equal({}, {}), 'An empty hash equals an empty hash';
ok is_equal({a => 1, b => 2}, {a => 1, b => 2}), 'A hash equals a hash with the same elements';
ok ! is_equal({a => 1, b => 2}, {a => 1, c => 2}), 'A hash does not equal a hash with different keys';
ok ! is_equal({a => 1, b => 2}, {a => 1, b => 3}), 'A hash does not equal a hash with different values';
ok is_equal([{a => 4, b => 10, c => [qw{mom dad}]}, 1, [4..6]], [{a => 4, b => 10, c => [qw{mom dad}]}, 1, [4..6]]), 'Equality does deep comparisons';

my $arr1 = [undef, 1 .. 5];
my $arr2 = [undef, 1 .. 5];
my $arr3 = [undef, 1 .. 4, 6];

$arr1->[0] = $arr1;
$arr2->[0] = $arr2;
$arr3->[0] = $arr3;
ok is_equal($arr1, $arr2), 'Equivalent self-referencing nested structures are detectable';
ok ! is_equal($arr1, $arr3), 'Differing self-referencing nested structures are detectable';
$arr1->[0] = $arr2;
$arr2->[0] = $arr1;
ok is_equal($arr1, $arr2), 'Equivalent cross-referencing nested structures are detectable';
$arr1->[0] = $arr3;
$arr3->[0] = $arr1;
ok ! is_equal($arr1, $arr2), 'Differing cross-referencing nested structures are detectable';

do {
	my ($circular1, $circular2) = ([], []);
	@$circular1 = (1, 2, $circular1);
	@$circular2 = (1, 2, $circular1);
	ok is_equal($circular1, $circular2), 'Equivalent structures leading to the same circular references are equal';
};

do {
	my ($circular1, $circular2) = ([], []);
	@$circular1 = (1, 2, $circular2);
	@$circular2 = (1, 2, $circular1);
	ok is_equal($circular1, $circular2), 'Equivalent structures leading to equivalent circular references are equal';
};
