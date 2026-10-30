#!/usr/bin/env perl
# Regressions for fisher_test(), binom_test() and chisq_test() from the
# 2026-10-20 audit of LikeR.xs, all fixed in 0.331.  Each block names what used
# to happen.  The r x c p-values themselves are cross-validated in
# t/fisher_test.R.scipy.t (Cases 8 and 11); this file holds the input handling,
# the croaks and the leak checks.
#
# Provenance of every expected number below that is not structural:
#
#   * R 4.6.1 at options(digits = 17), printed with sprintf("%.17g"), and its
#     warning text as conditionMessage() gives it (R prints the difference with
#     format()'s 7 significant digits):
#       fisher.test(matrix(c(2.7, 3, 1, 4), 2)): p = 0.54545454545454553,
#         odds ratio 3.5155254350976421, CI 0.16950808249453006
#         260.91403586540082; warning "'x' has been rounded to integer: Mean
#         relative difference: 0.1111111"
#       fisher.test(matrix(c(2.5, 3.5, 1, 4), 2)): p = 1, odds ratio
#         1.8793625122379274 (round() is half to even: 2.5 -> 2, 3.5 -> 4);
#         warning "... Mean relative difference: 0.1666667"
#       fisher.test(matrix(c(2 + 1e-9, 3, 1, 4), 2)): odds ratio
#         2.4142235673374195, no warning (all.equal() calls it equal)
#       fisher.test(matrix(c(1e-10, 3, 1, 4), 2)): odds ratio 0, CI upper
#         64.935064935064901, no warning (the absolute difference is below
#         all.equal()'s tolerance)
#       fisher.test(matrix(c(0.4, 3, 1, 4), 2)): the same, with the warning
#         "... Mean relative difference: 1"
#       fisher.test(matrix(c(2.7, 3, 1, 4, 5.5, 6), 2)): p = 0.5500259600407591,
#         warning "... Mean relative difference: 0.09756098"
#       fisher.test(matrix(c(2147483647, 3, 1, 4), 2)): p =
#         1.9748304869431231e-34
#       fisher.test(matrix(0, 2, 2)): p = 1, odds ratio 0, CI 0 Inf
#       fisher.test() on NaN, -0.4 or NA: "all entries of 'x' must be
#         nonnegative and finite"; on Inf or 2147483647.6: "'x' has entries
#         too large to be integer"
#       binom.test(Inf, 10), binom.test(3, Inf), binom.test(c(3, Inf)) stop
#         ("missing value where TRUE/FALSE needed"); binom.test(NaN, 10) and
#         binom.test(c(NaN, 3)) stop with "'x' must be nonnegative and
#         integer"; binom.test(3, NaN) with "'n' must be a positive integer >=
#         'x'"
#
# Tolerances are the ones t/fisher_test.R.scipy.t uses for the same 2x2 path
# (see its header): 1e-11 on a p-value, 1e-10 on the odds ratio, 1e-4 on a CI
# bound.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Config;
use Test::More;
use Stats::LikeR qw(binom_test chisq_test fisher_test);

# Imported at compile time, because no_leaks_ok's block form needs its
# prototype visible when the file is parsed. Same shape as t/croak.leaks.t.
BEGIN {
	if (eval { require Test::LeakTrace; 1 }) {
		Test::LeakTrace->import('no_leaks_ok');
	} else {
		*no_leaks_ok = sub (&;$) { SKIP: { skip 'Test::LeakTrace not installed', 1 } };
	}
}

my $INF = 9**9**9;
my $NAN = $INF - $INF;
sub near {
	my ($got, $want, $name, $tol) = @_;
	my $err = $want == 0 ? abs($got) : abs($got - $want) / abs($want);
	ok($err <= $tol, $name) or diag("got $got, want $want, rel err $err");
}

# Runs $code, returning its result and the warnings it raised.
sub warnings_of {
	my ($code) = @_;
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $r = $code->();
	return ($r, @w);
}

