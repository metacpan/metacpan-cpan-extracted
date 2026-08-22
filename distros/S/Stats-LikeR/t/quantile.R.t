#!/usr/bin/env perl
#
# Cross-validation of quantile() against R's stats::quantile(), and the
# regression guard for the sort underneath it.
#
# quantile() orders the whole column before it interpolates, so the sort is
# the part of it that can go wrong silently: a broken ordering does not
# crash, it returns plausible numbers that are not the sample's order
# statistics.  This file therefore leans on the two assertions R's own suite
# makes about quantile -- both of which are really assertions about the sort
# -- and adds the input patterns that distinguish a correct quicksort from
# one that mispartitions.
#
# Provenance:
#
#   * R 4.6.1 tests/reg-tests-1a.R, the "## quantile" block: for a sample of
#     n values, quantile(x, probs = ((1:n)-1)/(n-1)) must return sort(x)
#     exactly, and for a tied sample quantile(x, p) must equal the type-7
#     interpolation (1-f)*ox[i] + f*ox[i+1] computed by hand off sort(x).
#     Both are reproduced as A and B below, over this build's own samples --
#     they are properties, not a value table, so they need no frozen numbers.
#   * R 4.6.1 tests/reg-tests-1d.R, PR#16672: quantile must be monotone in
#     prob.  Its x2 case, rep(-0.00090419678460984, 602), is reproduced
#     verbatim in C; 602 identical values is also the input that makes a
#     naive quicksort go quadratic, so it earns its place twice.
#   * R 4.6.1 stats::quantile() itself for the frozen tables in D and E,
#     generated at options(digits=17) by t/quantile.R.R, which is committed
#     next to this file; re-run that script to regenerate them.
#
# The samples are built from an exact 16-bit Lehmer generator rather than
# pasted in as decimals.  Every value is a multiple of 2**-16, so a
# long-double or __float128 perl reads back the very sample R saw, ties
# included -- and ties are exactly what decides where an order statistic
# lands.  sw_lcg() here and in t/quantile.R.R agree value for value.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR 'quantile';

# Import no_leaks_ok at compile time so its (&;$) prototype is in scope for
# the block-style calls at the end.  Absent module -> those tests skip.
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	};
}

# R's type 7 is a linear interpolation between two order statistics, so on
# the exact binary samples below every quantile is exactly representable and
# the agreement with R is exact.  The limit is not zero only because a
# long-double or __float128 perl carries the interpolation weight at a
# different width; 1e-15 is the measured worst case on this build (0) with
# room for those.  It was not widened to make anything pass.
my $TOL = 1e-15;

sub rel { my ($got, $want) = @_; return $want == 0 ? abs($got) : abs($got - $want) / abs($want) }

# The exact sample generator, mirroring sw_lcg() in t/quantile.R.R.
#
# 75 and 65537 are the classic 16-bit Lehmer pair: 75 * 65536 = 4915200, so
# every product stays an exact integer on any NV, and dividing by 65536 makes
# each draw an exact binary fraction.
sub sw_lcg {
	my ($n) = @_;
	my ($s, @u) = (12345);
	for (1 .. $n) {
		$s = (75 * $s + 74) % 65537;
		push @u, ($s % 65536) / 65536;
	}
	return \@u;
}

