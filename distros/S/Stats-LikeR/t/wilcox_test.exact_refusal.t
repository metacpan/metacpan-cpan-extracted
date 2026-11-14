#!/usr/bin/env perl
# wilcox_test(exact => 1): a table whose counts overflow is refused before the recurrence runs.
#
# Provenance: for completely separated samples the exact two-sided p-value is
# 2 / C(m+n, m) (rank sum; R's 2 * pwilcox(0, m, n)) and 2 / 2^n (signed rank; R's
# 2 * psignrank(0, n)).  The expected values are those quantities computed exactly with
# Python 3.14 math.comb / fractions.Fraction and rounded once to a double with repr():
#   float(Fraction(2, comb(1028, 514)))  = 2.7948375223465e-308
#   float(Fraction(2, 2**1023))          = 2.2250738585072014e-308
# Both are written below as multiples of 2**-1022 (1.2560650567444769 times it,
# and 2**-1022 itself), because perl 5.10 and 5.18 misread decimal literals
# this close to the bottom of the double range.
#   float(Fraction(2, comb(120, 20)))    = 6.78835303330567e-23
# The overflow boundary is that of a double: C(1030, 515) and 2^1024 are the first of their
# kind past DBL_MAX (1.797e308), C(1028, 514) and 2^1023 the last below it.  Before the
# refusal was added the same inputs croaked with the same message, after running the whole
# recurrence (3000 against 3000: 11.2 s); the boundary cases below succeed or croak
# identically on the old build, which is what the early check must preserve.  Other NV
# widths put the boundary elsewhere, so the boundary cases run on double perls only.
# Tolerances: 1e-4 relative at 514 (the observed disagreement is 7e-6: the total is within
# 1% of DBL_MAX and its sum rounds there; left as the old build gave it), 1e-12 elsewhere
# (observed 3e-15).  The slow inputs -- the ones that took seconds before the fix -- run
# under EXTENDED_TESTING only.
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More; use Config; use Stats::LikeR;
my $msg = qr/overflow computing the exact distribution; use exact => 0/;
sub sep { my ($m, $n) = @_;
	return ([map { $_ + 0.5 } 1 .. $m], [map { $_ + $m + 1 } 1 .. $n]); }
sub near { my ($g, $e, $tol) = @_; return abs($g - $e) <= $tol * abs($e); }
SKIP: {
	skip 'boundary values are for a double NV', 8 unless $Config{nvtype} eq 'double';
	my $r = wilcox_test(sep(514, 514), exact => 1);
	ok(near($r->{p_value}, 1.2560650567444769 * 2**-1022, 1e-4), 'rank sum 514 vs 514 still succeeds');
	my @x = sep(515, 515);
	eval { wilcox_test(@x, exact => 1) };
	like($@, $msg, 'rank sum 515 vs 515 refused');
	@x = sep(300, 1043);
	ok(eval { wilcox_test(@x, exact => 1); 1 }, 'rank sum 300 vs 1043 (last that fits) succeeds');
	@x = sep(300, 1044);
	eval { wilcox_test(@x, exact => 1) };
	like($@, $msg, 'rank sum 300 vs 1044 refused');
	my $s = [map { $_ + 0.5 } 1 .. 1023];
	$r = wilcox_test($s, exact => 1);
	ok(near($r->{p_value}, 2**-1022, 1e-12), 'signed rank n = 1023 succeeds');
	$s = [map { $_ + 0.5 } 1 .. 1024];
	eval { wilcox_test($s, exact => 1) };
	like($@, $msg, 'signed rank n = 1024 refused');
	my @a = sep(20, 100);
	$r = wilcox_test(@a, exact => 1);
	ok(near($r->{p_value}, 6.78835303330567e-23, 1e-12), 'rank sum 20 vs 100 unaffected');
	@a = sep(5, 3000);
	ok(eval { wilcox_test(@a, exact => 1); 1 }, 'rank sum 5 vs 3000 unaffected');
}
SKIP: {
	skip 'slow without the early refusal: set EXTENDED_TESTING', 2 unless $ENV{EXTENDED_TESTING};
	my @x = sep(3000, 3000);
	eval { wilcox_test(@x, exact => 1) };
	like($@, $msg, 'rank sum 3000 vs 3000 refused');
	my $s = [map { $_ + 0.5 } 1 .. 1500];
	eval { wilcox_test($s, exact => 1) };
	like($@, $msg, 'signed rank n = 1500 refused');
}
done_testing;
