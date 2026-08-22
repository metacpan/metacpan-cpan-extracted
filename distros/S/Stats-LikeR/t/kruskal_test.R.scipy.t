#!/usr/bin/env perl
#
# Cross-validation of kruskal_test() against the two reference implementations,
# using their own test suites and man-page examples rather than cases invented
# here.  There is no hand-written t/kruskal_test.t; the only other coverage is
# six assertions in t/01.t on the single Hollander & Wolfe example, so this file
# also carries the call-form, return-field, croak and leak checks that would
# normally live there.
#
# Provenance of every expected value below:
#
#   * R 4.6.1 stats::kruskal.test() -- the function kruskal_test() is modelled
#     on.  The whole @CORPUS table was generated from it at options(digits=17)
#     by t/kruskal_test.R.scipy.R, which is committed next to this file; see the
#     comment at the top of it for how to re-run.  This file never invokes the
#     generator: the frozen literals are what gets tested, so the suite passes
#     on a machine with no R and no Python.
#   * R's man page src/library/stats/man/kruskal.test.Rd: the Hollander & Wolfe
#     (1973) p.116 mucociliary-efficiency example and the airquality
#     Ozone ~ Month example, whose printed output is pinned in
#     tests/Examples/stats-Ex.Rout.save ("chi-squared = 0.77143, df = 2,
#     p-value = 0.68" and "chi-squared = 29.267, df = 4, p-value = 6.901e-06").
#   * R's own suite: tests/reg-tests-1d.R, "kruskal.test(<non-numeric g>),
#     PR#16719" -- mtcars mpg by a two-level character grouping, which gave
#     'Error: all group levels must be finite' in R <= 3.5.1.
#   * SciPy 1.18.0 scipy/stats/tests/test_stats.py::TestKruskal -- test_simple,
#     test_array_like, test_basic, test_simple_tie, test_another_tie,
#     test_three_groups, test_empty.  SciPy states those statistics
#     analytically in the test bodies (it writes out h_uncorr and the tie
#     correction by hand), so they pin the tie adjustment independently of R,
#     and both references agree with @CORPUS on all five.
#
# Where R and SciPy disagree with each other -- an empty group, and a sample
# with no variation at all -- the divergence is recorded explicitly in
# "reference divergences" at the end of this file rather than papered over, so
# that changing sides later is a deliberate act.
#
# Six sections are regression guards for bugs this file turned up.  All are
# fixed; see the comments at @CORPUS "NaN dropped", @NUL_LABELS, @UTF8_LABELS,
# @CROAKS "all groups must contain data", @BAD_ARGS "odd number of named
# arguments", and the all-equal-at-large-n section, which guards get_p_value()
# rather than the statistic.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR 'kruskal_test';
use Test::LeakTrace 'no_leaks_ok';

# ---------------------------------------------------------------------------
# Tolerances.
#
# The Kruskal-Wallis statistic is a function of the ranks alone, so on this
# build H is bit-identical to R on all 37 corpus cases in all four call forms:
# worst disagreement exactly 0, and it stays 0 across 60 runs under
# PERL_PERTURB_KEYS=1.  That second part is not free -- both the rank sums and
# the sum(R^2/n) over groups had to be put in an order that does not depend on
# which order perl happened to iterate a hash in, or the answer moved by up to
# 1.2e-14 between runs on identical data.
#
# So the limit below is not sized off an observed disagreement with R; it is
# sized off the gap between NV widths.  The frozen expectations are R's
# doubles, and a long-double or __float128 build computes a more accurate H
# that can differ from the frozen double by an ulp of double, about 1.1e-16
# relative.  1e-13 leaves that three orders of headroom.
#
# The worst p disagreement is 3.26e-15 relative (SciPy's test_another_tie),
# out of the incomplete-gamma tail rather than out of kruskal_test().  igamc()'s
# convergence thresholds are hardcoded at 1e-15 regardless of NV width, so a
# wider build does not do better than that; 1e-12 leaves two and a half orders.
#
# Do not widen these to make a failure go away.  An H that has moved by more
# than a few ulps means the ranks changed, which is a bug and not a rounding
# question.
my $TOL_H = 1e-13;
my $TOL_P = 1e-12;