# The input shapes a quicksort can get wrong.  Sorted and reversed defeat a
# fixed-pivot choice; the organ pipe defeats median-of-three; two values and
# the tie ladder make almost every comparison equal, which is where a
# partition that does not stop on equals runs off the end; the sawtooth is
# many short ascending runs.
my %PATTERN = (
	plain    => sub { sw_lcg($_[0]) },
	sorted   => sub { [ sort { $a <=> $b } @{ sw_lcg($_[0]) } ] },
	reversed => sub { [ sort { $b <=> $a } @{ sw_lcg($_[0]) } ] },
	organ    => sub {
		my ($n) = @_;
		my @v = sort { $a <=> $b } @{ sw_lcg($n) };
		my (@odd, @even);
		for my $i (0 .. $#v) { $i % 2 ? push @even, $v[$i] : push @odd, $v[$i] }
		return [ @odd, reverse @even ];
	},
	ties     => sub { [ map { int($_ * 12) / 8 } @{ sw_lcg($_[0]) } ] },
	twovals  => sub { [ map { $_ < 0.5 ? 0 : 1 } @{ sw_lcg($_[0]) } ] },
	sawtooth => sub { my ($n) = @_; return [ map { ($_ % 32) / 32 } 1 .. $n ] },
);

# Every n either side of the two thresholds the sort switches on: 20, where
# a range stops being partitioned and finishes with an insertion sort, and
# the sizes big enough to drive the recursion to its 2*log2(n) depth limit
# and hand the rest to heapsort.
my @NS = (1, 2, 3, 19, 20, 21, 100, 999, 1000, 5000);

# A. R's reg-tests-1a.R: quantile at probs ((1:n)-1)/(n-1) is sort(x).  This
# is the strongest statement available about the ordering -- it checks every
# order statistic, not five of them -- so it runs over every pattern and
# every n.
#
# R's test asserts *exact* equality, and its comment says why: "the following
# is exact, because 1/(1001-1) is exact".  That is a claim about n = 1001, not
# about n in general.  Where i/(n-1) is not exact, 1 + (n-1)*p lands an ulp
# under the integer it should be, so the interpolation runs instead of being
# skipped and the answer comes back a little off the order statistic -- in R
# too, and to the same bits: at n = 100 both return 0.19151306152343753 where
# sort(x)[27] is 0.1915130615234375, and on a two-valued sample at n = 999
# both return 0.99999999999994316 for 1.  The exact form of the assertion is
# therefore made where R makes it -- n - 1 a power of two, plus R's own 1001
# -- and everywhere else the reference is R's type-7 formula itself, applied
# to the sample sorted by perl.  Either way what is under test is the
# ordering: every one of the n order statistics has to be in the right place
# for any of these to come out right.

# n - 1 a power of two: i/(n-1) is exact at any NV width, and so is
# (n-1) * that, so the index lands on the integer and no interpolation runs.
# R's own n = 1001 is exact too, but only on a double -- 1000 * (i/1000)
# rounds back to i at 53 bits and not at 64 or 113 -- so that one is claimed
# as exact only where R claims it, and checked to $TOL elsewhere.  Measured
# there: 1.7e-18 on the long-double perl, 3.5e-33 on the __float128 one.
use Config;
my %EXACT_N = map { $_ => 1 } (2, 3, 5, 9, 17, 33, 65, 129, 1025, 4097);
$EXACT_N{1001} = 1 if $Config{nvtype} eq 'double';

# R's type 7, transcribed from quantile.default: index = 1 + (n-1)*p, and the
# interpolation is skipped unless the index falls strictly between two order
# statistics that differ.
sub type7 {
	my ($sorted, $p) = @_;
	my $n = scalar @$sorted;
	return $sorted->[0] if $n == 1 || $p == 0;
	return $sorted->[$n - 1] if $p == 1;
	my $h = ($n - 1) * $p;
	my $j = int($h);
	my $g = $h - $j;
	return $sorted->[$j] if $g <= 0 || $sorted->[$j + 1] == $sorted->[$j];
	return (1 - $g) * $sorted->[$j] + $g * $sorted->[$j + 1];
}

# This section asks for n quantiles of an n-element sample, so it re-sorts
# n times: quadratic, and at n = 5000 that is a couple of seconds per pattern
# on a plain double build and far worse on a __float128 one.  The large sizes
# are still the ones that drive the recursion to its depth limit, so they run
# under EXTENDED_TESTING rather than being dropped; D and E cover n = 5000 on
# the default probs unconditionally.
my $EXTENDED = $ENV{EXTENDED_TESTING} || $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING};

