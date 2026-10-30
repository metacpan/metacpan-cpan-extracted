#!/usr/bin/env perl
# Regressions for bugs the 2026-10-20 audit found in cmh_test(), lmer(),
# zerotrunc() and hurdle(), fixed in 0.331.  The cross-validated halves of the
# same fixes -- the values R gives -- are in t/zerotrunc_hurdle.R.t,
# t/svyglm.R.t, t/ivreg.R.t and t/lmer.R.t; this file holds the croaks and the
# leak checks.
#
# Provenance:
#
#   * cmh_test: R 4.6.1's src/library/stats/R/mantelhaen.test.R stops with
#     "sample size in each stratum must be > 1" when any stratum's total is
#     below 2; mantelhaen.test(array(c(10, 5, 3, 12, 0, 0, 0, 0), c(2, 2, 2)))
#     and the same with a stratum of c(1, 0, 0, 0) both give that error.  A
#     stratum of total 2 is accepted by both.
#   * lmer's limit on the dense method is this module's own, and its reasons
#     are in the comment above the croak in LikeR.xs.
#
# No tolerances: everything here is a croak, an exact count or a leak check.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(cmh_test lmer zerotrunc hurdle);

sub dies_like {
	my ($code, $re, $name) = @_;
	my $lived = eval { $code->(); 1 };
	ok(!$lived && $@ =~ $re, $name) or diag($lived ? 'lived' : "died: $@");
}

# ------------------------------------------------------------ cmh_test
# A stratum of total 0 used to be skipped and one of total 1 pooled; R stops
# on both.
dies_like(sub { cmh_test([[10, 3, 5, 12], [0, 0, 0, 0]]) },
	qr/^cmh_test: sample size in each stratum must be > 1 \(stratum at index 1 has 0\)/,
	'cmh_test: a stratum of total 0 croaks, as mantelhaen.test()');
dies_like(sub { cmh_test([[10, 3, 5, 12], [1, 0, 0, 0]]) },
	qr/sample size in each stratum must be > 1 \(stratum at index 1 has 1\)/,
	'cmh_test: a stratum of total 1 croaks');
dies_like(sub { cmh_test([[0, 0, 1, 0], [10, 3, 5, 12]]) },
	qr/stratum at index 0 has 1/, 'cmh_test: whichever stratum it is');
{
	my $r = cmh_test([[10, 3, 5, 12], [1, 0, 0, 1]]);
	is($r->{k}, 2, 'cmh_test: a stratum of total 2 is accepted, as by R');
}

# ------------------------------------------------------------ lmer
# More than 4000 random effects over crossed factors used to be accepted up to
# 20000, which needs 6.4 GB and days; the croak now says what to do instead.
my %big;
{
	my $h = 2001;	# two factors of 2001 levels: Q = 4002, one over the limit
	for my $i (0 .. 2 * $h - 1) {
		push @{ $big{a} }, 'a' . ($i % $h);
		push @{ $big{b} }, 'b' . (($i * 7) % $h);
		push @{ $big{x} }, $i % 13;
		push @{ $big{y} }, ($i * 37) % 101;
	}
	push @{ $big{$_} }, $big{$_}[0] for qw(a b x y);	# n = 4003 > Q
}
dies_like(sub { lmer(formula => 'y ~ x + (1 | a) + (1 | b)', data => \%big) },
	qr/^lmer: 4002 random effects over more than one grouping factor is more than the dense method takes \(at most 4000;.*use a single grouping factor/s,
	'lmer: more than 4000 crossed random effects croaks, saying what to do');

# ------------------------------------------------------------ leaks
SKIP: {
	skip 'Test::LeakTrace not installed', 5 unless eval { require Test::LeakTrace; 1 };
	my %zt = (y => [1, 2, 1, 2, 1, 2, 3, 2, 1, 2, 2, 3], x => [1 .. 12]);
	my %h = (y => [2, 0, 0, 0, 2, 1, 0, 0, 0, 0, 0, 0, 3, 0, 2, 2, 2, 3, 2, 2], x => [1 .. 20]);
	my %one = (y => [1 .. 6], x => [1, 2, 1, 2, 1, 3], g => [('a') x 6]);
	Test::LeakTrace::no_leaks_ok(sub { zerotrunc(formula => 'y ~ x', data => \%zt, dist => 'negbin') },
		'no leaks: zerotrunc at theta = Inf');
	Test::LeakTrace::no_leaks_ok(sub { hurdle(formula => 'y ~ x', data => \%h, dist => 'negbin', zero_dist => 'negbin') },
		'no leaks: hurdle at theta = Inf');
	Test::LeakTrace::no_leaks_ok(sub { eval { cmh_test([[10, 3, 5, 12], [1, 0, 0, 0]]) } },
		'no leaks: cmh_test croak');
	Test::LeakTrace::no_leaks_ok(sub { eval { lmer(formula => 'y ~ x + (1 | g)', data => \%one) } },
		'no leaks: lmer one-level croak');
	Test::LeakTrace::no_leaks_ok(sub { eval { lmer(formula => 'y ~ x + (1 | a) + (1 | b)', data => \%big) } },
		'no leaks: lmer dense-limit croak');
}

done_testing();