# H is a difference of two O(n) quantities -- 12*sum(R^2/n)/(N(N+1)) minus
# 3(N+1) -- so when it cancels to near zero its error is set by the magnitudes
# that cancelled, not by the result, and a relative limit would be demanding
# accuracy the formula does not have.  Hence relative above 1, absolute below.
# A p-value is always in (0, 1] and the whole point of the far-tail cases is
# its relative accuracy there (airquality's p is 6.9e-06), so p is compared
# relatively throughout.
sub close_to {
	my ($got, $want, $tol, $name) = @_;
	if (!defined $got) { fail("$name (undef)"); return }
	# NaN is a legitimate expected value here (a sample with no variation at
	# all gives 0/0), and it has to be compared as NaN, not as a number.
	if ($want eq 'NaN') { ok($got != $got, "$name is NaN"); return }
	my $den = $tol == $TOL_P ? ($want != 0 ? abs($want) : 1)
	                         : (abs($want) > 1 ? abs($want) : 1);
	my $err = abs($got - $want) / $den;
	ok($err <= $tol, $name) or diag(sprintf("got %.17g want %.17g err %.3g", $got, $want, $err));
	return $err;
}

# ---------------------------------------------------------------------------
# @CORPUS: [ label, [ group, group, ... ], H, df, p ]
#
# Generated by t/kruskal_test.R.scipy.R from R 4.6.1 at options(digits=17).
# NA became undef and NaN / +-Inf became the strings perl's
# looks_like_number() accepts, which is also the form a caller reading a CSV
# hands over.
#
# Every datum in the "sweep" cases is an integer or a dyadic fraction
# (quarters and halves), so which observations tie is identical on a double, a
# long-double and a __float128 build.  That matters more here than the values
# themselves: H depends only on the ranks, so any order-preserving change to
# the data leaves H alone -- but a decimal like 0.1 that collides with another
# literal at one NV width need not collide at the next, and a tie appearing or
# disappearing does move H.  The reference examples keep R's own decimals, and
# their ties are all between repetitions of one literal (mtcars has 21, 22.8,
# 10.4, 30.4, 15.2, 19.2 and 21.4 twice each), which parse identically at any
# width.
#
# The four "NaN dropped" / "NA dropped" cases are regression guards.
# looks_like_number() is true for NaN, so NaN used to be ranked instead of
# dropped: R treats NaN as NA and complete.cases() removes it, and ranking it
# gave H = 4.5 where R gives 3.8571428571428577 on one NaN among six values.
# It also handed cmp_nv3() a comparison that is never true for every NaN pair,
# leaving qsort() without the strict weak ordering it is entitled to.  +-Inf is
# neither NA nor NaN to R and a rank test has no trouble with it, so the
# "+Inf kept" and "-Inf and +Inf" cases pin that it is *not* dropped.
my @CORPUS = (
	[ 'HW1973 mucociliary', [[2.8999999999999999, 3, 2.5, 2.6000000000000001, 3.2000000000000002], [3.7999999999999998, 2.7000000000000002, 4, 2.3999999999999999], [2.7999999999999998, 3.3999999999999999, 3.7000000000000002, 2.2000000000000002, 2]],
	  0.77142857142857224, 2, 0.67996477357889362 ],
	[ 'airquality Ozone by Month', [[41, 36, 12, 18, 28, 23, 19, 8, 7, 16, 11, 14, 18, 14, 34, 6, 30, 11, 1, 11, 4, 32, 23, 45, 115, 37], [29, 71, 39, 23, 21, 37, 20, 12, 13], [135, 49, 32, 64, 40, 77, 97, 97, 85, 10, 27, 7, 48, 35, 61, 79, 63, 16, 80, 108, 20, 52, 82, 50, 64, 59], [39, 9, 16, 78, 35, 66, 122, 89, 110, 44, 28, 65, 22, 59, 23, 31, 44, 21, 9, 45, 168, 73, 76, 118, 84, 85], [96, 78, 73, 91, 47, 32, 20, 23, 21, 24, 44, 21, 28, 9, 13, 46, 18, 13, 24, 16, 13, 23, 36, 7, 14, 30, 14, 18, 20]],
	  29.266576306116939, 4, 6.9007141185467839e-06 ],
	[ 'mtcars mpg by type PR#16719', [[21, 21, 22.800000000000001, 21.399999999999999, 18.699999999999999, 18.100000000000001, 14.300000000000001, 24.399999999999999, 22.800000000000001, 19.199999999999999, 17.800000000000001, 16.399999999999999, 17.300000000000001, 15.199999999999999, 10.4, 10.4], [14.699999999999999, 32.399999999999999, 30.399999999999999, 33.899999999999999, 21.5, 15.5, 15.199999999999999, 13.300000000000001, 19.199999999999999, 27.300000000000001, 26, 30.399999999999999, 15.800000000000001, 19.699999999999999, 15, 21.399999999999999]],
	  1.5022825289043824, 1, 0.22032049132551584 ],
	[ 'scipy test_array_like/test_simple', [[1], [2]],
	  1, 1, 0.31731050786291415 ],
	[ 'scipy test_basic', [[1, 3, 5, 7, 9], [2, 4, 6, 8, 10]],
	  0.27272727272727337, 1, 0.60150813444058937 ],
	[ 'scipy test_simple_tie', [[1], [1, 2]],
	  0.5, 1, 0.47950012218695348 ],
	[ 'scipy test_another_tie', [[1, 1, 1, 2], [2, 2, 2, 2]],
	  4.2000000000000002, 1, 0.040423979336908653 ],
	[ 'scipy test_three_groups', [[1, 1, 1], [2, 2, 2], [2, 2]],
	  7, 2, 0.030197383422318501 ],
	[ 'sweep k=2 variant=1', [[0, 0.25], [0.5, 0.75, 1]],
	  3, 1, 0.083264516663550558 ],
	[ 'sweep k=2 variant=2', [[0, 0.25, 0.5], [0.75, 0, 0.25, 0.5]],
	  0.29716981132075471, 1, 0.58566215904590946 ],
	[ 'sweep k=2 variant=3', [[0, 0.25, 2.5, 2.5], [2.5, 2.5, 2.5, 2.5, 2.5]],
	  2.8125, 1, 0.093532512689093072 ],
	[ 'sweep k=2 variant=4', [[0, 0.5, 0, 0.5, 0], [0.5, 0, 0.5, 0, 0.5, 0]],
	  0.099999999999994316, 1, 0.75182963404585601 ],
	[ 'sweep k=3 variant=1', [[0, 0.25], [0.5, 0.75, 1], [1.25, 1.5, 1.75, 2]],
	  7, 2, 0.030197383422318501 ],
	[ 'sweep k=3 variant=2', [[0, 0.25, 0.5], [0.75, 0, 0.25, 0.5], [0.75, 0, 0.25, 0.5, 0.75]],
	  0.8799999999999969, 2, 0.64403642108314241 ],
	[ 'sweep k=3 variant=3', [[0, 0.25, 2.5, 2.5], [2.5, 2.5, 2.5, 2.5, 2.5], [2.5, 2.5, 2.5, 2.5, 2.5, 2.5]],
	  5.8928571428571432, 2, 0.052526967666556852 ],
	[ 'sweep k=3 variant=4', [[0, 0.5, 0, 0.5, 0], [0.5, 0, 0.5, 0, 0.5, 0], [0.5, 0, 0.5, 0, 0.5, 0, 0.5]],
	  0.32380952380952466, 2, 0.85052220279766366 ],
	[ 'sweep k=4 variant=1', [[0, 0.25], [0.5, 0.75, 1], [1.25, 1.5, 1.75, 2], [2.25, 2.5, 2.75, 3, 3.25]],
	  12, 3, 0.0073831605053597711 ],
	[ 'sweep k=4 variant=2', [[0, 0.25, 0.5], [0.75, 0, 0.25, 0.5], [0.75, 0, 0.25, 0.5, 0.75], [0, 0.25, 0.5, 0.75, 0, 0.25]],
	  1.1794646131279873, 3, 0.75793364113236128 ],
	[ 'sweep k=4 variant=3', [[0, 0.25, 2.5, 2.5], [2.5, 2.5, 2.5, 2.5, 2.5], [2.5, 2.5, 2.5, 2.5, 2.5, 2.5], [2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5]],
	  9.4285714285714057, 3, 0.024103508103438677 ],
	[ 'sweep k=4 variant=4', [[0, 0.5, 0, 0.5, 0], [0.5, 0, 0.5, 0, 0.5, 0], [0.5, 0, 0.5, 0, 0.5, 0, 0.5], [0, 0.5, 0, 0.5, 0, 0.5, 0, 0.5]],
	  0.32967032967033799, 3, 0.95435503403621058 ],
	[ 'sweep k=5 variant=1', [[0, 0.25], [0.5, 0.75, 1], [1.25, 1.5, 1.75, 2], [2.25, 2.5, 2.75, 3, 3.25], [3.5, 3.75, 4, 4.25, 4.5, 4.75]],
	  18, 4, 0.0012340980408667955 ],
	[ 'sweep k=5 variant=2', [[0, 0.25, 0.5], [0.75, 0, 0.25, 0.5], [0.75, 0, 0.25, 0.5, 0.75], [0, 0.25, 0.5, 0.75, 0, 0.25], [0.5, 0.75, 0, 0.25, 0.5, 0.75, 0]],
	  1.3202249165348761, 4, 0.85793485216947585 ],
	[ 'sweep k=5 variant=3', [[0, 0.25, 2.5, 2.5], [2.5, 2.5, 2.5, 2.5, 2.5], [2.5, 2.5, 2.5, 2.5, 2.5, 2.5], [2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5], [2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5, 2.5]],
	  13.448275862068961, 4, 0.0092809839457676149 ],
	[ 'sweep k=5 variant=4', [[0, 0.5, 0, 0.5, 0], [0.5, 0, 0.5, 0, 0.5, 0], [0.5, 0, 0.5, 0, 0.5, 0, 0.5], [0, 0.5, 0, 0.5, 0, 0.5, 0, 0.5], [0, 0.5, 0, 0.5, 0, 0.5, 0, 0.5, 0]],
	  0.41358024691358725, 4, 0.98135002452030062 ],
	[ 'k=2 n=2 minimum', [[0], [1]],
	  1, 1, 0.31731050786291415 ],
	[ 'k=2 n=2 tied', [[1], [1]],
	  'NaN', 1, 'NaN' ],
	[ 'all identical k=3', [[2, 2], [2, 2], [2, 2]],
	  'NaN', 2, 'NaN' ],
	[ 'one group of one', [[0.5], [1, 1.5, 2, 2.5]],
	  2, 1, 0.15729920705028447 ],
	[ 'two levels perfectly separated', [[0, 0, 0, 0, 0, 0], [1, 1, 1, 1, 1, 1]],
	  11, 1, 0.00091111887715371223 ],
	[ '+Inf kept, R drops only NA/NaN', [[1, 2, 'Inf'], [4, 5, 6]],
	  0.42857142857142705, 1, 0.51269076026192406 ],
	[ '-Inf and +Inf', [['-Inf', 0, 'Inf'], [1, 2, 3]],
	  0.42857142857142705, 1, 0.51269076026192406 ],
	[ 'large magnitudes', [[4503599627370496, 4503599627370498, 9.0949470177292824e-13], [-4503599627370496, 1, 9.0949470177292824e-13]],
	  1.7647058823529422, 1, 0.18403862719642533 ],
	[ 'negative values', [[-4, -2, -1], [-8, -16, -32]],
	  3.8571428571428577, 1, 0.04953461343562679 ],
	[ 'NaN dropped (k=2)', [[1, 2, 'NaN'], [4, 5, 6]],
	  3, 1, 0.083264516663550558 ],
	[ 'NA dropped (k=2)', [[1, 2, undef], [4, 5, 6]],
	  3, 1, 0.083264516663550558 ],
	[ 'NaN dropped (k=3, ties)', [[1, 1, 'NaN'], [2, 2, 2], [2, 2, undef]],
	  6, 2, 0.049787068367863944 ],
	[ 'many ties k=4', [[1, 1, 1, 1, 1], [2, 2, 2, 2, 2], [1, 1, 1, 1, 1], [2, 2, 2, 2, 2]],
	  19.000000000000011, 3, 0.00027339888749079944 ],
);
is(scalar @CORPUS, 37, 'corpus is the expected size (generator ran to completion)');