for my $pat (sort keys %PATTERN) {
	for my $n (@NS, 17, 33, 1001, 1025, 4097) {
		next if $n < 2;		# ((1:n)-1)/(n-1) needs n >= 2
		next if $n > 1025 && !$EXTENDED;
		my $x = $PATTERN{$pat}->($n);
		my @sorted = sort { $a <=> $b } @$x;
		my $exact = $EXACT_N{$n};
		my ($bad, $worst) = (-1, 0);
		for my $i (0 .. $n - 1) {
			my $p = $i / ($n - 1);
			my $want = $exact ? $sorted[$i] : type7(\@sorted, $p);
			my $got = (values %{ quantile(x => $x, probs => [$p]) })[0];
			my $e = rel($got, $want);
			$worst = $e if $e > $worst;
			if ($bad < 0 && ($exact ? $got != $want : $e > $TOL)) { $bad = $i }
		}
		is($bad, -1, sprintf('A %s n=%d: %s (worst rel %.2g)', $pat, $n,
			$exact ? 'quantile is exactly every order statistic'
			       : 'quantile is R type 7 at every order statistic', $worst)
			. ($bad >= 0 ? " -- first wrong at $bad" : ''));
	}
}

# B. R's reg-tests-1a.R, second half: against the type-7 interpolation
# computed by hand off the sorted sample, on a tied sample.  R uses
# round(rnorm(777), 1) for the ties; the ladder below is the exact-binary
# equivalent, and the probs include both endpoints as R's do.
{
	my $n = 777;
	my $x = [ map { int($_ * 20) / 16 } @{ sw_lcg($n) } ];
	my @ox = sort { $a <=> $b } @$x;
	push @ox, $ox[$n - 1];		# ox[n+1] := ox[n], exactly as R's test does
	my @p = (0, 1, map { $_ / 512 } 1 .. 100);
	my $worst = 0;
	for my $p (@p) {
		my $r = 1 + ($n - 1) * $p;
		my $i = int($r);
		my $f = $r - $i;
		my $want = (1 - $f) * $ox[$i - 1] + $f * $ox[$i];
		my $got  = (values %{ quantile(x => $x, probs => [$p]) })[0];
		my $e = rel($got, $want);
		$worst = $e if $e > $worst;
	}
	ok($worst <= $TOL,
		sprintf('B tied n=777 matches the type-7 interpolation (worst rel %.2g)',
			$worst));
}

