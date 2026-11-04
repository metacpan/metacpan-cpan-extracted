#!/usr/bin/env perl
#
# predict() on terms and factor levels longer than the fixed buffers it used to
# copy them into.
#
# Provenance: there is no R or SciPy counterpart (neither limits a term's
# length), so the oracle is this module's own lm(): predict() on the fitting
# data must reproduce lm()'s fitted_values, which R's predict.lm() does too
# (stats::predict.lm with newdata = the fitting frame).  The audit of 2026-11-03
# found that an interaction term was copied into a 512-byte buffer to test
# whether any component is a factor, so a factor component that began past byte
# 511 was cut off, the term was taken for a continuous one, and every row
# predicted NaN.  The unseen-level croak copied the factor name and the level
# into 256-byte buffers, truncating the message.  Both lived up to 0.3413.
#
# Tolerance: the worst difference observed against fitted_values is 2.2e-15 on
# a double build; 1e-9 leaves room for long-double and quadmath builds without
# being loose enough to hide a wrong term (the factor effects here are 3 and 4).

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(lm predict);

my $TOL = 1e-9;
srand(5);

for my $len (10, 255, 256, 300, 511, 512, 600, 1200) {
	my $xn = 'x' x $len;     # numeric column with a long name
	my $lv = 'L' x $len;     # factor level with a long name
	my (@x, @f, @y);
	for my $i (0 .. 59) {
		my $x = rand();
		my $f = ('a', $lv, 'c')[$i % 3];
		push @x, $x;
		push @f, $f;
		push @y, 1 + 2 * $x + ($f eq $lv ? 3 : 0) + ($f eq 'c' ? -1 : 0)
		       + ($f eq $lv ? 4 * $x : 0) + rand() * 0.1;
	}
	my %d = (y => \@y, $xn => \@x, f => \@f);
	for my $form ("y ~ $xn * f", "y ~ f * $xn", 'y ~ f') {
		my $label = sprintf 'len %d, %s', $len, length($form) > 30 ? substr($form, 0, 12) . '...' : $form;
		my $fit = lm(formula => $form, data => \%d);
		my $p = predict($fit, \%d);
		my $fv = $fit->{fitted_values};
		my $bad = 0;
		for my $k (keys %$fv) {
			my ($a, $b) = ($p->{$k}, $fv->{$k});
			$bad++ unless defined $a && $a == $a && abs($a - $b) <= $TOL;
		}
		is($bad, 0, "$label: predict() reproduces fitted_values");
	}
	my $fit = lm(formula => 'y ~ f', data => \%d);
	my %nd = (f => ['z' x $len]);
	eval { predict($fit, \%nd) };
	like($@, qr/factor 'f' has unseen level '\Q@{[ 'z' x $len ]}\E'/,
	     "len $len: the unseen-level message names the whole level");
}

done_testing();
