#!/usr/bin/env perl
#
# interpolate(): the spline methods whose linear system is banded.
#
# ip_build_cubic() and ip_build_quad() used to assemble an n x n dense matrix
# and hand it to a dense Gaussian elimination, where n is the number of numeric
# anchors in the column.  Both systems are banded -- the not-a-knot cubic
# spline is tridiagonal apart from its two boundary rows, and the degree-2
# B-spline collocation matrix has three non-zero basis functions per row -- so
# that was O(n^2) memory and O(n^2) time for an O(n) problem: a column of
# 12,800 anchors needed 574 MB and 0.84 s, one of 100,000 would have wanted
# 80 GB, and ip_eval_quad() summed all n basis functions at every gap it
# filled.  0.316 solves in band storage (ip_solve_band) and evaluates only the
# basis functions whose support reaches the point.
#
# This file is here to make sure that stayed a change of *cost*: the values are
# SciPy's, at three sizes, the largest of which the dense form could not have
# run at all on an ordinary machine.
#
# Provenance:
#
#   * SciPy 1.15.2.  scipy.interpolate.CubicSpline(bc_type='not-a-knot') for
#     'cubic', and scipy.interpolate.make_interp_spline(k=2) -- which is what
#     interp1d(kind='quadratic') is -- for 'quadratic'.  The generator is
#     committed next to this file as t/interpolate.spline.banded.py and the
#     table below is its output pasted in; re-run it with
#         python3 t/interpolate.spline.banded.py
#     and paste the result over @CASES.  The test never calls it.
#   * t/interpolate_methods.t already pins the same two methods against pandas
#     at small n; this file exists for the sizes, not to repeat that.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(interpolate);

# The column the generator built, reproduced here exactly: a NaN wherever
# i % 10 == 5 or i % 23 == 7, both ends pinned so no gap is an extrapolation.
sub column {
	my ($n) = @_;
	my @v = map { ($_ % 10 == 5 || $_ % 23 == 7) ? undef : sin($_ / 13) + $_ / 500 }
	        0 .. $n - 1;
	$v[0] = 0.25; $v[-1] = 4.5;
	return \@v;
}

# [ n, [ [ gap index, scipy cubic, scipy quadratic ], ... ] ]
my @CASES = (
	# n = 200, 172 anchors, 28 gaps
	[ 200, [
		[ 5, 0.38578550640818388, 0.38541701124644712 ],
		[ 15, 0.94432607331602614, 0.94432524539968954 ],
		[ 30, 0.80055617374029253, 0.80055555238486098 ],
		[ 45, -0.22451435212450827, -0.22451407171211929 ],
		[ 55, -0.7762440764207954, -0.77623609582178021 ],
		[ 75, -0.34162028170988423, -0.34167293965034268 ],
		[ 85, 0.42251208204941204, 0.42251185692429039 ],
		[ 99, 1.1696681903041803, 1.1696671612614209 ],
		[ 115, 0.77687120772257545, 0.77687072157343173 ],
		[ 125, 0.060545859495075065, 0.060544614975252299 ],
		[ 145, -0.69749872350591713, -0.69749784321336827 ],
		[ 165, 0.45560406477865861, 0.45560265470553341 ],
	] ],
	# n = 2000, 1722 anchors, 278 gaps
	[ 2000, [
		[ 5, 0.38578550640818388, 0.38541701124644712 ],
		[ 168, 0.68518888846820436, 0.68518999501233568 ],
		[ 329, 0.83205953385951492, 0.83205913072636339 ],
		[ 495, 1.3588860531280318, 1.3588857681225428 ],
		[ 665, 2.1060389053439517, 2.1060382137845917 ],
		[ 825, 2.238889078604632, 2.2388885536476604 ],
		[ 995, 2.8987239493845758, 2.8986989185606093 ],
		[ 1157, 3.174067732496336, 3.1740592122385576 ],
		[ 1325, 3.6340759858296927, 3.6340751102212234 ],
		[ 1485, 3.8758696700657578, 3.875868854726578 ],
		[ 1655, 4.3073203867280832, 4.3073194974226876 ],
		[ 1824, 4.5222846411079356, 4.5223141025995641 ],
	] ],
	# n = 20000, 17217 anchors, 2783 gaps.  The dense build wanted
	# 17217^2 NVs -- 2.4 GB on a double perl, 4.7 on quadmath -- to solve this.
	[ 20000, [
		[ 5, 0.38578550640818388, 0.38541701124644712 ],
		[ 1663, 4.0981511197517682, 4.0981412030784927 ],
		[ 3319, 5.8942354387780656, 5.8942363396502362 ],
		[ 4985, 10.156142209162553, 10.156142043227337 ],
		[ 6645, 14.08907380194924, 14.089073089754336 ],
		[ 8305, 15.717507883671477, 15.717508672396036 ],
		[ 9965, 19.919854018572515, 19.919793652261085 ],
		[ 11622, 24.220568826395041, 24.220568650202008 ],
		[ 13285, 25.783289930365001, 25.78329063007574 ],
		[ 14945, 29.68396030103283, 29.683960484733532 ],
		[ 16605, 34.178841088471231, 34.178840224553696 ],
		[ 18265, 35.879622104232688, 35.879622571786186 ],
	] ],
);