# Each corpus case is run through all three documented call forms.  The
# hash-of-arrays form is the one R's list interface corresponds to; the x/g
# pair and the named-argument form both go down the other input path, which
# has its own group-id mapping and its own NA filter.
for my $c (@CORPUS) {
	my ($label, $groups, $H, $df, $P) = @$c;

	my (%h, @x, @g);
	for my $i (0 .. $#$groups) {
		my $name = "g$i";
		$h{$name} = [ @{ $groups->[$i] } ];
		push @x, @{ $groups->[$i] };
		push @g, ($name) x scalar @{ $groups->[$i] };
	}

	my @forms = (
		[ 'hashref'   => sub { kruskal_test(\%h) } ],
		[ 'x/g pair'  => sub { kruskal_test(\@x, \@g) } ],
		[ 'named x/g' => sub { kruskal_test(x => \@x, g => \@g) } ],
		[ 'named h'   => sub { kruskal_test(h => \%h) } ],
	);
	for my $f (@forms) {
		my ($form, $call) = @$f;
		my $r = $call->();
		close_to($r->{statistic}, $H, $TOL_H, "$label [$form]: statistic");
		is($r->{parameter}, $df, "$label [$form]: parameter (df)");
		close_to($r->{p_value}, $P, $TOL_P, "$label [$form]: p_value");
		# p.value is documented alongside p_value, for callers porting R code.
		close_to($r->{'p.value'}, $P, $TOL_P, "$label [$form]: p.value");
		is($r->{method}, 'Kruskal-Wallis rank sum test', "$label [$form]: method");
	}
}

