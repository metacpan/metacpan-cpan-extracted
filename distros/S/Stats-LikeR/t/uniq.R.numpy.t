#!/usr/bin/env perl
# uniq(), against R's, NumPy's and pandas' own unique() cases.
#
# Provenance:
#   R      R 4.6.1 src/library/base/man/unique.Rd, \examples: x <- c(3:5,
#          11:8, 8 + 0:5), unique(x) is 3 4 5 11 10 9 8 12 13;
#          tests/reg-tests-1b.R, "as.character(<numeric>)": nx <- 0.3 + 2e-16
#          * -2:2 and unique(as.character(nx)) is "0.3".
#   NumPy  2.4.6, numpy/lib/tests/test_arraysetops.py, test_unique_1d: a =
#          [5, 7, 1, 2, 1, 5, 7] * 10 has unique values {1, 2, 5, 7} (NumPy
#          sorts them; uniq() keeps first-seen order, 5 7 1 2, as pandas
#          does); and ticket #4785, unique([(1, 2), (1, 2), (2, 3)]) is
#          [1, 2, 3].
#   pandas 3.0.4, pandas/tests/test_algos.py TestUnique: test_signed_zero
#          (GH 21866, -0.0 and 0.0 are one value), test_different_nans (GH
#          21866, NaNs with different bit patterns are one value),
#          test_nan_in_object_array; pandas/tests/series/methods/test_unique.py:
#          test_unique (GH 714, [1.2345, NaN] x 50 has 2 values),
#          test_unique_uint64.
#   t/uniq.R.numpy.R and t/uniq.R.numpy.py (committed beside this file)
#   printed every expected value; re-run them with
#       Rscript t/uniq.R.numpy.R
#       /home/con/.pyenv/versions/3.14.2/bin/python3 -I t/uniq.R.numpy.py
#   This test never runs R or Python.
#
# Deliberate differences, kept so that changing one is a decision:
#   - uniq() compares by stringification (README), so R's
#     length(unique(nx)) of 5 for nx = 0.3 + 2e-16 * -2:2 is 1 here: all five
#     doubles print 0.3 at 15 digits.  R's own unique(as.character(nx)) is "0.3",
#     which is the case that does match.
#   - pandas and R treat NaN and NA as values; uniq() croaks on undef (README),
#     so pandas' test_unique_none and R's NA cases are croak tests.
#   - The string 'nan' and a computed NaN (which prints as "NaN") are two
#     values under eq, where pandas would call them one.
#   - -0.0 prints as 0 on this perl, so test_signed_zero holds trivially here.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Config;
use Stats::LikeR qw(:all);
use Test::Exception; # throws_ok / lives_and
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

#--------
# R, unique.Rd and reg-tests-1b.R
#--------
{
	my @x = (3 .. 5, reverse(8 .. 11), 8 .. 13);
	is_deeply([ uniq(@x) ], [3, 4, 5, 11, 10, 9, 8, 12, 13], 'R unique.Rd: unique(c(3:5, 11:8, 8 + 0:5))');
	is(scalar(uniq(@x)), 9, 'R unique.Rd: the count in scalar context');
	my @nx = map { 0.3 + 2e-16 * $_ } -2 .. 2;
	# uniq() keeps what this perl prints differently. A double NV prints all five
	# as 0.3, as R's as.character() does; a long-double or __float128 NV prints
	# enough digits to keep some apart, so the expectation is built from this
	# perl's own stringification, and R's "0.3" is checked on a double NV only.
	my @str = map { "$_" } @nx;
	my @exp_str = do { my %s; grep { !$s{$_}++ } @str };
	is_deeply([ uniq(@str) ], \@exp_str, 'R reg-tests-1b: unique(as.character(0.3 + 2e-16 * -2:2)), as this perl prints them');
	is(scalar(uniq(@nx)), scalar(@exp_str), 'R reg-tests-1b: the five numbers are as many values as they print (R: 5; see header)');
	SKIP: {
		skip 'an NV wider than a double prints the five apart', 1 unless $Config{nvsize} == 8;
		is_deeply(\@exp_str, ['0.3'], 'R reg-tests-1b: on a double NV they print as "0.3", as in R');
	}
	is_deeply([ uniq('a', 'A', 'a') ], ['a', 'A'], 'R: unique(c("a", "A", "a")) is case sensitive');
	# as this perl prints an infinity: -Inf and Inf, but -inf and inf before 5.22
	is_deeply([ uniq(-9**9**9, 9**9**9, 9**9**9) ], [ "" . -9**9**9, "" . 9**9**9 ], 'R: unique(c(-Inf, Inf, Inf))');
	is_deeply([ uniq([]) ], [], 'R: unique(character(0)) is empty');
	is(scalar(uniq([])), 0, 'R: length(unique(character(0))) is 0');
}

