#!/usr/bin/env perl
# cramers_v(), against R and SciPy.
#
# Provenance:
#   R 4.6.1 (values re-run on R 4.6.2, 2026-11-26): the tables of
#     src/library/stats/man/chisq.test.Rd \examples (Agresti 2007 p.39 party by
#     gender, "agresti"; the 12,5,7,7 matrix, "x2x2") and fisher.test.Rd
#     \examples (Convictions, Agresti 2002 p.57 Job satisfaction), and R's
#     datasets::mtcars (table(cyl, gear), and as two vectors).  The Rd's own
#     X-squared for Agresti is 30.07, df = 2.  t/cramers_v.R.scipy.R printed
#     chisq.test(correct = FALSE)'s statistic and the V built from it.
#   SciPy 1.18.1 / NumPy 2.4.6: scipy.stats.contingency.association(
#     method="cramer") and chi2_contingency(correction=False) on the same
#     tables (t/cramers_v.R.scipy.py), and scipy/stats/tests/test_contingency.py
#     ::test_assoc (obs1 -> 0.09222412010290792).  SciPy and R agree to the
#     last digit or two on every table here.
#   Bergsma 2013 (J. Korean Stat. Soc. 42:323-328): R has no implementation and
#     neither has SciPy, so "bias_corrected" is the paper's formula, written
#     out again in t/cramers_v.R.scipy.R apart from the module.  It is a
#     formula check, not an independent implementation's output.
# Re-run:  Rscript t/cramers_v.R.scipy.R ; python3 -I t/cramers_v.R.scipy.py
# This test never runs R or Python.
#
# Tolerance: this build (double) agrees with the frozen values to within a few ulp
# on every case (not measured further); 1e-12 relative leaves ~4500 double epsilons for
# long double and quadmath builds, which round differently.
#
# Deliberate differences:
#   - SciPy's association() takes a 2-d array only; the vector form
#     cramers_v(\@x, \@y) cross-tabulates, as R's table(x, y) does, with
#     levels in string order.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / lives_and
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $TOL = 1e-12; # relative; see header
sub near {
	my ($got, $want, $name) = @_;
	my $scale = abs($want) > 1 ? abs($want) : 1;
	my $ok = defined $got && abs($got - $want) <= $TOL * $scale;
	ok($ok, $name) or diag("got " . (defined $got ? $got : 'undef') . ", expected $want");
}

my %T = (
	agresti     => [[762, 327, 468], [484, 239, 477]],
	x2x2        => [[12, 7], [5, 7]],
	convictions => [[2, 15], [10, 3]],
	job         => [[1, 3, 10, 6], [2, 3, 10, 7], [1, 6, 14, 12], [0, 1, 9, 11]],
	scipy_obs1  => [[12, 13, 14, 15, 16], [17, 16, 18, 19, 11], [9, 15, 14, 12, 11]],
	mtcars      => [[1, 8, 2], [2, 4, 1], [12, 0, 2]],
	trivial     => [[1, 2], [1, 2]],
	perfect     => [[10, 0], [0, 10]],
	perfect3    => [[5, 0, 0], [0, 7, 0], [0, 0, 9]],
	small       => [[3, 1], [1, 3]],
	tall        => [[10, 20], [30, 40], [25, 5], [8, 12]],
);
# R 4.6.2 chisq.test(correct = FALSE) and V, Vc from t/cramers_v.R.scipy.R
my %E = (
	agresti      => { chisq => 30.070149095754672, df => 2, n => 2757, v => 0.10443580235646777, vc => 0.10091998278440886 },
	x2x2         => { chisq => 1.3716460268317854, df => 1, n => 31, v => 0.21034886742464717, vc => 0.10625268853474001 },
	convictions  => { chisq => 13.031674208144796, df => 1, n => 30, v => 0.65908204365730771, vc => 0.64357497809039044 },
	job          => { chisq => 5.9655145887704029, df => 9, n => 96, v => 0.14392217453234737, vc => 0 },
	scipy_obs1   => { chisq => 3.6062422513923686, df => 8, n => 212, v => 0.092224120102907925, vc => 0 },
	mtcars       => { chisq => 18.036363636363635, df => 4, n => 32, v => 0.53086550256932485, vc => 0.48196307042544084 },
	trivial      => { chisq => 0, df => 1, n => 6, v => 0, vc => 0 },
	perfect      => { chisq => 20, df => 1, n => 20, v => 1, vc => 1 },
	perfect3     => { chisq => 41.999999999999993, df => 4, n => 21, v => 0.99999999999999989, vc => 0.99999999999999989 },
	small        => { chisq => 2, df => 1, n => 8, v => 0.5, vc => 0.35355339059327379 },
	tall         => { chisq => 18.801941698223501, df => 3, n => 150, v => 0.35404276293712977, vc => 0.32545804956801605 },
);