# ---------------------------------------------------------------------------
# group_stats: the per-group sizes and means kruskal_test() returns on top of
# R's htest fields.  R reports neither, so there is nothing upstream to pin
# them against; what is checked here is that they agree with the input after
# the same NA/NaN filtering the statistic used, which is the property that
# makes them useful.
{
	my %h = ('normal.subjects'     => [2.9, 3.0, 2.5, 2.6, 3.2],
	         'obs. airway disease' => [3.8, 2.7, 4.0, 2.4],
	         'asbestosis'          => [2.8, 3.4, 3.7, 2.2, 2.0]);
	my $r  = kruskal_test(\%h);
	my $gs = $r->{group_stats};
	ok(defined $gs, 'group_stats is defined');
	is_deeply([sort keys %$gs], ['mean', 'size'], 'group_stats has mean and size');
	is_deeply([sort keys %{ $gs->{size} }], [sort keys %h], 'group_stats keys are the caller labels');
	for my $name (sort keys %h) {
		my @v = @{ $h{$name} };
		my $s = 0; $s += $_ for @v;
		is($gs->{size}{$name}, scalar @v, "group_stats size: $name");
		close_to($gs->{mean}{$name}, $s / @v, $TOL_H, "group_stats mean: $name");
	}

	# undef, NaN and non-numeric values are dropped from the group means and
	# sizes too, not just from the ranking.
	my $r2 = kruskal_test({ a => [1, 2, undef, 'NaN', 'not a number', 3],
	                        b => [10, 20, 30] });
	is($r2->{group_stats}{size}{a}, 3, 'group_stats size skips undef/NaN/non-numeric');
	close_to($r2->{group_stats}{mean}{a}, 2, $TOL_H, 'group_stats mean skips undef/NaN/non-numeric');
	# +-Inf is kept, so the mean of a group holding one is infinite.
	my $r3 = kruskal_test({ a => [1, 2, 'Inf'], b => [10, 20, 30] });
	is($r3->{group_stats}{size}{a}, 3, 'group_stats size keeps Inf');
	is($r3->{group_stats}{mean}{a}, 9**9**9, 'group_stats mean is Inf when the group holds one');
}

