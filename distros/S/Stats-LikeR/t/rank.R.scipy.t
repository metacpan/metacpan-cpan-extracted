#!/usr/bin/env perl
# rank(): R's and SciPy's own cases, frozen as literals.  t/rank.t is
# hand-written and checks only what the code did; it never took the references'
# cases, and rank("b", "a", "b") returned 2, 2, 2 undetected.
#
# Provenance
#  R 4.6.1 (/home/con/Scripts/r-source):
#   tests/reg-tests-1a.R:2023   rank(c("ch", "c", NA)) == c(2, 1, 3)
#   tests/reg-tests-1a.R:2573-2580  x2 <- c(3,1,4,1,5,NA,9,2,6,5,3,5), rank()
#       with na.last TRUE / FALSE / NA / "keep" (there the check is on names,
#       which Perl has no equivalent of; the values are frozen from Rscript 4.6.1)
#   tests/reg-tests-1a.R:3266   rank() of a list or a raw vector is an error
#       (analogue here: a reference that is not a number)
#   tests/reg-tests-1d.R:4005   rank() of a classed raw vector: no Perl
#       equivalent, not taken
#   src/library/base/man/rank.Rd examples: x1 <- c(3,1,4,15,92), x2 <-
#       c(3,1,4,1,5,9,2,6,5,3,5) under every ties.method; base-Ex.Rout.save is
#       not shipped in this source tree, so the values were printed by
#       Rscript 4.6.1 with options(digits=17).  "random" is checked for being a
#       permutation, as the Rd gives no fixed output.
#   String cases: Rscript 4.6.1 under Sys.setlocale("LC_COLLATE", "C"), since
#       R orders strings by the locale and this module by codepoint.
#  SciPy 1.18.0, scipy/stats/tests/test_rank.py:
#   TestRankData.test_list, test_basic, test_axis (rows), test_nan_policy_2d_axis_none
#   (nan_policy='omit' is na_last => 'keep'), _rankdata_cases (average, min, max,
#   ordinal = ties_method first; 'dense' has no equivalent), and
#   test_rankdata_object_string with the random choice fixed by
#   t/rank.R.scipy.py (RandomState(20241122)), re-run it to regenerate.
#  Not taken: test_large_int/test_large_uint (2**60 and 2**60 + 1 are one NV, so
#  they tie here), nan_policy 'raise'/'propagate' (rank has neither).

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception;
use Test::More;

# R: rank(c("ch","c",NA)) == c(2,1,3)
is_deeply([rank("ch", "c", undef)], [2, 1, 3], 'reg-tests-1a.R:2023 strings with NA');
is_deeply([rank("ch", "c", undef, 'na_last', 'keep')], [2, 1, undef], 'strings, keep');
is_deeply([rank("ch", "c", undef, 'na_last', 'false')], [3, 2, 1], 'strings, na_last false');
is_deeply([rank("ch", "c", undef, 'na_last', 'na')], [2, 1], 'strings, na dropped');

# R: the bug report
is_deeply([rank("b", "a", "b")], [2.5, 1, 2.5], 'rank("b","a","b")');
is_deeply([rank("abc", 5, 1)], [3, 2, 1], 'mixed vector is character');
is_deeply([rank("10", "9", "a")], [1, 2, 3], 'numbers in a string vector sort as strings');
is_deeply([rank("10", "9")], [2, 1], 'all numeric strings rank as numbers');
is_deeply([rank(2.5, "x", 10)], [2, 3, 1], 'R rank(c(2.5,"x",10))');
is_deeply([rank("0x10", "3")], [1, 2], '"0x10" is a string, not 0');
is_deeply([rank("", "a")], [1, 2], 'empty string is a string');
is_deeply([rank(" 3 ", "1e1", "2")], [2, 3, 1], 'numeric strings with space and exponent');
is_deeply([rank(["b", "a"], "b")], [2.5, 1, 2.5], 'array ref of strings');