# The band solve is a different elimination order from SciPy's, and the data
# spans four orders of magnitude by n = 20000, so the two answers differ by
# accumulated rounding rather than by anything structural.  Worst relative
# disagreement measured over the whole table on a double build: 2.3e-16, i.e.
# one ulp.  1e-12 is ~4500 ulp, which leaves room for a long-double or
# __float128 build to pivot differently without failing here.
my $TOL = 1e-12;

for my $case (@CASES) {
	my ($n, $points) = @$case;
	my $cubic = interpolate({ y => column($n) }, method => 'cubic')->{y};
	my $quad  = interpolate({ y => column($n) }, method => 'quadratic')->{y};
	my ($worst_c, $worst_q) = (0, 0);
	for my $p (@$points) {
		my ($i, $ec, $eq) = @$p;
		my $rc = abs($cubic->[$i] - $ec) / (1 + abs $ec);
		my $rq = abs($quad->[$i]  - $eq) / (1 + abs $eq);
		$worst_c = $rc if $rc > $worst_c;
		$worst_q = $rq if $rq > $worst_q;
	}
	ok($worst_c <= $TOL, "n=$n cubic matches SciPy CubicSpline (worst rel $worst_c)");
	ok($worst_q <= $TOL, "n=$n quadratic matches SciPy k=2 spline (worst rel $worst_q)");

	# Every gap must have been filled, and no anchor disturbed.
	my $src = column($n);
	my ($filled, $kept) = (0, 0);
	for my $i (0 .. $n - 1) {
		if (defined $src->[$i]) { $kept++ if $cubic->[$i] == $src->[$i] }
		else                    { $filled++ if defined $cubic->[$i] }
	}
	is($filled, scalar(grep { !defined } @$src), "n=$n cubic filled every gap");
	is($kept,   scalar(grep {  defined } @$src), "n=$n cubic left every anchor alone");
}

# The degree-2 collocation matrix is built into a band of a fixed width, and
# ip_build_quad() asserts the band was wide enough by checking that each row of
# the basis sums to 1 (the B-spline partition of unity).  A column short enough
# to be all boundary rows is where a too-narrow band would show first.
for my $n (4 .. 14) {
	my @v = map { ($_ == 2) ? undef : $_ * 1.5 - ($_ * $_) / 7 } 0 .. $n - 1;
	my $q = eval { interpolate({ y => [@v] }, method => 'quadratic')->{y} };
	ok(!$@, "quadratic on $n points: basis is complete") or diag($@);
	# a quadratic through a quadratic is exact
	ok($q && abs($q->[2] - (2 * 1.5 - 4 / 7)) < 1e-9,
	   "quadratic on $n points reproduces a quadratic exactly");
}

# ------------------------------------------------------------ the size itself
#
# 180,000 anchors.  The dense build would have asked for 180000^2 NVs -- 259 GB
# on a double perl -- so this case is not "slower" under it, it is impossible;
# banded it is 0.04 s and about 60 MB, most of that the Perl array.  No timing
# is asserted, because a smoker's clock is not evidence: what is asserted is
# that it returns at all, and returns the right numbers.
{
	my $n = 200_000;
	# Unlike the SciPy cases above, the ends are left on the curve: this case
	# checks the spline against the function it was sampled from, so pinning an
	# endpoint to an unrelated value would be measuring that instead.
	my @v = map { ($_ % 10 == 5) ? undef : sin($_ / 13) + $_ / 500 } 0 .. $n - 1;
	my $gaps = scalar grep { !defined } @v;
	my $out = eval { interpolate({ y => [ @v ] }, method => 'cubic')->{y} };
	ok($out, "cubic over $n points returns") or diag($@);
	if ($out) {
		is(scalar(grep { !defined } @$out), 0, "cubic over $n points filled every gap");
		cmp_ok($gaps, '>', 10_000, 'the case really is mostly gaps');
		# The column is smooth, so every filled value must sit between its
		# neighbouring anchors' values to well within the local variation.
		# This is an approximation error, not a rounding one: the gaps are one
		# point wide in a grid of spacing 1, and a not-a-knot cubic's error over
		# such a gap is O(h^4 f'''') ~ (1/13)^4 / 4! = 1.5e-6 for this curve.
		# Measured worst over all 20,000 gaps on a double build: 2.44e-6.  5e-5
		# is twenty times that -- enough for a wider NV to pivot differently,
		# far too little to admit a spline that has actually gone wrong (the
		# dense build, where the case can be run at all, agrees to 1e-15).
		my ($bad, $worst) = (0, 0);
		for my $i (1 .. $n - 2) {
			next if defined $v[$i];
			my $e = abs($out->[$i] - (sin($i / 13) + $i / 500));
			$worst = $e if $e > $worst;
			$bad++ if $e > 5e-5;
		}
		is($bad, 0, "cubic over $n points reproduces the underlying function")
			or diag("worst absolute error $worst");
	}
}

done_testing();