# ---------------------------------------------------------------------------
# @NUL_LABELS: regression guard.  The x/g path read the group label with
# SvPV_nolen() and then took strlen() of it, so a label was truncated at the
# first NUL byte: "a\0X" and "a\0Y" collapsed into one group, which deflated
# the degrees of freedom (df = 1, H = 2.4 for what is really a three-group
# problem).  Perl strings are counted, not NUL-terminated, so this is a
# perfectly ordinary label to hand over -- it is what you get from a packed
# key or a fixed-width field.
{
	my @x = (1, 2, 3, 4, 5, 6);
	my @g = ("a\0X", "a\0X", "a\0Y", "a\0Y", "b", "b");
	my $r = kruskal_test(\@x, \@g);
	is($r->{parameter}, 2, 'NUL in a group label: three distinct groups, df = 2');
	is_deeply([sort keys %{ $r->{group_stats}{size} }], ["a\0X", "a\0Y", 'b'],
	          'NUL in a group label: labels round-trip whole');
	# R, given the same three levels, agrees on the statistic and the p-value:
	# kruskal.test(list(c(1,2), c(3,4), c(5,6))) in R 4.6.1 at digits=17.
	close_to($r->{statistic}, 4.571428571428573,  $TOL_H, 'NUL in a group label: statistic');
	close_to($r->{p_value},   0.10170139230422676, $TOL_P, 'NUL in a group label: p_value');
}

# ---------------------------------------------------------------------------
# @UTF8_LABELS: regression guard.  Both input paths copied the label's bytes
# but dropped perl's UTF-8 flag when storing it into group_stats, so a label
# outside latin-1 came back as mojibake, and the two paths disagreed with each
# other about labels inside latin-1.  hv_store() takes the flag in the sign of
# the key length; these cases pin that a label comes back eq to what went in.
{
	my $latin1 = "gro\x{e9}pe";        # inside latin-1: perl may store it either way
	my $wide   = "\x{1f600}\x{4e2d}";  # outside latin-1: must stay wide
	for my $label ($latin1, $wide) {
		my $r = kruskal_test({ $label => [1, 2, 3], other => [4, 5, 6] });
		ok(exists $r->{group_stats}{size}{$label},
		   sprintf('hashref path: label U+%04X... round-trips', ord $label));
		my $r2 = kruskal_test([1, 2, 3, 4, 5, 6],
		                      [$label, $label, $label, 'other', 'other', 'other']);
		ok(exists $r2->{group_stats}{size}{$label},
		   sprintf('x/g path: label U+%04X... round-trips', ord $label));
		is($r2->{parameter}, 1, sprintf('x/g path: label U+%04X... is one group', ord $label));
	}
}