# R: x2 <- c(3,1,4,1,5,NA,9,2,6,5,3,5), reg-tests-1a.R:2573 (Rscript 4.6.1)
my @x2 = (3, 1, 4, 1, 5, undef, 9, 2, 6, 5, 3, 5);
is_deeply([rank(@x2)],                           [4.5, 1.5, 6, 1.5, 8, 12, 11, 3, 10, 8, 4.5, 8], 'y1 na.last=TRUE');
is_deeply([rank(@x2, 'na_last', 'false')],       [5.5, 2.5, 7, 2.5, 9, 1, 12, 4, 11, 9, 5.5, 9],  'y2 na.last=FALSE');
is_deeply([rank(@x2, 'na_last', 'na')],          [4.5, 1.5, 6, 1.5, 8, 11, 3, 10, 8, 4.5, 8],     'y3 na.last=NA');
is_deeply([rank(@x2, 'na_last', 'keep')],        [4.5, 1.5, 6, 1.5, 8, undef, 11, 3, 10, 8, 4.5, 8], 'y4 na.last="keep"');
my %x2 = (
	average => { true => [4.5, 1.5, 6, 1.5, 8, 12, 11, 3, 10, 8, 4.5, 8], false => [5.5, 2.5, 7, 2.5, 9, 1, 12, 4, 11, 9, 5.5, 9], keep => [4.5, 1.5, 6, 1.5, 8, undef, 11, 3, 10, 8, 4.5, 8] },
	first   => { true => [4, 1, 6, 2, 7, 12, 11, 3, 10, 8, 5, 9],         false => [5, 2, 7, 3, 8, 1, 12, 4, 11, 9, 6, 10],       keep => [4, 1, 6, 2, 7, undef, 11, 3, 10, 8, 5, 9] },
	last    => { true => [5, 2, 6, 1, 9, 12, 11, 3, 10, 8, 4, 7],         false => [6, 3, 7, 2, 10, 1, 12, 4, 11, 9, 5, 8],       keep => [5, 2, 6, 1, 9, undef, 11, 3, 10, 8, 4, 7] },
	max     => { true => [5, 2, 6, 2, 9, 12, 11, 3, 10, 9, 5, 9],         false => [6, 3, 7, 3, 10, 1, 12, 4, 11, 10, 6, 10],     keep => [5, 2, 6, 2, 9, undef, 11, 3, 10, 9, 5, 9] },
	min     => { true => [4, 1, 6, 1, 7, 12, 11, 3, 10, 7, 4, 7],         false => [5, 2, 7, 2, 8, 1, 12, 4, 11, 8, 5, 8],        keep => [4, 1, 6, 1, 7, undef, 11, 3, 10, 7, 4, 7] },
);
for my $m (sort keys %x2) {
	for my $nl (sort keys %{$x2{$m}}) {
		is_deeply([rank(@x2, 'ties_method', $m, 'na_last', $nl)], $x2{$m}{$nl}, "x2 $m na_last $nl");
	}
}

# rank.Rd examples
is_deeply([rank(3, 1, 4, 15, 92)], [2, 1, 3, 4, 5], 'Rd r1');
{
	my @x = (3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5);
	my %rx = (
		average => [4.5, 1.5, 6, 1.5, 8, 11, 3, 10, 8, 4.5, 8],
		first   => [4, 1, 6, 2, 7, 11, 3, 10, 8, 5, 9],
		last    => [5, 2, 6, 1, 9, 11, 3, 10, 8, 4, 7],
		max     => [5, 2, 6, 2, 9, 11, 3, 10, 9, 5, 9],
		min     => [4, 1, 6, 1, 7, 11, 3, 10, 7, 4, 7],
	);
	is_deeply([rank(@x, 'ties_method', $_)], $rx{$_}, "Rd x2 $_") for sort keys %rx;
	my @r2 = rank(@x);
	is_deeply([rank(@r2)], \@r2, 'rank is idempotent');
	my @r1 = rank(3, 1, 4, 15, 92);
	is_deeply([rank(@r1)], \@r1, 'rank is idempotent (r1)');
	srand(5);
	my @rr = rank(@x, 'ties_method', 'random');
	is_deeply([sort { $a <=> $b } @rr], [1 .. 11], 'random is a permutation');
	my @mx = rank(@x, 'ties_method', 'max'); my @mn = rank(@x, 'ties_method', 'min');
	is_deeply([map { $mx[$_] + $mn[$_] } 0 .. 10], [map { 2 * $_ } @r2], 'rma + rmi == round(r2 + r2)');
}

# strings under every ties_method and NA mode (Rscript, LC_COLLATE=C)
{
	my @s = ("B", "a", "b", "A", "a");
	is_deeply([rank(@s, 'ties_method', 'min')],   [2, 3, 5, 1, 3], 'strings min');
	is_deeply([rank(@s, 'ties_method', 'max')],   [2, 4, 5, 1, 4], 'strings max');
	is_deeply([rank(@s, 'ties_method', 'first')], [2, 3, 5, 1, 4], 'strings first');
	is_deeply([rank(@s, 'ties_method', 'last')],  [2, 4, 5, 1, 3], 'strings last');
	is_deeply([rank(@s)], [2, 3.5, 5, 1, 3.5], 'strings average');
	my @n = ("B", "a", undef, "b", "A", "a", undef);
	is_deeply([rank(@n, 'na_last', 'keep')],  [2, 3.5, undef, 5, 1, 3.5, undef], 'strings keep');
	is_deeply([rank(@n, 'na_last', 'false')], [4, 5.5, 1, 7, 3, 5.5, 2],         'strings na_last false');
	is_deeply([rank(@n)],                     [2, 3.5, 6, 5, 1, 3.5, 7],         'strings na_last true');
	is_deeply([rank(@n, 'na_last', 'na')],    [2, 3.5, 5, 1, 3.5],               'strings dropped');
	srand(7);
	my @rr = rank(@s, 'ties_method', 'random');
	is_deeply([sort { $a <=> $b } @rr], [1, 2, 3, 4, 5], 'strings random is a permutation');
	is_deeply([@rr[0, 2, 3]], [2, 5, 1], 'strings random leaves untied values');
}

