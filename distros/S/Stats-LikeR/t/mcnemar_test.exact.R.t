#!/usr/bin/env perl
# mcnemar_test(exact => 1) against R 4.6.1.
#
# Provenance: R 4.6.1, options(digits=17).  Small and medium counts are
# binom.test(c(b, c), p = 0.5)$p.value; the counts at or above 2**31 (where
# binom.test() itself refuses a non-integer-sized x) are
# min(1, 2 * pbinom(min(b, c), b + c, 0.5)), which is what binom.test()'s
# two-sided rule reduces to at p = 0.5.  b == c is p 1 (R: x == n*p).
# Before the fix the p-value was summed term by term: 0.009826950519575238 at
# b = 29990000, c = 30010000 (R 0.0098269491930559789, relative error 1.4e-7)
# in 0.9 s, and the (long) casts wrapped past 2**31 on 32-bit-long perls.
#
# Tolerance: relative 1e-12; worst observed disagreement 1.3e-15 (double perl).
require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::More;

my @cases = (
	[29990000, 30010000, 0.0098269491930559789],
	[100000, 100400, 0.3727681458396625],
	[2000, 2100, 0.12206497999113813],
	[5, 5, 1],
	[0, 7, 0.015625000000000007],
	[3, 10, 0.092285156250000028],
	[1, 0, 1],
	[2147483648, 2147523648, 0.5416409352649123],
	[5000000000, 5000100000, 0.31731776699674824],
	[10000000000, 10000300000, 0.033896786166882999],
	[2251799813685248, 2251799823685248, 0.88154448215212267],
);
for my $c (@cases) {
	my ($b, $cc, $exp) = @$c;
	my $r = mcnemar_test([[1, $b], [$cc, 1]], exact => 1);
	my $err = abs(($r->{p_value} - $exp) / $exp);
	ok($err <= 1e-12, "exact p for b=$b c=$cc") or diag("got $r->{p_value} expected $exp");
	my $s = mcnemar_test([[1, $cc], [$b, 1]], exact => 1);
	is($s->{p_value}, $r->{p_value}, "symmetric in b and c ($b, $cc)");
}
done_testing();