# ---------------------------------------------------------------------------
# @CROAKS: the refusals, and R's own order of checks.
#
# R's list interface filters each group's NAs, refuses an empty group, and
# only then counts what is left, so list(numeric(0), numeric(0)) is "all
# groups must contain data" to R and not "not enough observations".  The
# "all groups must contain data" cases are a regression guard: an empty hash
# value used to be counted in k anyway, which inflated the degrees of freedom.
# On { a => [1,1,1], b => [2,2,2], c => [] } that turned the correct df = 1,
# p = 0.025347318677468304 into df = 2, p = 0.082084998623898800.  SciPy takes
# the other side of this one and returns NaN; see "reference divergences".
#
# The x/g path cannot produce an empty group -- it mints a group id the first
# time an observation survives the filter -- so only the hash-of-arrays path
# can reach that message.
my @CROAKS = (
	[ 'empty group among two good ones', qr/^all groups must contain data/,
	  sub { kruskal_test({ a => [1,1,1], b => [2,2,2], c => [] }) } ],
	[ 'every group empty',               qr/^all groups must contain data/,
	  sub { kruskal_test({ a => [], b => [] }) } ],
	[ 'group emptied by dropping NaN',   qr/^all groups must contain data/,
	  sub { kruskal_test({ a => ['NaN'], b => [1,2] }) } ],
	[ 'group emptied by dropping undef', qr/^all groups must contain data/,
	  sub { kruskal_test({ a => [undef, undef], b => [1,2] }) } ],
	[ 'group with only non-numerics',    qr/^all groups must contain data/,
	  sub { kruskal_test({ a => ['x','y'], b => [1,2] }) } ],
	[ 'one group, hashref',              qr/^all observations are in the same group/,
	  sub { kruskal_test({ a => [1,2,3] }) } ],
	[ 'one group, x/g',                  qr/^all observations are in the same group/,
	  sub { kruskal_test([1,2,3], [qw(a a a)]) } ],
	[ 'nothing numeric, x/g',            qr/^not enough observations/,
	  sub { kruskal_test([qw(x y z)], [qw(a a b)]) } ],
	[ 'one usable observation, x/g',     qr/^not enough observations/,
	  sub { kruskal_test([1, undef, 'NaN'], [qw(a b c)]) } ],
);
for my $c (@CROAKS) {
	my ($label, $re, $call) = @$c;
	my $r = eval { $call->(); 1 };
	ok(!$r, "croaks: $label");
	like($@, $re, "croak message: $label");
}

# ---------------------------------------------------------------------------
# @BAD_ARGS: argument validation.
#
# The "odd number of named arguments" case is a regression guard.  The
# named-argument loop read ST(arg_idx + 1) unconditionally, so a stray trailing
# key read one slot past the argument stack -- and the garbage found there
# changed which branch ran: kruskal_test(\%h, 'x') came back complaining that
# 'h' cannot be mixed with 'x'/'g', because x_sv had been assigned whatever was
# past the top of the stack.  Every sibling that takes named arguments guards
# the same way (binom_test, chisq_test, fisher_test, wilcox_test, var_test,
# prcomp).
my @BAD_ARGS = (
	[ 'unknown named argument',       qr/^kruskal_test: unknown argument 'bogus'/,
	  sub { kruskal_test([1,2,3], [1,1,2], bogus => 1) } ],
	[ 'h mixed with x',               qr/^kruskal_test: cannot mix 'h'/,
	  sub { kruskal_test(h => { a => [1,2] }, x => [1,2]) } ],
	[ 'h mixed with g',               qr/^kruskal_test: cannot mix 'h'/,
	  sub { kruskal_test(h => { a => [1,2] }, g => [1,2]) } ],
	[ 'odd named args after hashref', qr/^kruskal_test: odd number of named arguments/,
	  sub { kruskal_test({ a => [1,2], b => [3,4] }, 'x') } ],
	[ 'odd named args after x/g',     qr/^kruskal_test: odd number of named arguments/,
	  sub { kruskal_test([1,2,3], [1,1,2], 'x') } ],
	[ 'a bare key and nothing else',  qr/^kruskal_test: odd number of named arguments/,
	  sub { kruskal_test('x') } ],
	[ 'no arguments at all',          qr/^kruskal_test: 'x' is a required argument/,
	  sub { kruskal_test() } ],
	[ 'x is not an arrayref',         qr/^kruskal_test: 'x' is a required argument/,
	  sub { kruskal_test(x => 42, g => [1,2]) } ],
	[ 'g missing',                    qr/^kruskal_test: 'g' is a required argument/,
	  sub { kruskal_test([1,2,3]) } ],
	[ 'g is not an arrayref',         qr/^kruskal_test: 'g' is a required argument/,
	  sub { kruskal_test(x => [1,2], g => 42) } ],
	[ 'x and g differ in length',     qr/^kruskal_test: 'x' and 'g' must have the same length/,
	  sub { kruskal_test([1,2,3], [1,2]) } ],
	[ 'h is not a hashref',           qr/^kruskal_test: 'h' must be a HASH reference/,
	  sub { kruskal_test(h => [1,2]) } ],
	[ 'h value is not an arrayref',   qr/^kruskal_test: every value in 'h' must be an ARRAY reference/,
	  sub { kruskal_test({ a => [1,2], b => 'not a ref' }) } ],
	# Degenerate shapes: these reach the second pass with the observation array
	# already allocated, so they are also the paths whose hand-written cleanup
	# has to run before the croak.
	[ 'empty hashref',                qr/^not enough observations/,
	  sub { kruskal_test({}) } ],
	[ 'empty hashref, named',         qr/^not enough observations/,
	  sub { kruskal_test(h => {}) } ],
	[ 'hashref with one empty group', qr/^all groups must contain data/,
	  sub { kruskal_test({ a => [] }) } ],
	[ 'empty x and g',                qr/^not enough observations/,
	  sub { kruskal_test([], []) } ],
	[ 'single observation',           qr/^not enough observations/,
	  sub { kruskal_test([1], ['a']) } ],
);
for my $c (@BAD_ARGS) {
	my ($label, $re, $call) = @$c;
	my $r = eval { $call->(); 1 };
	ok(!$r, "croaks: $label");
	like($@, $re, "croak message: $label");
}