#--------
# NumPy, test_unique_1d and ticket 4785
#--------
{
	my @a = (5, 7, 1, 2, 1, 5, 7) x 10;
	is_deeply([ uniq(@a) ], [5, 7, 1, 2], 'NumPy test_unique_1d: first-seen order (pandas.unique)');
	is_deeply([ sort { $a <=> $b } uniq(\@a) ], [1, 2, 5, 7], 'NumPy test_unique_1d: sorted, as numpy.unique');
	is(scalar(uniq(\@a)), 4, 'NumPy test_unique_1d: four distinct values');
	is_deeply([ uniq([1, 2], [1, 2], [2, 3]) ], [1, 2, 3], 'NumPy ticket 4785: tuples flattened one level');
}

#--------
# pandas
#--------
{
	# One value where this perl prints -0.0 as 0, as pandas has it; a perl that
	# prints it as -0 (5.10.1 and 5.12.5 here) keeps two, since uniq() compares the
	# printed form (README).
	{
		my @z = (-0.0, 0.0);
		my @exp_z = do { my %s; grep { !$s{$_}++ } map { "$_" } @z };
		is_deeply([ uniq(@z) ], \@exp_z, 'pandas test_signed_zero: -0.0 and 0.0, compared as this perl prints them');
		is_deeply(\@exp_z, [0], 'pandas test_signed_zero: one value, where -0.0 prints as 0') if "" . -0.0 eq '0';
	}
	my $n1 = unpack('d>', pack('H*', '7ff8000000000000'));
	my $n2 = unpack('d>', pack('H*', '7ff8000000000001'));
	ok($n1 != $n1 && $n2 != $n2, 'the two NaNs are NaNs');
	is(scalar(uniq($n1, $n2)), 1, 'pandas test_different_nans: NaNs of different payload are one value');
	is(scalar(uniq(('NaN', 1.2345) x 50)), 2, 'pandas test_unique: [1.2345, NaN] x 50 has 2 values');
	is_deeply([ uniq('a', 'NaN', 'c', 'c') ], ['a', 'NaN', 'c'], 'pandas test_nan_in_object_array: first-seen order');
	is_deeply([ uniq('NaN', 'nan') ], ['NaN', 'nan'], 'the string nan differs from NaN under eq (see header)');
	SKIP: {
		skip 'IV is not 64 bits wide', 1 if $Config{ivsize} < 8;
		is_deeply([ uniq(1, 2, 9223372036854775808, 9223372036854775808) ],
			[1, 2, '9223372036854775808'], 'pandas test_unique_uint64: 2**63 twice');
	}
	throws_ok { uniq(1, 2, 3, undef, undef, undef) } qr/undefined value at argument index 3/,
		'pandas test_unique_none: undef croaks (see header)';
	throws_ok { uniq(['a', undef]) } qr/undefined value at array ref index 1 \(argument 0\)/,
		'pandas test_obj_none_preservation: undef in a reference croaks';
}

#--------
# leaks
#--------
{
	my @a = (5, 7, 1, 2, 1, 5, 7) x 10;
	no_leaks_ok { my @u = uniq(@a) } 'uniq no leaks: test_unique_1d' unless $INC{'Devel/Cover.pm'};
}

done_testing();
