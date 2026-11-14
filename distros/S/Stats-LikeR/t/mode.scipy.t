#!/usr/bin/env perl
# mode() against SciPy's own tests for scipy.stats.mode, and across the growth
# of the count array that 0.3421 introduced.
#
# PROVENANCE
#
# The first block ports the one-dimensional cases of class TestMode in SciPy
# 1.18.1, scipy/stats/tests/test_stats.py, each named by its test method. The
# expected modes and counts are the literals that file asserts; nothing was
# run to get them.
#
#   test_basic               [3, 5, 1, 10, 23, 3, 2, 6, 8, 6, 10, 6] -> 6
#   test_scalar              4. -> 4
#   test_axes                the 5 x 4 array, flattened (axis=None) -> 30; its
#                            rows (axis=1) -> 10, 10, 20, 30, 30; its columns
#                            (axis=0) -> 10, 10, 30, 30
#   test_smallest_equal      [3, 5, 1, 1, 3.] and [3, 5, 1.] -> 1
#
# WHERE THIS MODULE IS NOT SCIPY
#
# scipy.stats.mode returns one value, the smallest of those tied for most
# common, and its count. This module's mode() returns every tied value, in the
# order each was first seen, and no count (README, "mode"). So where SciPy's
# case has a tie -- both test_smallest_equal arrays -- the assertion here is
# the full list this module documents, and separately that SciPy's answer is
# the smallest member of it. SciPy's NaN
# cases (test_nan_propagate, test_nan_omit) and its empty-input case are not
# ported: this module has no nan_policy, counts a NaN as the string it prints
# as, and croaks on no data, which t/01.t and t/croak.messages.t cover.
#
# THE GROWTH CASES
#
# The second block has no reference to copy, because it tests an allocation
# and not a statistic: mode() keeps its counts in a size_t array that starts
# with room for 64 distinct values and doubles (mode_take() in LikeR.xs).
# The inputs are built so the answer follows from the construction -- value k
# is repeated a stated number of times -- at distinct-value counts on both
# sides of the first few doublings (64, 65, 128, 129, 1024, 1025) and at
# 100000, with the winner placed first, last and at a slot past each boundary.
# No tolerance anywhere: every comparison is of whole values.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::LeakTrace 'no_leaks_ok';
use List::Util qw(min);
use Stats::LikeR qw(mode);

# ---- SciPy TestMode -------------------------------------------------------
{
	my @data1 = (3, 5, 1, 10, 23, 3, 2, 6, 8, 6, 10, 6);
	is_deeply([ mode(@data1) ],  [6], 'test_basic: mode is 6 (list)');
	is_deeply([ mode(\@data1) ], [6], 'test_basic: mode is 6 (array reference)');
	is_deeply([ mode(4.) ],      [4], 'test_scalar: mode of 4. is 4');

	my @arr = ([10, 10, 30, 40], [10, 10, 10, 10], [20, 10, 20, 20],
	           [30, 30, 30, 30], [40, 30, 30, 30]);
	is_deeply([ mode(map { @$_ } @arr) ], [30], 'test_axes, axis=None: 30 (it occurs 8 times)');
	is_deeply([ mode(@arr) ], [30], 'test_axes, axis=None, as five array references');
	my @row_want = (10, 10, 20, 30, 30);
	for my $i (0 .. $#arr) {
		is_deeply([ mode($arr[$i]) ], [ $row_want[$i] ], "test_axes, axis=1, row $i: $row_want[$i]");
	}
	# No column has a tie (SciPy's counts for them are 2, 3, 3, 2), so each is
	# a single value here as well.
	my @col_want = (10, 10, 30, 30);
	for my $j (0 .. 3) {
		is_deeply([ mode(map { $_->[$j] } @arr) ], [ $col_want[$j] ], "test_axes, axis=0, column $j: $col_want[$j]");
	}

	# test_smallest_equal: SciPy's 1 is the smallest of the tied values, which
	# this module returns all of, in first-seen order.
	my @tie5 = mode(3, 5, 1, 1, 3.);
	is_deeply(\@tie5, [3, 1], 'test_smallest_equal [3, 5, 1, 1, 3.]: 3 and 1 tie, 3 seen first');
	is(min(@tie5), 1, '... and the smallest is SciPy\'s 1');
	my @tie3 = mode(3, 5, 1.);
	is_deeply(\@tie3, [3, 5, 1], 'test_smallest_equal [3, 5, 1.]: all three tie');
	is(min(@tie3), 1, '... and the smallest is SciPy\'s 1');
}

# ---- the count array, across its doublings --------------------------------
for my $n (1, 2, 63, 64, 65, 127, 128, 129, 1024, 1025, 100_000) {
	# n distinct values, each once: every one is a mode, in first-seen order
	my @once = map { "v$_" } 1 .. $n;
	is_deeply([ mode(\@once) ], \@once, "$n distinct strings, once each: all $n come back in order");

	# one winner, at the first slot, the last, and (where there is one) the
	# slot that opens the second half of the array
	my %seen;
	for my $win (grep { $_ <= $n && !$seen{$_}++ } 1, $n, int($n / 2) + 1) {
		my @x = (1 .. $n, $win);
		is_deeply([ mode(\@x) ], [$win], "$n distinct integers with $win repeated: $win");
	}

	# the count of an early slot must survive the array moving: value 1 is
	# counted three times before the other slots open and once after
	my @x = (1, 1, 1, 2 .. $n, 1);
	is_deeply([ mode(@x) ], [1], "$n distinct integers, 1 counted before and after the growth");
}

# Two winners either side of the first doubling: 3 is in slot 2 and 70 in slot
# 69, past the first 64. The repeat of 70 comes before the repeat of 3, and the
# answer is still in the order the values were first seen.
is_deeply([ mode(1 .. 200, 70, 3) ], [3, 70], 'ties across the first doubling come back in first-seen order');

# Mixed arguments fill one count array: slots opened by a list argument are
# still counted when an array reference repeats them.
is_deeply([ mode(1 .. 100, [ 50, 50 ], 50) ], [50], 'list and array-reference arguments share the counts');

# ---- nothing is left behind -----------------------------------------------
SKIP: {
	skip 'leak checks are meaningless under Devel::Cover', 3 if $INC{'Devel/Cover.pm'};
	my @many = (1 .. 1000, 7);
	no_leaks_ok { my @m = mode(\@many) } 'mode: no leaks after the count array has grown';
	no_leaks_ok { my @m = mode(@many) } 'mode: no leaks with 1001 list arguments';
	# a croak after four doublings: the count array is a mortal's buffer and
	# has to go with it
	my @bad = (1 .. 1000, undef);
	no_leaks_ok { eval { mode(\@bad) } } 'mode: no leaks when it croaks after the count array has grown';
}

done_testing();