# SciPy: test_list, test_basic, test_axis rows, _rankdata_cases
is_deeply([rank(40, 10, 30, 10, 50)], [4, 1.5, 3, 1.5, 5], 'scipy test_list');
is_deeply([rank(100, 10, 50)], [3, 1, 2], 'scipy test_basic 1');
is_deeply([rank(20, 20, 20, 10, 10, 10)], [5, 5, 5, 2, 2, 2], 'scipy test_basic 3');
is_deeply([rank(0, 2, 1)], [1, 3, 2], 'axis=1 row 0');
is_deeply([rank(4, 2, 2)], [3, 1.5, 1.5], 'axis=1 row 1');
is_deeply([rank(0, 4)], [1, 2], 'axis=0 col 0');
is_deeply([rank(2, 2)], [1.5, 1.5], 'axis=0 col 1');
is_deeply([rank(1, 2, 2)], [1, 2.5, 2.5], 'axis=0 col 2 (data rows)');
is_deeply([rank(0, undef, 3, 4, 2, undef, 1, 2, 2, 'na_last', 'keep')], [1, undef, 6, 7, 4, undef, 2, 4, 4], 'nan_policy omit, axis=None');
{
	my @cases = (
		[[], 'average', []], [[], 'min', []], [[], 'max', []], [[], 'first', []],
		[[100], 'average', [1]], [[100], 'min', [1]], [[100], 'max', [1]], [[100], 'first', [1]],
		[[100, 100, 100], 'average', [2, 2, 2]], [[100, 100, 100], 'min', [1, 1, 1]],
		[[100, 100, 100], 'max', [3, 3, 3]], [[100, 100, 100], 'first', [1, 2, 3]],
		[[100, 300, 200], 'average', [1, 3, 2]], [[100, 300, 200], 'min', [1, 3, 2]],
		[[100, 300, 200], 'max', [1, 3, 2]], [[100, 300, 200], 'first', [1, 3, 2]],
		[[100, 200, 300, 200], 'average', [1, 2.5, 4, 2.5]], [[100, 200, 300, 200], 'min', [1, 2, 4, 2]],
		[[100, 200, 300, 200], 'max', [1, 3, 4, 3]], [[100, 200, 300, 200], 'first', [1, 2, 4, 3]],
		[[100, 200, 300, 200, 100], 'average', [1.5, 3.5, 5, 3.5, 1.5]],
		[[100, 200, 300, 200, 100], 'min', [1, 3, 5, 3, 1]],
		[[100, 200, 300, 200, 100], 'max', [2, 4, 5, 4, 2]],
		[[100, 200, 300, 200, 100], 'first', [1, 3, 5, 4, 2]],
		[[(10) x 30], 'first', [1 .. 30]],
	);
	for my $c (@cases) {
		is_deeply([rank(@{$c->[0]}, 'ties_method', $c->[1])], $c->[2], "scipy case n=" . scalar(@{$c->[0]}) . " $c->[1]");
	}
}