# ---------------------------------------------------------------------------
# Leak checks.  t/01.t leak-checks the two success paths; what is added here is
# every path that croaks after ri[] and the group-label array are already
# allocated, since those have to be freed by hand before croaking.  Skipped
# only under Devel::Cover, which perturbs the allocation counts; t/01.t guards
# its own leak checks the same way.
unless ($INC{'Devel/Cover.pm'}) {
	my @paths = (
		[ 'hashref success'          => sub { kruskal_test({ a => [1,2,3], b => [4,5,6] }) } ],
		[ 'x/g success'              => sub { kruskal_test([1,2,3,4,5,6], [qw(a a a b b b)]) } ],
		[ 'named-args success'       => sub { kruskal_test(x => [1,2,3,4,5,6], g => [qw(a a a b b b)]) } ],
		[ 'many labels (realloc)'    => sub { kruskal_test([1..40], [map { "g$_" } 1..40]) } ],
		# croaks with ri[] and the label array live:
		[ 'croak: same group, hash'  => sub { kruskal_test({ a => [1,2,3] }) } ],
		[ 'croak: same group, x/g'   => sub { kruskal_test([1,2,3], [qw(a a a)]) } ],
		[ 'croak: empty group'       => sub { kruskal_test({ a => [1,2], b => [] }) } ],
		[ 'croak: all NaN, hash'     => sub { kruskal_test({ a => ['NaN'], b => ['NaN'] }) } ],
		[ 'croak: nothing numeric'   => sub { kruskal_test([qw(x y)], [qw(a b)]) } ],
		[ 'croak: empty hashref'     => sub { kruskal_test({}) } ],
		[ 'croak: one empty group'   => sub { kruskal_test({ a => [] }) } ],
		[ 'croak: empty x and g'     => sub { kruskal_test([], []) } ],
		# croaks before anything is allocated:
		[ 'croak: length mismatch'   => sub { kruskal_test([1,2,3], [1,2]) } ],
		[ 'croak: bad h value'       => sub { kruskal_test({ a => [1,2], b => 'x' }) } ],
		[ 'croak: odd named args'    => sub { kruskal_test([1,2],[1,2],'x') } ],
		[ 'croak: unknown argument'  => sub { kruskal_test([1,2],[1,2], bogus => 1) } ],
	);
	for my $p (@paths) {
		no_leaks_ok { eval { $p->[1]->() } } "no leaks: $p->[0]";
	}
}

# ---------------------------------------------------------------------------
# The group-label array on the x/g path is grown geometrically from 8 rather
# than sized at the number of observations, so the realloc path needs
# exercising: 8 is the initial capacity, so k crossing 8, 16 and 32 are the
# interesting counts.  H for k groups of one observation each is k-1 exactly
# (every rank sum is its own rank, and the statistic collapses to n-1), which
# R agrees with; kruskal.test(as.list(1:9)) gives 8 with df 8.
for my $k (2, 8, 9, 16, 17, 33, 64) {
	my @x = (1 .. $k);
	my @g = map { "group.$_" } 1 .. $k;
	my $r = kruskal_test(\@x, \@g);
	is($r->{parameter}, $k - 1, "k = $k groups of one: df");
	close_to($r->{statistic}, $k - 1, $TOL_H, "k = $k groups of one: statistic");
	is(scalar keys %{ $r->{group_stats}{size} }, $k, "k = $k groups of one: all labels kept");
	is($r->{group_stats}{size}{"group.$k"}, 1, "k = $k groups of one: last label kept");
}