# C. R's reg-tests-1d.R PR#16672: quantile has to be monotone in prob.  The
# x2 sample is R's verbatim -- 602 copies of one value, which is both the
# regression case and the input a quicksort mispartitions on if it does not
# stop its scans on equal elements.
{
	my $x2 = [ (-0.00090419678460984) x 602 ];
	my @q = map { (values %{ quantile(x => $x2, probs => [ $_ / 5 ]) })[0] } 0 .. 5;
	is(scalar(grep { $_ == -0.00090419678460984 } @q), 6,
		'C PR#16672: 602 identical values give that value at every prob');

	for my $pat (sort keys %PATTERN) {
		my $x = $PATTERN{$pat}->(1000);
		my @q = map { (values %{ quantile(x => $x, probs => [ $_ / 40 ]) })[0] }
			0 .. 40;
		my $sorted = 1;
		for my $i (1 .. $#q) { $sorted = 0 if $q[$i] < $q[$i - 1] }
		ok($sorted, "C $pat: quantile is monotone in prob");
	}
}

#---------------------------------------------------------------------------
# D. R's own numbers for the five default quantiles, over every pattern and
# every n.  A is the ordering; this is the interpolation and the key naming
# on top of it.
#---------------------------------------------------------------------------
my @KEYS = ('0%', '25%', '50%', '75%', '100%');
my @DEFAULTS = (
	[ 'plain_1', [ 0.1286468505859375, 0.1286468505859375, 0.1286468505859375, 0.1286468505859375, 0.1286468505859375 ] ],
	[ 'plain_2', [ 0.1286468505859375, 0.25886154174804688, 0.38907623291015625, 0.51929092407226562, 0.649505615234375 ] ],
	[ 'plain_3', [ 0.1286468505859375, 0.38907623291015625, 0.649505615234375, 0.6814117431640625, 0.71331787109375 ] ],
	[ 'plain_19', [ 0.121978759765625, 0.26746368408203125, 0.4991607666015625, 0.69464874267578125, 0.9963836669921875 ] ],
	[ 'plain_20', [ 0.121978759765625, 0.29825973510742188, 0.47021484375, 0.68729782104492188, 0.9963836669921875 ] ],
	[ 'plain_21', [ 0.095794677734375, 0.20587158203125, 0.4412689208984375, 0.6799468994140625, 0.9963836669921875 ] ],
	[ 'plain_100', [ 0.0042572021484375, 0.17794036865234375, 0.43433380126953125, 0.683563232421875, 0.9963836669921875 ] ],
	[ 'plain_999', [ 0.000213623046875, 0.22661590576171875, 0.490203857421875, 0.7363739013671875, 0.9998016357421875 ] ],
	[ 'plain_1000', [ 0.000213623046875, 0.22688674926757812, 0.4904632568359375, 0.7368621826171875, 0.9998016357421875 ] ],
	[ 'plain_5000', [ 9.1552734375e-05, 0.24505996704101562, 0.49868011474609375, 0.748809814453125, 0.9999237060546875 ] ],
	[ 'sorted_1', [ 0.1286468505859375, 0.1286468505859375, 0.1286468505859375, 0.1286468505859375, 0.1286468505859375 ] ],
	[ 'sorted_2', [ 0.1286468505859375, 0.25886154174804688, 0.38907623291015625, 0.51929092407226562, 0.649505615234375 ] ],
	[ 'sorted_3', [ 0.1286468505859375, 0.38907623291015625, 0.649505615234375, 0.6814117431640625, 0.71331787109375 ] ],
	[ 'sorted_19', [ 0.121978759765625, 0.26746368408203125, 0.4991607666015625, 0.69464874267578125, 0.9963836669921875 ] ],
	[ 'sorted_20', [ 0.121978759765625, 0.29825973510742188, 0.47021484375, 0.68729782104492188, 0.9963836669921875 ] ],
	[ 'sorted_21', [ 0.095794677734375, 0.20587158203125, 0.4412689208984375, 0.6799468994140625, 0.9963836669921875 ] ],
	[ 'sorted_100', [ 0.0042572021484375, 0.17794036865234375, 0.43433380126953125, 0.683563232421875, 0.9963836669921875 ] ],
	[ 'sorted_999', [ 0.000213623046875, 0.22661590576171875, 0.490203857421875, 0.7363739013671875, 0.9998016357421875 ] ],
	[ 'sorted_1000', [ 0.000213623046875, 0.22688674926757812, 0.4904632568359375, 0.7368621826171875, 0.9998016357421875 ] ],
	[ 'sorted_5000', [ 9.1552734375e-05, 0.24505996704101562, 0.49868011474609375, 0.748809814453125, 0.9999237060546875 ] ],
	[ 'reversed_1', [ 0.1286468505859375, 0.1286468505859375, 0.1286468505859375, 0.1286468505859375, 0.1286468505859375 ] ],
	[ 'reversed_2', [ 0.1286468505859375, 0.25886154174804688, 0.38907623291015625, 0.51929092407226562, 0.649505615234375 ] ],
	[ 'reversed_3', [ 0.1286468505859375, 0.38907623291015625, 0.649505615234375, 0.6814117431640625, 0.71331787109375 ] ],
	[ 'reversed_19', [ 0.121978759765625, 0.26746368408203125, 0.4991607666015625, 0.69464874267578125, 0.9963836669921875 ] ],
	[ 'reversed_20', [ 0.121978759765625, 0.29825973510742188, 0.47021484375, 0.68729782104492188, 0.9963836669921875 ] ],
	[ 'reversed_21', [ 0.095794677734375, 0.20587158203125, 0.4412689208984375, 0.6799468994140625, 0.9963836669921875 ] ],
	[ 'reversed_100', [ 0.0042572021484375, 0.17794036865234375, 0.43433380126953125, 0.683563232421875, 0.9963836669921875 ] ],
	[ 'reversed_999', [ 0.000213623046875, 0.22661590576171875, 0.490203857421875, 0.7363739013671875, 0.9998016357421875 ] ],
	[ 'reversed_1000', [ 0.000213623046875, 0.22688674926757812, 0.4904632568359375, 0.7368621826171875, 0.9998016357421875 ] ],
	[ 'reversed_5000', [ 9.1552734375e-05, 0.24505996704101562, 0.49868011474609375, 0.748809814453125, 0.9999237060546875 ] ],
	[ 'organ_1', [ 0.1286468505859375, 0.1286468505859375, 0.1286468505859375, 0.1286468505859375, 0.1286468505859375 ] ],
	[ 'organ_2', [ 0.1286468505859375, 0.25886154174804688, 0.38907623291015625, 0.51929092407226562, 0.649505615234375 ] ],
	[ 'organ_3', [ 0.1286468505859375, 0.38907623291015625, 0.649505615234375, 0.6814117431640625, 0.71331787109375 ] ],
	[ 'organ_19', [ 0.121978759765625, 0.26746368408203125, 0.4991607666015625, 0.69464874267578125, 0.9963836669921875 ] ],
	[ 'organ_20', [ 0.121978759765625, 0.29825973510742188, 0.47021484375, 0.68729782104492188, 0.9963836669921875 ] ],
	[ 'organ_21', [ 0.095794677734375, 0.20587158203125, 0.4412689208984375, 0.6799468994140625, 0.9963836669921875 ] ],
	[ 'organ_100', [ 0.0042572021484375, 0.17794036865234375, 0.43433380126953125, 0.683563232421875, 0.9963836669921875 ] ],
	[ 'organ_999', [ 0.000213623046875, 0.22661590576171875, 0.490203857421875, 0.7363739013671875, 0.9998016357421875 ] ],
	[ 'organ_1000', [ 0.000213623046875, 0.22688674926757812, 0.4904632568359375, 0.7368621826171875, 0.9998016357421875 ] ],
	[ 'organ_5000', [ 9.1552734375e-05, 0.24505996704101562, 0.49868011474609375, 0.748809814453125, 0.9999237060546875 ] ],
	[ 'ties_1', [ 0.125, 0.125, 0.125, 0.125, 0.125 ] ],
	[ 'ties_2', [ 0.125, 0.3125, 0.5, 0.6875, 0.875 ] ],
	[ 'ties_3', [ 0.125, 0.5, 0.875, 0.9375, 1 ] ],
	[ 'ties_19', [ 0.125, 0.3125, 0.625, 1, 1.375 ] ],
	[ 'ties_20', [ 0.125, 0.34375, 0.625, 1, 1.375 ] ],
	[ 'ties_21', [ 0.125, 0.25, 0.625, 1, 1.375 ] ],
	[ 'ties_100', [ 0, 0.21875, 0.625, 1, 1.375 ] ],
	[ 'ties_999', [ 0, 0.25, 0.625, 1, 1.375 ] ],
	[ 'ties_1000', [ 0, 0.25, 0.625, 1, 1.375 ] ],
	[ 'ties_5000', [ 0, 0.25, 0.625, 1, 1.375 ] ],
	[ 'twovals_1', [ 0, 0, 0, 0, 0 ] ],
	[ 'twovals_2', [ 0, 0.25, 0.5, 0.75, 1 ] ],
	[ 'twovals_3', [ 0, 0.5, 1, 1, 1 ] ],
	[ 'twovals_19', [ 0, 0, 0, 1, 1 ] ],
	[ 'twovals_20', [ 0, 0, 0, 1, 1 ] ],
	[ 'twovals_21', [ 0, 0, 0, 1, 1 ] ],
	[ 'twovals_100', [ 0, 0, 0, 1, 1 ] ],
	[ 'twovals_999', [ 0, 0, 0, 1, 1 ] ],
	[ 'twovals_1000', [ 0, 0, 0, 1, 1 ] ],
	[ 'twovals_5000', [ 0, 0, 0, 1, 1 ] ],
	[ 'sawtooth_1', [ 0.03125, 0.03125, 0.03125, 0.03125, 0.03125 ] ],
	[ 'sawtooth_2', [ 0.03125, 0.0390625, 0.046875, 0.0546875, 0.0625 ] ],
	[ 'sawtooth_3', [ 0.03125, 0.046875, 0.0625, 0.078125, 0.09375 ] ],
	[ 'sawtooth_19', [ 0.03125, 0.171875, 0.3125, 0.453125, 0.59375 ] ],
	[ 'sawtooth_20', [ 0.03125, 0.1796875, 0.328125, 0.4765625, 0.625 ] ],
	[ 'sawtooth_21', [ 0.03125, 0.1875, 0.34375, 0.5, 0.65625 ] ],
	[ 'sawtooth_100', [ 0, 0.2109375, 0.46875, 0.71875, 0.96875 ] ],
	[ 'sawtooth_999', [ 0, 0.21875, 0.46875, 0.71875, 0.96875 ] ],
	[ 'sawtooth_1000', [ 0, 0.21875, 0.46875, 0.71875, 0.96875 ] ],
	[ 'sawtooth_5000', [ 0, 0.21875, 0.46875, 0.71875, 0.96875 ] ],
);

for my $c (@DEFAULTS) {
	my ($label, $want) = @$c;
	my ($pat, $n) = $label =~ /^([a-z]+)_(\d+)$/;
	my $r = quantile(x => $PATTERN{$pat}->($n));
	my $worst = 0;
	for my $i (0 .. 4) {
		my $e = rel($r->{ $KEYS[$i] }, $want->[$i]);
		$worst = $e if $e > $worst;
	}
	ok($worst <= $TOL, sprintf('D %s: the five defaults match R (worst rel %.2g)',
		$label, $worst));
}

#---------------------------------------------------------------------------
# E. R's numbers for a spread of non-default probs, including both endpoints
# and the ones that land between order statistics.  Each prob is requested on
# its own so the value is read back without depending on how the percentage
# is spelled in the key (R writes 1/3 as "33.33333%", this build as "33.3%").
#---------------------------------------------------------------------------
my @PR = (0, 0.001, 0.05, 1/3, 0.5, 0.666, 0.95, 0.999, 1);
my @PROBS = (
	[ 'probs_plain_7', [ 0.1286468505859375, 0.13050070190429688, 0.22133941650390626, 0.4991607666015625, 0.649505615234375, 0.67231744384765624, 0.78960266113281241, 0.82164227294921877, 0.822296142578125 ] ],
	[ 'probs_plain_100', [ 0.0042572021484375, 0.004610687255859375, 0.047402954101562506, 0.271636962890625, 0.43433380126953125, 0.61580871582031249, 0.92984390258789062, 0.99507546997070317, 0.9963836669921875 ] ],
	[ 'probs_plain_1000', [ 0.000213623046875, 0.00050325012207031253, 0.038879394531250007, 0.32080078125, 0.4904632568359375, 0.67149868774414068, 0.94659347534179683, 0.99887178039550784, 0.9998016357421875 ] ],
	[ 'probs_ties_7', [ 0.125, 0.128, 0.27500000000000002, 0.625, 0.875, 0.99950000000000006, 1.0874999999999999, 1.12425, 1.125 ] ],
	[ 'probs_ties_100', [ 0, 0, 0, 0.375, 0.625, 0.875, 1.375, 1.375, 1.375 ] ],
	[ 'probs_ties_1000', [ 0, 0, 0, 0.375, 0.625, 1, 1.375, 1.375, 1.375 ] ],
	[ 'probs_sawtooth_7', [ 0.03125, 0.0314375, 0.040625000000000001, 0.09375, 0.125, 0.15612500000000001, 0.20937499999999998, 0.21856249999999999, 0.21875 ] ],
	[ 'probs_sawtooth_100', [ 0, 0, 0.03125, 0.28125, 0.46875, 0.625, 0.9375, 0.96875, 0.96875 ] ],
	[ 'probs_sawtooth_1000', [ 0, 0, 0.03125, 0.3125, 0.46875, 0.65625, 0.9375, 0.96875, 0.96875 ] ],
);

for my $c (@PROBS) {
	my ($label, $want) = @$c;
	my ($pat, $n) = $label =~ /^probs_([a-z]+)_(\d+)$/;
	my $x = $PATTERN{$pat}->($n);
	my $worst = 0;
	for my $i (0 .. $#PR) {
		my $got = (values %{ quantile(x => $x, probs => [ $PR[$i] ]) })[0];
		my $e = rel($got, $want->[$i]);
		$worst = $e if $e > $worst;
	}
	ok($worst <= $TOL, sprintf('E %s: nine probs match R (worst rel %.2g)',
		$label, $worst));
}

#---------------------------------------------------------------------------
# F. The Perl-side surface: undef handling, the croaks, and the shapes that
# have to survive the sort without being ordered at all.
#---------------------------------------------------------------------------
{
	my $x = sw_lcg(50);
	my $clean = quantile(x => $x);
	my $holed = quantile(x => [ undef, @$x[0 .. 24], undef, @$x[25 .. 49], undef ]);
	is_deeply([ map { $holed->{$_} } @KEYS ], [ map { $clean->{$_} } @KEYS ],
		'F undef values are dropped, not ordered');
}

{	# +/-Inf orders like any other value; only NaN has no place in an ordering
	my $r = quantile(x => [ 9**9**9, -9**9**9, 0, 1, -1 ]);
	is($r->{'0%'},   -9**9**9, 'F -Inf sorts to the bottom');
	is($r->{'100%'},  9**9**9, 'F +Inf sorts to the top');
	is($r->{'50%'},   0,       'F and the finite middle is untouched');
}

{	# NaN cannot be placed by any comparison sort -- R refuses the input
	# outright ("missing values and NaN's not allowed if 'na.rm' is FALSE")
	# and this build has no na.rm, so what it returns is unspecified.  What
	# is pinned here is that it is still a well-formed answer: the sort keeps
	# the sample a permutation of itself and stays inside its own buffer, so
	# the call neither dies nor corrupts anything.  Fuzzed under ASan/UBSan
	# at the C level; this is the Perl-visible half of that guarantee.
	my $nan = 9**9**9 - 9**9**9;
	for my $n (5, 25, 300) {
		my @x = @{ sw_lcg($n) };
		$x[$_ * 3] = $nan for 0 .. int($n / 3) - 1;
		my $r = eval { quantile(x => \@x) };
		ok(!$@, "F NaN at n=$n does not die");
		is(scalar(keys %$r), 5, "F NaN at n=$n still returns five quantiles");
	}
}

{	# R's reg-tests-1d.R PR#17891:
	#   stopifnot( identical(quantile(0:1, 1+1e-14), c("100%" = 1)) )
	# A probability arrived at by arithmetic can land a hair outside [0, 1];
	# R clamps within 100*.Machine$double.eps of an endpoint rather than
	# refusing, and this build now does the same.  Anything further out is
	# still an error, as it is in R.
	my $r = quantile(x => [ 0, 1 ], probs => [ 1 + 1e-14 ]);
	is((values %$r)[0], 1, 'F PR#17891: probs just over 1 is clamped, not refused');
	$r = quantile(x => [ 0, 1 ], probs => [ -1e-14 ]);
	is((values %$r)[0], 0, 'F and just under 0 likewise');
	for my $p (1.001, -0.001, 2, -1) {
		eval { quantile(x => [ 0, 1 ], probs => [$p]) };
		like($@, qr/probabilities must be between 0 and 1/,
			"F probs = $p is still an error");
	}
}

{	# argument validation
	my @bad = (
		[ 'x missing',      sub { quantile(probs => [0.5]) },   qr/'x' must be an array reference/ ],
		[ 'x not a ref',    sub { quantile(x => 5) },           qr/'x' must be an array reference/ ],
		[ 'x a hashref',    sub { quantile(x => { a => 1 }) },  qr/'x' must be an array reference/ ],
		[ 'x empty',        sub { quantile(x => []) },          qr/'x' is empty/ ],
		[ 'x all undef',    sub { quantile(x => [ undef, undef ]) }, qr/no valid numbers/ ],
		[ 'unknown arg',    sub { quantile(x => [1,2], nope => 1) }, qr/unknown argument/ ],
	);
	for my $b (@bad) {
		my ($label, $code, $re) = @$b;
		eval { $code->() };
		like($@, $re, "F croaks on $label");
	}
}

SKIP: {
	skip 'Test::LeakTrace not installed', 3 unless $HAVE_LEAKTRACE;
	skip 'Devel::Cover perturbs refcounts', 3 if $INC{'Devel/Cover.pm'};
	no_leaks_ok { quantile(x => sw_lcg(200)) } 'no leaks on the default probs';
	no_leaks_ok { quantile(x => sw_lcg(200), probs => [ 0, 0.5, 1 ]) }
		'no leaks with explicit probs';
	no_leaks_ok { eval { quantile(x => []) } } 'no leaks on the croak path';
}

done_testing();