# SciPy test_rankdata_object_string, fixed draw (see t/rank.R.scipy.py)
my @str = qw(foo qux xyz bar abc ace ace ace ace foo bar foo qaz abc xyz ace qaz ace qux xyz efg abc qux qwe xyz efg ace abc abc qaz xyz xyz bar qaz xyz qwe qux qux bar efg);
my %str_exp = (
	average	=> [21, 29, 37, 14.5, 3, 9, 9, 9, 9, 21, 14.5, 21, 24.5, 3, 37, 9, 24.5, 9, 29, 37, 18, 3, 29, 32.5, 37, 18, 9, 3, 3, 24.5, 37, 37, 14.5, 24.5, 37, 32.5, 29, 29, 14.5, 18],
	min	=> [20, 27, 34, 13, 1, 6, 6, 6, 6, 20, 13, 20, 23, 1, 34, 6, 23, 6, 27, 34, 17, 1, 27, 32, 34, 17, 6, 1, 1, 23, 34, 34, 13, 23, 34, 32, 27, 27, 13, 17],
	max	=> [22, 31, 40, 16, 5, 12, 12, 12, 12, 22, 16, 22, 26, 5, 40, 12, 26, 12, 31, 40, 19, 5, 31, 33, 40, 19, 12, 5, 5, 26, 40, 40, 16, 26, 40, 33, 31, 31, 16, 19],
	first	=> [20, 27, 34, 13, 1, 6, 7, 8, 9, 21, 14, 22, 23, 2, 35, 10, 24, 11, 28, 36, 17, 3, 29, 32, 37, 18, 12, 4, 5, 25, 38, 39, 15, 26, 40, 33, 30, 31, 16, 19],
);
is_deeply([rank(@str, 'ties_method', $_)], $str_exp{$_}, "scipy strings $_") for sort keys %str_exp;
is_deeply([rank([@str])], $str_exp{average}, 'scipy strings, array ref');
# the numeric 'object' draw
my @num = (3, 1, 1, 1, 0, 2.718, 2.718, 1, 3, 0, 2, 3.141, 2, 0, 2.718, 0, 3, 2.718, 1, 3.141, 1, 2.718, 1, 2.718, 2, 1, 2, 2.718, 3.141, 2, 3.141, 3, 2, 3, 1, 0, 3, 0, 3.141, 3.141);
my %num_exp = (
	average	=> [31.5, 11, 11, 11, 3.5, 25, 25, 11, 31.5, 3.5, 18.5, 37.5, 18.5, 3.5, 25, 3.5, 31.5, 25, 11, 37.5, 11, 25, 11, 25, 18.5, 11, 18.5, 25, 37.5, 18.5, 37.5, 31.5, 18.5, 31.5, 11, 3.5, 31.5, 3.5, 37.5, 37.5],
	min	=> [29, 7, 7, 7, 1, 22, 22, 7, 29, 1, 16, 35, 16, 1, 22, 1, 29, 22, 7, 35, 7, 22, 7, 22, 16, 7, 16, 22, 35, 16, 35, 29, 16, 29, 7, 1, 29, 1, 35, 35],
	max	=> [34, 15, 15, 15, 6, 28, 28, 15, 34, 6, 21, 40, 21, 6, 28, 6, 34, 28, 15, 40, 15, 28, 15, 28, 21, 15, 21, 28, 40, 21, 40, 34, 21, 34, 15, 6, 34, 6, 40, 40],
	first	=> [29, 7, 8, 9, 1, 22, 23, 10, 30, 2, 16, 35, 17, 3, 24, 4, 31, 25, 11, 36, 12, 26, 13, 27, 18, 14, 19, 28, 37, 20, 38, 32, 21, 33, 15, 5, 34, 6, 39, 40],
);
is_deeply([rank(@num, 'ties_method', $_)], $num_exp{$_}, "scipy numbers $_") for sort keys %num_exp;

# invalid inputs, reg-tests-1a.R:3266 (R refuses a list and a raw vector)
throws_ok { rank(1, {}, 3) }    qr/rank: error: cannot rank a HASH reference/,  'hashref element dies';
throws_ok { rank([1, [2], 3]) } qr/rank: error: cannot rank a ARRAY reference/, 'nested arrayref dies';
throws_ok { rank(sub { 1 }) }   qr/rank: error: cannot rank a CODE reference/,  'coderef dies';

# no warning for strings, whatever the caller's warning settings
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	my @r = rank("b", "a", "b");
	is(scalar(@w), 0, 'no numeric warning');
}

# a tied array is fetched once per element
{
	package CountTie;
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
	our $fetches = 0;
	sub FETCH { $fetches++; $_[0]->SUPER::FETCH($_[1]) }
	package main;
	tie my @t, 'CountTie';
	@t = ("b", "a", "b", 7);
	$CountTie::fetches = 0;
	is_deeply([rank(\@t)], [3.5, 2, 3.5, 1], 'tied strings with a number');
	is($CountTie::fetches, 4, 'one FETCH per element');
}

# leaks: string ranking, and the croak path (real calls hoisted)
unless ($INC{"Devel/Cover.pm"}) {
	require Test::LeakTrace;
	my @warm = rank("b", "a", "b", undef);
	@warm = rank(["ch", 5], "x", "ties_method", "random");
	eval { rank(1, {}) };
	Test::LeakTrace::no_leaks_ok(sub { my @r = rank("b", "a", "b", undef, "na_last", "keep") }, "string rank: no leaks");
	Test::LeakTrace::no_leaks_ok(sub { my @r = rank(["ch", 5], "x", "ties_method", "random") }, "mixed random: no leaks");
	Test::LeakTrace::no_leaks_ok(sub { eval { rank(1, {}) } }, "croak: no leaks");
}

done_testing();