# fisher_test(): cells used to go through SvIV(), which truncated 2.7 to 2
# and read NaN and -0.4 as 0.  They are now read as fisher.test() reads 'x'.
{
	my ($r, @w) = warnings_of(sub { fisher_test([[2.7, 1], [3, 4]]) });
	near($r->{p_value}, 0.54545454545454553, 'fisher 2.7 is rounded to 3: p-value as R', 1e-11);
	near($r->{estimate}{'odds ratio'}, 3.5155254350976421, 'fisher 2.7 is rounded to 3: odds ratio as R', 1e-10);
	near($r->{conf_int}[0], 0.16950808249453006, 'fisher 2.7: CI lower as R', 1e-4);
	near($r->{conf_int}[1], 260.91403586540082, 'fisher 2.7: CI upper as R', 1e-4);
	is(scalar @w, 1, 'fisher 2.7: one warning');
	like($w[0] // '', qr/^fisher_test: 'x' has been rounded to integer: Mean relative difference: 0\.1111111 at /,
	     "fisher 2.7: R's warning, R's number");

	($r, @w) = warnings_of(sub { fisher_test([[2.5, 1], [3.5, 4]]) });
	near($r->{estimate}{'odds ratio'}, 1.8793625122379274, 'fisher rounds half to even, as R (2.5 -> 2, 3.5 -> 4)', 1e-10);
	like($w[0] // '', qr/Mean relative difference: 0\.1666667 at /, 'fisher 2.5/3.5: the warning');

	($r, @w) = warnings_of(sub { fisher_test([[2 + 1e-9, 1], [3, 4]]) });
	near($r->{estimate}{'odds ratio'}, 2.4142235673374195, 'fisher 2 + 1e-9 is 2', 1e-10);
	is(scalar @w, 0, 'fisher 2 + 1e-9: no warning, all.equal() calls it equal');

	($r, @w) = warnings_of(sub { fisher_test([[1e-10, 1], [3, 4]]) });
	is($r->{estimate}{'odds ratio'}, 0, 'fisher 1e-10 is 0');
	near($r->{conf_int}[1], 64.935064935064901, 'fisher 1e-10: CI upper as R', 1e-4);
	is(scalar @w, 0, 'fisher 1e-10: no warning (the absolute difference is within tolerance)');

	($r, @w) = warnings_of(sub { fisher_test([[0.4, 1], [3, 4]]) });
	like($w[0] // '', qr/Mean relative difference: 1 at /, 'fisher 0.4 -> 0: the whole cell changed');

	($r, @w) = warnings_of(sub { fisher_test([[2.7, 1, 5.5], [3, 4, 6]]) });
	near($r->{p_value}, 0.5500259600407591, 'fisher r x c rounds too: p-value as R', 1e-11);
	like($w[0] // '', qr/Mean relative difference: 0\.09756098 at /, 'fisher r x c: one warning over all the cells');

	($r, @w) = warnings_of(sub { fisher_test({ a => { x => 2.7, y => 1 }, b => { x => 3, y => 4 } }) });
	near($r->{p_value}, 0.54545454545454553, 'fisher hash input rounds too', 1e-11);
	is(scalar @w, 1, 'fisher hash input: one warning');

	for my $c ([ 'NaN', $NAN, qr/nonnegative and finite \(array cell\)/ ],
		   [ 'NaN string', 'nan', qr/nonnegative and finite/ ],
		   [ '-0.4', -0.4, qr/nonnegative and finite/ ],
		   [ '-Inf', -$INF, qr/nonnegative and finite/ ],
		   [ 'Inf', $INF, qr/'x' has entries too large to be integer/ ],
		   [ '2147483647.6', 2147483647.6, qr/'x' has entries too large to be integer/ ],
		   [ 'undef', undef, qr/array cell is undef/ ],
		   [ 'a string', 'abc', qr/array cell is not a number/ ]) {
		my ($name, $v, $re) = @$c;
		eval { fisher_test([[$v, 1], [3, 4]]) };
		like($@, $re, "fisher 2x2 cell $name croaks, as R stops");
		eval { fisher_test([[1, 2, 3], [4, 5, $v]]) };
		like($@, $re, "fisher r x c cell $name croaks, as R stops");
	}
	my ($neg0) = warnings_of(sub { fisher_test([[-0.0, 1], [3, 4]]) });
	is($neg0->{p_value}, fisher_test([[0, 1], [3, 4]])->{p_value}, 'fisher -0 is 0, as in R');

	# R's limit is .Machine$integer.max, which is a cell, not a total: the 2x2
	# margins are longs here, so a total past 2^31 - 1 is refused where long
	# is 32 bits (Windows, 32-bit perls) and answered as R does elsewhere.
	if ($Config{longsize} >= 8) {
		near(fisher_test([[2147483647, 1], [3, 4]])->{p_value}, 1.9748304869431231e-34,
		     'fisher a cell of 2^31 - 1 is taken, as R', 1e-11);
	} else {
		eval { fisher_test([[2147483647, 1], [3, 4]]) };
		like($@, qr/the table's total, \d+, is too large/, 'fisher a total past a 32-bit long croaks');
	}
}

# fisher_test(): an all-zero table croaked "table is all zeros".  R answers a
# 2x2 one and stops on an r x c one; so does fisher_test() now.
{
	my $r = fisher_test([[0, 0], [0, 0]]);
	is($r->{p_value}, 1, 'fisher all-zero 2x2: p = 1, as R');
	is($r->{estimate}{'odds ratio'}, 0, 'fisher all-zero 2x2: odds ratio 0, as R');
	is_deeply($r->{conf_int}, [0, $INF], 'fisher all-zero 2x2: CI [0, Inf], as R');
	eval { fisher_test([[0, 0, 0], [0, 0, 0]]) };
	like($@, qr/all elements of the 2x3 table are zero/, 'fisher all-zero 2x3 croaks, as R (FEXACT error 3)');
}

# fisher_test(): the r x c refusal croaked with the result hash and two of its
# values already allocated, and leaked all three.  The table is one the
# network algorithm gives up on quickly (0.4 s on a double build here).
my $too_big = [[3000, 3000, 3000], [3000, 3000, 3100], [2900, 3000, 3000]];
eval { fisher_test($too_big) };
like($@, qr/fisher_test: 3x3 table is too large for exact enumeration/, 'fisher refuses a table past its caps');
no_leaks_ok { eval { fisher_test($too_big) } } 'fisher r x c refusal leaks nothing';
no_leaks_ok { eval { fisher_test([[1, 2, 3], [4, 5, $NAN]]) } } 'fisher NaN-cell croak leaks nothing';
no_leaks_ok {
	local $SIG{__WARN__} = sub { die "dying handler\n" };
	eval { fisher_test([[2.7, 1, 5], [3, 4, 6]]) };
} 'fisher rounding warning leaks nothing under a dying __WARN__ handler';
no_leaks_ok { fisher_test([[0, 1, 8, 4], [4, 7, 6, 3], [4, 0, 8, 7], [7, 4, 5, 5]]) } 'fisher r x c network leaks nothing';

# binom_test(): Inf and NaN passed bt_check_count(), whose integer test is
# false for both (Inf - Inf is NaN), and the cast to long was undefined.
{
	my $big = 2**64;	# past LONG_MAX on every platform
	for my $c ([ 'x = Inf', [$INF, 10], qr/x must be a nonnegative integer/ ],
		   [ 'x = NaN', [$NAN, 10], qr/x must be a nonnegative integer/ ],
		   [ 'x = "inf"', ['inf', 10], qr/x must be a nonnegative integer/ ],
		   [ 'n = Inf', [3, $INF], qr/n must be a nonnegative integer/ ],
		   [ 'n = NaN', [3, $NAN], qr/n must be a nonnegative integer/ ],
		   [ 'failures = Inf', [[3, $INF]], qr/failures must be a nonnegative integer/ ],
		   [ 'successes = NaN', [[$NAN, 3]], qr/successes must be a nonnegative integer/ ],
		   [ 'successes = -Inf', [[-$INF, 3]], qr/successes must be a nonnegative integer/ ],
		   [ 'x = 2^64', [$big, $big], qr/x is too large/ ],
		   [ 'n = 2^64', [3, $big], qr/n is too large/ ]) {
		my ($name, $args, $re) = @$c;
		eval { binom_test(@$args) };
		like($@, $re, "binom_test $name croaks, as R stops");
	}
	# Each count fits a long, but the sum does not.
	my $half = $Config{longsize} >= 8 ? 2**62 : 2**30;
	eval { binom_test([$half, $half]) };
	like($@, qr/successes \+ failures is too large/, 'binom_test successes + failures past LONG_MAX croaks');
	no_leaks_ok { eval { binom_test($INF, 10) } } 'binom_test Inf croak leaks nothing';
}

# chisq_test(): every cell read built a mortal SV for its own name, held to
# the end of the call; the name is now formatted only for a croak.  The
# messages must read as they did.
{
	for my $c ([ 'AoA undef', sub { chisq_test([[1, 2], [3, undef]]) }, qr/^chisq_test: cell \[1\]\[1\] is undef/ ],
		   [ 'HoH string', sub { chisq_test({ a => { x => 1, y => 'q' }, b => { x => 1, y => 2 } }) },
		     qr/^chisq_test: cell \{a\}\{y\} is not a number/ ],
		   [ 'vector negative', sub { chisq_test([1, -2, 3]) },
		     qr/^chisq_test: all entries of 'x' must be nonnegative and finite \(element \[1\]\)/ ],
		   [ 'hash Inf', sub { chisq_test({ a => 1, b => $INF }) },
		     qr/^chisq_test: all entries of 'x' must be nonnegative and finite \(element \{b\}\)/ ],
		   [ 'p undef', sub { chisq_test([1, 2, 3], p => [0.5, undef, 0.5]) }, qr/^chisq_test: p\[1\] is undef/ ],
		   [ 'p hash string', sub { chisq_test({ a => 1, b => 2 }, p => { a => 0.5, b => 'z' }) },
		     qr/^chisq_test: p\{b\} is not a number/ ]) {
		my ($name, $code, $re) = @$c;
		eval { $code->() };
		like($@, $re, "chisq_test $name: the cell is still named");
		no_leaks_ok { eval { $code->() } } "chisq_test $name: no leak";
	}
	my $utf8_key = "k\x{263a}";
	eval { chisq_test({ $utf8_key => -1, b => 2 }) };
	like($@, qr/\(element \{k\x{263a}\}\)/, 'chisq_test names a UTF-8 key as the string it is');
}

done_testing();