# ---------------------------------------------------------------------------
# Group labels are compared as perl strings, so numeric and string forms of
# the same label are one group, exactly as R's factor() would have it.
{
	my $r = kruskal_test([1,2,3,4,5,6], [1, '1', 1.0, 2, '2', 2.0]);
	is($r->{parameter}, 1, 'numeric and string group labels are the same group');
	is_deeply([sort keys %{ $r->{group_stats}{size} }], ['1', '2'],
	          'numeric group labels stringify');
}

# ---------------------------------------------------------------------------
# A sample with no variation at all, at a size where the tie correction stops
# being exact.  This is a regression guard for get_p_value(), not for the
# statistic.
#
# The correction is 1 - sum(t^3 - t)/(n^3 - n), and when everything ties that
# is (n^3 - n)/(n^3 - n).  Once n^3 is past 2^53 the subtraction of n is lost
# from at least one of them, so the ratio is no longer exactly 1 and the
# uncorrected statistic -- an exact 0 in theory, the difference of two O(n)
# quantities in practice -- is divided by something that rounded to zero.  R
# has exactly the same problem and returns +Inf, -Inf or NaN depending on which
# way n rounded: R 4.6.1 gives NaN at n = 250000, -Inf at 300000, NaN at
# 400000, +Inf at 500000, NaN at 750000, +Inf at 1000000, NaN at 1500000 and
# +Inf at 2000000, and kruskal_test() agrees with it on all eight.
#
# Those values are not asserted here, because which one comes out is a rounding
# coin-flip that moves with NV width: a long-double build does not lose the
# "- n" until n^3 passes 2^64, so it gets a large finite H where a double build
# gets an infinity.  What is asserted is the part that must hold at every
# width -- that the p-value is the chi-squared upper tail *of whatever
# statistic came out*.  +Inf used to come back with p = NaN: it is not NaN, so
# it fell through to igamc()'s continued fraction, where the first 1/d is
# 1/Inf = 0 and then del = 0 * Inf = NaN, and an overwhelmingly significant
# result was reported as no result at all.  R gives 0, as pchisq(Inf, df,
# lower.tail = FALSE) must.
#
# n = 500000 is the smallest of R's +Inf cases and takes 0.11s here, so it is
# not gated; the whole section is 0.4s.
my $INF = 9**9**9;
for my $n (250000, 300000, 500000) {
	my @x = map { 1 } 1 .. $n;
	my @g = map { 'g' . ($_ % 3) } 0 .. $n - 1;
	my $r = kruskal_test(\@x, \@g);
	my ($H, $P) = ($r->{statistic}, $r->{p_value});
	if ($H != $H) {                       # NaN statistic -> NaN p-value
		ok($P != $P, "all-equal n = $n: NaN statistic gives NaN p-value");
	} elsif ($H == $INF) {                # the whole mass is below +Inf
		is($P, 0, "all-equal n = $n: +Inf statistic gives p = 0");
	} elsif ($H == -$INF) {               # ... and above -Inf
		is($P, 1, "all-equal n = $n: -Inf statistic gives p = 1");
	} else {                              # a wide NV build: large but finite
		ok($P >= 0 && $P <= 1, "all-equal n = $n: finite statistic gives a p-value in [0,1]");
	}
	is($r->{parameter}, 2, "all-equal n = $n: df is still k - 1");
}

# ---------------------------------------------------------------------------
# reference divergences
#
# Two cases where R and SciPy do not agree with each other, recorded so that
# taking the other side later is a deliberate act rather than a drift:
#
#  1. An empty group.  R (kruskal.test on a list) refuses: "all groups must
#     contain data".  SciPy 1.18.0 warns SmallSampleWarning and returns
#     statistic = nan, pvalue = nan (TestKruskal::test_empty).  kruskal_test()
#     follows R, because the hash-of-arrays form is R's list interface and
#     because the alternative -- silently testing the groups that do have data
#     under a df that counts the one that does not -- is what the bug was.
#
#  2. A sample with no variation at all.  The tie correction is
#     1 - sum(t^3 - t)/(n^3 - n), which is exactly 0 when every observation is
#     tied, and the uncorrected statistic is exactly 0 too, so the statistic is
#     0/0.  R returns NaN for both the statistic and the p-value; SciPy raises
#     ValueError("All numbers are identical in kruskal").  kruskal_test()
#     follows R -- see the "k=2 n=2 tied" and "all identical k=3" corpus rows,
#     which assert NaN.  get_p_value() short-circuits a NaN statistic rather
#     than letting it run igamc()'s continued fraction to its iteration bound.
#     Past n^3 = 2^53 the same 0/0 becomes an inexact-0 over an exact-0 and the
#     answer is an infinity instead; see the section above this one.

done_testing();