for my $k (sort keys %T) {
	my $r = eval { cramers_v($T{$k}) };
	if (!$r) { fail("$k: cramers_v died: $@") for 1 .. 5; next }
	my $e = $E{$k};
	near($r->{estimate},       $e->{v},     "$k: estimate (V)");
	near($r->{bias_corrected}, $e->{vc},    "$k: bias_corrected (Bergsma)");
	near($r->{chisq},          $e->{chisq}, "$k: chisq is the uncorrected Pearson statistic");
	is($r->{df}, $e->{df}, "$k: df");
	is($r->{n},  $e->{n},  "$k: n");
}

# mtcars as two vectors: R table(mtcars$cyl, mtcars$gear)
{
	my @cyl  = (6, 6, 4, 6, 8, 6, 8, 4, 4, 6, 6, 8, 8, 8, 8, 8, 8, 4, 4, 4, 4, 8, 8, 8, 8, 4, 4, 4, 8, 6, 8, 4);
	my @gear = (4, 4, 4, 3, 3, 3, 3, 4, 4, 4, 4, 3, 3, 3, 3, 3, 3, 4, 4, 4, 3, 3, 3, 3, 3, 4, 5, 5, 5, 5, 5, 4);
	lives_and {
		my $r = cramers_v(\@cyl, \@gear);
		near($r->{estimate}, $E{mtcars}{v}, 'mtcars vectors: V as for the table');
	} 'mtcars vectors: lives';
	lives_and {
		my $r = cramers_v(\@gear, \@cyl);
		near($r->{estimate}, $E{mtcars}{v}, 'mtcars vectors swapped: V is symmetric');
	} 'mtcars vectors swapped: lives';
	lives_and {
		my @g = @gear; $g[3] = undef;
		my @c = @cyl;
		my $r = cramers_v(\@c, \@g);
		is($r->{n}, 31, 'an undef in one vector drops that pair');
	} 'undef pair: lives';
}

# transposition leaves V alone (SciPy association is symmetric)
for my $k (qw(agresti job tall)) {
	my $t = $T{$k};
	my @tt = map { my $j = $_; [ map { $_->[$j] } @$t ] } 0 .. $#{ $t->[0] };
	lives_and { near(cramers_v(\@tt)->{estimate}, $E{$k}{v}, "$k transposed: V") } "$k transposed: lives";
}

# SciPy test_bad_association_args: a negative count is refused
throws_ok { cramers_v([[-1, 10], [1, 2]]) } qr/non-negative/, 'SciPy test_bad_association_args: negative count dies';
throws_ok { cramers_v([[1, 2]]) } qr/at least two rows/, 'one row dies (SciPy requires 2-d)';
throws_ok { cramers_v([[1], [2]]) } qr/at least two/, 'one column dies';
throws_ok { cramers_v([[1, 2], [3]]) } qr/ragged/, 'ragged table dies';
throws_ok { cramers_v([[0, 0], [0, 0]]) } qr/total is zero/, 'all-zero table dies';

my $agr = $T{agresti};
no_leaks_ok { cramers_v($agr) } 'cramers_v table does not leak' unless $INC{'Devel/Cover.pm'};

done_testing();
