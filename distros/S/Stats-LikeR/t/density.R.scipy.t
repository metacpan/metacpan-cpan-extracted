#!/usr/bin/env perl
#
# Cross-validation of density(), bw_nrd0(), bw_nrd(), bw_ucv(), bw_bcv() and
# bw_sj() against the reference implementations, using their own test suites
# and documented examples rather than cases invented here.  t/density.t covers
# the Perl-side surface (argument forms, croak messages, returned fields);
# this file is about the numbers.
#
# Provenance of every expected value below:
#
#   * R 4.6.1 (2026-06-24) stats::density.default() and stats::bw.nrd0 /
#     bw.nrd / bw.ucv / bw.bcv / bw.SJ, which these functions are a port of --
#     down to R's own BinDist(), fft(), approx(), seq.int(), Brent_fmin() and
#     zeroin().  The @R_DENSITY, @R_BW and %R_KERN tables were generated from R
#     at options(digits=17) by t/density.R.scipy.R, which is committed next to
#     this file; re-run it with `Rscript t/density.R.scipy.R`.
#
#   * R's own regression suite:
#       - tests/reg-tests-1a.R, PR#8033: density() with an infinite observation
#         ("density with 'Inf' in x"), pinned there as
#         y == rep(1/sqrt(27), 2) to tol 1e-14.
#       - tests/reg-tests-1a.R, PR#8876: "density() could give negative values
#         by rounding error", pinned as result$y >= 0.
#       - tests/reg-tests-1a.R: bw.SJ(1:20) must not raise "no solution in the
#         specified range of bandwidths" (it did for R <= 2.5.0).
#       - tests/reg-tests-1b.R: bw.SJ(c(1:99, 1e6), tol = 1e-3) == 0.725 to
#         tolerance 1e-3 -- "bw.SJ(x) failed for R <= 2.9.0 (in two ways!),
#         when x had extreme outlier".
#       - tests/reg-tests-1c.R, PR#16024: bw.SJ(c(NA,2,3)), bw.bcv(c(-Inf,2,3))
#         and bw.ucv(c(1,NaN,3,4)) must all raise an error rather than
#         segfault.
#       - tests/reg-tests-1d.R, PR#18151: density(x_with_NA, weights = *,
#         na.rm = TRUE) -- the four all.equal() relations asserted there.
#
#   * R's documented examples, whose printed output is pinned in
#     tests/Examples/stats-Ex.Rout.save: every example in
#     src/library/stats/man/density.Rd (the IQR == 0 case, faithful$eruptions
#     with bw = "sj", the weighted-unique-values identity, the seven kernels in
#     R's and in S's parametrisation, the old.coords comparison, the R(K) table
#     and the "exactly equivalent kernels" adjustment factors) and the six
#     bandwidth rules on `precip` from man/bandwidth.Rd -- including the
#     "minimum occurred at one end of the range" warning that example pins.
#
#   * SciPy 1.18.0 and NumPy 2.5.2.  SciPy has no port of R's density():
#     scipy.stats.gaussian_kde evaluates the estimate *exactly*, one Gaussian
#     per observation, where R bins onto a grid, convolves with the FFT and
#     interpolates back.  That makes it the right second opinion -- it checks
#     the pipeline against the quantity the pipeline approximates rather than
#     against another copy of the same algorithm -- but it can only agree to
#     the discretisation error, which t/density.R.scipy.py measures and freezes
#     as $PY_DISCRETISATION_*.  NumPy's std(ddof=1) and SciPy's
#     iqr(interpolation='linear') also give an independent reading of bw.nrd0
#     and bw.nrd (@PY_NRD).  Re-run it with `python3 t/density.R.scipy.py`.
#
#     Deliberately NOT used: statsmodels' bw_silverman/bw_scott divide the IQR
#     by 1.349 where R's bw.nrd0/bw.nrd divide by 1.34, so they compute a
#     different quantity and agreeing with them would mean disagreeing with R.
#
# Nothing here runs R or Python: every number is a frozen literal.
#
# Tolerances, and the worst disagreement each was chosen against.  Two numbers
# are quoted for each: what the default double perl shows, and what
# perl-5.12.5 (long double) and 5.44.0-quadmath show, since the wider builds
# re-parse every frozen literal at a different width and, for anything that
# came out of a search, follow different iterates.
#
#   $TOL_BW       1e-12 relative, for the closed forms bw.nrd0 and bw.nrd.
#                 Worst observed 6.6e-16 on double, 1e-16 on long double --
#                 these are arithmetic, and they agree to the last few ulps at
#                 every width.
#   $TOL_BW_CV    1e-6 relative, for bw.ucv/bw.bcv/bw.SJ at R's own default
#                 tol.  That default is 0.1*lower, of order a percent of the
#                 answer, so this is not what pins those three.  Worst observed
#                 2.8e-10 on double but 1.5e-8 on long double, which is
#                 sqrt(DBL_EPSILON): Brent's fmin cannot place a smooth
#                 function's minimum closer than the square root of the working
#                 precision, so the answer genuinely moves with NV width.
#   $TOL_BW_MIN   1e-6 relative, bw.ucv/bw.bcv with tol = 1e-10.  Same floor;
#                 a smaller tol cannot buy past it.
#   $TOL_BW_ROOT  1e-12 relative, bw.SJ with tol = 1e-10.  A root, unlike a
#                 minimum, can be found to full precision, and is.
#   $TOL_Y        1e-11 relative on the density values, floored at
#                 $TOL_YFLOOR * max(y).  The floor is what actually governs:
#                 in the tails y is a sum of ~2n terms that cancel to nothing,
#                 so its *relative* error is unbounded (worst observed 1.2e-9)
#                 while its size relative to max(y) is not (worst observed
#                 1.6e-13 on double, 1e-15 on long double, against a floor of
#                 1e-11).  That residual is the radix-2 FFT here disagreeing
#                 with R's mixed-radix one, and it shrinks, not grows, with NV
#                 width.
#   $TOL_X        1e-14, applied to |x| *plus the grid's span*.  A grid that
#                 straddles zero has coordinates whose own magnitude is
#                 arbitrarily small although the arithmetic that produced them
#                 worked at the scale of the whole grid, so a purely relative
#                 test there compares representation noise: worst observed
#                 4.4e-14 of the coordinate but 4.3e-17 of the span.  Against
#                 the span the worst observed is 0 on double -- bit-identical
#                 -- and 4.4e-17 on long double.
#   $TOL_X_SEARCH 1e-7, $TOL_Y_SEARCH and $TOL_YFLOOR_SEARCH 1e-6: the same
#                 quantities for the cases whose bandwidth came out of a
#                 search.  The grid is built from that bandwidth and the
#                 estimate from that grid, so both inherit the 1.5e-8 above.
#                 Worst observed 2.9e-9 of the span, 2.8e-8 relative in y and
#                 5.9e-9 of max(y), all on long double; on double they are
#                 3.7e-14 and 5.7e-12.  These cases are deliberately the loose
#                 ones -- what pins bw.ucv/bw.bcv/bw.SJ is the tight-tol half
#                 of @R_BW, not these.
#
use strict;
use warnings FATAL => 'all';
require 5.010;
use Test::More;
use Stats::LikeR qw(density bw_nrd0 bw_nrd bw_ucv bw_bcv bw_sj);

our (%DATA, %DATA2, @R_DENSITY, @R_BW, %R_KERN);
our (@PY_NRD, @PY_EXACT);
our ($PY_DISCRETISATION_512_ABS,  $PY_DISCRETISATION_512_REL,
     $PY_DISCRETISATION_8192_ABS, $PY_DISCRETISATION_8192_REL);

my $TOL_BW       = 1e-12;   # closed-form bandwidths: bw.nrd0, bw.nrd
my $TOL_BW_CV    = 1e-6;    # bw.ucv / bw.bcv / bw.SJ at R's own default tol
my $TOL_BW_MIN   = 1e-6;    # ... at a tight tol: bw.ucv / bw.bcv
my $TOL_BW_ROOT  = 1e-12;   # ... at a tight tol: bw.SJ
my $TOL_Y        = 1e-11;   # density values, relative
my $TOL_YFLOOR   = 1e-11;   # ... floored at this multiple of max(y)
my $TOL_X        = 1e-14;   # the output grid, relative to |x| + its span
my $TOL_X_SEARCH = 1e-7;    # ... when the bandwidth came out of a search
my $TOL_Y_SEARCH = 1e-6;    # density values, likewise
my $TOL_YFLOOR_SEARCH = 1e-6;

# helpers

# Collect warnings instead of letting them onto the test output; several of the
# cases below are meant to warn, and one of those warnings is itself pinned by
# R's documented output.
my @WARNINGS;
$SIG{__WARN__} = sub { push @WARNINGS, $_[0] };
sub warnings_since { my @w = @WARNINGS; @WARNINGS = (); return @w }

sub rel_ok {
	my ($got, $want, $tol, $name, $floor) = @_;
	$floor = 0 unless defined $floor;
	my $lim = abs($want) * $tol;
	$lim = $floor if $floor > $lim;
	my $d = abs($got - $want);
	my $ok = ($d <= $lim);
	ok($ok, $name) or diag(sprintf "got %.17g want %.17g  |diff| %.3g > %.3g",
	                       $got, $want, $d, $lim);
	return $ok;
}

sub dataset {
	my ($name) = @_;
	my $d = exists $DATA{$name} ? $DATA{$name} : $DATA2{$name};
	die "no data set '$name'" unless $d;
	return $d;
}

# R: density() itself

for my $c (@R_DENSITY) {
	my $x   = dataset($c->{data});
	my @arg = @{ $c->{args} };
	my $tag = "density($c->{data}"
	        . (@arg ? ', ' . join(', ', map { defined $_ && !ref $_ ? $_ : '[..]' } @arg) : '')
	        . ')';
	my $d = density($x, @arg);
	warnings_since();

	# A bandwidth that came out of bw.ucv/bw.bcv/bw.SJ is only pinned to that
	# search's own stopping tolerance, and every coordinate and every density
	# value downstream of it inherits that.  Worst observed on the default
	# perl: 1.7e-13 relative in bw, 1.3e-13 absolute in the grid.
	my ($tol_x, $tol_y, $tol_yfloor) =
		$c->{search} ? ($TOL_X_SEARCH, $TOL_Y_SEARCH, $TOL_YFLOOR_SEARCH)
		             : ($TOL_X,        $TOL_Y,        $TOL_YFLOOR);

	# The grid coordinates are compared against |x| *plus the grid's span*.  A
	# grid that straddles zero has points whose own magnitude is arbitrarily
	# small while the arithmetic that produced them worked at the scale of the
	# whole grid, so a purely relative test there compares representation noise:
	# on a long-double perl x = -0.045 out of a span of 46 came back 2e-15 away,
	# which is 4e-14 of itself and 4e-17 of the span.
	my $span = abs($c->{xn} - $c->{x1});

	is(ref $d, 'HASH', "$tag returns a hash reference");
	is(scalar @{ $d->{y} }, $c->{len}, "$tag length of y");
	is(scalar @{ $d->{x} }, $c->{len}, "$tag length of x");
	is($d->{n}, $c->{n}, "$tag n");
	rel_ok($d->{bw}, $c->{bw}, $c->{search} ? $TOL_BW_CV : $TOL_BW, "$tag bw");
	rel_ok($d->{x}[0], $c->{x1}, $tol_x, "$tag x[0]", $tol_x * $span);
	rel_ok($d->{x}[ $c->{len} - 1 ], $c->{xn}, $tol_x, "$tag x[-1]", $tol_x * $span);

	my $ymax = $c->{ymax};
	my $floor = $tol_yfloor * abs($ymax);
	rel_ok(_max($d->{y}), $ymax, $tol_y, "$tag max(y)", $floor);
	rel_ok(_sum($d->{y}), $c->{ysum}, $tol_y, "$tag sum(y)", $floor * $c->{len});

	my $bad = 0;
	for my $i (0 .. $#{ $c->{at} }) {
		my $k = $c->{at}[$i] - 1;
		my $lim = abs($c->{y}[$i]) * $tol_y;
		$lim = $floor if $floor > $lim;
		$bad++ if abs($d->{y}[$k] - $c->{y}[$i]) > $lim;
		my $xlim = (abs($c->{xs}[$i]) + $span) * $tol_x;
		$bad++ if abs($d->{x}[$k] - $c->{xs}[$i]) > $xlim;
	}
	is($bad, 0, "$tag y and x at " . scalar(@{ $c->{at} }) . " grid points");

	# PR#8876: density() must never return a negative y, on any input.
	my $neg = grep { $_ < 0 } @{ $d->{y} };
	is($neg, 0, "$tag no negative y (PR#8876)");
}

sub _sum { my $s = 0; $s += $_ for @{ $_[0] }; return $s }
sub _max { my $m = $_[0][0]; for (@{ $_[0] }) { $m = $_ if $_ > $m } return $m }

# R: bw.*

my %BW_FN = (
	bw_nrd0 => \&bw_nrd0, bw_nrd => \&bw_nrd,
	bw_ucv  => \&bw_ucv,  bw_bcv => \&bw_bcv, bw_sj => \&bw_sj,
);
for my $b (@R_BW) {
	my $x   = dataset($b->{data});
	my @arg = @{ $b->{args} };
	my $tag = "$b->{fn}($b->{data}" . (@arg ? ', ' . join(', ', @arg) : '') . ')';
	my $got = $BW_FN{ $b->{fn} }->($x, @arg);
	warnings_since();
	# bw.nrd0/bw.nrd are closed forms.  The other three are the output of a
	# search: at R's default tol -- 0.1*lower, of order a percent of the
	# answer -- they only agree while the iterates do, which is why the table
	# also carries tight-tol variants.  With the search asked to converge
	# properly, bw.SJ (zeroin, a root) pins to the last digits, while bw.ucv
	# and bw.bcv (Brent's fmin, a minimum) cannot beat the sqrt(machine
	# epsilon) floor that minimising a smooth function imposes.
	my $tol = $TOL_BW_CV;
	if ($b->{fn} eq 'bw_nrd0' || $b->{fn} eq 'bw_nrd') { $tol = $TOL_BW }
	elsif ($b->{tight}) {
		$tol = ($b->{fn} eq 'bw_sj') ? $TOL_BW_ROOT : $TOL_BW_MIN;
	}
	rel_ok($got, $b->{val}, $tol, $tag);
}

# --------------------------------------------------- R: give.Rkern = TRUE

for my $k (sort keys %R_KERN) {
	rel_ok(density(kernel => $k, give_rkern => 1), $R_KERN{$k}, $TOL_BW,
	       "density(kernel => '$k', give_rkern => 1)");
	# R accepts give.Rkern with no data at all, and so must this.
	rel_ok(density(x => [], kernel => $k, give_rkern => 1), $R_KERN{$k},
	       $TOL_BW, "give_rkern ignores x for '$k'");
}
# The abbreviations match.arg() accepts.  Every single letter is unambiguous.
my %ABBREV = (g => 'gaussian', e => 'epanechnikov', r => 'rectangular',
              t => 'triangular', b => 'biweight', c => 'cosine',
              o => 'optcosine', gauss => 'gaussian', optc => 'optcosine');
for my $a (sort keys %ABBREV) {
	rel_ok(density(kernel => $a, give_rkern => 1), $R_KERN{ $ABBREV{$a} },
	       $TOL_BW, "kernel => '$a' abbreviates '$ABBREV{$a}'");
}

# stats-Ex.Rout.save pins the R(K) table rounded to 7 significant digits, and
# the efficiencies 100*round(RK["epanechnikov"]/RK, 4) next to it.
my %RK_PINNED = (
	gaussian => 0.2820948, epanechnikov => 0.2683282, rectangular => 0.2886751,
	triangular => 0.2721655, biweight => 0.2699746, cosine => 0.2711340,
	optcosine => 0.2684756,
);
my %EFF_PINNED = (
	gaussian => 95.12, epanechnikov => 100.00, rectangular => 92.95,
	triangular => 98.59, biweight => 99.39, cosine => 98.97, optcosine => 99.95,
);
# and (RK["gaussian"]/RK)^0.2, the "exactly equivalent kernels" adjustment
my %HF_PINNED = (
	gaussian => 1.0000000, epanechnikov => 1.0100567, rectangular => 0.9953989,
	triangular => 1.0071923, biweight => 1.0088217, cosine => 1.0079575,
	optcosine => 1.0099458,
);
my $rk_epan = density(kernel => 'epanechnikov', give_rkern => 1);
my $rk_gaus = density(kernel => 'gaussian',     give_rkern => 1);
for my $k (sort keys %RK_PINNED) {
	my $rk = density(kernel => $k, give_rkern => 1);
	rel_ok($rk, $RK_PINNED{$k}, 5e-7, "R(K) for '$k' matches stats-Ex.Rout.save");
	rel_ok(100 * sprintf('%.4f', $rk_epan / $rk), $EFF_PINNED{$k}, 1e-9,
	       "efficiency for '$k' matches stats-Ex.Rout.save");
	rel_ok(($rk_gaus / $rk) ** 0.2, $HF_PINNED{$k}, 5e-8,
	       "equivalent-kernel adjustment for '$k' matches stats-Ex.Rout.save");
}

# R's regression tests, spelled out

# tests/reg-tests-1a.R, PR#8033: "density with 'Inf' in x".  1/0:2 is
# c(Inf, 1, 0.5); the infinite observation is a point mass outside the grid,
# so what is left is a sub-density carrying 2/3 of the mass.
{
	my $d = density([9**9**9, 1, 0.5], kernel => 'rect', bw => 1,
	                from => 0, to => 1, n => 2);
	warnings_since();
	my $want = 1 / sqrt(27);
	rel_ok($d->{y}[0], $want, 1e-14, 'PR#8033: y[1] == 1/sqrt(27)');
	rel_ok($d->{y}[1], $want, 1e-14, 'PR#8033: y[2] == 1/sqrt(27)');
	is($d->{n}, 3, 'PR#8033: n counts the infinite observation');
}

# tests/reg-tests-1a.R, PR#8876: density() could give negative values by
# rounding error.  (Checked for every case in @R_DENSITY as well.)
{
	my $d = density(dataset('pr8876'), n => 20, from => -1, to => 1);
	warnings_since();
	is(scalar(grep { $_ < 0 } @{ $d->{y} }), 0, 'PR#8876: no negative y');
}

# tests/reg-tests-1a.R: bw.SJ(1:20) raised "no solution in the specified range
# of bandwidths" for R <= 2.5.0, because the search interval was too small.
{
	my $bw = eval { bw_sj(dataset('seq20')) };
	warnings_since();
	ok(defined $bw && $bw > 0, 'bw_sj(1..20) finds a solution (reg-tests-1a)')
		or diag("error: $@");
}

# tests/reg-tests-1b.R: bw.SJ on an extreme example, pinned as 0.725.
{
	my $bw = bw_sj(dataset('out99'), tol => 1e-3);
	warnings_since();
	rel_ok($bw, 0.725, 1e-3, 'bw_sj(c(1:99, 1e6), tol => 1e-3) == 0.725 (reg-tests-1b)');
}

# tests/reg-tests-1c.R, PR#16024: these segfaulted in 3.0.0 <= R <= 3.1.1.
{
	my $inf = 9**9**9;
	ok(!defined eval { bw_sj([undef, 2, 3]); 1 },  'PR#16024: bw_sj rejects NA');
	ok(!defined eval { bw_bcv([-$inf, 2, 3]); 1 }, 'PR#16024: bw_bcv rejects -Inf');
	ok(!defined eval { bw_ucv([1, $inf - $inf, 3, 4]); 1 },
	   'PR#16024: bw_ucv rejects NaN');
	warnings_since();
}

# tests/reg-tests-1d.R, PR#18151: density(x_with_NA, weights = *, na.rm = TRUE)
# used to be an error, because the weights were compared against the length of
# x after the NAs had gone.  All four all.equal() relations from that test.
{
	my @x = (1, 2, undef, 4);
	my @w = (0.25, 0.25, 0.25, 0.25);
	my @x3 = (1, 2, 4);
	my $dxw  = density(\@x, weights => \@w, na_rm => 1);
	my @warn = warnings_since();
	is(scalar @warn, 0, 'PR#18151: no warning when the weights summed to one');
	my $dx3  = density(\@x3, weights => [0.25, 0.25, 0.25], subdensity => 1);
	my $dx3w = density(\@x3, weights => [map { $_ * 4 / 3 } (0.25, 0.25, 0.25)]);
	my $dx3d = density(\@x3);
	warnings_since();

	my $cmp = sub {
		my ($a, $b, $name, $scale) = @_;
		$scale = 1 unless defined $scale;
		my $bad = 0;
		$bad++ if abs($a->{bw} - $b->{bw}) > $TOL_BW * abs($b->{bw});
		$bad++ if $a->{n} != $b->{n};
		for my $i (0 .. $#{ $a->{y} }) {
			$bad++ if abs($a->{x}[$i] - $b->{x}[$i]) > $TOL_X * (abs($b->{x}[$i]) || 1);
			$bad++ if abs($a->{y}[$i] - $scale * $b->{y}[$i])
			        > $TOL_Y * abs($scale * $b->{y}[$i]) + 1e-14;
		}
		is($bad, 0, $name);
	};
	$cmp->($dxw, $dx3d, 'PR#18151: dxw == density(x[-3])');
	$cmp->($dxw, $dx3w, 'PR#18151: dxw == density(x[-3], w[-3]*4/3)');
	rel_ok($dxw->{bw}, $dx3->{bw}, $TOL_BW, 'PR#18151: dxw$bw == dx3$bw');
	$cmp->($dxw, $dx3, 'PR#18151: dxw$y == dx3$y * 4/3', 4 / 3);
}

# ------------------------- R's documented examples, spelled out

# man/density.Rd: the weighted-observations example.  126 unique eruption
# times weighted by their counts give the same estimate as all 272
# observations; stats-Ex.Rout.save pins n = 126 for the weighted fit and
# stopifnot(all.equal(d[1:3], dw[1:3])) for the identity.
{
	my @fe = sort { $a <=> $b } @{ dataset('eruptions') };
	my (@u, %cnt);
	for my $v (@fe) { push @u, $v unless $cnt{$v}++ }
	my @w = map { $cnt{$_} / scalar(@fe) } @u;
	my $d  = density(dataset('eruptions'), bw => 'sj');
	my $dw = density(\@u, weights => \@w, bw => $d->{bw});
	warnings_since();
	is(scalar @u, 126, 'density.Rd: 126 unique eruption times');
	is($dw->{n}, 126, 'density.Rd: weighted fit reports n = 126');
	rel_ok($dw->{bw}, $d->{bw}, $TOL_BW, 'density.Rd: dw$bw == d$bw');
	my $bad = 0;
	for my $i (0 .. $#{ $d->{y} }) {
		$bad++ if abs($dw->{x}[$i] - $d->{x}[$i]) > $TOL_X * (abs($d->{x}[$i]) || 1);
		$bad++ if abs($dw->{y}[$i] - $d->{y}[$i]) > 1e-9 * (abs($d->{y}[$i]) || 1) + 1e-12;
	}
	is($bad, 0, 'density.Rd: all.equal(d[1:3], dw[1:3])');
}

# man/bandwidth.Rd: bw.bcv(precip) warns "minimum occurred at one end of the
# range", which stats-Ex.Rout.save pins as part of that example's output.
{
	warnings_since();
	my $bw = bw_bcv(dataset('precip'));
	my @w  = warnings_since();
	ok((grep { /minimum occurred at one end of the range/ } @w),
	   'bandwidth.Rd: bw_bcv(precip) warns about the range')
		or diag("warnings: @w");
	ok($bw > 0, 'bandwidth.Rd: bw_bcv(precip) still returns a bandwidth');
}

# man/density.Rd: old.coords = TRUE reproduces the pre-R-4.4.0 grid, which is
# too large by about 1 + 1/(2n-2).  The example's own summary of the ratio runs
# from 1.001 to 1.011 on runif(2^12); the frozen @R_DENSITY rows pin both
# settings exactly, and this checks the documented structure of the difference.
{
	my $x    = dataset('unif4096');
	my $den  = density($x);
	my $den0 = density($x, old_coords => 1);
	warnings_since();
	my ($mn, $mx) = (9**9**9, -9**9**9);
	for my $i (0 .. $#{ $den->{y} }) {
		next unless $den->{y}[$i] > 1e-6;
		my $r = $den0->{y}[$i] / $den->{y}[$i];
		$mn = $r if $r < $mn;
		$mx = $r if $r > $mx;
	}
	my $expect = 1 + 1 / (2 * 512 - 2);
	ok($mn >= 1.0 && $mn < $expect * 1.001,
	   sprintf('old_coords: smallest ratio %.6f is just above 1', $mn));
	ok($mx > $expect * 0.99 && $mx < 1.02,
	   sprintf('old_coords: largest ratio %.6f is about 1+1/(2n-2)', $mx));
}

# ---------------------------------------------- SciPy / NumPy: bw.nrd0, bw.nrd

for my $p (@PY_NRD) {
	my $x = dataset($p->{data});
	rel_ok(bw_nrd0($x), $p->{nrd0}, $TOL_BW,
	       "bw_nrd0($p->{data}) == NumPy std/SciPy iqr rebuild");
	rel_ok(bw_nrd($x), $p->{nrd}, $TOL_BW,
	       "bw_nrd($p->{data}) == NumPy std/SciPy iqr rebuild");
}

# ------------------------------- SciPy: the exact kernel density estimate
#
# scipy.stats.gaussian_kde sums one Gaussian per observation; density() bins,
# convolves and interpolates.  They agree to the discretisation error, which
# t/density.R.scipy.py measured against R itself -- so this asserts that our
# port sits the same distance from the exact estimate that R does, with a
# factor of two of headroom rather than a tolerance chosen to fit.

for my $p (@PY_EXACT) {
	my $x = dataset($p->{data});
	my $d = density($x, n => $p->{n});
	warnings_since();
	rel_ok($d->{bw}, $p->{bw}, $TOL_BW, "exact-KDE check: bw for $p->{data}");
	my $ymax = _max($d->{y});
	my $abs_tol = 2 * ($p->{n} == 512 ? $PY_DISCRETISATION_512_ABS
	                                  : $PY_DISCRETISATION_8192_ABS) * $ymax;
	my $rel_tol = 2 * ($p->{n} == 512 ? $PY_DISCRETISATION_512_REL
	                                  : $PY_DISCRETISATION_8192_REL);
	my $bad = 0;
	for my $i (0 .. $#{ $p->{at} }) {
		my $k    = $p->{at}[$i] - 1;
		my $want = $p->{y}[$i];
		my $lim  = abs($want) * $rel_tol;
		$lim = $abs_tol if $abs_tol > $lim;
		$bad++ if abs($d->{y}[$k] - $want) > $lim;
	}
	is($bad, 0, "exact-KDE check: $p->{data}, n = $p->{n}, "
	          . scalar(@{ $p->{at} }) . ' grid points');
}

is(scalar(@WARNINGS), 0, 'no unexpected warnings left over')
	or diag("leftover warnings: @WARNINGS");

done_testing();

# The frozen reference tables.  They live in a BEGIN block at the foot of the
# file so that the tests above read as tests; regenerate them with the two
# scripts named in the header and paste each between its own markers.
BEGIN {
## BEGIN GENERATED (R) -- Rscript t/density.R.scipy.R
our %DATA = (
	pr8876 => ['0.0060000000000000001', '0.002', '0.024', '0.02', '0.034000000000000002', '0.089999999999999997', '0.073999999999999996', '0.071999999999999995', '0.122', '0.048000000000000001', '0.043999999999999997', '0.16800000000000001'],
	pr8033 => [9**9**9, '1', '0.5'],
	iqr0 => ['-20', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '0', '20'],
	precip => ['67', '54.700000000000003', '7', '48.5', '14', '17.199999999999999', '20.699999999999999', '13', '43.399999999999999', '40.200000000000003', '38.899999999999999', '54.5', '59.799999999999997', '48.299999999999997', '22.899999999999999', '11.5', '34.399999999999999', '35.100000000000001', '38.700000000000003', '30.800000000000001', '30.600000000000001', '43.100000000000001', '56.799999999999997', '40.799999999999997', '41.799999999999997', '42.5', '31', '31.699999999999999', '30.199999999999999', '25.899999999999999', '49.200000000000003', '37', '35.899999999999999', '15', '30.199999999999999', '7.2000000000000002', '36.200000000000003', '45.5', '7.7999999999999998', '33.399999999999999', '36.100000000000001', '40.200000000000003', '42.700000000000003', '42.5', '16.199999999999999', '39', '35', '37', '31.399999999999999', '37.600000000000001', '39.899999999999999', '36.200000000000003', '42.799999999999997', '46.399999999999999', '24.699999999999999', '49.100000000000001', '46', '35.899999999999999', '7.7999999999999998', '48.200000000000003', '15.199999999999999', '32.5', '44.700000000000003', '42.600000000000001', '38.799999999999997', '17.399999999999999', '40.799999999999997', '29.100000000000001', '14.6', '59.200000000000003'],
	eruptions => ['3.6000000000000001', '1.8', '3.3330000000000002', '2.2829999999999999', '4.5330000000000004', '2.883', '4.7000000000000002', '3.6000000000000001', '1.95', '4.3499999999999996', '1.833', '3.9169999999999998', '4.2000000000000002', '1.75', '4.7000000000000002', '2.1669999999999998', '1.75', '4.7999999999999998', '1.6000000000000001', '4.25', '1.8', '1.75', '3.4500000000000002', '3.0670000000000002', '4.5330000000000004', '3.6000000000000001', '1.9670000000000001', '4.0830000000000002', '3.8500000000000001', '4.4329999999999998', '4.2999999999999998', '4.4669999999999996', '3.367', '4.0330000000000004', '3.8330000000000002', '2.0169999999999999', '1.867', '4.8330000000000002', '1.833', '4.7830000000000004', '4.3499999999999996', '1.883', '4.5670000000000002', '1.75', '4.5330000000000004', '3.3170000000000002', '3.8330000000000002', '2.1000000000000001', '4.633', '2', '4.7999999999999998', '4.7160000000000002', '1.833', '4.8330000000000002', '1.7330000000000001', '4.883', '3.7170000000000001', '1.667', '4.5670000000000002', '4.3170000000000002', '2.2330000000000001', '4.5', '1.75', '4.7999999999999998', '1.8169999999999999', '4.4000000000000004', '4.1669999999999998', '4.7000000000000002', '2.0670000000000002', '4.7000000000000002', '4.0330000000000004', '1.9670000000000001', '4.5', '4', '1.9830000000000001', '5.0670000000000002', '2.0169999999999999', '4.5670000000000002', '3.883', '3.6000000000000001', '4.133', '4.3330000000000002', '4.0999999999999996', '2.633', '4.0670000000000002', '4.9329999999999998', '3.9500000000000002', '4.5170000000000003', '2.1669999999999998', '4', '2.2000000000000002', '4.3330000000000002', '1.867', '4.8170000000000002', '1.833', '4.2999999999999998', '4.6669999999999998', '3.75', '1.867', '4.9000000000000004', '2.4830000000000001', '4.367', '2.1000000000000001', '4.5', '4.0499999999999998', '1.867', '4.7000000000000002', '1.7829999999999999', '4.8499999999999996', '3.6829999999999998', '4.7329999999999997', '2.2999999999999998', '4.9000000000000004', '4.4169999999999998', '1.7', '4.633', '2.3170000000000002', '4.5999999999999996', '1.8169999999999999', '4.4169999999999998', '2.617', '4.0670000000000002', '4.25', '1.9670000000000001', '4.5999999999999996', '3.7669999999999999', '1.917', '4.5', '2.2669999999999999', '4.6500000000000004', '1.867', '4.1669999999999998', '2.7999999999999998', '4.3330000000000002', '1.833', '4.383', '1.883', '4.9329999999999998', '2.0329999999999999', '3.7330000000000001', '4.2329999999999997', '2.2330000000000001', '4.5330000000000004', '4.8170000000000002', '4.3330000000000002', '1.9830000000000001', '4.633', '2.0169999999999999', '5.0999999999999996', '1.8', '5.0330000000000004', '4', '2.3999999999999999', '4.5999999999999996', '3.5670000000000002', '4', '4.5', '4.0830000000000002', '1.8', '3.9670000000000001', '2.2000000000000002', '4.1500000000000004', '2', '3.8330000000000002', '3.5', '4.5830000000000002', '2.367', '5', '1.9330000000000001', '4.617', '1.917', '2.0830000000000002', '4.5830000000000002', '3.3330000000000002', '4.1669999999999998', '4.3330000000000002', '4.5', '2.4169999999999998', '4', '4.1669999999999998', '1.883', '4.5830000000000002', '4.25', '3.7669999999999999', '2.0329999999999999', '4.4329999999999998', '4.0830000000000002', '1.833', '4.4169999999999998', '2.1829999999999998', '4.7999999999999998', '1.833', '4.7999999999999998', '4.0999999999999996', '3.9660000000000002', '4.2329999999999997', '3.5', '4.3659999999999997', '2.25', '4.6669999999999998', '2.1000000000000001', '4.3499999999999996', '4.133', '1.867', '4.5999999999999996', '1.7829999999999999', '4.367', '3.8500000000000001', '1.9330000000000001', '4.5', '2.383', '4.7000000000000002', '1.867', '3.8330000000000002', '3.4169999999999998', '4.2329999999999997', '2.3999999999999999', '4.7999999999999998', '2', '4.1500000000000004', '1.867', '4.2670000000000003', '1.75', '4.4829999999999997', '4', '4.117', '4.0830000000000002', '4.2670000000000003', '3.9169999999999998', '4.5499999999999998', '4.0830000000000002', '2.4169999999999998', '4.1829999999999998', '2.2170000000000001', '4.4500000000000002', '1.883', '1.8500000000000001', '4.2830000000000004', '3.9500000000000002', '2.3330000000000002', '4.1500000000000004', '2.3500000000000001', '4.9329999999999998', '2.8999999999999999', '4.5830000000000002', '3.8330000000000002', '2.0830000000000002', '4.367', '2.133', '4.3499999999999996', '2.2000000000000002', '4.4500000000000002', '3.5670000000000002', '4.5', '4.1500000000000004', '3.8170000000000002', '3.9169999999999998', '4.4500000000000002', '2', '4.2830000000000004', '4.7670000000000003', '4.5330000000000004', '1.8500000000000001', '4.25', '1.9830000000000001', '2.25', '4.75', '4.117', '2.1499999999999999', '4.4169999999999998', '1.8169999999999999', '4.4669999999999996'],
	z60 => ['-0.6259765625', '0.18359375', '-0.8359375', '1.595703125', '0.3291015625', '-0.8203125', '0.4873046875', '0.73828125', '0.576171875', '-0.3056640625', '1.51171875', '0.3896484375', '-0.62109375', '-2.21484375', '1.125', '-0.044921875', '-0.0166015625', '0.943359375', '0.8212890625', '0.59375', '0.9189453125', '0.7822265625', '0.07421875', '-1.9892578125', '0.6201171875', '-0.0556640625', '-0.15625', '-1.470703125', '-0.478515625', '0.41796875', '1.3583984375', '-0.1025390625', '0.3876953125', '-0.0537109375', '-1.376953125', '-0.4150390625', '-0.39453125', '-0.0595703125', '1.099609375', '0.7626953125', '-0.1640625', '-0.2529296875', '0.697265625', '0.556640625', '-0.6884765625', '-0.70703125', '0.3642578125', '0.7685546875', '-0.1123046875', '0.880859375', '0.3984375', '-0.6123046875', '0.3408203125', '-1.12890625', '1.4326171875', '1.98046875', '-0.3671875', '-1.0439453125', '0.5693359375', '-0.134765625'],
	z200 => ['2.4013671875', '-0.0390625', '0.689453125', '0.0283203125', '-0.7431640625', '0.1884765625', '-1.8046875', '1.4658203125', '0.1533203125', '2.1728515625', '0.4755859375', '-0.7099609375', '0.6103515625', '-0.9345703125', '-1.25390625', '0.291015625', '-0.443359375', '0.0009765625', '0.07421875', '-0.58984375', '-0.568359375', '-0.134765625', '1.177734375', '-1.5234375', '0.59375', '0.3330078125', '1.0634765625', '-0.3037109375', '0.3701171875', '0.267578125', '-0.54296875', '1.2080078125', '1.16015625', '0.7001953125', '1.5869140625', '0.55859375', '-1.2763671875', '-0.5732421875', '-1.224609375', '-0.4736328125', '-0.6201171875', '0.0419921875', '-0.9111328125', '0.158203125', '-0.654296875', '1.767578125', '0.716796875', '0.91015625', '0.3837890625', '1.6826171875', '-0.6357421875', '-0.4619140625', '1.4326171875', '-0.650390625', '-0.20703125', '-0.392578125', '-0.3203125', '-0.279296875', '0.494140625', '-0.177734375', '-0.505859375', '1.3427734375', '-0.21484375', '-0.1796875', '-0.1005859375', '0.712890625', '-0.0732421875', '-0.0380859375', '-0.681640625', '-0.32421875', '0.060546875', '-0.5888671875', '0.53125', '-1.5185546875', '0.306640625', '-1.5361328125', '-0.30078125', '-0.5283203125', '-0.65234375', '-0.056640625', '-1.9140625', '1.1767578125', '-1.6650390625', '-0.4638671875', '-1.1162109375', '-0.7509765625', '2.0869140625', '0.017578125', '-1.2861328125', '-1.640625', '0.4501953125', '-0.0185546875', '-0.318359375', '-0.9296875', '-1.4873046875', '-1.0751953125', '1', '-0.62109375', '-1.384765625', '1.869140625', '0.4248046875', '-0.23828125', '1.05859375', '0.88671875', '-0.619140625', '2.2060546875', '-0.2548828125', '-1.4248046875', '-0.14453125', '0.2080078125', '2.3076171875', '0.10546875', '0.45703125', '-0.0771484375', '-0.333984375', '-0.03515625', '0.7880859375', '2.0751953125', '1.02734375', '1.2080078125', '-1.2314453125', '0.984375', '0.2197265625', '-1.466796875', '0.521484375', '-0.1591796875', '1.46484375', '-0.765625', '-0.4306640625', '-0.92578125', '-0.1767578125', '0.40234375', '-0.7314453125', '0.830078125', '-1.2080078125', '-1.0478515625', '1.44140625', '-1.015625', '0.412109375', '-0.380859375', '0.4091796875', '1.6884765625', '1.5869140625', '-0.3310546875', '-2.28515625', '2.498046875', '0.6669921875', '0.541015625', '-0.013671875', '0.509765625', '-0.1640625', '0.4208984375', '-0.400390625', '-1.3701171875', '0.98828125', '1.51953125', '-0.30859375', '-1.2529296875', '0.642578125', '-0.044921875', '-1.7333984375', '0.001953125', '-0.6298828125', '-0.3408203125', '-1.15625', '1.802734375', '-0.3310546875', '-1.60546875', '0.197265625', '0.2626953125', '-0.9853515625', '-2.888671875', '-0.640625', '0.5703125', '-0.0595703125', '-0.0986328125', '0.560546875', '-1.1865234375', '1.0966796875', '-0.0048828125', '0.70703125', '1.0341796875', '0.2236328125', '-0.87890625', '1.1630859375', '-2', '-0.544921875', '-0.255859375', '-0.166015625', '1.0205078125', '0.1357421875', '0.4072265625', '-0.0693359375', '-0.248046875', '0.6953125', '1.146484375', '-2.4033203125', '0.572265625', '0.375', '-0.4248046875'],
	z9 => ['0.951171875', '-0.3896484375', '-0.2841796875', '0.857421875', '1.7197265625', '0.2705078125', '-0.421875', '-1.189453125', '-0.3310546875'],
	const => ['3', '3', '3', '3', '3', '3', '3', '3', '3', '3'],
	two => ['-1.5', '2.25'],
	ties => ['1', '1', '1', '1', '1', '2', '2', '2', '2', '2', '4', '4', '4'],
	withna => ['1', '2', undef, '4'],
	pr18151 => ['1', '2', undef, '4'],
	unif4096 => ['0.9892578125', '0.3974609375', '0.115234375', '0.0693359375', '0.244140625', '0.7919921875', '0.33984375', '0.9716796875', '0.166015625', '0.458984375', '0.171875', '0.2314453125', '0.7724609375', '0.0966796875', '0.453125', '0.0849609375', '0.560546875', '0.0087890625', '0.9853515625', '0.31640625', '0.6396484375', '0.294921875', '0.9970703125', '0.90625', '0.98828125', '0.0654296875', '0.626953125', '0.490234375', '0.970703125', '0.3623046875', '0.6796875', '0.263671875', '0.185546875', '0.185546875', '0.37890625', '0.8466796875', '0.498046875', '0.791015625', '0.8388671875', '0.45703125', '0.7998046875', '0.3818359375', '0.759765625', '0.4365234375', '0.904296875', '0.3193359375', '0.0830078125', '0.81640625', '0.8984375', '0.966796875', '0.5732421875', '0.7197265625', '0.7744140625', '0.6279296875', '0.72265625', '0.38671875', '0.1630859375', '0.1875', '0.3916015625', '0.2734375', '0.1923828125', '0.50390625', '0.763671875', '0.693359375', '0.5439453125', '0.6591796875', '0.46875', '0.4814453125', '0.3369140625', '0.4248046875', '0.287109375', '0.6015625', '0.8408203125', '0.62109375', '0.134765625', '0.5673828125', '0.443359375', '0.4375', '0.6240234375', '0.9326171875', '0.888671875', '0.87890625', '0.2421875', '0.7412109375', '0.3876953125', '0.0791015625', '0.0947265625', '0.76171875', '0.34765625', '0.4169921875', '0.34375', '0.0087890625', '0.9111328125', '0.1826171875', '0.72265625', '0.572265625', '0.5400390625', '0.3544921875', '0.82421875', '0.1865234375', '0.396484375', '0.486328125', '0.4970703125', '0.38671875', '0.6435546875', '0.34375', '0.9560546875', '0.04296875', '0.765625', '0.2041015625', '0.6845703125', '0.396484375', '0.05859375', '0.736328125', '0.625', '0.62890625', '0.56640625', '0.7890625', '0.1845703125', '0.8330078125', '0.5302734375', '0.47265625', '0.5634765625', '0.2216796875', '0.70703125', '0.3212890625', '0.759765625', '0.16015625', '0.625', '0.1083984375', '0.8662109375', '0.7783203125', '0.779296875', '0.5048828125', '0.8759765625', '0.6572265625', '0.896484375', '0.8095703125', '0.7578125', '0.8056640625', '0.6669921875', '0.513671875', '0.177734375', '0.5625', '0.26953125', '0.71875', '0.193359375', '0.923828125', '0.05078125', '0.966796875', '0.0927734375', '0.9033203125', '0.1865234375', '0.203125', '0.2880859375', '0.798828125', '0.4755859375', '0.7705078125', '0.9921875', '0.8115234375', '0.6337890625', '0.845703125', '0.501953125', '0.6630859375', '0.51171875', '0.5244140625', '0.3466796875', '0.8095703125', '0.2138671875', '0.4228515625', '0.3779296875', '0.7841796875', '0.3642578125', '0.7314453125', '0.3798828125', '0.71484375', '0.037109375', '0.4990234375', '0.7216796875', '0.978515625', '0.94921875', '0.2958984375', '0.259765625', '0.923828125', '0.732421875', '0.7392578125', '0.59375', '0.080078125', '0.8017578125', '0.2607421875', '0.283203125', '0.7138671875', '0.8681640625', '0.701171875', '0.0615234375', '0.4375', '0.3310546875', '0.904296875', '0.4404296875', '0.384765625', '0.6982421875', '0.8740234375', '0.7216796875', '0.4423828125', '0.46875', '0.8662109375', '0.1201171875', '0.0166015625', '0.62109375', '0.4501953125', '0.0546875', '0.3974609375', '0.8388671875', '0.5166015625', '0.8466796875', '0.3388671875', '0.7998046875', '0.72265625', '0.5478515625', '0.2900390625', '0.3349609375', '0.65234375', '0.6767578125', '0.734375', '0.740234375', '0.2421875', '0.7294921875', '0.2578125', '0.1865234375', '0.9052734375', '0.9384765625', '0.966796875', '0.107421875', '0.38671875', '0.865234375', '0.39453125', '0.8369140625', '0.0517578125', '0.619140625', '0.5283203125', '0.0595703125', '0.130859375', '0.94140625', '0.7255859375', '0.7548828125', '0.4541015625', '0.4296875', '0.708984375', '0.7666015625', '0.2802734375', '0.9375', '0.0478515625', '0.693359375', '0.7275390625', '0.513671875', '0.3388671875', '0.0712890625', '0.67578125', '0.845703125', '0.42578125', '0.2763671875', '0.185546875', '0.7919921875', '0.29296875', '0.806640625', '0.3037109375', '0.6435546875', '0.5439453125', '0.8720703125', '0.5068359375', '0.224609375', '0.7080078125', '0.671875', '0.3955078125', '0.8203125', '0.931640625', '0.6064453125', '0.41015625', '0.8427734375', '0.3583984375', '0.072265625', '0.8369140625', '0.1904296875', '0.4169921875', '0.5654296875', '0.05078125', '0.58203125', '0.173828125', '0.685546875', '0.2783203125', '0.4716796875', '0.4755859375', '0.1875', '0.345703125', '0.6865234375', '0.7236328125', '0.6328125', '0.048828125', '0.1357421875', '0.5595703125', '0.361328125', '0.6494140625', '0.86328125', '0.3359375', '0.1826171875', '0.154296875', '0.41796875', '0.2890625', '0.7509765625', '0.556640625', '0.212890625', '0.828125', '0.0556640625', '0.82421875', '0.880859375', '0.8134765625', '0.8896484375', '0.4267578125', '0.49609375', '0.8115234375', '0.634765625', '0.9658203125', '0.537109375', '0.16796875', '0.5029296875', '0.9443359375', '0.771484375', '0.6142578125', '0.8515625', '0.3203125', '0.375', '0.921875', '0.626953125', '0.62890625', '0.7529296875', '0.388671875', '0.6259765625', '0.2509765625', '0.02734375', '0.32421875', '0.009765625', '0.4384765625', '0.685546875', '0.1875', '0.880859375', '0.47265625', '0.09765625', '0.39453125', '0.7314453125', '0.6875', '0.6005859375', '0.357421875', '0.7666015625', '0.0517578125', '0.9072265625', '0.3427734375', '0.55859375', '0.435546875', '0.2744140625', '0.1171875', '0.9853515625', '0.9267578125', '0.990234375', '0.556640625', '0.8720703125', '0.751953125', '0.423828125', '0.421875', '0.6826171875', '0.1220703125', '0.29296875', '0.1982421875', '0.8544921875', '0.048828125', '0.666015625', '0.3974609375', '0.0341796875', '0.1630859375', '0.244140625', '0.427734375', '0.0263671875', '0.6943359375', '0.88671875', '0.861328125', '0.3896484375', '0.34375', '0.13671875', '0.35546875', '0.458984375', '0.8701171875', '0.6396484375', '0.4775390625', '0.1884765625', '0.509765625', '0.4775390625', '0.1767578125', '0.2802734375', '0.1142578125', '0.740234375', '0.4970703125', '0.978515625', '0.6513671875', '0.8056640625', '0.9111328125', '0.490234375', '0.046875', '0.7255859375', '0.0986328125', '0.8876953125', '0.3935546875', '0.1201171875', '0.828125', '0.271484375', '0.951171875', '0.650390625', '0.1396484375', '0.0810546875', '0.451171875', '0.8916015625', '0.7880859375', '0.505859375', '0.8037109375', '0.052734375', '0.794921875', '0.2529296875', '0.923828125', '0.2822265625', '0.796875', '0.18359375', '0.9248046875', '0.931640625', '0.185546875', '0.4453125', '0.3564453125', '0.54296875', '0.0146484375', '0.150390625', '0.3681640625', '0.328125', '0.1298828125', '0.421875', '0.0234375', '0.1025390625', '0.4501953125', '0.830078125', '0.201171875', '0.681640625', '0.55859375', '0.2880859375', '0.1103515625', '0.892578125', '0.150390625', '0.494140625', '0.2001953125', '0.2138671875', '0.416015625', '0.34375', '0.068359375', '0.029296875', '0.693359375', '0.833984375', '0.9130859375', '0.3037109375', '0.404296875', '0.505859375', '0.0517578125', '0.3974609375', '0.4755859375', '0.9365234375', '0.7998046875', '0.0703125', '0.224609375', '0.4931640625', '0.5546875', '0.509765625', '0.1240234375', '0.4990234375', '0.390625', '0.33203125', '0.0712890625', '0.3427734375', '0.4619140625', '0.5615234375', '0.154296875', '0.1650390625', '0.279296875', '0.939453125', '0.8671875', '0.35546875', '0.9716796875', '0.974609375', '0.2646484375', '0.2705078125', '0.0263671875', '0.46875', '0.29296875', '0.0341796875', '0.205078125', '0.7900390625', '0.2548828125', '0.0693359375', '0.4677734375', '0.001953125', '0.2099609375', '0.08984375', '0.6982421875', '0.3955078125', '0.474609375', '0.3505859375', '0.16796875', '0.2734375', '0.9658203125', '0.2578125', '0.9990234375', '0.9609375', '0.1220703125', '0.4921875', '0.28125', '0.5615234375', '0.771484375', '0.2236328125', '0.9248046875', '0.060546875', '0.2509765625', '0.9970703125', '0.302734375', '0.8525390625', '0.794921875', '0.8203125', '0.876953125', '0.6806640625', '0.275390625', '0.2685546875', '0.7978515625', '0.5166015625', '0.66796875', '0.18359375', '0.6552734375', '0.91015625', '0.6884765625', '0.7890625', '0.400390625', '0.625', '0.4560546875', '0.4248046875', '0.7861328125', '0.138671875', '0.154296875', '0.5576171875', '0.53125', '0.9931640625', '0.3876953125', '0.822265625', '0.8310546875', '0.7705078125', '0.2099609375', '0.921875', '0.162109375', '0.89453125', '0.1318359375', '0.982421875', '0.47265625', '0.76171875', '0.8037109375', '0.0703125', '0.115234375', '0.27734375', '0.70703125', '0.5556640625', '0.490234375', '0.3046875', '0.771484375', '0.5595703125', '0.8291015625', '0.6708984375', '0.5361328125', '0.435546875', '0.26171875', '0.833984375', '0.888671875', '0.2509765625', '0.48046875', '0.94921875', '0.4931640625', '0.142578125', '0.8740234375', '0.4951171875', '0.60546875', '0.03125', '0.6416015625', '0.5068359375', '0.544921875', '0.40234375', '0.482421875', '0.1787109375', '0.884765625', '0.0146484375', '0.8837890625', '0.2578125', '0.4599609375', '0.7001953125', '0.123046875', '0.3916015625', '0.787109375', '0.521484375', '0.578125', '0.3486328125', '0.591796875', '0.337890625', '0.99609375', '0.1220703125', '0.42578125', '0.958984375', '0.908203125', '0.3994140625', '0.462890625', '0.1650390625', '0.4326171875', '0.8671875', '0.078125', '0.8349609375', '0.6015625', '0.8955078125', '0.3056640625', '0.9619140625', '0.1455078125', '0.00390625', '0.07421875', '0.7451171875', '0.005859375', '0.880859375', '0.2578125', '0.6533203125', '0.5', '0.1171875', '0.6796875', '0.3603515625', '0.826171875', '0.0712890625', '0.935546875', '0.1376953125', '0.0439453125', '0.255859375', '0.91796875', '0.98828125', '0.6669921875', '0.53515625', '0.1083984375', '0.7783203125', '0.4951171875', '0.26953125', '0.984375', '0.560546875', '0.75', '0.27734375', '0.8271484375', '0.16796875', '0.2802734375', '0.279296875', '0.21875', '0.744140625', '0.8037109375', '0.3857421875', '0.4794921875', '0.8173828125', '0.8876953125', '0.5791015625', '0.6689453125', '0.4794921875', '0.236328125', '0.181640625', '0.9208984375', '0.126953125', '0.765625', '0.8388671875', '0.5341796875', '0.544921875', '0.8583984375', '0.875', '0.169921875', '0.181640625', '0.10546875', '0.134765625', '0.970703125', '0.05078125', '0.61328125', '0.052734375', '0.7890625', '0.201171875', '0.5595703125', '0.86328125', '0.7509765625', '0.8916015625', '0.1787109375', '0.568359375', '0.1044921875', '0.5478515625', '0.072265625', '0.7109375', '0.2216796875', '0.6884765625', '0.2412109375', '0.47265625', '0.490234375', '0.0888671875', '0.0302734375', '0.7880859375', '0.568359375', '0.3740234375', '0.962890625', '0.3603515625', '0.162109375', '0.3046875', '0.6630859375', '0.0302734375', '0.46484375', '0.1708984375', '0.634765625', '0.98828125', '0.4765625', '0.580078125', '0.9375', '0.0107421875', '0.080078125', '0.4775390625', '0.6708984375', '0.525390625', '0.8681640625', '0.7607421875', '0.3955078125', '0.2763671875', '0.125', '0.6171875', '0.794921875', '0.7392578125', '0.369140625', '0.982421875', '0.56640625', '0.8203125', '0.2021484375', '0.0576171875', '0.703125', '0.83984375', '0.34765625', '0.6845703125', '0.6669921875', '0.3837890625', '0.2470703125', '0.79296875', '0.203125', '0.1591796875', '0.8330078125', '0.708984375', '0.98828125', '0.6103515625', '0.8134765625', '0.8203125', '0.9619140625', '0.0419921875', '0.6044921875', '0.0693359375', '0.9853515625', '0.9873046875', '0.2666015625', '0.650390625', '0.9765625', '0.7451171875', '0.0185546875', '0.3916015625', '0.4833984375', '0.6083984375', '0.689453125', '0.01171875', '0.6318359375', '0.818359375', '0.7880859375', '0.138671875', '0.0771484375', '0.4150390625', '0.060546875', '0.2314453125', '0.5283203125', '0.583984375', '0.4130859375', '0.173828125', '0.2236328125', '0.267578125', '0.9375', '0.5966796875', '0.6181640625', '0.64453125', '0.73046875', '0.734375', '0.4833984375', '0.1416015625', '0.69921875', '0.2392578125', '0.6123046875', '0.8173828125', '0.3193359375', '0.375', '0.48046875', '0.8779296875', '0.783203125', '0.2666015625', '0.1044921875', '0.8935546875', '0.2861328125', '0.9248046875', '0.740234375', '0.77734375', '0.0185546875', '0.7119140625', '0.2822265625', '0.9453125', '0.9970703125', '0.4609375', '0.3828125', '0.0732421875', '0.376953125', '0.3984375', '0.3544921875', '0.021484375', '0.4599609375', '0.7216796875', '0.3818359375', '0.5634765625', '0.767578125', '0.544921875', '0.4130859375', '0.7158203125', '0.0986328125', '0.1669921875', '0.5703125', '0.625', '0.12890625', '0.4306640625', '0.2421875', '0.1806640625', '0.3837890625', '0.0322265625', '0.5908203125', '0.748046875', '0.3466796875', '0.45703125', '0.0322265625', '0.94140625', '0.7548828125', '0.19921875', '0.5390625', '0.8642578125', '0.6142578125', '0.6181640625', '0.107421875', '0.21875', '0.6708984375', '0.484375', '0.5966796875', '0.8662109375', '0.6591796875', '0.7041015625', '0.771484375', '0.3583984375', '0.2607421875', '0.4580078125', '0.947265625', '0.630859375', '0.365234375', '0.791015625', '0.4365234375', '0.0458984375', '0.80078125', '0.7470703125', '0.0634765625', '0.2138671875', '0.400390625', '0.9365234375', '0.990234375', '0.068359375', '0.607421875', '0.2509765625', '0.451171875', '0.953125', '0.5107421875', '0.7294921875', '0.5341796875', '0.408203125', '0.8369140625', '0.7275390625', '0.7998046875', '0.123046875', '0.8046875', '0.1220703125', '0.125', '0.1923828125', '0.146484375', '0.3974609375', '0.048828125', '0.310546875', '0.927734375', '0.095703125', '0.5546875', '0.978515625', '0.701171875', '0.224609375', '0.5517578125', '0.404296875', '0.8095703125', '0.86328125', '0.984375', '0.171875', '0.0244140625', '0.1279296875', '0.6396484375', '0.1884765625', '0.9462890625', '0.697265625', '0.140625', '0.3681640625', '0.7587890625', '0.4912109375', '0.515625', '0.458984375', '0.3837890625', '0.6181640625', '0.568359375', '0.7900390625', '0.583984375', '0.4853515625', '0.2001953125', '0.072265625', '0.1689453125', '0.2666015625', '0.8134765625', '0.4326171875', '0.30078125', '0.8994140625', '0.193359375', '0.3994140625', '0.9775390625', '0.4345703125', '0.595703125', '0.3349609375', '0.556640625', '0.4775390625', '0.4306640625', '0.07421875', '0.283203125', '0.9697265625', '0.7275390625', '0.546875', '0.1396484375', '0.6630859375', '0.640625', '0.9423828125', '0.0048828125', '0.400390625', '0.5205078125', '0.4775390625', '0.08984375', '0.4912109375', '0.1689453125', '0.990234375', '0.36328125', '0.4609375', '0.658203125', '0.56640625', '0.1982421875', '0.3935546875', '0.0908203125', '0.80078125', '0.115234375', '0.9208984375', '0.8427734375', '0.05859375', '0.8681640625', '0.5673828125', '0.5947265625', '0.06640625', '0.44921875', '0.83984375', '0.908203125', '0.8935546875', '0.5107421875', '0.4853515625', '0.9306640625', '0.3408203125', '0.4140625', '0.900390625', '0.1103515625', '0.1318359375', '0.943359375', '0.2021484375', '0.072265625', '0.93359375', '0.8369140625', '0.8154296875', '0.951171875', '0.32421875', '0.7802734375', '0.41796875', '0.8125', '0.2783203125', '0.96875', '0.24609375', '0.9052734375', '0.8427734375', '0.193359375', '0.2197265625', '0.2666015625', '0.0234375', '0.4765625', '0.181640625', '0.40625', '0.287109375', '0.4833984375', '0.111328125', '0.626953125', '0.0341796875', '0.26171875', '0.3447265625', '0.1396484375', '0.9833984375', '0.7119140625', '0.921875', '0.228515625', '0.7138671875', '0.3642578125', '0.1396484375', '0.1064453125', '0.1728515625', '0.1845703125', '0.4033203125', '0.1201171875', '0.861328125', '0.7421875', '0.7119140625', '0.2451171875', '0.0146484375', '0.376953125', '0.8095703125', '0.58984375', '0.7998046875', '0.35546875', '0.4794921875', '0.2783203125', '0.2451171875', '0.787109375', '0.033203125', '0.587890625', '0.611328125', '0.908203125', '0.01171875', '0.232421875', '0.7685546875', '0.1416015625', '0.5576171875', '0.2421875', '0.2578125', '0.9912109375', '0.287109375', '0.2021484375', '0.630859375', '0.8779296875', '0.5126953125', '0.8359375', '0.8916015625', '0.0908203125', '0.5224609375', '0.48046875', '0.4423828125', '0.1611328125', '0.2763671875', '0.806640625', '0.103515625', '0.1904296875', '0.2470703125', '0.0029296875', '0.435546875', '0.30859375', '0.330078125', '0.4873046875', '0.28125', '0.470703125', '0.943359375', '0.767578125', '0.9384765625', '0.3388671875', '0.7587890625', '0.83203125', '0.474609375', '0.751953125', '0.2294921875', '0.9404296875', '0.150390625', '0.423828125', '0.3837890625', '0.51171875', '0.07421875', '0.998046875', '0.4892578125', '0.880859375', '0.9404296875', '0.267578125', '0.1611328125', '0.791015625', '0.501953125', '0.845703125', '0.482421875', '0.51953125', '0.2451171875', '0.6953125', '0.4482421875', '0.158203125', '0.5615234375', '0.4306640625', '0.8994140625', '0.67578125', '0.853515625', '0.6650390625', '0.35546875', '0.3349609375', '0.458984375', '0.98046875', '0.994140625', '0.849609375', '0.21875', '0.9609375', '0.775390625', '0.671875', '0.5087890625', '0.509765625', '0.0498046875', '0.306640625', '0.1865234375', '0.5302734375', '0.271484375', '0.1845703125', '0.416015625', '0.4296875', '0.9296875', '0.095703125', '0.6796875', '0.166015625', '0.9658203125', '0.0302734375', '0.97265625', '0.751953125', '0.294921875', '0.650390625', '0.349609375', '0.84375', '0.1943359375', '0.1083984375', '0.34375', '0.6484375', '0.7255859375', '0.681640625', '0.5322265625', '0.2265625', '0.6298828125', '0.5166015625', '0.322265625', '0.2861328125', '0.640625', '0.0048828125', '0.302734375', '0.2890625', '0.7216796875', '0.8994140625', '0.947265625', '0.3046875', '0.671875', '0.3408203125', '0.8955078125', '0.658203125', '0.2822265625', '0.7392578125', '0.6240234375', '0.1630859375', '0.0146484375', '0.255859375', '0.9912109375', '0.4326171875', '0.8359375', '0.33984375', '0.73046875', '0.27734375', '0.3759765625', '0.8779296875', '0.591796875', '0.6083984375', '0.9814453125', '0.3095703125', '0.7431640625', '0.830078125', '0.4853515625', '0.107421875', '0.240234375', '0.6533203125', '0.109375', '0.8828125', '0.5537109375', '0.47265625', '0.3544921875', '0.931640625', '0.515625', '0.017578125', '0.556640625', '0.873046875', '0.5419921875', '0.56640625', '0.7265625', '0.669921875', '0.453125', '0.884765625', '0.7119140625', '0.1806640625', '0.5166015625', '0.3232421875', '0.525390625', '0.982421875', '0.9287109375', '0.013671875', '0.318359375', '0.61328125', '0.564453125', '0.689453125', '0.6201171875', '0.1328125', '0.7861328125', '0.9892578125', '0.1708984375', '0.4267578125', '0.8173828125', '0.9794921875', '0.3671875', '0.2529296875', '0.9375', '0.3037109375', '0.6513671875', '0.919921875', '0.6904296875', '0.0869140625', '0.740234375', '0.7421875', '0.482421875', '0.5751953125', '0.087890625', '0.875', '0.72265625', '0.2763671875', '0.0234375', '0.888671875', '0.8212890625', '0.7216796875', '0.2333984375', '0.951171875', '0.4130859375', '0.1875', '0.619140625', '0.2626953125', '0.83984375', '0.0166015625', '0.470703125', '0.599609375', '0.4951171875', '0.55078125', '0.8427734375', '0.1640625', '0.599609375', '0.3046875', '0.1591796875', '0.8271484375', '0.2119140625', '0.0595703125', '0.880859375', '0.138671875', '0.794921875', '0.1728515625', '0.8291015625', '0.0341796875', '0.10546875', '0.7734375', '0.056640625', '0.5380859375', '0.4912109375', '0.873046875', '0.12109375', '0.5224609375', '0.2919921875', '0.32421875', '0.1484375', '0.203125', '0.505859375', '0.66015625', '0.0556640625', '0.2822265625', '0.119140625', '0.1640625', '0.7841796875', '0.1953125', '0.970703125', '0.5341796875', '0.33984375', '0.0595703125', '0.7509765625', '0.052734375', '0.1953125', '0.544921875', '0.4521484375', '0.02734375', '0.236328125', '0.22265625', '0.322265625', '0.2490234375', '0.478515625', '0.8408203125', '0.9677734375', '0.8525390625', '0.71875', '0.1650390625', '0.53515625', '0.7099609375', '0.833984375', '0.8818359375', '0.8505859375', '0.76171875', '0.265625', '0.7412109375', '0.4765625', '0.9326171875', '0.19921875', '0.8740234375', '0.57421875', '0.34375', '0.3330078125', '0.0732421875', '0.03515625', '0.7001953125', '0.431640625', '0.0380859375', '0.23046875', '0.087890625', '0.4990234375', '0.8408203125', '0.46875', '0.5439453125', '0.421875', '0.2734375', '0.0478515625', '0.8974609375', '0.17578125', '0.99609375', '0.2255859375', '0.0771484375', '0.455078125', '0.2099609375', '0.3193359375', '0.49609375', '0.193359375', '0.130859375', '0.0576171875', '0.98046875', '0.7021484375', '0.6484375', '0.349609375', '0.7822265625', '0.07421875', '0.236328125', '0.859375', '0.87890625', '0.646484375', '0.83984375', '0.16015625', '0.9814453125', '0.8642578125', '0.4130859375', '0.2587890625', '0.1416015625', '0.498046875', '0.6044921875', '0.4462890625', '0.8310546875', '0.9033203125', '0.701171875', '0.0283203125', '0.20703125', '0.8876953125', '0.642578125', '0.27734375', '0.01171875', '0.6318359375', '0.9951171875', '0.9248046875', '0.279296875', '0.65625', '0.435546875', '0.2275390625', '0.1005859375', '0.91015625', '0.0625', '0.4267578125', '0.5166015625', '0.8349609375', '0.1357421875', '0.8212890625', '0.5576171875', '0.4794921875', '0.7177734375', '0.0751953125', '0.021484375', '0.853515625', '0.1357421875', '0.9873046875', '0.076171875', '0.7578125', '0.015625', '0.1201171875', '0.650390625', '0.310546875', '0.4296875', '0.609375', '0.0625', '0.7626953125', '0.029296875', '0.015625', '0.0634765625', '0.3251953125', '0.1044921875', '0.1650390625', '0.498046875', '0.2958984375', '0.5078125', '0.62109375', '0.259765625', '0.6630859375', '0.498046875', '0.669921875', '0.8330078125', '0.162109375', '0.1650390625', '0.2529296875', '0.060546875', '0.6005859375', '0.498046875', '0.2099609375', '0.8330078125', '0.6416015625', '0.21484375', '0.7744140625', '0.359375', '0.173828125', '0.412109375', '0.3779296875', '0.5546875', '0.4677734375', '0.5107421875', '0.732421875', '0.1748046875', '0.6455078125', '0.9931640625', '0.3359375', '0.8046875', '0.38671875', '0.9697265625', '0.3505859375', '0.2783203125', '0.8212890625', '0.3544921875', '0.845703125', '0.9755859375', '0.751953125', '0.634765625', '0.9130859375', '0.138671875', '0.4111328125', '0.740234375', '0.7265625', '0.7265625', '0.443359375', '0.373046875', '0.73046875', '0.5341796875', '0.8544921875', '0.9091796875', '0.998046875', '0.310546875', '0.7412109375', '0.1328125', '0.6357421875', '0.34765625', '0.146484375', '0.1923828125', '0.69140625', '0.0625', '0.4462890625', '0.4677734375', '0.111328125', '0.890625', '0.9765625', '0.720703125', '0.041015625', '0.7294921875', '0.6259765625', '0.88671875', '0.0234375', '0.2744140625', '0.765625', '0.9248046875', '0.3505859375', '0.1796875', '0.4755859375', '0.23046875', '0.0732421875', '0.5419921875', '0.54296875', '0.3330078125', '0.443359375', '0.9150390625', '0.9443359375', '0.8544921875', '0.9267578125', '0.2822265625', '0.47265625', '0.0634765625', '0.3740234375', '0.212890625', '0.4921875', '0.44921875', '0.0927734375', '0.3291015625', '0.3984375', '0.2900390625', '0.681640625', '0.7392578125', '0.822265625', '0.75390625', '0.1962890625', '0.673828125', '0.02734375', '0.279296875', '0.9404296875', '0.693359375', '0.1572265625', '0.1923828125', '0.330078125', '0.9658203125', '0.015625', '0.6357421875', '0.51953125', '0.3095703125', '0.412109375', '0.8134765625', '0.3720703125', '0.830078125', '0.6552734375', '0.734375', '0.150390625', '0.732421875', '0.0625', '0.8525390625', '0.9453125', '0.7724609375', '0.650390625', '0.4091796875', '0.814453125', '0.072265625', '0.69140625', '0.08984375', '0.2841796875', '0.46484375', '0.2548828125', '0.4365234375', '0.400390625', '0.8759765625', '0.599609375', '0.30078125', '0.58984375', '0.99609375', '0.607421875', '0.9365234375', '0.8583984375', '0.7236328125', '0.388671875', '0.39453125', '0.0087890625', '0.61328125', '0.724609375', '0.376953125', '0.4833984375', '0.3779296875', '0.736328125', '0.5830078125', '0.8740234375', '0.787109375', '0.1396484375', '0.9599609375', '0.5087890625', '0.748046875', '0.55078125', '0.974609375', '0.291015625', '0.0693359375', '0.0830078125', '0.1025390625', '0.443359375', '0.7255859375', '0.16796875', '0.2197265625', '0.7890625', '0.0517578125', '0.103515625', '0.849609375', '0.28515625', '0.6015625', '0.2763671875', '0.13671875', '0.263671875', '0.2236328125', '0.8349609375', '0.7900390625', '0.765625', '0.2958984375', '0.7666015625', '0.0283203125', '0.9501953125', '0.404296875', '0.73046875', '0.1982421875', '0.8583984375', '0.55859375', '0.8212890625', '0.302734375', '0.3798828125', '0.9951171875', '0.48828125', '0.1044921875', '0.466796875', '0.2685546875', '0.458984375', '0.3955078125', '0.140625', '0.900390625', '0.83984375', '0.5537109375', '0.8056640625', '0.126953125', '0.25', '0.3056640625', '0.3779296875', '0.568359375', '0.2744140625', '0.90234375', '0.1494140625', '0.3583984375', '0.8662109375', '0.9072265625', '0.572265625', '0.873046875', '0.51171875', '0.9755859375', '0.6787109375', '0.71875', '0.4072265625', '0.4033203125', '0.3232421875', '0.6201171875', '0.080078125', '0.3369140625', '0.51953125', '0.3232421875', '0.310546875', '0.943359375', '0.560546875', '0.27734375', '0.41796875', '0.9599609375', '0.5185546875', '0.0029296875', '0.974609375', '0.591796875', '0.4560546875', '0.5439453125', '0.1689453125', '0.306640625', '0.21875', '0.134765625', '0.53125', '0.5126953125', '0.0703125', '0.0146484375', '0.3583984375', '0.0400390625', '0.158203125', '0.01171875', '0.7099609375', '0.07421875', '0.9736328125', '0.431640625', '0.328125', '0.6572265625', '0.736328125', '0.5244140625', '0.00390625', '0.90234375', '0.6142578125', '0.244140625', '0.146484375', '0.5703125', '0.84765625', '0.03125', '0.2861328125', '0.30078125', '0.5283203125', '0.1669921875', '0.1279296875', '0.0732421875', '0.185546875', '0.59375', '0.279296875', '0.00390625', '0.2197265625', '0.9677734375', '0.5869140625', '0.654296875', '0.90234375', '0.1826171875', '0.8662109375', '0.2587890625', '0.265625', '0.9248046875', '0.947265625', '0.4130859375', '0.765625', '0.8798828125', '0.6533203125', '0.873046875', '0.13671875', '0.501953125', '0.837890625', '0.5693359375', '0.1923828125', '0.2744140625', '0.0126953125', '0.3017578125', '0.8212890625', '0.326171875', '0.2265625', '0.6015625', '0.75390625', '0.521484375', '0.98046875', '0.2607421875', '0.13671875', '0.4111328125', '0.3193359375', '0.3408203125', '0.5732421875', '0.9443359375', '0.0810546875', '0.9873046875', '0.513671875', '0.2373046875', '0.51171875', '0.1337890625', '0.203125', '0.4130859375', '0.5068359375', '0.275390625', '0.271484375', '0.607421875', '0.0595703125', '0.1953125', '0.435546875', '0.74609375', '0.40234375', '0.8828125', '0.4423828125', '0.318359375', '0.7177734375', '0.6005859375', '0.0078125', '0.88671875', '0.03515625', '0.4208984375', '0.3984375', '0.181640625', '0.1884765625', '0.2900390625', '0.1513671875', '0.4189453125', '0.0576171875', '0.36328125', '0.4833984375', '0.3359375', '0.94140625', '0.9765625', '0.0361328125', '0.88671875', '0.1572265625', '0.779296875', '0.46875', '0.966796875', '0.07421875', '0.4814453125', '0.5458984375', '0.662109375', '0.1142578125', '0.9765625', '0.97265625', '0.6728515625', '0.4580078125', '0.3857421875', '0.3125', '0.005859375', '0.1005859375', '0.083984375', '0.0986328125', '0.3017578125', '0.08984375', '0.4296875', '0.654296875', '0.513671875', '0.7021484375', '0.7275390625', '0.185546875', '0.93359375', '0.8564453125', '0.91796875', '0.4716796875', '0.431640625', '0.0244140625', '0.927734375', '0.794921875', '0.796875', '0.4794921875', '0.884765625', '0.9462890625', '0.83984375', '0.4443359375', '0.810546875', '0.6923828125', '0.263671875', '0.25390625', '0.20703125', '0.8173828125', '0.666015625', '0.6220703125', '0.2490234375', '0.4853515625', '0.4951171875', '0.8662109375', '0.29296875', '0.6533203125', '0.228515625', '0.2001953125', '0.6591796875', '0.8818359375', '0.2373046875', '0.560546875', '0.451171875', '0.9384765625', '0.791015625', '0.6943359375', '0.7626953125', '0.5244140625', '0.7578125', '0.3857421875', '0.9892578125', '0.904296875', '0.1376953125', '0.5078125', '0.80078125', '0.2900390625', '0.05859375', '0.4013671875', '0.73828125', '0.70703125', '0.7529296875', '0.603515625', '0.1201171875', '0.578125', '0.70703125', '0.921875', '0.72265625', '0.2900390625', '0.7138671875', '0.6787109375', '0.0185546875', '0.3076171875', '0.7490234375', '0.615234375', '0.6162109375', '0.2216796875', '0.1513671875', '0.998046875', '0.2314453125', '0.328125', '0.6982421875', '0.3486328125', '0.126953125', '0.4248046875', '0.5205078125', '0.82421875', '0.1318359375', '0.0673828125', '0.1845703125', '0.40625', '0.9296875', '0.6318359375', '0.7861328125', '0.5185546875', '0.984375', '0.720703125', '0.12890625', '0.9541015625', '0.3564453125', '0.4951171875', '0.4287109375', '0.80859375', '0.8662109375', '0.974609375', '0.3916015625', '0.216796875', '0.9765625', '0.5654296875', '0.765625', '0.5244140625', '0.4853515625', '0.4765625', '0.0302734375', '0.177734375', '0.2119140625', '0.3779296875', '0.5107421875', '0.4892578125', '0.9208984375', '0.857421875', '0.111328125', '0.37109375', '0.771484375', '0.1279296875', '0.130859375', '0.435546875', '0.43359375', '0.12890625', '0.5654296875', '0.6279296875', '0.9619140625', '0.119140625', '0.0615234375', '0.8623046875', '0.7861328125', '0.7861328125', '0.8115234375', '0.609375', '0.3564453125', '0.8828125', '0.58203125', '0.18359375', '0.4208984375', '0.8798828125', '0.63671875', '0.24609375', '0.5224609375', '0.4609375', '0.2255859375', '0.0107421875', '0.650390625', '0.3564453125', '0.42578125', '0.1962890625', '0.3564453125', '0.3349609375', '0.1943359375', '0.3466796875', '0.568359375', '0.25390625', '0.7060546875', '0.7109375', '0.701171875', '0.8876953125', '0.80078125', '0.2841796875', '0.5908203125', '0.052734375', '0.00390625', '0.83203125', '0.5322265625', '0.638671875', '0.7705078125', '0.392578125', '0.9111328125', '0.9326171875', '0.107421875', '0.029296875', '0.8125', '0.91015625', '0.9384765625', '0.8935546875', '0.833984375', '0.2216796875', '0.666015625', '0.5859375', '0.79296875', '0.357421875', '0.400390625', '0.2060546875', '0.0419921875', '0.7197265625', '0.1279296875', '0.1044921875', '0.041015625', '0.0625', '0.2080078125', '0.26171875', '0.0126953125', '0.81640625', '0.8505859375', '0.02734375', '0.0732421875', '0.4970703125', '0.6826171875', '0.76953125', '0.2099609375', '0.7978515625', '0.41796875', '0.884765625', '0.2744140625', '0.1650390625', '0.5361328125', '0.5625', '0.28515625', '0.7529296875', '0.6494140625', '0.66796875', '0.271484375', '0.740234375', '0.9580078125', '0.8955078125', '0.205078125', '0.66796875', '0.6630859375', '0.7568359375', '0.177734375', '0.6357421875', '0.9189453125', '0.6650390625', '0.943359375', '0.81640625', '0.345703125', '0.4140625', '0.7431640625', '0.68359375', '0.958984375', '0.927734375', '0.4306640625', '0.26171875', '0.830078125', '0.1806640625', '0.025390625', '0.1904296875', '0.001953125', '0.658203125', '0.9580078125', '0.037109375', '0.0732421875', '0.7802734375', '0.0341796875', '0.4794921875', '0.9970703125', '0.1484375', '0.6806640625', '0.3759765625', '0.712890625', '0.1435546875', '0.7294921875', '0.4169921875', '0.1943359375', '0.2763671875', '0.6474609375', '0.0546875', '0.8828125', '0.9638671875', '0.3994140625', '0.3828125', '0.7548828125', '0.1806640625', '0.0234375', '0.6982421875', '0.7890625', '0.6796875', '0.2783203125', '0.7744140625', '0.34765625', '0.6416015625', '0.5673828125', '0.740234375', '0.3916015625', '0.96484375', '0.8603515625', '0.3134765625', '0.46484375', '0.95703125', '0.0146484375', '0.359375', '0.1806640625', '0.4169921875', '0.0859375', '0.7958984375', '0.15625', '0.2255859375', '0.548828125', '0.5673828125', '0.3828125', '0.296875', '0.3974609375', '0.037109375', '0.10546875', '0.16015625', '0.123046875', '0.896484375', '0.58203125', '0.6455078125', '0.1259765625', '0.44921875', '0.8828125', '0.0517578125', '0.830078125', '0.0380859375', '0.4716796875', '0.123046875', '0.064453125', '0.2958984375', '0.01171875', '0.318359375', '0.97265625', '0.2138671875', '0.7431640625', '0.6484375', '0.6298828125', '0.2412109375', '0.0341796875', '0.0205078125', '0.9033203125', '0.162109375', '0.3271484375', '0.71484375', '0.5810546875', '0.2783203125', '0.28125', '0.3466796875', '0.1181640625', '0.25390625', '0.556640625', '0.2314453125', '0.9873046875', '0.9599609375', '0.857421875', '0.1982421875', '0.4208984375', '0.9638671875', '0.2705078125', '0.46875', '0.0908203125', '0.1318359375', '0.91015625', '0.4853515625', '0.818359375', '0.0458984375', '0.6806640625', '0.5', '0.27734375', '0.396484375', '0.224609375', '0.8017578125', '0.17578125', '0.5712890625', '0.486328125', '0.4638671875', '0.8330078125', '0.443359375', '0.2470703125', '0.6865234375', '0.1962890625', '0.3935546875', '0.9794921875', '0.166015625', '0.580078125', '0.130859375', '0.302734375', '0.9990234375', '0.4697265625', '0.166015625', '0.515625', '0.033203125', '0.2373046875', '0.1005859375', '0.9482421875', '0.984375', '0.986328125', '0.9921875', '0.3369140625', '0.986328125', '0.3876953125', '0.8193359375', '0.4404296875', '0.8154296875', '0.78515625', '0.236328125', '0.8837890625', '0.224609375', '0.3671875', '0.03515625', '0.78515625', '0.271484375', '0.263671875', '0.390625', '0.0673828125', '0.3193359375', '0.4462890625', '0.732421875', '0.576171875', '0.935546875', '0.8486328125', '0.8291015625', '0.4609375', '0.3046875', '0.46484375', '0.83203125', '0.90625', '0.0673828125', '0.6318359375', '0.41015625', '0.9873046875', '0.181640625', '0.2392578125', '0.8212890625', '0.2265625', '0.806640625', '0.6533203125', '0.357421875', '0.1640625', '0.71484375', '0.04296875', '0.197265625', '0.1640625', '0.6171875', '0.10546875', '0.6044921875', '0.44921875', '0.0986328125', '0.8935546875', '0.7724609375', '0.7578125', '0.3359375', '0.5966796875', '0.0400390625', '0.787109375', '0.822265625', '0.3037109375', '0.1884765625', '0.677734375', '0.6982421875', '0.548828125', '0.3583984375', '0.8310546875', '0.701171875', '0.7578125', '0.908203125', '0.17578125', '0.8701171875', '0.5927734375', '0.8369140625', '0.482421875', '0.470703125', '0.57421875', '0.9794921875', '0.6923828125', '0.419921875', '0.98828125', '0.1015625', '0.603515625', '0.34375', '0.4716796875', '0.3486328125', '0.7734375', '0.3125', '0.703125', '0.2939453125', '0.373046875', '0.1591796875', '0.1650390625', '0.572265625', '0.2060546875', '0.685546875', '0.87109375', '0.8359375', '0.4228515625', '0.251953125', '0.9853515625', '0.42578125', '0.01953125', '0.9453125', '0.0380859375', '0.79296875', '0.79296875', '0.138671875', '0.2978515625', '0.3359375', '0.7490234375', '0.0302734375', '0.6005859375', '0.689453125', '0.1064453125', '0.3896484375', '0.6689453125', '0.95703125', '0.0634765625', '0.3828125', '0.4541015625', '0.8779296875', '0.8466796875', '0.4013671875', '0.283203125', '0.8623046875', '0.98046875', '0.41015625', '0.1494140625', '0.36328125', '0.5390625', '0.56640625', '0.107421875', '0.115234375', '0.2060546875', '0.4013671875', '0.732421875', '0.5654296875', '0.232421875', '0.4560546875', '0.8154296875', '0.6796875', '0.0029296875', '0.2724609375', '0.3046875', '0.0302734375', '0.4111328125', '0.6318359375', '0.517578125', '0.85546875', '0.9560546875', '0.8984375', '0.9033203125', '0.724609375', '0.029296875', '0.9970703125', '0.9052734375', '0.681640625', '0.0791015625', '0.087890625', '0.876953125', '0.4814453125', '0.0087890625', '0.2021484375', '0.970703125', '0.6123046875', '0.95703125', '0.9189453125', '0.4482421875', '0.017578125', '0.90234375', '0.5703125', '0.4375', '0.7255859375', '0.5810546875', '0.2353515625', '0.583984375', '0.541015625', '0.7939453125', '0.3232421875', '0.0654296875', '0.4091796875', '0.4091796875', '0.6025390625', '0.189453125', '0.0791015625', '0.8115234375', '0.275390625', '0.34765625', '0.345703125', '0.8623046875', '0.185546875', '0.1591796875', '0.890625', '0.4013671875', '0.0517578125', '0.0302734375', '0.498046875', '0.0166015625', '0.6787109375', '0.5380859375', '0.54296875', '0.53125', '0.3203125', '0.298828125', '0.9951171875', '0.462890625', '0.513671875', '0.72265625', '0.912109375', '0.9716796875', '0.150390625', '0.3828125', '0.5390625', '0.4501953125', '0.0771484375', '0.37890625', '0.0732421875', '0.80859375', '0.0859375', '0.0302734375', '0.2607421875', '0.2333984375', '0.0439453125', '0.3935546875', '0.70703125', '0.673828125', '0.60546875', '0.7607421875', '0.017578125', '0.1650390625', '0.5361328125', '0.1748046875', '0.341796875', '0.263671875', '0.328125', '0.9208984375', '0.78125', '0.814453125', '0.6806640625', '0.1572265625', '0.3447265625', '0.8271484375', '0.650390625', '0.6572265625', '0.8037109375', '0.6865234375', '0.638671875', '0.3935546875', '0.5361328125', '0.2119140625', '0.9404296875', '0.802734375', '0.1298828125', '0.9130859375', '0.25', '0.005859375', '0.525390625', '0.3818359375', '0.2724609375', '0.203125', '0.7080078125', '0.658203125', '0.6064453125', '0.9208984375', '0.1640625', '0.5810546875', '0.44140625', '0.962890625', '0.111328125', '0.828125', '0.4736328125', '0.4892578125', '0.6962890625', '0.0625', '0.5498046875', '0.8798828125', '0.130859375', '0.20703125', '0.5068359375', '0.7041015625', '0.572265625', '0.486328125', '0.4365234375', '0.5458984375', '0.81640625', '0.6064453125', '0.4638671875', '0.9287109375', '0.2666015625', '0.1318359375', '0.486328125', '0.8271484375', '0.1630859375', '0.400390625', '0.537109375', '0.94140625', '0.796875', '0.2236328125', '0.24609375', '0.1796875', '0.9130859375', '0.677734375', '0.6953125', '0.1337890625', '0.04296875', '0.970703125', '0.015625', '0.0400390625', '0.7412109375', '0.7529296875', '0.0302734375', '0.392578125', '0.615234375', '0.3125', '0.576171875', '0.0771484375', '0.7314453125', '0.884765625', '0.732421875', '0.7880859375', '0.9794921875', '0.9765625', '0.17578125', '0.365234375', '0.322265625', '0.0439453125', '0.5791015625', '0.234375', '0.087890625', '0.216796875', '0.2080078125', '0.22265625', '0.291015625', '0.982421875', '0.736328125', '0.1171875', '0.740234375', '0.037109375', '0.0087890625', '0.765625', '0.658203125', '0.5', '0.546875', '0.716796875', '0.748046875', '0.5458984375', '0.1005859375', '0.017578125', '0.373046875', '0.62109375', '0.984375', '0.1728515625', '0.5302734375', '0.2431640625', '0.5', '0.30078125', '0.939453125', '0.6474609375', '0.47265625', '0.2861328125', '0.6181640625', '0.484375', '0.8974609375', '0.0810546875', '0.083984375', '0.8466796875', '0.287109375', '0.5966796875', '0.900390625', '0.5556640625', '0.8037109375', '0.6171875', '0.42578125', '0.921875', '0.9970703125', '0.75', '0.6513671875', '0.6845703125', '0.646484375', '0.6904296875', '0.740234375', '0.931640625', '0.0283203125', '0.4189453125', '0.7333984375', '0.1279296875', '0.458984375', '0.0556640625', '0.9033203125', '0.654296875', '0.716796875', '0.0009765625', '0.6904296875', '0.2431640625', '0.5458984375', '0.1220703125', '0.2724609375', '0.0205078125', '0.916015625', '0.2333984375', '0.9599609375', '0.8896484375', '0.2109375', '0.1962890625', '0.7099609375', '0.6787109375', '0.1953125', '0.560546875', '0.59765625', '0.4990234375', '0.9208984375', '0.8076171875', '0.4150390625', '0.5166015625', '0.31640625', '0.8974609375', '0.689453125', '0.009765625', '0.125', '0.96875', '0.443359375', '0.0361328125', '0.466796875', '0.607421875', '0.208984375', '0.54296875', '0.7216796875', '0.7216796875', '0.53515625', '0.5986328125', '0.849609375', '0.1630859375', '0.1708984375', '0.0166015625', '0.966796875', '0.3896484375', '0.3974609375', '0.7607421875', '0.3369140625', '0.708984375', '0.375', '0.4365234375', '0.638671875', '0.947265625', '0.939453125', '0.2568359375', '0.13671875', '0.392578125', '0.74609375', '0.1064453125', '0.12890625', '0.5810546875', '0.1142578125', '0.947265625', '0.50390625', '0.6708984375', '0.20703125', '0.3369140625', '0.2734375', '0.14453125', '0.1416015625', '0.0146484375', '0.3125', '0.013671875', '0.4453125', '0.2041015625', '0.0400390625', '0.501953125', '0.9599609375', '0.7890625', '0.0947265625', '0.26953125', '0.9599609375', '0.123046875', '0.595703125', '0.884765625', '0.88671875', '0.0107421875', '0.099609375', '0.189453125', '0.654296875', '0.16015625', '0.63671875', '0.787109375', '0.3095703125', '0.4599609375', '0.9541015625', '0.0908203125', '0.103515625', '0.2734375', '0.2783203125', '0.6494140625', '0.4453125', '0.525390625', '0.18359375', '0.375', '0.19140625', '0.958984375', '0.533203125', '0.9443359375', '0.1494140625', '0.48828125', '0.2822265625', '0.2890625', '0.2138671875', '0.4990234375', '0.3359375', '0.87109375', '0.65234375', '0.2109375', '0.00390625', '0.0947265625', '0.6787109375', '0.4462890625', '0.6337890625', '0.513671875', '0.3623046875', '0.8251953125', '0.25', '0.2060546875', '0.2626953125', '0.15234375', '0.2109375', '0.03125', '0.52734375', '0.46484375', '0.3720703125', '0.9453125', '0.478515625', '0.513671875', '0.6083984375', '0.986328125', '0.3349609375', '0.8564453125', '0.99609375', '0.1787109375', '0.9208984375', '0.7685546875', '0.5205078125', '0.357421875', '0.7138671875', '0.5400390625', '0.224609375', '0.1689453125', '0.4365234375', '0.10546875', '0.189453125', '0.3603515625', '0.1455078125', '0.109375', '0.8466796875', '0.982421875', '0.986328125', '0.607421875', '0.8173828125', '0.1455078125', '0.17578125', '0.275390625', '0.7724609375', '0.9072265625', '0.0185546875', '0.80078125', '0.5078125', '0.65625', '0.9580078125', '0.267578125', '0.8125', '0.3974609375', '0.0537109375', '0.681640625', '0.88671875', '0.5849609375', '0.572265625', '0.349609375', '0.7314453125', '0.2890625', '0.5244140625', '0.4453125', '0.201171875', '0.9248046875', '0.01953125', '0.78125', '0.7568359375', '0.158203125', '0.525390625', '0.2158203125', '0.263671875', '0.595703125', '0.029296875', '0.802734375', '0.9033203125', '0.095703125', '0.8359375', '0.2138671875', '0.962890625', '0.322265625', '0.646484375', '0.1435546875', '0.8193359375', '0.720703125', '0.7314453125', '0.1552734375', '0.8779296875', '0.4736328125', '0.94921875', '0.7470703125', '0.2919921875', '0.6005859375', '0.794921875', '0.9423828125', '0.1298828125', '0.3388671875', '0.1005859375', '0.7919921875', '0.1064453125', '0.3623046875', '0.0185546875', '0.1416015625', '0.744140625', '0.8837890625', '0.66796875', '0.13671875', '0.7158203125', '0.2900390625', '0.9482421875', '0.9208984375', '0.9541015625', '0.3955078125', '0.8974609375', '0.87109375', '0.0419921875', '0.853515625', '0.154296875', '0.1455078125', '0.2431640625', '0.7822265625', '0.220703125', '0.5205078125', '0.5712890625', '0.69921875', '0.50390625', '0.7138671875', '0.39453125', '0.2314453125', '0.2861328125', '0.3232421875', '0.6396484375', '0.263671875', '0.26953125', '0.349609375', '0.8857421875', '0.65234375', '0.8935546875', '0.39453125', '0.8310546875', '0.625', '0.330078125', '0.224609375', '0.5458984375', '0.705078125', '0.798828125', '0.3681640625', '0.60546875', '0.560546875', '0.10546875', '0.921875', '0.9853515625', '0.9013671875', '0.1484375', '0.9091796875', '0.2001953125', '0.4599609375', '0.2744140625', '0.25', '0.8935546875', '0.0908203125', '0.62890625', '0.921875', '0.1474609375', '0.853515625', '0.8115234375', '0.8232421875', '0.724609375', '0.8271484375', '0.59765625', '0.05859375', '0.3701171875', '0.51953125', '0.8974609375', '0.0078125', '0.6044921875', '0.4111328125', '0.0498046875', '0.7724609375', '0.3720703125', '0.517578125', '0.4716796875', '0.1767578125', '0.2060546875', '0.6875', '0.271484375', '0.2958984375', '0.369140625', '0.7314453125', '0.0458984375', '0.6337890625', '0.1005859375', '0.9658203125', '0.8525390625', '0.5322265625', '0.4296875', '0.91796875', '0.8271484375', '0.279296875', '0.603515625', '0.8837890625', '0.947265625', '0.2255859375', '0.583984375', '0.5751953125', '0.2685546875', '0.2646484375', '0.1728515625', '0.9814453125', '0.2685546875', '0.3046875', '0.1728515625', '0.5576171875', '0.1328125', '0.5625', '0.126953125', '0.2900390625', '0.6689453125', '0.548828125', '0.5732421875', '0.638671875', '0.4248046875', '0.703125', '0.4560546875', '0.115234375', '0.9970703125', '0.5595703125', '0.7197265625', '0.431640625', '0.025390625', '0.427734375', '0.791015625', '0.4609375', '0.19921875', '0.5185546875', '0.900390625', '0.54296875', '0.9287109375', '0.8203125', '0.5390625', '0.34375', '0.0166015625', '0.154296875', '0.0859375', '0.0107421875', '0.1630859375', '0.884765625', '0.63671875', '0.0556640625', '0.6943359375', '0.16015625', '0.052734375', '0.8408203125', '0.767578125', '0.185546875', '0.7333984375', '0.3408203125', '0.974609375', '0.33984375', '0.673828125', '0.9638671875', '0.208984375', '0.2353515625', '0.7197265625', '0.7138671875', '0.3359375', '0.6748046875', '0.2470703125', '0.9052734375', '0.4013671875', '0.2216796875', '0.6982421875', '0.41015625', '0.9423828125', '0.4287109375', '0.0859375', '0.8662109375', '0.927734375', '0.3837890625', '0.6650390625', '0.6123046875', '0.681640625', '0.3212890625', '0.2255859375', '0.6552734375', '0.41796875', '0.2236328125', '0.4189453125', '0.197265625', '0.244140625', '0.388671875', '0.6767578125', '0.478515625', '0.0009765625', '0.193359375', '0.0966796875', '0.087890625', '0.849609375', '0.2666015625', '0.0869140625', '0.62890625', '0.724609375', '0.923828125', '0.89453125', '0.376953125', '0.595703125', '0.6376953125', '0.0927734375', '0.4287109375', '0.57421875', '0.5068359375', '0.9462890625', '0.03125', '0.91015625', '0.212890625', '0.9912109375', '0.6591796875', '0.2138671875', '0.7353515625', '0.6767578125', '0.375', '0.384765625', '0.59765625', '0.029296875', '0.5927734375', '0.439453125', '0.185546875', '0.337890625', '0.0771484375', '0.978515625', '0.8828125', '0.5634765625', '0.55859375', '0.7265625', '0.759765625', '0.775390625', '0.1376953125', '0.171875', '0.8681640625', '0.22265625', '0.9072265625', '0.8486328125', '0.060546875', '0.5791015625', '0.099609375', '0.98046875', '0.9013671875', '0.447265625', '0.046875', '0.8740234375', '0.4375', '0.66796875', '0.587890625', '0.2900390625', '0.677734375', '0.5849609375', '0.431640625', '0.6845703125', '0.2421875', '0.45703125', '0.7607421875', '0.626953125', '0.51953125', '0.6962890625', '0.5048828125', '0.3076171875', '0.787109375', '0.421875', '0.6142578125', '0.7763671875', '0.759765625', '0.2822265625', '0.8984375', '0.775390625', '0.4091796875', '0.140625', '0.24609375', '0.78515625', '0.0146484375', '0.5732421875', '0.7470703125', '0.34765625', '0.9677734375', '0.1630859375', '0.0625', '0.5732421875', '0.763671875', '0.5087890625', '0.21875', '0.041015625', '0.1044921875', '0.1474609375', '0.5068359375', '0.4638671875', '0.751953125', '0.5087890625', '0.1357421875', '0.9580078125', '0.787109375', '0.0224609375', '0.4560546875', '0.673828125', '0.14453125', '0.9072265625', '0.8984375', '0.1767578125', '0.501953125', '0.583984375', '0.814453125', '0.478515625', '0.7626953125', '0.6767578125', '0.5263671875', '0.6884765625', '0.2880859375', '0.5712890625', '0.7236328125', '0.9189453125', '0.138671875', '0.830078125', '0.55859375', '0.7998046875', '0.5', '0.2939453125', '0.6591796875', '0.4169921875', '0.1025390625', '0.1474609375', '0.5966796875', '0.259765625', '0.2470703125', '0.0390625', '0.2021484375', '0.12890625', '0.744140625', '0.0537109375', '0.4296875', '0.2822265625', '0.7958984375', '0.689453125', '0.3349609375', '0.642578125', '0.359375', '0.615234375', '0.2373046875', '0.0283203125', '0.78125', '0.2685546875', '0.5400390625', '0.3251953125', '0.8369140625', '0.3076171875', '0.5625', '0.37109375', '0.1875', '0.0791015625', '0.955078125', '0.275390625', '0.06640625', '0.4482421875', '0.4560546875', '0.126953125', '0.2578125', '0.6767578125', '0.9189453125', '0.607421875', '0.986328125', '0.8720703125', '0.6435546875', '0.7587890625', '0.9365234375', '0.96875', '0.2197265625', '0.9892578125', '0.80859375', '0.7236328125', '0.37109375', '0.015625', '0.380859375', '0.546875', '0.5009765625', '0.3251953125', '0.28125', '0.966796875', '0.310546875', '0.109375', '0.4169921875', '0.0283203125', '0.544921875', '0.552734375', '0.0087890625', '0.7509765625', '0.8125', '0.517578125', '0.6171875', '0.8642578125', '0.48828125', '0.095703125', '0.9482421875', '0.5595703125', '0.048828125', '0.474609375', '0.2958984375', '0.8251953125', '0.1630859375', '0.18359375', '0.681640625', '0.83984375', '0.6416015625', '0.7900390625', '0.1533203125', '0.6435546875', '0.326171875', '0.166015625', '0.076171875', '0.8525390625', '0.466796875', '0.935546875', '0.4267578125', '0.833984375', '0.421875', '0.6904296875', '0.421875', '0.3037109375', '0.0244140625', '0.572265625', '0.732421875', '0.5361328125', '0.240234375', '0.7041015625', '0.7412109375', '0.05078125', '0.6396484375', '0.7060546875', '0.2578125', '0.1708984375', '0.8955078125', '0.1279296875', '0.6962890625', '0.5185546875', '0.8984375', '0.8125', '0.1279296875', '0.791015625', '0.1943359375', '0.298828125', '0.34375', '0.9580078125', '0.4013671875', '0.9052734375', '0.474609375', '0.7529296875', '0.9169921875', '0.8603515625', '0.6083984375', '0.6201171875', '0.5654296875', '0.279296875', '0.4775390625', '0.0126953125', '0.1650390625', '0.9677734375', '0.66015625', '0.9814453125', '0.572265625', '0.3828125', '0.7314453125', '0.8251953125', '0.505859375', '0.4169921875', '0.80078125', '0.486328125', '0.197265625', '0.8818359375', '0.728515625', '0.744140625', '0.333984375', '0.3603515625', '0.3720703125', '0.76171875', '0.34765625', '0.783203125', '0.2783203125', '0.05859375', '0.2158203125', '0.9072265625', '0.5029296875', '0.775390625', '0.5009765625', '0.162109375', '0.162109375', '0.9365234375', '0.400390625', '0.7470703125', '0.7265625', '0.9462890625', '0.69140625', '0.931640625', '0.8837890625', '0.5419921875', '0.6806640625', '0.4853515625', '0.2607421875', '0.064453125', '0.2509765625', '0.6337890625', '0.3857421875', '0.8125', '0.5703125', '0.1953125', '0.4345703125', '0.486328125', '0.2587890625', '0.427734375', '0.4755859375', '0.8095703125', '0.3564453125', '0.5751953125', '0.1767578125', '0.5595703125', '0.6962890625', '0.521484375', '0.9365234375', '0.84765625', '0.6669921875', '0.939453125', '0.4970703125', '0.900390625', '0.505859375', '0.5712890625', '0.484375', '0.09765625', '0.0419921875', '0.685546875', '0.146484375', '0.4892578125', '0.0126953125', '0.470703125', '0.427734375', '0.98828125', '0.771484375', '0.51953125', '0.5712890625', '0.052734375', '0.4326171875', '0.8837890625', '0.4033203125', '0.99609375', '0.2412109375', '0.1650390625', '0.1591796875', '0.759765625', '0.09375', '0.580078125', '0.6201171875', '0.9501953125', '0.033203125', '0.6611328125', '0.259765625', '0.0263671875', '0.962890625', '0.6875', '0.0791015625', '0.7216796875', '0.64453125', '0.0087890625', '0.5478515625', '0.15625', '0.20703125', '0.1474609375', '0.8857421875', '0.892578125', '0.689453125', '0.1044921875', '0.0966796875', '0.595703125', '0.4423828125', '0.451171875', '0.859375', '0.6630859375', '0.435546875', '0.259765625', '0.833984375', '0.0869140625', '0.4833984375', '0.8125', '0.96875', '0.263671875', '0.888671875', '0.2880859375', '0.755859375', '0.5986328125', '0.7646484375', '0.3427734375', '0.650390625', '0.4521484375', '0.9970703125', '0.0341796875', '0.623046875', '0.28125', '0.0078125', '0.9970703125', '0.5', '0.8623046875', '0.94140625', '0.529296875', '0.44140625', '0.2900390625', '0.568359375', '0.033203125', '0.59765625', '0.1396484375', '0.384765625', '0.625', '1', '0.1845703125', '0.7353515625', '0.7119140625', '0.5625', '0.251953125', '0.6806640625', '0.5205078125', '0.5732421875', '0.580078125', '0.01171875', '0.0302734375', '0.578125', '0.357421875', '0.345703125', '0.26953125', '0.0908203125', '0.44140625', '0.41015625', '0.263671875', '0.138671875', '0.677734375', '0.642578125', '0.09765625', '0.5224609375', '0.80078125', '0.07421875', '0.6474609375', '0.2529296875', '0.314453125', '0.2109375', '0.5244140625', '0.7421875', '0.3720703125', '0.6669921875', '0.65625', '0.8623046875', '0.6142578125', '0.01953125', '0.5869140625', '0.4541015625', '0.37890625', '0.7080078125', '0.421875', '0.119140625', '0.8349609375', '0.556640625', '0.2294921875', '0.06640625', '0.642578125', '0.0830078125', '0.0810546875', '0.4189453125', '0.267578125', '0.671875', '0.9189453125', '0.23046875', '0.662109375', '0.578125', '0.345703125', '0.7099609375', '0.978515625', '0.13671875', '0.314453125', '0.7587890625', '0.2802734375', '0.25', '0.2138671875', '0.0595703125', '0.466796875', '0.337890625', '0.6865234375', '0.7548828125', '0.1376953125', '0.6279296875', '0.0791015625', '0.701171875', '0.1533203125', '0.4833984375', '0.888671875', '0.865234375', '0.1494140625', '0.8623046875', '0.0087890625', '0.955078125', '0.96875', '0.455078125', '0.6806640625', '0.0068359375', '0.2578125', '0.419921875', '0.8740234375', '0.2939453125', '0.9970703125', '0.38671875', '0.4716796875', '0.8984375', '0.6015625', '0.5224609375', '0.4833984375', '0.6689453125', '0.2939453125', '0.2646484375', '0.95703125', '0.515625', '0.7763671875', '0.013671875', '0.1279296875', '0.7744140625', '0.9931640625', '0.599609375', '0.103515625', '0.93359375', '0.1630859375', '0.3388671875', '0.509765625', '0.193359375', '0.1845703125', '0.8935546875', '0.9501953125', '0.3505859375', '0.3271484375', '0.98046875', '0.90234375', '0.130859375', '0.658203125', '0.537109375', '0.6376953125', '0.6396484375', '0.44140625', '0.79296875', '0.669921875', '0.306640625', '0.8427734375', '0.626953125', '0.732421875', '0.501953125', '0.6591796875', '0.787109375', '0.3935546875', '0.0302734375', '0.74609375', '0.21875', '0.1435546875', '0.857421875', '0.6943359375', '0.0654296875', '0.9443359375', '0.072265625', '0.83203125', '0.0673828125', '0.19921875', '0.154296875', '0.9033203125', '0.2626953125', '0.453125', '0.958984375', '0.1318359375', '0.7373046875', '0.0478515625', '0.1630859375', '1', '0.3701171875', '0.08984375', '0.818359375', '0.921875', '0.3330078125', '0.7001953125', '0.900390625', '0.4501953125', '0.09375', '0.3134765625', '0.130859375', '0.9775390625', '0.0615234375', '0.85546875', '0.5302734375', '0.0595703125', '0.2626953125', '0.0693359375', '0.3115234375', '0.66015625', '0.552734375', '0.5380859375', '0.6328125', '0.2578125', '0.0185546875', '0.62109375', '0.2685546875', '0.0595703125', '0.953125', '0.6376953125', '0.865234375', '0.3759765625', '0.4921875', '0.6611328125', '0.685546875', '0.357421875', '0.2578125', '0.439453125', '0.8740234375', '0.5986328125', '0.6533203125', '0.552734375', '0.4619140625', '0.669921875', '0.03125', '0.5673828125', '0.005859375', '0.51953125', '0.6611328125', '0.134765625', '0.53515625', '0.4072265625', '1', '0.84765625', '0.259765625', '0.10546875', '0.1201171875', '0.3984375', '0.8642578125', '0.0869140625', '0.423828125', '0.12890625', '0.048828125', '0.048828125', '0.302734375', '0.1767578125', '0.056640625', '0.4189453125', '0.0146484375', '0.728515625', '0.818359375', '0.60546875', '0.9482421875', '0.8076171875', '0.9150390625', '0.4765625', '0.65625', '0.5380859375', '0.76953125', '0.4326171875', '0.2998046875', '0.4130859375', '0.45703125', '0.98046875', '0.2646484375', '0.296875', '0.529296875', '0.8603515625', '0.1904296875', '0.6474609375', '0.94140625', '0.7568359375', '0.140625', '0.8525390625', '0.6796875', '0.5126953125', '0.267578125', '0.697265625', '0.8017578125', '0.318359375', '0.892578125', '0.2431640625', '0.0546875', '0.62109375', '0.58203125', '0.728515625', '0.2783203125', '0.1455078125', '0.953125', '0.056640625', '0.0341796875', '0.6650390625', '0.6337890625', '0.7255859375', '0.42578125', '0.3076171875', '0.5986328125', '0.11328125', '0.375', '0.328125', '0.12890625', '0.576171875', '0.29296875', '0.10546875', '0.197265625', '0.1318359375', '0.646484375', '0.1181640625', '0.927734375', '0.23828125', '0.7080078125', '0.693359375', '0.2509765625', '0.443359375', '0.6572265625', '0.388671875', '0.05078125', '0.7236328125', '0.1767578125', '0.181640625', '0.6416015625', '0.4296875', '0.3359375', '0.345703125', '0.9111328125', '0.7431640625', '0.494140625', '0.0234375', '0.66796875', '0.619140625', '0.4501953125', '0.669921875', '0.4228515625', '0.1943359375', '0.0859375', '0.337890625', '0.71875', '0.443359375', '0.2080078125', '0.65234375', '0.873046875', '0.5751953125', '0.1123046875', '0.994140625', '0.5390625', '0.3740234375', '0.623046875', '0.734375', '0.80078125', '0.708984375', '0.119140625', '0.892578125', '0.9560546875', '0.013671875', '0.5234375', '0.6181640625', '0.9072265625', '0.55859375', '0.0810546875', '0.353515625', '0.7841796875', '0.89453125', '0.6220703125', '0.416015625', '0.0966796875', '0.875', '0.5537109375', '0.1279296875', '0.6611328125', '0.986328125', '0.978515625', '0.7099609375', '0.580078125', '0.109375', '0.638671875', '0.990234375', '0.9404296875', '0.8291015625', '0.083984375', '0.6064453125', '0.9775390625', '0.6806640625', '0.14453125', '0.052734375', '0.08984375', '0.2529296875', '0.8818359375', '0.1171875', '0.798828125', '0.234375', '0.3681640625', '0.451171875', '0.185546875', '0.3330078125', '0.0712890625', '0.802734375', '0.333984375', '0.1455078125', '0.6162109375', '0.40625', '0.2744140625', '0.1552734375', '0.2119140625', '0.0185546875', '0.3720703125', '0.1953125', '0.5517578125', '0.48828125', '0.3994140625', '0.572265625', '0.6279296875', '0.6708984375', '0.01953125', '0.72265625', '0.97265625', '0.708984375', '0.1435546875', '0.529296875', '0.5634765625', '0.697265625', '0.0107421875', '0.9296875', '0.1787109375', '0.6435546875', '0.2177734375', '0.08203125', '0.8271484375', '0.716796875', '0.076171875', '0.0703125', '0.0654296875', '0.9697265625', '0.6669921875', '0.638671875', '0.2080078125', '0.794921875', '0.7197265625', '0.8046875', '0.568359375', '0.193359375', '0.1484375', '0.326171875', '0.6484375', '0.5498046875', '0.4599609375', '0.822265625', '0.73046875', '0.7109375', '0.216796875', '0.271484375', '0.666015625', '0.1845703125', '0.9833984375', '0.708984375', '0.591796875', '0.796875', '0.7275390625', '0.470703125', '0.65234375', '0.1982421875', '0.3837890625', '0.1357421875', '0.505859375', '0.56640625', '0.3818359375', '0.04296875', '0.96484375', '0.5166015625', '0.7392578125', '0.7607421875', '0.5361328125', '0.267578125', '0.5087890625', '0.3388671875', '0.1416015625', '0.75', '0.7978515625', '0.029296875', '0.7265625', '0.923828125', '0.783203125', '0.91796875', '0.4970703125', '0.9609375', '0.8994140625', '0.771484375', '0.94921875', '0.84375', '0.083984375', '0.203125', '0.60546875', '1', '0.7626953125', '0.546875', '0.4033203125', '0.7890625', '0.6875', '0.66015625', '0.6337890625', '0.9150390625', '0.9287109375', '0.857421875', '0.8798828125', '0.2080078125', '0.07421875', '0.68359375', '0.0615234375', '0.326171875', '0.39453125', '0.3466796875', '0.2939453125', '0.13671875', '0.75390625', '0.8984375', '0.2744140625', '0.6083984375', '0.830078125', '0.8115234375', '0.2431640625', '0.9453125', '0.3388671875', '0.6142578125', '0.0380859375', '0.0615234375', '0.974609375', '0.8173828125', '0.0390625', '0.291015625', '0.0849609375', '0.5439453125', '0.50390625', '0.4716796875', '0.7412109375', '0.470703125', '0.8330078125', '0.859375', '0.9677734375', '0.6005859375', '0.181640625', '0.4658203125', '0.513671875', '0.8994140625', '0.41015625', '0.0361328125', '0.4384765625', '0.9912109375', '0.1064453125', '0.525390625', '0.1953125', '0.3603515625', '0.1171875', '0.4443359375', '0.0673828125', '0.03125', '0.3681640625', '0.03515625', '0.4267578125', '0.740234375', '0.6083984375', '0.9423828125', '0.435546875', '0.58203125', '0.298828125', '0.6552734375', '0.6806640625', '0.302734375', '0.58203125', '0.66015625', '0.1259765625', '0.337890625', '0.0419921875', '0.3486328125', '0.6904296875', '0.962890625', '0.7734375', '0.1748046875', '0.833984375', '0.671875', '0.90625', '0.8359375', '0.888671875', '0.5986328125', '0.6982421875', '0.8671875', '0.0869140625', '0.2861328125', '0.560546875', '0.921875', '0.6015625', '0.017578125', '0.73046875', '0.1396484375', '0.841796875', '0.35546875', '0.529296875', '0.775390625', '0.2578125', '0.5703125', '0.744140625', '0.2900390625', '0.6533203125', '0.58984375', '0.9052734375', '0.404296875', '0.671875', '0.33984375', '0.7216796875', '0.1318359375', '0.69921875', '0.5751953125', '0.3203125', '0.2529296875', '0.830078125', '0.94140625', '0.1796875', '0.986328125', '0.1640625', '0.400390625', '0.9423828125', '0.111328125', '0.880859375', '0.4619140625', '0.0458984375', '0.4365234375', '0.3203125', '0.388671875', '0.6767578125', '0.90625', '0.876953125', '0.78515625', '0.36328125', '0.80859375', '0.43359375', '0.306640625', '0.466796875', '0.27734375', '0.123046875', '0.7646484375', '0.7255859375', '0.5849609375', '0.6953125', '0.7119140625', '0.6591796875', '0.42578125', '0.419921875', '0.1982421875', '0.533203125', '0.46875', '0.8037109375', '0.3662109375', '0.986328125', '0.9619140625', '0.8740234375', '0.57421875', '0.642578125', '0.708984375', '0.3095703125', '0.39453125', '0.537109375', '0.2041015625', '0.9501953125', '0.318359375', '0.3583984375', '0.6328125', '0.197265625', '0.57421875', '0.5517578125', '0.1787109375', '0.107421875', '0.2744140625', '0.458984375', '0.54296875', '0.7998046875', '0.4892578125', '0.3125', '0.7900390625', '0.6328125', '0.30078125', '0.9267578125', '0.4892578125', '0.2080078125', '0.7998046875', '0.9521484375'],
);

our @R_DENSITY = (
	{ data => 'pr8033', args => ['kernel' => 'rectangular', 'bw' => '1', 'from' => '0', 'to' => '1', 'n' => '2'], search => 0,
	  bw => '1', n => 3, len => 2,
	  x1 => '0', xn => '1',
	  ysum => '0.38490017945975052', ymax => '0.19245008972987529',
	  at => [1, 2],
	  y  => ['0.19245008972987529', '0.19245008972987526'],
	  xs => ['0', '1'] },
	{ data => 'pr8876', args => ['n' => '20', 'from' => '-1', 'to' => '1'], search => 0,
	  bw => '0.022473160390831099', n => 12, len => 20,
	  x1 => '-1', xn => '1',
	  ysum => '9.5823569819357548', ymax => '7.6728663651308882',
	  at => [1, 2, 3, 7, 19, 20],
	  y  => ['5.2160949459816639e-16', '1.3462944965406125e-16', '5.6020343899541091e-17', '1.0488517447782927e-16', '6.8162005118910656e-18', '1.8601258172841556e-16'],
	  xs => ['-1', '-0.89473684210526316', '-0.78947368421052633', '-0.36842105263157898', '0.89473684210526305', '1'] },
	{ data => 'iqr0', args => [], search => 0,
	  bw => '1.0185208073797294', n => 100, len => 512,
	  x1 => '-23.055562422139189', xn => '23.055562422139189',
	  ysum => '11.081661191342555', ymax => '0.38281400230988355',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['4.4185682369889364e-05', '5.721862954297227e-05', '7.3401331717891285e-05', '0.00018804280637806415', '0.00014082055931386681', '0', '1.4831137374244804e-06', '0.38281400230988355', '4.5837623332778507e-11', '1.6969312051139222e-13', '5.7218629542972962e-05', '4.4185682369883103e-05'],
	  xs => ['-23.055562422139189', '-22.965325387218879', '-22.875088352298569', '-22.514140212617331', '-17.370629222159664', '-11.595458987259828', '-5.0983924729975136', '-0.045118517460156937', '6.9031331714037094', '12.949014511064476', '22.965325387218876', '23.055562422139189'] },
	{ data => 'eruptions', args => ['bw' => 'sj'], search => 1,
	  bw => '0.14004353589438365', n => 272, len => 512,
	  x1 => '1.1798693923168493', xn => '5.5201306076831509',
	  ysum => '117.73316849583193', ymax => '0.59406687403037806',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00018142738414042751', '0.00022063748376380805', '0.00026688567624073649', '0.00056772299812597228', '0.34771493534015802', '0.28764576271119441', '0.039004717983804879', '0.087379716084599351', '0.41345063086724365', '0.56407643349506476', '0.00026169682740272241', '0.00021647636544927648'],
	  xs => ['1.1798693923168493', '1.1883630541864507', '1.1968567160560519', '1.2308313635344574', '1.714970090101736', '2.2585644497562236', '2.8701081043675227', '3.3457531690651994', '3.9997651330245052', '4.5688404782877967', '5.5116369458135495', '5.5201306076831509'] },
	{ data => 'eruptions', args => ['bw' => '0.14999999999999999'], search => 0,
	  bw => '0.14999999999999999', n => 272, len => 512,
	  x1 => '1.1500000000000001', xn => '5.5499999999999998',
	  ysum => '116.13458334871352', ymax => '0.58806393638265542',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00018372969161140236', '0.00022243600923452339', '0.00026795013889123481', '0.00055181020016840531', '0.3068857077498266', '0.29767301401077634', '0.0388342848125212', '0.08720511413159221', '0.41776596497291008', '0.54873974075940612', '0.00025440014121643032', '0.00021171532136967156'],
	  xs => ['1.1500000000000001', '1.1586105675146772', '1.1672211350293544', '1.2016634050880628', '1.6924657534246577', '2.243542074363992', '2.8635029354207435', '3.3456947162426616', '4.0087084148727978', '4.5856164383561637', '5.5413894324853228', '5.5499999999999998'] },
	{ data => 'precip', args => ['n' => '1000'], search => 0,
	  bw => '3.8478922425896878', n => 70, len => 1000,
	  x1 => '-4.5436767277690642', xn => '78.543676727769068',
	  ysum => '12.022629145143696', ymax => '0.036072649768724707',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 999, 1000],
	  y  => ['4.8147953754406417e-05', '5.1437612607463308e-05', '5.4991302410577011e-05', '7.1356305467406428e-05', '0.0013283674954302676', '0.0068957224681832881', '0.012583579724065899', '0.012976548518420228', '0.0090991888478289089', '0.017573646353980003', '1.7571391695774592e-05', '1.6481240587495744e-05'],
	  xs => ['-4.5436767277690642', '-4.4605062037895467', '-4.3773356798100291', '-4.0446535838919582', '0.6960662829405484', '6.0189798176296776', '12.00725754415495', '16.664806887007938', '23.068937233430798', '28.641362340058482', '78.460506203789549', '78.543676727769068'] },
	{ data => 'precip', args => ['bw' => 'SJ', 'kernel' => 'gaussian'], search => 1,
	  bw => '3.9317684586929098', n => 70, len => 512,
	  x1 => '-4.7953053760787299', xn => '78.79530537607873',
	  ysum => '6.1126985112145071', ymax => '0.035896761753960386',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['4.7580429391354506e-05', '5.4163882664343799e-05', '6.1428388293813222e-05', '0.00010000135733547391', '0.0062665205938431884', '0.013267133756566993', '0.015541159806108342', '0.0349199776776919', '0.015542464938641878', '0.0051450990887297347', '1.8348862614891763e-05', '1.618520296473622e-05'],
	  xs => ['-4.7953053760787299', '-4.6317229675617879', '-4.4681405590448451', '-3.8138109249770764', '5.5103863604886278', '15.97966050557293', '27.757593918792764', '36.918208795741528', '49.514054251546078', '60.474075622181203', '78.631722967561785', '78.79530537607873'] },
	{ data => 'precip', args => ['bw' => 'SJ', 'kernel' => 'epanechnikov'], search => 1,
	  bw => '3.9317684586929098', n => 70, len => 512,
	  x1 => '-4.7953053760787299', xn => '78.79530537607873',
	  ysum => '6.1124079043453694', ymax => '0.035649478620821858',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['8.3499866055526753e-19', '1.3545900549107059e-18', '1.8942371595869162e-18', '9.358804958709114e-19', '0.0056968254160332625', '0.012025122819593965', '0.015670255718281085', '0.035378192717967188', '0.015803074097092279', '0.005305000174253993', '0', '0'],
	  xs => ['-4.7953053760787299', '-4.6317229675617879', '-4.4681405590448451', '-3.8138109249770764', '5.5103863604886278', '15.97966050557293', '27.757593918792764', '36.918208795741528', '49.514054251546078', '60.474075622181203', '78.631722967561785', '78.79530537607873'] },
	{ data => 'precip', args => ['bw' => 'SJ', 'kernel' => 'rectangular'], search => 1,
	  bw => '3.9317684586929098', n => 70, len => 512,
	  x1 => '-4.7953053760787299', xn => '78.79530537607873',
	  ysum => '6.1640441344287193', ymax => '0.038808345376613491',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['2.0411078369128761e-18', '2.8903222456997789e-18', '3.0516560918125186e-18', '1.8597049804220236e-18', '0.0052443709968396602', '0.010745174098921631', '0.014741884494636615', '0.038606488559647739', '0.015763649021399546', '0.0062932451962075878', '0', '0'],
	  xs => ['-4.7953053760787299', '-4.6317229675617879', '-4.4681405590448451', '-3.8138109249770764', '5.5103863604886278', '15.97966050557293', '27.757593918792764', '36.918208795741528', '49.514054251546078', '60.474075622181203', '78.631722967561785', '78.79530537607873'] },
	{ data => 'precip', args => ['bw' => 'SJ', 'kernel' => 'triangular'], search => 1,
	  bw => '3.9317684586929098', n => 70, len => 512,
	  x1 => '-4.7953053760787299', xn => '78.79530537607873',
	  ysum => '6.1136917864701239', ymax => '0.035532726394344794',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['1.2061091763576087e-18', '5.8871194160469332e-19', '0', '2.3822412622168653e-18', '0.0059176980943801451', '0.012964501133726132', '0.01536516082396033', '0.035232401274523269', '0.015904569680635475', '0.0052195035054256461', '0', '0'],
	  xs => ['-4.7953053760787299', '-4.6317229675617879', '-4.4681405590448451', '-3.8138109249770764', '5.5103863604886278', '15.97966050557293', '27.757593918792764', '36.918208795741528', '49.514054251546078', '60.474075622181203', '78.631722967561785', '78.79530537607873'] },
	{ data => 'precip', args => ['bw' => 'SJ', 'kernel' => 'biweight'], search => 1,
	  bw => '3.9317684586929098', n => 70, len => 512,
	  x1 => '-4.7953053760787299', xn => '78.79530537607873',
	  ysum => '6.113118497791624', ymax => '0.035606285097196815',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['4.855721882026365e-18', '3.6806761152769052e-18', '2.5447584630782189e-18', '3.7367430985109347e-18', '0.0059365654799489248', '0.012594945754404487', '0.015698721007242199', '0.035102628488158413', '0.01567581493495222', '0.0051791798867501767', '0', '2.8156658936312481e-19'],
	  xs => ['-4.7953053760787299', '-4.6317229675617879', '-4.4681405590448451', '-3.8138109249770764', '5.5103863604886278', '15.97966050557293', '27.757593918792764', '36.918208795741528', '49.514054251546078', '60.474075622181203', '78.631722967561785', '78.79530537607873'] },
	{ data => 'precip', args => ['bw' => 'SJ', 'kernel' => 'cosine'], search => 1,
	  bw => '3.9317684586929098', n => 70, len => 512,
	  x1 => '-4.7953053760787299', xn => '78.79530537607873',
	  ysum => '6.1131222082655547', ymax => '0.035641707457568388',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['1.1759019005988839e-18', '5.4342640763510146e-19', '0', '4.9400874671388828e-07', '0.0060104415092572441', '0.012735445854367955', '0.015674974028065999', '0.035030369719167884', '0.015658468053547939', '0.0051491657449652473', '0', '0'],
	  xs => ['-4.7953053760787299', '-4.6317229675617879', '-4.4681405590448451', '-3.8138109249770764', '5.5103863604886278', '15.97966050557293', '27.757593918792764', '36.918208795741528', '49.514054251546078', '60.474075622181203', '78.631722967561785', '78.79530537607873'] },
	{ data => 'precip', args => ['bw' => 'SJ', 'kernel' => 'optcosine'], search => 1,
	  bw => '3.9317684586929098', n => 70, len => 512,
	  x1 => '-4.7953053760787299', xn => '78.79530537607873',
	  ysum => '6.1128676468240055', ymax => '0.03566809250979866',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['2.3194407237646321e-18', '2.5842360646558439e-18', '2.1587476206433354e-18', '3.2443258738581805e-18', '0.0057551893472792253', '0.012248942139123578', '0.015702458923478758', '0.035272445146973426', '0.015761028666878781', '0.0052623260067731136', '0', '0'],
	  xs => ['-4.7953053760787299', '-4.6317229675617879', '-4.4681405590448451', '-3.8138109249770764', '5.5103863604886278', '15.97966050557293', '27.757593918792764', '36.918208795741528', '49.514054251546078', '60.474075622181203', '78.631722967561785', '78.79530537607873'] },
	{ data => 'precip', args => ['bw' => 'nrd0'], search => 0,
	  bw => '3.8478922425896878', n => 70, len => 512,
	  x1 => '-4.5436767277690642', xn => '78.543676727769068',
	  ysum => '6.149726557031352', ymax => '0.036069982644174145',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['4.8269312071050914e-05', '5.503476463373708e-05', '6.2638593717390321e-05', '0.00010275869628752606', '0.0065090158303923746', '0.013312444416016088', '0.015577367054555175', '0.035061256999894222', '0.015628283987213932', '0.0052467659071095633', '1.8745543308898635e-05', '1.6509513034491287e-05'],
	  xs => ['-4.5436767277690642', '-4.3810791671907117', '-4.2184816066123592', '-3.5680913642989491', '5.6999695886671446', '16.106213465681705', '27.813237827323082', '36.918701219710826', '49.438713384243968', '60.332749942993587', '78.381079167190705', '78.543676727769068'] },
	{ data => 'precip', args => ['bw' => 'nrd'], search => 0,
	  bw => '4.5319619746056317', n => 70, len => 512,
	  x1 => '-6.5958859238168941', xn => '80.595885923816894',
	  ysum => '5.8602171919665569', ymax => '0.034641703300707725',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['4.3157029442874029e-05', '4.8540717390458689e-05', '5.44618760191475e-05', '8.4832286766821203e-05', '0.0048006571678582454', '0.012819816636950924', '0.01540152049391269', '0.033841706723872281', '0.015063162135897555', '0.0045437443520868525', '1.5762798411878528e-05', '1.4063816867584893e-05'],
	  xs => ['-6.5958859238168941', '-6.4252562333127186', '-6.254626542808543', '-5.57210778079184', '4.1537845779461744', '15.074084770213421', '27.35942248651407', '36.914685154747907', '50.053171323569437', '61.485360587349206', '80.425256233312709', '80.595885923816894'] },
	{ data => 'precip', args => ['bw' => 'ucv'], search => 1,
	  bw => '4.8618676706865616', n => 70, len => 512,
	  x1 => '-7.5856030120596856', xn => '81.585603012059693',
	  ysum => '5.7301236841511782', ymax => '0.033940847919248028',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['4.1209243690550708e-05', '4.6006103239940217e-05', '5.1200691942283172e-05', '7.8395603674046404e-05', '0.0041794086282563019', '0.012517307392169641', '0.015401440951938081', '0.033214227893568871', '0.014852523116475336', '0.0042792746556536386', '1.4649129312245634e-05', '1.3162679684655094e-05'],
	  xs => ['-7.5856030120596856', '-7.411099673460626', '-7.2365963348615665', '-6.5385829804653284', '3.4081073196810596', '14.576320990020864', '27.140561369153147', '36.912748330700474', '50.349505402828051', '62.041229088965032', '81.411099673460626', '81.585603012059693'] },
	{ data => 'precip', args => ['bw' => 'bcv'], search => 1,
	  bw => '6.6808118050666163', n => 70, len => 512,
	  x1 => '-13.042435415199847', xn => '87.042435415199847',
	  ysum => '5.105247207519291', ymax => '0.030175137515353119',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['3.3540406150014127e-05', '3.6788616434450686e-05', '4.0234852409968614e-05', '5.7167033404715643e-05', '0.002216511380280577', '0.010416535772428088', '0.015871330324714817', '0.029717849959957993', '0.013826845367905911', '0.0031993508801869117', '1.0833924804747084e-05', '9.8972586247047059e-06'],
	  xs => ['-13.042435415199847', '-12.846574611226462', '-12.650713807253076', '-11.867270591359537', '-0.70320476487659711', '11.831886689420038', '25.933864575503755', '36.902069598013313', '51.983351503963945', '65.106025370180745', '86.846574611226472', '87.042435415199847'] },
	{ data => 'precip', args => ['bw' => 'SJ-ste'], search => 1,
	  bw => '3.9317684586929098', n => 70, len => 512,
	  x1 => '-4.7953053760787299', xn => '78.79530537607873',
	  ysum => '6.1126985112145071', ymax => '0.035896761753960386',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['4.7580429391354506e-05', '5.4163882664343799e-05', '6.1428388293813222e-05', '0.00010000135733547391', '0.0062665205938431884', '0.013267133756566993', '0.015541159806108342', '0.0349199776776919', '0.015542464938641878', '0.0051450990887297347', '1.8348862614891763e-05', '1.618520296473622e-05'],
	  xs => ['-4.7953053760787299', '-4.6317229675617879', '-4.4681405590448451', '-3.8138109249770764', '5.5103863604886278', '15.97966050557293', '27.757593918792764', '36.918208795741528', '49.514054251546078', '60.474075622181203', '78.631722967561785', '78.79530537607873'] },
	{ data => 'precip', args => ['bw' => 'SJ-dpi'], search => 1,
	  bw => '4.0220440847261347', n => 70, len => 512,
	  x1 => '-5.0661322541784042', xn => '79.066132254178399',
	  ysum => '6.0733420917440606', ymax => '0.035709018375897135',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['4.6939354712235176e-05', '5.3253567272618229e-05', '6.0194162540876117e-05', '9.7215378608604141e-05', '0.0060156898115850139', '0.013211242169333056', '0.015506906798952558', '0.034765001483724432', '0.015458906211388778', '0.0050413255384920853', '1.7911988980924558e-05', '1.5850274949630953e-05'],
	  xs => ['-5.0661322541784042', '-4.9014898578802502', '-4.7368474615820961', '-4.0782778763894791', '5.3063387126053101', '15.843452075687177', '27.697704609154279', '36.917678801850911', '49.595143316808787', '60.626183868785112', '78.901489857880236', '79.066132254178399'] },
	{ data => 'const', args => ['bw' => '1', 'kernel' => 'gaussian'], search => 0,
	  bw => '1', n => 10, len => 512,
	  x1 => '0', xn => '6',
	  ysum => '84.940791854909278', ymax => '0.39886743194444951',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00443517519617255', '0.0045971984215994596', '0.0047592216470263692', '0.0054689743024014682', '0.031024678562161168', '0.12784331954863692', '0.32011095374379656', '0.39886743194444951', '0.26649833072676588', '0.096495094865227213', '0.0045971984215994362', '0.0044351751961725309'],
	  xs => ['0', '0.011741682974559686', '0.023483365949119372', '0.070450097847358117', '0.73972602739726023', '1.49119373776908', '2.3365949119373775', '2.9941291585127199', '3.8982387475538158', '4.6849315068493151', '5.9882583170254398', '6'] },
	{ data => 'const', args => ['bw' => '1', 'kernel' => 'epanechnikov'], search => 0,
	  bw => '1', n => 10, len => 512,
	  x1 => '0', xn => '6',
	  ysum => '85.168021059910643', ymax => '0.33538502040454232',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0', '1.5147383846306379e-17', '3.0294767692612759e-17', '0', '6.4421028009761899e-17', '0.18267326050645208', '0.30586410365363526', '0.33538502040454232', '0.28126333969454576', '0.14495208910251495', '0', '0'],
	  xs => ['0', '0.011741682974559686', '0.023483365949119372', '0.070450097847358117', '0.73972602739726023', '1.49119373776908', '2.3365949119373775', '2.9941291585127199', '3.8982387475538158', '4.6849315068493151', '5.9882583170254398', '6'] },
	{ data => 'const', args => ['bw' => '1', 'kernel' => 'rectangular'], search => 0,
	  bw => '1', n => 10, len => 512,
	  x1 => '0', xn => '6',
	  ysum => '85.530318449948851', ymax => '0.28867513459481303',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0', '0', '0', '2.9815492634970859e-18', '2.062427884122132e-17', '0.28867513459481275', '0.28867513459481303', '0.28867513459481281', '0.28867513459481298', '0.28867513459481287', '0', '0'],
	  xs => ['0', '0.011741682974559686', '0.023483365949119372', '0.070450097847358117', '0.73972602739726023', '1.49119373776908', '2.3365949119373775', '2.9941291585127199', '3.8982387475538158', '4.6849315068493151', '5.9882583170254398', '6'] },
	{ data => 'const', args => ['bw' => '1', 'kernel' => 'triangular'], search => 0,
	  bw => '1', n => 10, len => 512,
	  x1 => '0', xn => '6',
	  ysum => '85.169107820141832', ymax => '0.40596518544103183',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0', '2.1775231827004469e-19', '4.3550463654008938e-19', '0', '0.031535961696739771', '0.15678058009204293', '0.29768077578675944', '0.40596518544103183', '0.25854183253822699', '0.12742637265564374', '0', '0'],
	  xs => ['0', '0.011741682974559686', '0.023483365949119372', '0.070450097847358117', '0.73972602739726023', '1.49119373776908', '2.3365949119373775', '2.9941291585127199', '3.8982387475538158', '4.6849315068493151', '5.9882583170254398', '6'] },
	{ data => 'const', args => ['bw' => '1', 'kernel' => 'biweight'], search => 0,
	  bw => '1', n => 10, len => 512,
	  x1 => '0', xn => '6',
	  ysum => '85.166673931493449', ymax => '0.3543036994300745',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0', '1.2240555365486811e-18', '2.4481110730973623e-18', '9.9603827555411255e-18', '0.025885869059916022', '0.16134374912661384', '0.31115777468911793', '0.3543036994300745', '0.27734255180403589', '0.12520944880749846', '0', '0'],
	  xs => ['0', '0.011741682974559686', '0.023483365949119372', '0.070450097847358117', '0.73972602739726023', '1.49119373776908', '2.3365949119373775', '2.9941291585127199', '3.8982387475538158', '4.6849315068493151', '5.9882583170254398', '6'] },
	{ data => 'const', args => ['bw' => '1', 'kernel' => 'cosine'], search => 0,
	  bw => '1', n => 10, len => 512,
	  x1 => '0', xn => '6',
	  ysum => '85.166667522617999', ymax => '0.36146830727813989',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0', '0', '0', '2.6736009817614084e-18', '0.029040722413136884', '0.15503951933542912', '0.31255894792975414', '0.36146830727813989', '0.27531360483663114', '0.12000323659033157', '0', '0'],
	  xs => ['0', '0.011741682974559686', '0.023483365949119372', '0.070450097847358117', '0.73972602739726023', '1.49119373776908', '2.3365949119373775', '2.9941291585127199', '3.8982387475538158', '4.6849315068493151', '5.9882583170254398', '6'] },
	{ data => 'const', args => ['bw' => '1', 'kernel' => 'optcosine'], search => 0,
	  bw => '1', n => 10, len => 512,
	  x1 => '0', xn => '6',
	  ysum => '85.166109665726239', ymax => '0.34180371404025234',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0', '5.1668100365916242e-18', '1.0333620073183248e-17', '2.8037365333639262e-18', '0.008722512207847961', '0.17552105265249637', '0.30724913354298716', '0.34180371404025234', '0.27935652108153941', '0.13902537729120368', '0', '0'],
	  xs => ['0', '0.011741682974559686', '0.023483365949119372', '0.070450097847358117', '0.73972602739726023', '1.49119373776908', '2.3365949119373775', '2.9941291585127199', '3.8982387475538158', '4.6849315068493151', '5.9882583170254398', '6'] },
	{ data => 'const', args => ['width' => '2', 'kernel' => 'gaussian'], search => 0,
	  bw => '0.5', n => 10, len => 512,
	  x1 => '1.5', xn => '4.5',
	  ysum => '169.88158370981856', ymax => '0.79773486388889903',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.0088703503923450999', '0.0091943968431989227', '0.0095184432940527454', '0.010937948604802929', '0.062049357124322316', '0.25568663909727407', '0.64022190748759289', '0.79773486388889903', '0.53299666145353197', '0.19299018973045443', '0.0091943968431988481', '0.0088703503923450618'],
	  xs => ['1.5', '1.5058708414872799', '1.5117416829745598', '1.5352250489236789', '1.8698630136986301', '2.2455968688845402', '2.6682974559686885', '2.9970645792563602', '3.4491193737769077', '3.8424657534246576', '4.4941291585127203', '4.5'] },
	{ data => 'const', args => ['width' => '2', 'kernel' => 'epanechnikov'], search => 0,
	  bw => '0.44721359549995793', n => 10, len => 512,
	  x1 => '1.6583592135001262', xn => '4.3416407864998741',
	  ysum => '190.44148459909383', ymax => '0.74994370425971069',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0', '0', '0', '2.8817293602833474e-17', '2.2172689903098587e-16', '0.40846982816395433', '0.6839329276465701', '0.74994370425971069', '0.62892394713561894', '0.32412272471382991', '0', '0'],
	  xs => ['1.6583592135001262', '1.6636102537603996', '1.6688612940206731', '1.6898654550617671', '1.9891747498973555', '2.3252413265548579', '2.7033162252945484', '2.9973744798698636', '3.4017045799109216', '3.7535242773492445', '4.3363897462396013', '4.3416407864998741'] },
	{ data => 'const', args => ['width' => '2', 'kernel' => 'rectangular'], search => 0,
	  bw => '0.57735026918962584', n => 10, len => 512,
	  x1 => '1.2679491924311224', xn => '4.7320508075688776',
	  ysum => '148.14285714285717', ymax => '0.50000000000000022',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['1.1003603844948092e-17', '6.2877736256845577e-18', '1.5719434064211791e-18', '0', '5.1693007293475977e-17', '0.49999999999999972', '0.50000000000000022', '0.49999999999999983', '0.50000000000000011', '0.5', '0', '0'],
	  xs => ['1.2679491924311224', '1.2747282562572237', '1.2815073200833249', '1.30862357538773', '1.6950302134755031', '2.1288902983459854', '2.6169828938252775', '2.9966104680869492', '3.518598382696748', '3.9727956590455338', '4.725271743742776', '4.7320508075688776'] },
	{ data => 'const', args => ['width' => '2', 'kernel' => 'triangular'], search => 0,
	  bw => '0.40824829046386307', n => 10, len => 512,
	  x1 => '1.7752551286084108', xn => '4.2247448713915894',
	  ysum => '208.620856007432', ymax => '0.99440755766487887',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0', '0', '0', '1.7502719759139461e-17', '0.077247014704967143', '0.38403242280305611', '0.72916600691340683', '0.99440755766487887', '0.63329556688275279', '0.31212959278006591', '0', '0'],
	  xs => ['1.7752551286084108', '1.7800486506099436', '1.784842172611476', '1.8040162606176067', '2.0772470147049669', '2.3840324228030561', '2.7291660069134061', '2.9976032389992335', '3.3667044331172473', '3.687870407219934', '4.2199513493900564', '4.2247448713915894'] },
	{ data => 'const', args => ['width' => '2', 'kernel' => 'biweight'], search => 0,
	  bw => '0.3779644730092272', n => 10, len => 512,
	  x1 => '1.8661065809723185', xn => '4.1338934190276815',
	  ysum => '225.32983921325939', ymax => '0.93739947728215467',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0', '0', '0', '2.1007390425846259e-17', '0.068487572003319036', '0.42687543578381482', '0.82324609033167462', '0.93739947728215467', '0.73377942004952768', '0.33127306334011436', '0', '0'],
	  xs => ['1.8661065809723185', '1.8705445199900395', '1.8749824590077602', '1.8927342150786437', '2.1456967390887329', '2.4297248362228685', '2.7492564454987711', '2.9977810304911392', '3.3395023348556463', '3.6368442490429445', '4.1294554800099608', '4.1338934190276815'] },
	{ data => 'const', args => ['width' => '2', 'kernel' => 'cosine'], search => 0,
	  bw => '0.36151205519132801', n => 10, len => 512,
	  x1 => '1.915463834426016', xn => '4.0845361655739838',
	  ysum => '235.58458507709813', ymax => '0.99987898629503502',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['2.9228776352233656e-17', '1.6702157915561995e-17', '4.1755394788896806e-18', '0', '0.080331269721468118', '0.42886403678398916', '0.86458789808360381', '0.99987898629503502', '0.76156133905665468', '0.33194809098916689', '0', '0'],
	  xs => ['1.915463834426016', '1.919708594369554', '1.9239533543130922', '1.9409323940872445', '2.1828837108689161', '2.4545483472553542', '2.7601710631900973', '2.9978776200282309', '3.3247241356806643', '3.6091230518977166', '4.0802914056304456', '4.0845361655739838'] },
	{ data => 'const', args => ['width' => '2', 'kernel' => 'optcosine'], search => 0,
	  bw => '0.43523617825417249', n => 10, len => 512,
	  x1 => '1.6942914652374825', xn => '4.3057085347625179',
	  ysum => '195.67791907222912', ymax => '0.78532927894758653',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['2.5091848900848097e-17', '2.492693215470585e-17', '2.476201540856266e-17', '0', '0.020040871241071911', '0.40327771775901017', '0.70593656707360741', '0.78532927894758653', '0.64185041372732277', '0.31942514027410357', '0', '0'],
	  xs => ['1.6942914652374825', '1.6994018704616021', '1.7045122756857214', '1.7249538965821991', '2.0162469943570076', '2.3433129287006516', '2.7112621048372514', '2.9974447973879403', '3.3909459996451377', '3.73334314966114', '4.3005981295383986', '4.3057085347625179'] },
	{ data => 'const', args => ['from' => '-1.2', 'to' => '1.2', 'width' => '2', 'kernel' => 'gaussian'], search => 0,
	  bw => '0.5', n => 10, len => 512,
	  x1 => '-1.2', xn => '1.2',
	  ysum => '0.034521746384628717', ymax => '0.0012249356760122849',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['3.2114068349020789e-16', '3.5052256236456763e-16', '4.0321478794736255e-16', '5.3429483060085777e-16', '4.6172701079205724e-14', '4.214116468975746e-12', '4.3846846986550586e-10', '1.1846176934358901e-08', '7.0092290599226152e-07', '1.5966790936073037e-05', '0.0011834472991108199', '0.0012249356760122849'],
	  xs => ['-1.2', '-1.195303326810176', '-1.1906066536203521', '-1.1718199608610567', '-0.90410958904109584', '-0.60352250489236792', '-0.26536203522504886', '-0.0023483365949119595', '0.35929549902152647', '0.67397260273972615', '1.195303326810176', '1.2'] },
	{ data => 'z60', args => ['kernel' => 'gaussian'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.915338358710912', ymax => '0.44175103671405297',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00024917333185729413', '0.00027806672600706874', '0.00031126894795352017', '0.00047836858665699849', '0.02436356933456163', '0.059326897028961705', '0.23979241756191538', '0.41537903000872428', '0.3785626383463494', '0.10703956574317471', '0.00025792375949583549', '0.00023140916339818996'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['kernel' => 'epanechnikov'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.923338962732558', ymax => '0.45505537989442896',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['2.232274155095777e-17', '1.7455547544544296e-17', '4.3521081478772577e-17', '1.7639591841689734e-18', '0.026091671992690989', '0.064075926818967538', '0.23474449807132253', '0.40810074757970294', '0.36712772920939768', '0.10046537909041299', '0', '0'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['kernel' => 'rectangular'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '84.087399777383013', ymax => '0.49786535962711764',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['4.5560137648878429e-17', '5.5294525661705377e-17', '5.3131710620439238e-17', '0', '0.029346973360627599', '0.073367433401569079', '0.22494571858515044', '0.42634960979393099', '0.36683716700784552', '0.10271440676219672', '0', '0'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['kernel' => 'triangular'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.926751832049561', ymax => '0.45042331294566251',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['4.366378954555678e-17', '3.1495804529523095e-17', '3.5983903789219712e-17', '0', '0.024105148614663497', '0.059466316351609858', '0.24285095466173989', '0.42259458376928033', '0.37184654958667757', '0.10391049514638769', '0', '0'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['kernel' => 'biweight'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.91903120440675', ymax => '0.44777365419930998',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['3.4237142246054698e-17', '2.4502754233227749e-17', '2.9045009885312484e-17', '0', '0.025324139715747179', '0.06154232488240035', '0.23963226271570107', '0.41028431774438157', '0.36961031558911978', '0.1026144170460865', '0', '0'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['kernel' => 'cosine'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.919090192793533', ymax => '0.44581088902998328',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['1.7871601042645393e-17', '1.0570810033025182e-17', '5.0858831239776889e-17', '2.2903769219831818e-06', '0.025058836981642713', '0.061073238957592646', '0.2402288709051226', '0.41090011685982936', '0.37084760394722716', '0.10350026112147223', '0', '0'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['kernel' => 'optcosine'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.918116744728152', ymax => '0.45250297871650524',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['2.677388205927015e-17', '2.4340285056063413e-17', '3.6183331717768258e-17', '1.7639591841689734e-18', '0.025795742253494219', '0.063241932148386734', '0.23664947427016828', '0.40989766157487018', '0.36790538279608054', '0.10132350529713738', '0', '0'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z200', args => ['kernel' => 'gaussian', 'adjust' => '0.5'], search => 0,
	  bw => '0.13943051333418083', n => 200, len => 512,
	  x1 => '-3.3069634150025427', xn => '2.9163384150025427',
	  ysum => '82.10973986121752', ymax => '0.48936281051167041',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00016008951248904239', '0.00020781031520644049', '0.00026717594381683949', '0.00066933783256760914', '0.012211573950727249', '0.083442608896308043', '0.19542347806693958', '0.48685044475793099', '0.24367156940116061', '0.11962342831279228', '0.00023151115723529119', '0.00017718116268827677'],
	  xs => ['-3.3069634150025427', '-3.29478474214539', '-3.2826060692882368', '-3.2338913778596257', '-2.5397070250019156', '-1.7602719621441361', '-0.88340751642913373', '-0.20140183642857634', '0.73635597357219007', '1.5523270550014279', '2.90415974214539', '2.9163384150025427'] },
	{ data => 'z200', args => ['kernel' => 'epanechnikov', 'adjust' => '0.5'], search => 0,
	  bw => '0.13943051333418083', n => 200, len => 512,
	  x1 => '-3.3069634150025427', xn => '2.9163384150025427',
	  ysum => '82.122172293242073', ymax => '0.49405964349610015',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['2.4607404978151988e-17', '1.6468200503820509e-17', '4.8873815866083189e-18', '2.122020927072034e-17', '0.013721374630464613', '0.08771611994000876', '0.20193534999956853', '0.4933904933998895', '0.24275311644527856', '0.11542330649304683', '0', '0'],
	  xs => ['-3.3069634150025427', '-3.29478474214539', '-3.2826060692882368', '-3.2338913778596257', '-2.5397070250019156', '-1.7602719621441361', '-0.88340751642913373', '-0.20140183642857634', '0.73635597357219007', '1.5523270550014279', '2.90415974214539', '2.9163384150025427'] },
	{ data => 'z200', args => ['kernel' => 'rectangular', 'adjust' => '0.5'], search => 0,
	  bw => '0.13943051333418083', n => 200, len => 512,
	  x1 => '-3.3069634150025427', xn => '2.9163384150025427',
	  ysum => '80.573161288297499', ymax => '0.49853304031926038',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['2.0264921746713403e-17', '7.7125486428577562e-18', '0', '0', '0.010396702115152296', '0.084749588609976376', '0.18833749406050476', '0.49808465830393683', '0.23118443833151864', '0.11460482459094427', '0', '0'],
	  xs => ['-3.3069634150025427', '-3.29478474214539', '-3.2826060692882368', '-3.2338913778596257', '-2.5397070250019156', '-1.7602719621441361', '-0.88340751642913373', '-0.20140183642857634', '0.73635597357219007', '1.5523270550014279', '2.90415974214539', '2.9163384150025427'] },
	{ data => 'z200', args => ['kernel' => 'triangular', 'adjust' => '0.5'], search => 0,
	  bw => '0.13943051333418083', n => 200, len => 512,
	  x1 => '-3.3069634150025427', xn => '2.9163384150025427',
	  ysum => '82.13441400068649', ymax => '0.48771276630371291',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['2.8836397379659208e-18', '3.7249537806300112e-17', '3.2612750556479677e-17', '1.7636222075233072e-05', '0.012522149056115452', '0.085822517909068557', '0.20100896816220234', '0.48441497309894238', '0.24624425028356733', '0.11482562853323114', '0', '0'],
	  xs => ['-3.3069634150025427', '-3.29478474214539', '-3.2826060692882368', '-3.2338913778596257', '-2.5397070250019156', '-1.7602719621441361', '-0.88340751642913373', '-0.20140183642857634', '0.73635597357219007', '1.5523270550014279', '2.90415974214539', '2.9163384150025427'] },
	{ data => 'z200', args => ['kernel' => 'biweight', 'adjust' => '0.5'], search => 0,
	  bw => '0.13943051333418083', n => 200, len => 512,
	  x1 => '-3.3069634150025427', xn => '2.9163384150025427',
	  ysum => '82.111106241524041', ymax => '0.49096042364063147',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['4.1656061589429643e-17', '3.2080711787611773e-17', '5.5465968242332234e-17', '0.00020313785616594312', '0.013107703243032112', '0.085964445272904519', '0.20003950533115053', '0.48947803172009102', '0.24461927580750228', '0.11636311425184885', '0', '0'],
	  xs => ['-3.3069634150025427', '-3.29478474214539', '-3.2826060692882368', '-3.2338913778596257', '-2.5397070250019156', '-1.7602719621441361', '-0.88340751642913373', '-0.20140183642857634', '0.73635597357219007', '1.5523270550014279', '2.90415974214539', '2.9163384150025427'] },
	{ data => 'z200', args => ['kernel' => 'cosine', 'adjust' => '0.5'], search => 0,
	  bw => '0.13943051333418083', n => 200, len => 512,
	  x1 => '-3.3069634150025427', xn => '2.9163384150025427',
	  ysum => '82.11094506823413', ymax => '0.49017376478378077',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['2.3424441467183464e-17', '7.7125486428577562e-18', '6.8406939979374367e-07', '0.00035357797075881913', '0.01301238460415133', '0.085501556316436939', '0.19954117052161557', '0.48855180724189351', '0.2449499924931263', '0.11679406688022181', '0', '1.1489162619887553e-18'],
	  xs => ['-3.3069634150025427', '-3.29478474214539', '-3.2826060692882368', '-3.2338913778596257', '-2.5397070250019156', '-1.7602719621441361', '-0.88340751642913373', '-0.20140183642857634', '0.73635597357219007', '1.5523270550014279', '2.90415974214539', '2.9163384150025427'] },
	{ data => 'z200', args => ['kernel' => 'optcosine', 'adjust' => '0.5'], search => 0,
	  bw => '0.13943051333418083', n => 200, len => 512,
	  x1 => '-3.3069634150025427', xn => '2.9163384150025427',
	  ysum => '82.121298927371697', ymax => '0.49252953060989446',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['6.916195737920956e-18', '3.4694469519536142e-18', '1.17508858558324e-17', '2.2282386815032723e-17', '0.013493654090602778', '0.087245016819509899', '0.20143326352300131', '0.49174308671363998', '0.24327248522826378', '0.11548681708118948', '0', '0'],
	  xs => ['-3.3069634150025427', '-3.29478474214539', '-3.2826060692882368', '-3.2338913778596257', '-2.5397070250019156', '-1.7602719621441361', '-0.88340751642913373', '-0.20140183642857634', '0.73635597357219007', '1.5523270550014279', '2.90415974214539', '2.9163384150025427'] },
	{ data => 'z60', args => ['adjust' => '0.25'], search => 0,
	  bw => '0.081971864425749177', n => 60, len => 512,
	  x1 => '-2.4607593432772474', xn => '2.2263843432772474',
	  ysum => '109.01734072520152', ymax => '0.71203289866680741',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00092174467137562551', '0.0012754268800761685', '0.0017405558797397062', '0.0054571343420632308', '0.035067107363005931', '0.069136585883026541', '0.38636752575877786', '0.68451097884371459', '0.52656108158267412', '0.10762382615050375', '0.0012754156858202368', '0.00092173866467300312'],
	  xs => ['-2.4607593432772474', '-2.4515868507399587', '-2.4424143582026701', '-2.4057243880535157', '-1.8828923134280631', '-1.2958527910415902', '-0.6354333283568081', '-0.12177374626864435', '0.58450817910258079', '1.1990651791009199', '2.2172118507399587', '2.2263843432772474'] },
	{ data => 'z60', args => ['adjust' => '1'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.915338358710912', ymax => '0.44175103671405297',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00024917333185729413', '0.00027806672600706874', '0.00031126894795352017', '0.00047836858665699849', '0.02436356933456163', '0.059326897028961705', '0.23979241756191538', '0.41537903000872428', '0.3785626383463494', '0.10703956574317471', '0.00025792375949583549', '0.00023140916339818996'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['adjust' => '4'], search => 0,
	  bw => '1.3115498308119868', n => 60, len => 512,
	  x1 => '-6.1494932424359607', xn => '5.9151182424359607',
	  ysum => '42.350828246992897', ymax => '0.25629185427880069',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00012105385340990475', '0.00012845601549062182', '0.00013606941454032495', '0.00017143868937445541', '0.002953990955152181', '0.029896191615043671', '0.15151094669839713', '0.25196928023710485', '0.15590658171903765', '0.031939305000002298', '0.00018655252549576063', '0.00017534755907293583'],
	  xs => ['-6.1494932424359607', '-6.1258834352248615', '-6.1022736280137613', '-6.0078343991693632', '-4.6620753881366825', '-3.1510477266263051', '-1.4511416074271297', '-0.1289924036055492', '1.6889627516491235', '3.2708198347927997', '5.8915084352248623', '5.9151182424359607'] },
	{ data => 'z60', args => ['n' => '1'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 1,
	  x1 => '-3.1985061231089902', xn => '-3.1985061231089902',
	  ysum => '0.00024917333185729413', ymax => '0.00024917333185729413',
	  at => [1],
	  y  => ['0.00024917333185729413'],
	  xs => ['-3.1985061231089902'] },
	{ data => 'z60', args => ['n' => '2'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 2,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '0.0004805824952554841', ymax => '0.00024917333185729413',
	  at => [1, 2],
	  y  => ['0.00024917333185729413', '0.00023140916339818996'],
	  xs => ['-3.1985061231089902', '2.9641311231089902'] },
	{ data => 'z60', args => ['n' => '10'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 10,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '1.456003377417538', ymax => '0.43226524079359968',
	  at => [1, 2, 3, 7, 9, 10],
	  y  => ['0.00024917333185729413', '0.019209867496276282', '0.050946824022849189', '0.33632260624073612', '0.018206274690792088', '0.00023140916339818996'],
	  xs => ['-3.1985061231089902', '-2.5137686513069921', '-1.8290311795049945', '0.90991870770299732', '2.2793936513069926', '2.9641311231089902'] },
	{ data => 'z60', args => ['n' => '100'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 100,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '16.064005586421516', ymax => '0.44158309610718471',
	  at => [1, 2, 3, 7, 64, 99, 100],
	  y  => ['0.00024917333185729413', '0.00043722421810051931', '0.00074335041888430803', '0.0043869795282558965', '0.40560228193952652', '0.00040335530145028519', '0.00023140916339818996'],
	  xs => ['-3.1985061231089902', '-3.1362572620360814', '-3.0740084009631725', '-2.8250129566715367', '0.72317212448426993', '2.9018822620360809', '2.9641311231089902'] },
	{ data => 'z60', args => ['n' => '511'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 511,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.753080180555912', ymax => '0.44174500628790309',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 510, 511],
	  y  => ['0.00024917333185729413', '0.0002781233797210889', '0.00031139953733177095', '0.00047895801663620124', '0.024467933902092707', '0.059544099840026642', '0.24140334673557659', '0.41588866597985186', '0.3756353020137459', '0.10523662493251969', '0.00025797574889994745', '0.00023140916339818996'],
	  xs => ['-3.1985061231089902', '-3.1864225206654253', '-3.1743389182218609', '-3.1260045084476022', '-2.4372391691644162', '-1.6638886127762773', '-0.79386923683962118', '-0.1171875', '0.81324988815448007', '1.6228512518733127', '2.9520475206654262', '2.9641311231089902'] },
	{ data => 'z60', args => ['n' => '512'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.915338358710912', ymax => '0.44175103671405297',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00024917333185729413', '0.00027806672600706874', '0.00031126894795352017', '0.00047836858665699849', '0.02436356933456163', '0.059326897028961705', '0.23979241756191538', '0.41537903000872428', '0.3785626383463494', '0.10703956574317471', '0.00025792375949583549', '0.00023140916339818996'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['n' => '513'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 513,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '83.077623264620641', ymax => '0.44177041263423533',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 512, 513],
	  y  => ['0.00024815073249181123', '0.00027741710954409934', '0.00030994435746491448', '0.00047580178528070183', '0.024259157827805376', '0.059098908059630438', '0.23818757208390093', '0.41486582484027501', '0.38144420399562146', '0.10884745885100874', '0.00025733596952609648', '0.00023048384275162689'],
	  xs => ['-3.1985061231089902', '-3.1864697222374705', '-3.1744333213659512', '-3.1262877178798734', '-2.440212868203262', '-1.6698832124260146', '-0.80326234967661092', '-0.12922390087151969', '0.79757896623548152', '1.6040178246272876', '2.9520947222374709', '2.9641311231089902'] },
	{ data => 'z60', args => ['n' => '1000'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 1000,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '162.09849250428891', ymax => '0.44177891855004531',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 999, 1000],
	  y  => ['0.00024815073249181123', '0.00026285493034055907', '0.00027820974497583104', '0.00034831590050925308', '0.0048000092368063159', '0.026023502630824057', '0.047138689306107789', '0.062516631920982502', '0.13514407441326781', '0.26092977838297488', '0.00024397900082349418', '0.00023048384275162689'],
	  xs => ['-3.1985061231089902', '-3.1923373170567197', '-3.1861685110044498', '-3.1614932867953689', '-2.8098713418159642', '-2.4150677544706682', '-1.9709137187072103', '-1.6254605797800763', '-1.1504625137552669', '-0.73715250825316048', '2.9579623170567193', '2.9641311231089902'] },
	{ data => 'z60', args => ['n' => '1024'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 1024,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '165.99274480718853', ymax => '0.44177659648718492',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 1023, 1024],
	  y  => ['0.00024815073249181123', '0.00026250022038961388', '0.00027744807113926198', '0.00034564136074655637', '0.0045459979250246632', '0.024733548073277527', '0.046455536555937794', '0.059639792874592139', '0.12437949636734359', '0.24104949784848151', '0.00024365358608396034', '0.00023048384275162689'],
	  xs => ['-3.1985061231089902', '-3.1924820397793536', '-3.1864579564497175', '-3.1623616231311722', '-2.8189888733419006', '-2.4334475402451745', '-1.9997135405113575', '-1.6623648740517223', '-1.1985104576697239', '-0.79489687458408875', '2.9581070397793536', '2.9641311231089902'] },
	{ data => 'z60', args => ['n' => '2048'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 2048,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '332.14752842267228', ymax => '0.4417846326729763',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 2047, 2048],
	  y  => ['0.00024794321998122153', '0.00025499676030921436', '0.00026220261742690415', '0.000293070143031307', '0.0012425260473324434', '0.0046227842822660131', '0.01385917896710118', '0.024918395299047904', '0.039524508500311077', '0.046515166435845391', '0.00023677969826132217', '0.00023030414574610274'],
	  xs => ['-3.1985061231089902', '-3.1954955528861189', '-3.1924849826632471', '-3.1804427017717609', '-3.0088401990680849', '-2.8161637048043087', '-2.5994026487575597', '-2.4308107162767554', '-2.1989968091156489', '-1.9972886041832578', '2.9611205528861189', '2.9641311231089902'] },
	{ data => 'z60', args => ['cut' => '0'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-2.21484375', xn => '1.98046875',
	  ysum => '118.70470019829375', ymax => '0.44176425018460524',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.038720218555855848', '0.039140415276893617', '0.039545988766240783', '0.041073884464604901', '0.057238815441340546', '0.13018047289314982', '0.31383513603926022', '0.41556319323634527', '0.44041917924848012', '0.26985818961000491', '0.048884925915905451', '0.04783028151844896'],
	  xs => ['-2.21484375', '-2.2066337451076321', '-2.1984237402152642', '-2.1655837206457926', '-1.6976134417808217', '-1.1721731286692758', '-0.5810527764187865', '-0.12129250244618373', '0.51087787426614506', '1.0609482020547949', '1.9722587451076325', '1.98046875'] },
	{ data => 'z60', args => ['cut' => '1'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-2.5427312077029969', xn => '2.3083562077029969',
	  ysum => '104.6649410267915', ymax => '0.44177526196241412',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.017318726755085185', '0.017930491730982063', '0.018548902376248795', '0.021100683235026996', '0.047752217358281765', '0.098167847914433878', '0.28963459401936387', '0.41548665280256941', '0.43078259614110337', '0.19851778890336255', '0.016854213696416664', '0.016218634639507463'],
	  xs => ['-2.5427312077029969', '-2.5332378859507347', '-2.5237445641984726', '-2.4857712771894236', '-1.9446519373104771', '-1.337079345165695', '-0.65356017900281538', '-0.12193416087613107', '0.60905161404805952', '1.2451041714496283', '2.2988628859507347', '2.3083562077029969'] },
	{ data => 'z60', args => ['cut' => '3'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.915338358710912', ymax => '0.44175103671405297',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00024917333185729413', '0.00027806672600706874', '0.00031126894795352017', '0.00047836858665699849', '0.02436356933456163', '0.059326897028961705', '0.23979241756191538', '0.41537903000872428', '0.3785626383463494', '0.10703956574317471', '0.00025792375949583549', '0.00023140916339818996'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['cut' => '10'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-5.493718327029967', xn => '5.259343327029967',
	  ysum => '47.521346129666767', ymax => '0.44167000418104951',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['2.083407705744975e-17', '7.5859495512051327e-18', '2.5216006573798433e-17', '4.7669221775450497e-17', '4.2293970596693455e-10', '0.0044973251915405143', '0.10345277551589915', '0.41496312772340649', '0.13174295024571714', '0.00040304397969471447', '6.3764942538370896e-19', '6.2158083753814428e-18'],
	  xs => ['-5.493718327029967', '-5.4726751535386562', '-5.4516319800473445', '-5.3674592860821004', '-4.1679983970773726', '-2.821235293633467', '-1.3061268022590733', '-0.1277090867456554', '1.4926152720852937', '2.9025078960031312', '5.2383001535386562', '5.259343327029967'] },
	{ data => 'z60', args => ['ext' => '1'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.915351746235189', ymax => '0.44175710433670523',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00024862956980690077', '0.00027808678483751061', '0.00031059197212594515', '0.00047659460647071907', '0.02436295960858555', '0.059318857411833237', '0.23978675681667524', '0.41540052698124241', '0.37856635312092912', '0.10703621114665535', '0.0002579590058290646', '0.00023093257653417288'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['ext' => '4'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.915338358710912', ymax => '0.44175103671405297',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00024917333185729413', '0.00027806672600706874', '0.00031126894795352017', '0.00047836858665699849', '0.02436356933456163', '0.059326897028961705', '0.23979241756191538', '0.41537903000872428', '0.3785626383463494', '0.10703956574317471', '0.00025792375949583549', '0.00023140916339818996'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['ext' => '8'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.915327333064369', ymax => '0.44171451754892366',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00025027475184513149', '0.00027869777290551417', '0.00031251679478202425', '0.00047950946724943742', '0.024363260229564948', '0.059322925843297611', '0.23980379359972198', '0.41535803848505637', '0.37853526150924538', '0.10702921713459185', '0.000258501014566555', '0.00023241245603818013'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['from' => '-1'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-1', xn => '2.9641311231089902',
	  ysum => '114.93342278618987', ymax => '0.44176246665401514',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.17487889254005551', '0.17716630353993026', '0.17946907195345232', '0.18891033744658334', '0.3359702692237988', '0.42232378306956014', '0.438321989351941', '0.30628874023153219', '0.11444970075844373', '0.034436717538615318', '0.00024769632682633764', '0.00023058420465471842'],
	  xs => ['-1', '-0.99224240484714488', '-0.98448480969428964', '-0.95345442908286904', '-0.51127150537012445', '-0.014785415587393769', '0.54376143541817812', '0.97818676397806748', '1.5755215907479152', '2.0952804659892115', '2.956373527956135', '2.9641311231089902'] },
	{ data => 'z60', args => ['to' => '1'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '1',
	  ysum => '102.9237176698153', ymax => '0.44176296912732527',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00024832478764434668', '0.00026791090336913319', '0.00028927544915499615', '0.00038892068550731645', '0.0096090512620463624', '0.041527867818350037', '0.068208232551528941', '0.14660617859343528', '0.34809345922768192', '0.4259758363547827', '0.30024532101605922', '0.29659695849683809'],
	  xs => ['-3.1985061231089902', '-3.1902898684649412', '-3.1820736138208923', '-3.1492085952446969', '-2.6808820805339093', '-2.1550417833147795', '-1.5634714489432584', '-1.1033611888765198', '-0.47070958128475437', '0.07977947986652234', '0.9917837453559506', '1'] },
	{ data => 'z60', args => ['from' => '-1', 'to' => '1'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-1', xn => '1',
	  ysum => '188.13490069962634', ymax => '0.44177674054720439',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.17487456474197116', '0.17602855464287445', '0.17718348877331394', '0.18186447051400337', '0.25531467910547806', '0.33851802517200774', '0.40403289232642609', '0.42288400255913494', '0.43632121140391228', '0.43674266321518007', '0.29833722129108764', '0.29659890717608028'],
	  xs => ['-1', '-0.99608610567514677', '-0.99217221135029354', '-0.97651663405088063', '-0.75342465753424659', '-0.50293542074363995', '-0.22113502935420748', '-0.0019569471624266699', '0.29941291585127194', '0.56164383561643838', '0.99608610567514666', '1'] },
	{ data => 'z60', args => ['from' => '-1', 'to' => '1', 'n' => '37'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 37,
	  x1 => '-1', xn => '1',
	  ysum => '13.469850700559057', ymax => '0.44175659592093336',
	  at => [1, 2, 3, 7, 36, 37],
	  y  => ['0.17487456474197116', '0.19170530443499217', '0.20947712697366661', '0.28517238939429368', '0.32124948008005727', '0.29659890717608028'],
	  xs => ['-1', '-0.94444444444444442', '-0.88888888888888884', '-0.66666666666666674', '0.94444444444444442', '1'] },
	{ data => 'z200', args => ['bw' => 'nrd0'], search => 0,
	  bw => '0.27886102666836166', n => 200, len => 512,
	  x1 => '-3.7252549550050849', xn => '3.3346299550050849',
	  ysum => '72.379686941839111', ymax => '0.43596156086232474',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['8.0192008374392455e-05', '9.2717269614363902e-05', '0.00010718493274651796', '0.00018666181203212695', '0.010014535744961087', '0.055367973879506704', '0.22138044571744891', '0.43596156086232474', '0.23681510513753803', '0.087873197816955725', '0.00013847268748173904', '0.00011884457893877432'],
	  xs => ['-3.7252549550050849', '-3.711439133263382', '-3.6976233115216792', '-3.6423600245548675', '-2.8548581852778039', '-1.9706455938088194', '-0.97590642840621245', '-0.20222041087085119', '0.86159786324027055', '1.7872579199343632', '3.3208141332633825', '3.3346299550050849'] },
	{ data => 'z200', args => ['bw' => 'nrd'], search => 0,
	  bw => '0.32843632029829262', n => 200, len => 512,
	  x1 => '-3.8739808358948777', xn => '3.4833558358948777',
	  ysum => '69.453353655242481', ymax => '0.42107478979168356',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['6.8186888850855847e-05', '7.7539337239057078e-05', '8.8411220100730818e-05', '0.00014525126814118075', '0.0081409646153397155', '0.050343912048896315', '0.22289724842729525', '0.42076172110479049', '0.23044612439513823', '0.08205999772377047', '0.00012789235520293992', '0.00011162844628663128'],
	  xs => ['-3.8739808358948777', '-3.8595829167720015', '-3.8451849976491252', '-3.7875933211576203', '-2.9669119311536751', '-2.0454451072895958', '-1.008794930442507', '-0.20251145956143812', '0.90612831290003149', '1.87078889413274', '3.4689579167720015', '3.4833558358948777'] },
	{ data => 'z200', args => ['bw' => 'ucv'], search => 1,
	  bw => '0.36282590920947061', n => 200, len => 512,
	  x1 => '-3.9771496026284119', xn => '3.5865246026284119',
	  ysum => '67.558612146145677', ymax => '0.41173234704329825',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['6.1730573765170351e-05', '6.9851259509930722e-05', '7.8759995963592288e-05', '0.00012534307159953436', '0.0069503808116369815', '0.047431449967741353', '0.22247829132104485', '0.41097046428173606', '0.22557070174599131', '0.078164972236502483', '0.00012295680061281801', '0.00010782279407112443'],
	  xs => ['-3.9771496026284119', '-3.9623478918549151', '-3.9475461810814183', '-3.8883393379874316', '-3.0446418238981185', '-2.0973323343943289', '-1.0316091587025649', '-0.20271335538674862', '0.93701837417249845', '1.9287329959967794', '3.5717228918549146', '3.5865246026284119'] },
	{ data => 'z200', args => ['bw' => 'bcv'], search => 1,
	  bw => '0.39055799849637562', n => 200, len => 512,
	  x1 => '-4.0603458704891269', xn => '3.6697208704891269',
	  ysum => '66.104345662895653', ymax => '0.4046298871179167',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['5.7858660644969307e-05', '6.4937209809325043e-05', '7.268322334075722e-05', '0.00011343880969703153', '0.0061219007063847029', '0.045339357077124887', '0.22143726778176925', '0.40345372035919574', '0.22160218021332961', '0.074927846825714711', '0.00011977393932272506', '0.00010595470489810525'],
	  xs => ['-4.0603458704891269', '-4.0452185383150008', '-4.0300912061408756', '-3.9695818774443725', '-3.107323943519205', '-2.1391746843751576', '-1.0500067678381044', '-0.2028761660870626', '0.96192841132061968', '1.9754596669870441', '3.6545935383150017', '3.6697208704891269'] },
	{ data => 'z200', args => ['bw' => 'sj'], search => 1,
	  bw => '0.31757415427963309', n => 200, len => 512,
	  x1 => '-3.8413943378388993', xn => '3.4507693378388993',
	  ysum => '70.074102703332201', ymax => '0.42417321632843275',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['7.0311857718305653e-05', '8.0575734689128755e-05', '9.202273136327915e-05', '0.00015284818554638538', '0.0085470286938835929', '0.051350558793333285', '0.22281050272026384', '0.42397674437266075', '0.23193625879055593', '0.083275366128842773', '0.00013016095196578177', '0.00011265179599796119'],
	  xs => ['-3.8413943378388993', '-3.827123958825831', '-3.8128535798127632', '-3.7557720637604906', '-2.942360460015609', '-2.029056203179251', '-1.0015889142383476', '-0.20244768950653436', '0.89637149449970899', '1.8524868883752719', '3.4364989588258306', '3.4507693378388993'] },
	{ data => 'z200', args => ['bw' => 'SJ-ste'], search => 1,
	  bw => '0.31757415427963309', n => 200, len => 512,
	  x1 => '-3.8413943378388993', xn => '3.4507693378388993',
	  ysum => '70.074102703332201', ymax => '0.42417321632843275',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['7.0311857718305653e-05', '8.0575734689128755e-05', '9.202273136327915e-05', '0.00015284818554638538', '0.0085470286938835929', '0.051350558793333285', '0.22281050272026384', '0.42397674437266075', '0.23193625879055593', '0.083275366128842773', '0.00013016095196578177', '0.00011265179599796119'],
	  xs => ['-3.8413943378388993', '-3.827123958825831', '-3.8128535798127632', '-3.7557720637604906', '-2.942360460015609', '-2.029056203179251', '-1.0015889142383476', '-0.20244768950653436', '0.89637149449970899', '1.8524868883752719', '3.4364989588258306', '3.4507693378388993'] },
	{ data => 'z200', args => ['bw' => 'SJ-dpi'], search => 1,
	  bw => '0.32165942029504913', n => 200, len => 512,
	  x1 => '-3.8536501358851476', xn => '3.4630251358851476',
	  ysum => '69.839341664052583', ymax => '0.42299390667799408',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['6.9647025545189179e-05', '7.9440862704959687e-05', '9.0364940031858294e-05', '0.00014957263937546668', '0.0083937611132418148', '0.050965552549581884', '0.22285724158833375', '0.4227599619380078', '0.2313686328776369', '0.082820368086596263', '0.00012932902360931597', '0.00011251363503078802'],
	  xs => ['-3.8536501358851476', '-3.8393317889736598', '-3.825013442062172', '-3.7677400544162203', '-2.9515942804614124', '-2.0352200781261898', '-1.0042991004990638', '-0.20247167345574368', '0.9000410387288218', '1.8593702817985083', '3.4487067889736602', '3.4630251358851476'] },
	{ data => 'z200', args => ['bw' => 'NRD0'], search => 0,
	  bw => '0.27886102666836166', n => 200, len => 512,
	  x1 => '-3.7252549550050849', xn => '3.3346299550050849',
	  ysum => '72.379686941839111', ymax => '0.43596156086232474',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['8.0192008374392455e-05', '9.2717269614363902e-05', '0.00010718493274651796', '0.00018666181203212695', '0.010014535744961087', '0.055367973879506704', '0.22138044571744891', '0.43596156086232474', '0.23681510513753803', '0.087873197816955725', '0.00013847268748173904', '0.00011884457893877432'],
	  xs => ['-3.7252549550050849', '-3.711439133263382', '-3.6976233115216792', '-3.6423600245548675', '-2.8548581852778039', '-1.9706455938088194', '-0.97590642840621245', '-0.20222041087085119', '0.86159786324027055', '1.7872579199343632', '3.3208141332633825', '3.3346299550050849'] },
	{ data => 'z200', args => ['bw' => 'Sj'], search => 1,
	  bw => '0.31757415427963309', n => 200, len => 512,
	  x1 => '-3.8413943378388993', xn => '3.4507693378388993',
	  ysum => '70.074102703332201', ymax => '0.42417321632843275',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['7.0311857718305653e-05', '8.0575734689128755e-05', '9.202273136327915e-05', '0.00015284818554638538', '0.0085470286938835929', '0.051350558793333285', '0.22281050272026384', '0.42397674437266075', '0.23193625879055593', '0.083275366128842773', '0.00013016095196578177', '0.00011265179599796119'],
	  xs => ['-3.8413943378388993', '-3.827123958825831', '-3.8128535798127632', '-3.7557720637604906', '-2.942360460015609', '-2.029056203179251', '-1.0015889142383476', '-0.20244768950653436', '0.89637149449970899', '1.8524868883752719', '3.4364989588258306', '3.4507693378388993'] },
	{ data => 'z9', args => ['bw' => 'nrd'], search => 0,
	  bw => '0.61333169251739672', n => 9, len => 512,
	  x1 => '-3.0294482025521901', xn => '3.5597216400521901',
	  ysum => '77.528621667261476', ymax => '0.38180047045781634',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00082696107334499487', '0.0008821688505868913', '0.0009393624531467519', '0.0012050505981228779', '0.020780272188783117', '0.14048854394134375', '0.36717823388265308', '0.3387767706725191', '0.20652768559994944', '0.080305767584643764', '0.00087087138877189028', '0.0008166714720433322'],
	  xs => ['-3.0294482025521901', '-3.0165535453259582', '-3.0036588880997268', '-2.9520802591947999', '-2.2170847972995951', '-1.3918267348207687', '-0.46341141453208889', '0.25868939013688408', '1.2515779965567222', '2.1155200307142441', '3.5468269828259582', '3.5597216400521901'] },
	{ data => 'z9', args => ['bw' => 'SJ'], search => 1,
	  bw => '0.5766651282016827', n => 9, len => 512,
	  x1 => '-2.919448509605048', xn => '3.449721947105048',
	  ysum => '80.206698548444919', ymax => '0.39367728628559934',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00087285603803337341', '0.00093092500068859847', '0.0009941068780644042', '0.0012815255310252242', '0.022863636724287643', '0.14925682829777909', '0.38248056736877517', '0.33950408120168724', '0.21237238649486712', '0.086995759919744509', '0.00092267885546493968', '0.00086534852168089504'],
	  xs => ['-2.919448509605048', '-2.9069843795527777', '-2.8945202495005073', '-2.8446637292914265', '-2.1342083163120225', '-1.3365039929667268', '-0.43908662920326913', '0.25890465372386462', '1.2186426677486732', '2.0537393812507805', '3.4372578170527772', '3.449721947105048'] },
	{ data => 'const', args => [], search => 0,
	  bw => '1.703584830096522', n => 10, len => 512,
	  x1 => '-2.1107544902895654', xn => '8.1107544902895654',
	  ysum => '49.860030656704502', ymax => '0.23413417688266833',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.0026034366576986575', '0.0026985438825133496', '0.0027936511073280417', '0.003210274126526243', '0.018211408093134634', '0.075043706242320651', '0.18790432274843616', '0.23413417688266833', '0.15643384821151918', '0.056642377391773399', '0.0026985438825133253', '0.002603436657698641'],
	  xs => ['-2.1107544902895654', '-2.0907515372943029', '-2.0707485842990403', '-1.9907367723179905', '-0.85056845158802874', '0.42962054010877049', '1.8698331557676697', '2.9899985235023694', '4.5302259041375805', '5.870423754820167', '8.0907515372943042', '8.1107544902895654'] },
	{ data => 'two', args => [], search => 0,
	  bw => '1.0963090116135892', n => 2, len => 512,
	  x1 => '-4.7889270348407678', xn => '5.5389270348407678',
	  ysum => '49.412916858668666', ymax => '0.18244087467458009',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.0020254300248100511', '0.0021390511802946788', '0.0022608673905411439', '0.0028050441511507525', '0.033589479277710201', '0.14649851048427009', '0.14961441737913167', '0.084340231586092579', '0.17531261004777071', '0.1175073925867028', '0.0021390511802946662', '0.0020254300248100468'],
	  xs => ['-4.7889270348407678', '-4.7687159701251485', '-4.7485049054095292', '-4.6676606465470512', '-3.5156299577567429', '-2.2221218159570983', '-0.76692515643249859', '0.36489446764219036', '1.921146450744887', '3.2752877866913899', '5.5187159701251485', '5.5389270348407678'] },
	{ data => 'ties', args => [], search => 0,
	  bw => '0.40211385819951334', n => 13, len => 512,
	  x1 => '-0.20634157459853997', xn => '5.2063415745985395',
	  ysum => '94.332557617629817', ymax => '0.40215975850500446',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.0042513262841122777', '0.0045965814065288962', '0.0049739045653465408', '0.0067358840475496206', '0.15567810973310148', '0.39795191558425935', '0.40120393345912025', '0.17964265433909546', '0.054530358196709032', '0.22857314673068738', '0.0027578717008027338', '0.0025507288358715941'],
	  xs => ['-0.20634157459853997', '-0.19574923966860439', '-0.1851569047386688', '-0.14278756501892653', '0.46097552598740121', '1.1388849615032781', '1.9015330764586396', '2.4947038325350315', '3.3103136221400709', '4.0200000624457548', '5.1957492396686025', '5.2063415745985395'] },
	{ data => 'ties', args => ['kernel' => 'epanechnikov', 'adjust' => '2'], search => 0,
	  bw => '0.80422771639902668', n => 13, len => 512,
	  x1 => '-1.4126831491970799', xn => '6.4126831491970799',
	  ysum => '65.302554961271909', ymax => '0.29597686302398696',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0', '0', '0', '0', '0.056407886130588565', '0.20307278304458412', '0.29417577951773305', '0.22688184090686234', '0.11482702383957044', '0.08175523147934563', '0', '0'],
	  xs => ['-1.4126831491970799', '-1.3973693208244886', '-1.3820554924518973', '-1.320800178961532', '-0.44791196172382741', '0.53217305412201643', '1.6347686969485906', '2.4923430858137041', '3.6715078705032349', '4.6975343714668529', '6.3973693208244882', '6.4126831491970799'] },
	{ data => 'withna', args => ['na_rm' => 1], search => 0,
	  bw => '0.80873217043008305', n => 3, len => 512,
	  x1 => '-1.4261965112902493', xn => '6.4261965112902493',
	  ysum => '65.018648442469342', ymax => '0.27306055238626031',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.0018498975034713448', '0.0019565510631849884', '0.0020728958182593326', '0.0025910820964511064', '0.03399521740870394', '0.16963422948853829', '0.2716516359964124', '0.19550738715815061', '0.17163272113045328', '0.11305249398073908', '0.0019339804233363372', '0.0018290217905386041'],
	  xs => ['-1.4261965112902493', '-1.4108297930464517', '-1.3954630748026544', '-1.3339962018274645', '-0.45809326193100974', '0.5253767056720271', '1.6317804192254437', '2.492316640878101', '3.6755539456505053', '4.7051240679849347', '6.4108297930464513', '6.4261965112902493'] },
	{ data => 'withna', args => ['na_rm' => 1, 'bw' => '0.5'], search => 0,
	  bw => '0.5', n => 3, len => 512,
	  x1 => '-0.5', xn => '5.5',
	  ysum => '85.092771722679572', ymax => '0.3226298450855335',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.0029608664874974174', '0.0031759508895701379', '0.0034065948562341988', '0.0044734029555654406', '0.084258843895444246', '0.30061178292493607', '0.31773735133626185', '0.1691303768690742', '0.13426674655363996', '0.24833649439268354', '0.0031748324194041892', '0.002959871407390088'],
	  xs => ['-0.5', '-0.48825831702544031', '-0.47651663405088063', '-0.42954990215264188', '0.23972602739726023', '0.99119373776908004', '1.8365949119373775', '2.4941291585127199', '3.3982387475538158', '4.1849315068493151', '5.4882583170254398', '5.5'] },
	{ data => 'pr8033', args => ['bw' => '0.5'], search => 0,
	  bw => '0.5', n => 3, len => 512,
	  x1 => '-1', xn => '2.5',
	  ysum => '97.201647876058772', ymax => '0.46934472943108463',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.0030485882363400904', '0.003177374164207662', '0.0033106859933952166', '0.0038955943015768386', '0.029076231754284504', '0.14091448950912072', '0.37427647017007531', '0.46934472943108463', '0.30914004140660722', '0.10360207872824366', '0.0031773741642075817', '0.003048588236340011'],
	  xs => ['-1', '-0.99315068493150682', '-0.98630136986301364', '-0.95890410958904115', '-0.56849315068493156', '-0.13013698630136994', '0.36301369863013688', '0.7465753424657533', '1.2739726027397258', '1.7328767123287672', '2.4931506849315066', '2.5'] },
	{ data => 'pr8033', args => ['bw' => '0.5', 'kernel' => 'cosine'], search => 0,
	  bw => '0.5', n => 3, len => 512,
	  x1 => '-1', xn => '2.5',
	  ysum => '97.333321806443507', ymax => '0.44413421897680894',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0', '0', '0', '2.8802020887289643e-19', '0.029501908836498454', '0.15662829700496769', '0.37059324283363199', '0.44413421897680888', '0.31647256130314366', '0.11618625887856764', '0', '0'],
	  xs => ['-1', '-0.99315068493150682', '-0.98630136986301364', '-0.95890410958904115', '-0.56849315068493156', '-0.13013698630136994', '0.36301369863013688', '0.7465753424657533', '1.2739726027397258', '1.7328767123287672', '2.4931506849315066', '2.5'] },
	{ data => 'unif4096', args => [], search => 0,
	  bw => '0.049432327642498261', n => 4096, len => 512,
	  x1 => '-0.14732042042749477', xn => '1.1482969829274947',
	  ysum => '394.39222879357817', ymax => '1.0457472460763253',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.0013656602348034218', '0.0016176325001549835', '0.0019069072161874139', '0.0036082409789814102', '0.60664029832738875', '1.0452912695357137', '0.96281075265116112', '1.0082670044719579', '1.0193072566197472', '0.96902447070098296', '0.0017549277101566692', '0.0014836495880365401'],
	  xs => ['-0.14732042042749477', '-0.14478496562640869', '-0.14224951082532261', '-0.13210769162097827', '0.01241323204092859', '0.17468233931043803', '0.35723508498863615', '0.49922055384945691', '0.69445057353308548', '0.86432604520585321', '1.1457615281264086', '1.1482969829274947'] },
	{ data => 'unif4096', args => ['old_coords' => 1], search => 0,
	  bw => '0.049432327642498261', n => 4096, len => 512,
	  x1 => '-0.14732042042749477', xn => '1.1482969829274947',
	  ysum => '394.77796531048551', ymax => '1.0467163876995589',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.0013803377826988566', '0.001634512159963928', '0.0019262357588547461', '0.0036406362149793326', '0.60712943130951824', '1.0462658937984599', '0.96380824143096444', '1.0092233981899139', '1.0202547453773256', '0.9699657112500355', '0.0017729386591311836', '0.0014993366465085411'],
	  xs => ['-0.14732042042749477', '-0.14478496562640869', '-0.14224951082532261', '-0.13210769162097827', '0.01241323204092859', '0.17468233931043803', '0.35723508498863615', '0.49922055384945691', '0.69445057353308548', '0.86432604520585321', '1.1457615281264086', '1.1482969829274947'] },
	{ data => 'z200', args => ['old_coords' => 1], search => 0,
	  bw => '0.27886102666836166', n => 200, len => 512,
	  x1 => '-3.7252549550050849', xn => '3.3346299550050849',
	  ysum => '72.450497175954723', ymax => '0.43630043757859965',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['8.0899149932343192e-05', '9.3508971614248408e-05', '0.00010806979358089601', '0.00018800099422539945', '0.010024248416232919', '0.055448905084699414', '0.22165477857591984', '0.43630043757859965', '0.23706983209846205', '0.087973171826829288', '0.0001398008373014037', '0.00012001664164121894'],
	  xs => ['-3.7252549550050849', '-3.711439133263382', '-3.6976233115216792', '-3.6423600245548675', '-2.8548581852778039', '-1.9706455938088194', '-0.97590642840621245', '-0.20222041087085119', '0.86159786324027055', '1.7872579199343632', '3.3208141332633825', '3.3346299550050849'] },
	{ data => 'z200', args => ['old_coords' => 1, 'kernel' => 'biweight'], search => 0,
	  bw => '0.27886102666836166', n => 200, len => 512,
	  x1 => '-3.7252549550050849', xn => '3.3346299550050849',
	  ysum => '72.451677890824215', ymax => '0.4309875141944074',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['9.6350151060792603e-18', '2.5624355225132412e-17', '3.4851642932987584e-17', '6.3116983458398652e-18', '0.0098592485217169189', '0.05732756593692577', '0.22736063416094449', '0.43093001543985393', '0.24219690272421052', '0.08761153502991037', '0', '0'],
	  xs => ['-3.7252549550050849', '-3.711439133263382', '-3.6976233115216792', '-3.6423600245548675', '-2.8548581852778039', '-1.9706455938088194', '-0.97590642840621245', '-0.20222041087085119', '0.86159786324027055', '1.7872579199343632', '3.3208141332633825', '3.3346299550050849'] },
	{ data => 'z60', args => ['kernel' => 'c'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.919090192793533', ymax => '0.44581088902998328',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['1.7871601042645393e-17', '1.0570810033025182e-17', '5.0858831239776889e-17', '2.2903769219831818e-06', '0.025058836981642713', '0.061073238957592646', '0.2402288709051226', '0.41090011685982936', '0.37084760394722716', '0.10350026112147223', '0', '0'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['kernel' => 'o'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.918116744728152', ymax => '0.45250297871650524',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['2.677388205927015e-17', '2.4340285056063413e-17', '3.6183331717768258e-17', '1.7639591841689734e-18', '0.025795742253494219', '0.063241932148386734', '0.23664947427016828', '0.40989766157487018', '0.36790538279608054', '0.10132350529713738', '0', '0'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['window' => 'epanechnikov'], search => 0,
	  bw => '0.32788745770299671', n => 60, len => 512,
	  x1 => '-3.1985061231089902', xn => '2.9641311231089902',
	  ysum => '82.923338962732558', ymax => '0.45505537989442896',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['2.232274155095777e-17', '1.7455547544544296e-17', '4.3521081478772577e-17', '1.7639591841689734e-18', '0.026091671992690989', '0.064075926818967538', '0.23474449807132253', '0.40810074757970294', '0.36712772920939768', '0.10046537909041299', '0', '0'],
	  xs => ['-3.1985061231089902', '-3.1864461676369396', '-3.1743862121648885', '-3.1261463902766851', '-2.4387289283697871', '-1.6668917781585333', '-0.79857498417087269', '-0.12321747773602532', '0.80539909361188888', '1.6134161102392954', '2.9520711676369396', '2.9641311231089902'] },
	{ data => 'z60', args => ['width' => '1.5'], search => 0,
	  bw => '0.375', n => 60, len => 512,
	  x1 => '-3.33984375', xn => '3.10546875',
	  ysum => '79.278789619859893', ymax => '0.43355280293617049',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00022450435832030368', '0.00024881832823088322', '0.00027576704412677434', '0.0004094939422043983', '0.018391497403536732', '0.058358312013532226', '0.23130891786373367', '0.40800812481790732', '0.35265206574765368', '0.095446074575761417', '0.00022812566791723443', '0.00020600201341411083'],
	  xs => ['-3.33984375', '-3.3272306139921723', '-3.3146174779843443', '-3.2641649339530332', '-2.5452161815068495', '-1.7379754770058709', '-0.82982968444227012', '-0.1234940680039136', '0.84771740459882583', '1.6927975171232879', '3.0928556139921728', '3.10546875'] },
	{ data => 'z60', args => ['width' => 'SJ'], search => 1,
	  bw => '0.40748668334785099', n => 60, len => 512,
	  x1 => '-3.4373038000435532', xn => '3.2029288000435532',
	  ysum => '76.951521131392653', ymax => '0.42890946675297775',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00021157077955491008', '0.00023335796816981375', '0.0002572636439546114', '0.00037464356347072984', '0.015439474552513236', '0.057351657989670693', '0.22610310002030323', '0.40326225534718269', '0.33744367224991911', '0.088432877627009909', '0.00021339024334399601', '0.00019354874170370048'],
	  xs => ['-3.4373038000435532', '-3.4243092156989601', '-3.411314631354367', '-3.3593362939759941', '-2.6186449863341839', '-1.7869915882802214', '-0.85138151546951368', '-0.12368479217229655', '0.87689820236137717', '1.7475353534491189', '3.1899342156989601', '3.2029288000435532'] },
	{ data => 'z9', args => ['weights' => ['0.1111111111111111', '0.1111111111111111', '0.1111111111111111', '0.1111111111111111', '0.1111111111111111', '0.1111111111111111', '0.1111111111111111', '0.1111111111111111', '0.1111111111111111']], search => 0,
	  bw => '0.52075332383552542', n => 9, len => 512,
	  x1 => '-2.7517130965065761', xn => '3.2819865340065761',
	  ysum => '84.666315334762501', ymax => '0.41537735862839287',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00095785820522145042', '0.0010242317238791001', '0.0010971294757286607', '0.0014292077185076354', '0.027122084804301914', '0.16415616766237423', '0.4090362904550659', '0.33727825857759114', '0.22195523614409396', '0.099140725643650465', '0.0010196418071742074', '0.00095370915764688216'],
	  xs => ['-2.7517130965065761', '-2.7399054651357089', '-2.7280978337648416', '-2.680867308281373', '-2.007832320141941', '-1.2521439124064386', '-0.40199445370399856', '0.25923290306456614', '1.1684205186213426', '1.9595318204694467', '3.2701789026357084', '3.2819865340065761'] },
	{ data => 'z9', args => ['weights' => ['0.022222222222222223', '0.044444444444444446', '0.066666666666666666', '0.088888888888888892', '0.1111111111111111', '0.13333333333333333', '0.15555555555555556', '0.17777777777777778', '0.20000000000000001']], search => 0,
	  bw => '0.52075332383552542', n => 9, len => 512,
	  x1 => '-2.7517130965065761', xn => '3.2819865340065761',
	  ysum => '84.658976356376243', ymax => '0.44857982781585387',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.0015275087985129594', '0.0016331710578799297', '0.0017491839443665958', '0.0022774173593684399', '0.04214741162080117', '0.21986212995773965', '0.44671176475068952', '0.32543229726594886', '0.14928133536574748', '0.086961372151713706', '0.0010158988023946697', '0.00095031885466169658'],
	  xs => ['-2.7517130965065761', '-2.7399054651357089', '-2.7280978337648416', '-2.680867308281373', '-2.007832320141941', '-1.2521439124064386', '-0.40199445370399856', '0.25923290306456614', '1.1684205186213426', '1.9595318204694467', '3.2701789026357084', '3.2819865340065761'] },
	{ data => 'z9', args => ['subdensity' => 1, 'weights' => ['0.055555555555555552', '0.055555555555555552', '0.055555555555555552', '0.055555555555555552', '0.055555555555555552', '0.055555555555555552', '0.055555555555555552', '0.055555555555555552', '0.055555555555555552']], search => 0,
	  bw => '0.52075332383552542', n => 9, len => 512,
	  x1 => '-2.7517130965065761', xn => '3.2819865340065761',
	  ysum => '42.333157667381251', ymax => '0.20768867931419643',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00047892910261072521', '0.00051211586193955006', '0.00054856473786433037', '0.00071460385925381769', '0.013561042402150957', '0.082078083831187115', '0.20451814522753295', '0.16863912928879557', '0.11097761807204698', '0.049570362821825233', '0.00050982090358710371', '0.00047685457882344108'],
	  xs => ['-2.7517130965065761', '-2.7399054651357089', '-2.7280978337648416', '-2.680867308281373', '-2.007832320141941', '-1.2521439124064386', '-0.40199445370399856', '0.25923290306456614', '1.1684205186213426', '1.9595318204694467', '3.2701789026357084', '3.2819865340065761'] },
	{ data => 'pr18151', args => ['na_rm' => 1, 'weights' => ['0.25', '0.25', '0.25', '0.25']], search => 0,
	  bw => '0.80873217043008305', n => 3, len => 512,
	  x1 => '-1.4261965112902493', xn => '6.4261965112902493',
	  ysum => '65.018648442469342', ymax => '0.27306055238626031',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.0018498975034713448', '0.0019565510631849884', '0.0020728958182593326', '0.0025910820964511064', '0.03399521740870394', '0.16963422948853829', '0.2716516359964124', '0.19550738715815061', '0.17163272113045328', '0.11305249398073908', '0.0019339804233363372', '0.0018290217905386041'],
	  xs => ['-1.4261965112902493', '-1.4108297930464517', '-1.3954630748026544', '-1.3339962018274645', '-0.45809326193100974', '0.5253767056720271', '1.6317804192254437', '2.492316640878101', '3.6755539456505053', '4.7051240679849347', '6.4108297930464513', '6.4261965112902493'] },
	{ data => 'eruptions', args => ['bw' => 'sj', 'weights' => ['0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941', '0.0036764705882352941']], search => 1,
	  bw => '0.14004353589438365', n => 272, len => 512,
	  x1 => '1.1798693923168493', xn => '5.5201306076831509',
	  ysum => '117.73316849583193', ymax => '0.59406687403037806',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.00018142738414042751', '0.00022063748376380805', '0.00026688567624073649', '0.00056772299812597228', '0.34771493534015802', '0.28764576271119441', '0.039004717983804879', '0.087379716084599351', '0.41345063086724365', '0.56407643349506476', '0.00026169682740272241', '0.00021647636544927648'],
	  xs => ['1.1798693923168493', '1.1883630541864507', '1.1968567160560519', '1.2308313635344574', '1.714970090101736', '2.2585644497562236', '2.8701081043675227', '3.3457531690651994', '3.9997651330245052', '4.5688404782877967', '5.5116369458135495', '5.5201306076831509'] },
	{ data => 'pr8033', args => ['weights' => ['0.5', '0.25', '0.25']], search => 0,
	  bw => '0.14617453488181187', n => 3, len => 512,
	  x1 => '0.061476395354564395', xn => '1.4385236046454355',
	  ysum => '92.64921911000377', ymax => '0.34207664001483773',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.003797681296518883', '0.0040107209630525584', '0.004239126357264685', '0.0052594577834077011', '0.062980273645706852', '0.27468470715800686', '0.28052703258587175', '0.15813793422392358', '0.32871114383957017', '0.22032636110006784', '0.0040107209630525099', '0.0037976812965188683'],
	  xs => ['0.061476395354564395', '0.064171203983313649', '0.066866012612062917', '0.077645247127059946', '0.23124933896576766', '0.40371709120572019', '0.59774331247566681', '0.74865259568562526', '0.9561528600993181', '1.1367050382255184', '1.4358287960166862', '1.4385236046454355'] },
	{ data => 'pr8033', args => ['subdensity' => 1, 'weights' => ['0.5', '0.25', '0.25']], search => 0,
	  bw => '0.14617453488181187', n => 3, len => 512,
	  x1 => '0.061476395354564395', xn => '1.4385236046454355',
	  ysum => '92.64921911000377', ymax => '0.34207664001483773',
	  at => [1, 2, 3, 7, 64, 128, 200, 256, 333, 400, 511, 512],
	  y  => ['0.003797681296518883', '0.0040107209630525584', '0.004239126357264685', '0.0052594577834077011', '0.062980273645706852', '0.27468470715800686', '0.28052703258587175', '0.15813793422392358', '0.32871114383957017', '0.22032636110006784', '0.0040107209630525099', '0.0037976812965188683'],
	  xs => ['0.061476395354564395', '0.064171203983313649', '0.066866012612062917', '0.077645247127059946', '0.23124933896576766', '0.40371709120572019', '0.59774331247566681', '0.74865259568562526', '0.9561528600993181', '1.1367050382255184', '1.4358287960166862', '1.4385236046454355'] },
);

our %DATA2 = (
	seq20 => ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20'],
	out99 => ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46', '47', '48', '49', '50', '51', '52', '53', '54', '55', '56', '57', '58', '59', '60', '61', '62', '63', '64', '65', '66', '67', '68', '69', '70', '71', '72', '73', '74', '75', '76', '77', '78', '79', '80', '81', '82', '83', '84', '85', '86', '87', '88', '89', '90', '91', '92', '93', '94', '95', '96', '97', '98', '99', '1000000'],
);

our @R_BW = (
	{ fn => 'bw_nrd0', data => 'precip', args => [], tight => 0, val => '3.8478922425896878' },
	{ fn => 'bw_nrd', data => 'precip', args => [], tight => 0, val => '4.5319619746056317' },
	{ fn => 'bw_nrd0', data => 'eruptions', args => [], tight => 0, val => '0.33477703446394325' },
	{ fn => 'bw_nrd', data => 'eruptions', args => [], tight => 0, val => '0.39429295170197759' },
	{ fn => 'bw_nrd0', data => 'z60', args => [], tight => 0, val => '0.32788745770299671' },
	{ fn => 'bw_nrd', data => 'z60', args => [], tight => 0, val => '0.38617856129464057' },
	{ fn => 'bw_nrd0', data => 'z200', args => [], tight => 0, val => '0.27886102666836166' },
	{ fn => 'bw_nrd', data => 'z200', args => [], tight => 0, val => '0.32843632029829262' },
	{ fn => 'bw_nrd0', data => 'z9', args => [], tight => 0, val => '0.52075332383552542' },
	{ fn => 'bw_nrd', data => 'z9', args => [], tight => 0, val => '0.61333169251739672' },
	{ fn => 'bw_nrd0', data => 'unif4096', args => [], tight => 0, val => '0.049432327642498261' },
	{ fn => 'bw_nrd', data => 'unif4096', args => [], tight => 0, val => '0.058220297001164621' },
	{ fn => 'bw_nrd0', data => 'two', args => [], tight => 0, val => '1.0963090116135892' },
	{ fn => 'bw_nrd', data => 'two', args => [], tight => 0, val => '1.2912083914560051' },
	{ fn => 'bw_nrd0', data => 'ties', args => [], tight => 0, val => '0.40211385819951334' },
	{ fn => 'bw_nrd', data => 'ties', args => [], tight => 0, val => '0.47360076632387127' },
	{ fn => 'bw_ucv', data => 'precip', args => [], tight => 0, val => '4.8618676706865616' },
	{ fn => 'bw_bcv', data => 'precip', args => [], tight => 0, val => '6.6808118050666163' },
	{ fn => 'bw_sj', data => 'precip', args => [], tight => 0, val => '3.9317684586929098' },
	{ fn => 'bw_sj', data => 'precip', args => ['method' => 'dpi'], tight => 0, val => '4.0220440847261347' },
	{ fn => 'bw_ucv', data => 'eruptions', args => [], tight => 0, val => '0.10191930268782584' },
	{ fn => 'bw_bcv', data => 'eruptions', args => [], tight => 0, val => '0.15769214221991296' },
	{ fn => 'bw_sj', data => 'eruptions', args => [], tight => 0, val => '0.14004353589438365' },
	{ fn => 'bw_sj', data => 'eruptions', args => ['method' => 'dpi'], tight => 0, val => '0.16527277852454081' },
	{ fn => 'bw_ucv', data => 'z60', args => [], tight => 0, val => '0.42962115216343277' },
	{ fn => 'bw_bcv', data => 'z60', args => [], tight => 0, val => '0.429608571321005' },
	{ fn => 'bw_sj', data => 'z60', args => [], tight => 0, val => '0.40748668334785099' },
	{ fn => 'bw_sj', data => 'z60', args => ['method' => 'dpi'], tight => 0, val => '0.40490436381783912' },
	{ fn => 'bw_ucv', data => 'z200', args => [], tight => 0, val => '0.36282590920947061' },
	{ fn => 'bw_bcv', data => 'z200', args => [], tight => 0, val => '0.39055799849637562' },
	{ fn => 'bw_sj', data => 'z200', args => [], tight => 0, val => '0.31757415427963309' },
	{ fn => 'bw_sj', data => 'z200', args => ['method' => 'dpi'], tight => 0, val => '0.32165942029504913' },
	{ fn => 'bw_ucv', data => 'unif4096', args => [], tight => 0, val => '0.0079658567535423191' },
	{ fn => 'bw_bcv', data => 'unif4096', args => [], tight => 0, val => '0.038936092524287709' },
	{ fn => 'bw_sj', data => 'unif4096', args => [], tight => 0, val => '0.026299597877984238' },
	{ fn => 'bw_sj', data => 'unif4096', args => ['method' => 'dpi'], tight => 0, val => '0.032328338489455384' },
	{ fn => 'bw_nrd0', data => 'iqr0', args => [], tight => 0, val => '1.0185208073797294' },
	{ fn => 'bw_nrd', data => 'iqr0', args => [], tight => 0, val => '0' },
	{ fn => 'bw_nrd0', data => 'const', args => [], tight => 0, val => '1.703584830096522' },
	{ fn => 'bw_nrd', data => 'const', args => [], tight => 0, val => '0' },
	{ fn => 'bw_sj', data => 'seq20', args => [], tight => 0, val => '3.8748824353260458' },
	{ fn => 'bw_sj', data => 'out99', args => ['tol' => '0.001'], tight => 0, val => '0.72525520604455007' },
	{ fn => 'bw_sj', data => 'out99', args => ['tol' => '0.001', 'method' => 'dpi'], tight => 0, val => '3.6785470765687216' },
	{ fn => 'bw_ucv', data => 'z200', args => ['nb' => '64'], tight => 0, val => '0.31148336079684791' },
	{ fn => 'bw_bcv', data => 'z200', args => ['nb' => '64'], tight => 0, val => '0.35238002964362175' },
	{ fn => 'bw_sj', data => 'z200', args => ['nb' => '64'], tight => 0, val => '0.27305827105192482' },
	{ fn => 'bw_ucv', data => 'z200', args => ['lower' => '0.050000000000000003', 'upper' => '2'], tight => 0, val => '0.36256789186568533' },
	{ fn => 'bw_sj', data => 'z200', args => ['lower' => '0.050000000000000003', 'upper' => '2'], tight => 0, val => '0.31792363296293347' },
	{ fn => 'bw_ucv', data => 'z200', args => ['tol' => '9.9999999999999995e-07'], tight => 0, val => '0.3625538116846056' },
	{ fn => 'bw_bcv', data => 'z200', args => ['tol' => '9.9999999999999995e-07'], tight => 0, val => '0.39291603080695148' },
	{ fn => 'bw_sj', data => 'z200', args => ['tol' => '9.9999999999999995e-07'], tight => 0, val => '0.31776668222002008' },
	{ fn => 'bw_sj', data => 'z200', args => ['nb' => '100'], tight => 0, val => '0.28934451004163708' },
	{ fn => 'bw_ucv', data => 'z200', args => ['nb' => '100'], tight => 0, val => '0.32827241588379263' },
	{ fn => 'bw_bcv', data => 'z200', args => ['nb' => '100'], tight => 0, val => '0.37644045291088696' },
	{ fn => 'bw_ucv', data => 'precip', args => ['tol' => '1e-10'], tight => 1, val => '4.8524309346134959' },
	{ fn => 'bw_bcv', data => 'precip', args => ['tol' => '1e-10'], tight => 1, val => '6.7040575172729859' },
	{ fn => 'bw_sj', data => 'precip', args => ['tol' => '1e-10'], tight => 1, val => '3.9410502824256901' },
	{ fn => 'bw_sj', data => 'precip', args => ['tol' => '1e-10', 'method' => 'dpi'], tight => 1, val => '4.0220440847261347' },
	{ fn => 'bw_ucv', data => 'eruptions', args => ['tol' => '1e-10'], tight => 1, val => '0.10214574740800215' },
	{ fn => 'bw_bcv', data => 'eruptions', args => ['tol' => '1e-10'], tight => 1, val => '0.15833136845968246' },
	{ fn => 'bw_sj', data => 'eruptions', args => ['tol' => '1e-10'], tight => 1, val => '0.13954633957449558' },
	{ fn => 'bw_sj', data => 'eruptions', args => ['tol' => '1e-10', 'method' => 'dpi'], tight => 1, val => '0.16527277852454081' },
	{ fn => 'bw_ucv', data => 'z60', args => ['tol' => '1e-10'], tight => 1, val => '0.4313396879426839' },
	{ fn => 'bw_bcv', data => 'z60', args => ['tol' => '1e-10'], tight => 1, val => '0.43133968789633598' },
	{ fn => 'bw_sj', data => 'z60', args => ['tol' => '1e-10'], tight => 1, val => '0.40772973190030659' },
	{ fn => 'bw_sj', data => 'z60', args => ['tol' => '1e-10', 'method' => 'dpi'], tight => 1, val => '0.40490436381783912' },
	{ fn => 'bw_ucv', data => 'z200', args => ['tol' => '1e-10'], tight => 1, val => '0.36255378332731142' },
	{ fn => 'bw_bcv', data => 'z200', args => ['tol' => '1e-10'], tight => 1, val => '0.39291668314855993' },
	{ fn => 'bw_sj', data => 'z200', args => ['tol' => '1e-10'], tight => 1, val => '0.31776652424705321' },
	{ fn => 'bw_sj', data => 'z200', args => ['tol' => '1e-10', 'method' => 'dpi'], tight => 1, val => '0.32165942029504913' },
	{ fn => 'bw_ucv', data => 'unif4096', args => ['tol' => '1e-10'], tight => 1, val => '0.0079817725358117281' },
	{ fn => 'bw_bcv', data => 'unif4096', args => ['tol' => '1e-10'], tight => 1, val => '0.038949467534221779' },
	{ fn => 'bw_sj', data => 'unif4096', args => ['tol' => '1e-10'], tight => 1, val => '0.02614525229325295' },
	{ fn => 'bw_sj', data => 'unif4096', args => ['tol' => '1e-10', 'method' => 'dpi'], tight => 1, val => '0.032328338489455384' },
);

our %R_KERN = (
	gaussian => '0.28209479177387814',
	epanechnikov => '0.26832815729997472',
	rectangular => '0.28867513459481287',
	triangular => '0.27216552697590868',
	biweight => '0.26997462357801943',
	cosine => '0.27113404139349595',
	optcosine => '0.26847555627566833',
);
## END GENERATED (R)

## BEGIN GENERATED (Python) -- python3 t/density.R.scipy.py
our @PY_NRD = (
	{ data => 'z60', nrd0 => '0.3278874577029967', nrd => '0.38617856129464057' },
	{ data => 'z200', nrd0 => '0.27886102666836166', nrd => '0.3284363202982926' },
	{ data => 'z9', nrd0 => '0.5207533238355254', nrd => '0.6133316925173967' },
	{ data => 'precip', nrd0 => '3.8478922425896878', nrd => '4.531961974605632' },
	{ data => 'eruptions', nrd0 => '0.33477703446394314', nrd => '0.3942929517019775' },
);

our @PY_EXACT = (
	{ data => 'z60', n => 512, bw => '0.3278874577029967',
	  at => [1, 23, 45, 68, 90, 112, 134, 157, 179, 201, 223, 245, 268, 290, 312, 334, 356, 379, 401, 423, 445, 468, 490, 512],
	  y  => ['0.000247866450869093', '0.0021627890458157236', '0.010224275347896546', '0.027743805436617926', '0.04272020196121412', '0.04995175589913965', '0.06521649586261807', '0.10151882895423057', '0.16016766681122796', '0.24392229879993085', '0.33292474332884364', '0.39854807316985214', '0.42384211540650135', '0.43562628507544165', '0.43765333026426784', '0.3740960543559509', '0.2605157534333122', '0.16382472184360564', '0.10472748472198648', '0.06007813703080728', '0.028366256337102304', '0.009272476293490605', '0.001956304649185411', '0.0002302354448077152'] },
	{ data => 'z60', n => 8192, bw => '0.3278874577029967',
	  at => [1, 357, 713, 1069, 1426, 1782, 2138, 2494, 2850, 3206, 3562, 3918, 4275, 4631, 4987, 5343, 5699, 6055, 6411, 6767, 7124, 7480, 7836, 8192],
	  y  => ['0.000247866450869093', '0.002201261061078982', '0.010470034028429054', '0.02743058101255035', '0.04267456551609046', '0.04999106506521677', '0.06557025868916395', '0.10054354102201817', '0.15929974409061434', '0.24369742485936274', '0.3335026956545889', '0.39928635979552446', '0.4236701297667019', '0.43552234325705413', '0.43759484548170047', '0.37289027137977576', '0.258107342641', '0.1648644068984246', '0.10497663414862615', '0.05990202498656216', '0.027946647278372122', '0.009502527380252016', '0.001990722581249315', '0.0002302354448077152'] },
	{ data => 'z200', n => 512, bw => '0.27886102666836166',
	  at => [1, 23, 45, 68, 90, 112, 134, 157, 179, 201, 223, 245, 268, 290, 312, 334, 356, 379, 401, 423, 445, 468, 490, 512],
	  y  => ['7.956934692744941e-05', '0.0011651475986198115', '0.005466480846562153', '0.0108933446897584', '0.017865154007684368', '0.03237881966616868', '0.06820673179199278', '0.13032219171123693', '0.17740434012523112', '0.22453500748966224', '0.3266601559030522', '0.4215977363493542', '0.4227927782079883', '0.3661684739120512', '0.307017107920305', '0.23379512921559026', '0.17799047047732564', '0.12556205170230744', '0.08640039528570492', '0.06273268243286535', '0.041389147824557895', '0.014401966374730188', '0.002161687894200669', '0.00011782412893673072'] },
	{ data => 'z200', n => 8192, bw => '0.27886102666836166',
	  at => [1, 357, 713, 1069, 1426, 1782, 2138, 2494, 2850, 3206, 3562, 3918, 4275, 4631, 4987, 5343, 5699, 6055, 6411, 6767, 7124, 7480, 7836, 8192],
	  y  => ['7.956934692744941e-05', '0.0011885972078811244', '0.00557322097643452', '0.010810481325462315', '0.017820084561649612', '0.032486341864000075', '0.06895083841563626', '0.1290476471625055', '0.17696807265279452', '0.22435678599851988', '0.32749137866141376', '0.42250541967866706', '0.42354229250142295', '0.36655595503223226', '0.3068423613703444', '0.23301375606951819', '0.17687478355710015', '0.12622398186773662', '0.08655746934584466', '0.06264940932702844', '0.04094274204310044', '0.014796974282607851', '0.002211190197510008', '0.00011782412893673072'] },
	{ data => 'precip', n => 512, bw => '3.8478922425896878',
	  at => [1, 23, 45, 68, 90, 112, 134, 157, 179, 201, 223, 245, 268, 290, 312, 334, 356, 379, 401, 423, 445, 468, 490, 512],
	  y  => ['4.809367018725182e-05', '0.0005621431429382029', '0.0028848539652473254', '0.007289490594260804', '0.010898620500657378', '0.013442888308464674', '0.01266692285590846', '0.009456711579524294', '0.009897887351880567', '0.01595363254687574', '0.025082686990596043', '0.03268291127960689', '0.03607388383794142', '0.03271898363438025', '0.024289160285064584', '0.015261715446974404', '0.00945782644117838', '0.007219230831390678', '0.005134923964745353', '0.0029672381255773077', '0.0018152517267750038', '0.0007997481433530566', '0.00017468929659098992', '1.6469142721314443e-05'] },
	{ data => 'precip', n => 8192, bw => '3.8478922425896878',
	  at => [1, 357, 713, 1069, 1426, 1782, 2138, 2494, 2850, 3206, 3562, 3918, 4275, 4631, 4987, 5343, 5699, 6055, 6411, 6767, 7124, 7480, 7836, 8192],
	  y  => ['4.809367018725182e-05', '0.0005731369268985156', '0.0029535005559973696', '0.007218219109720434', '0.01088429557427923', '0.013449830672867698', '0.012625495581828171', '0.009501576463074268', '0.009859388761901544', '0.01593283325747903', '0.025145572779922333', '0.032780160991606674', '0.03607161571036252', '0.03276497420810915', '0.024265779811883395', '0.015166868760302507', '0.009382933952436924', '0.007242620689616395', '0.005147135297527958', '0.0029599479185703974', '0.0017991057679993577', '0.0008168959162184751', '0.00017792719356311902', '1.6469142721314443e-05'] },
	{ data => 'eruptions', n => 512, bw => '0.33477703446394314',
	  at => [1, 23, 45, 68, 90, 112, 134, 157, 179, 201, 223, 245, 268, 290, 312, 334, 356, 379, 401, 423, 445, 468, 490, 512],
	  y  => ['0.0003347885826256078', '0.0031678369844216577', '0.019061265241751574', '0.07721221336901417', '0.18879187308577425', '0.3057166586210079', '0.33951191889143956', '0.26688220116742417', '0.1625242833581011', '0.08842401024943057', '0.06420665341177517', '0.08555952692649384', '0.1499621224038177', '0.24643389335848953', '0.3610084494827888', '0.45569292114663207', '0.4818577667205998', '0.4083717271067547', '0.2707993495199959', '0.13504666786914926', '0.04888406117696238', '0.011574130949801635', '0.0019699838619664386', '0.00022248278535344078'] },
	{ data => 'eruptions', n => 8192, bw => '0.33477703446394314',
	  at => [1, 357, 713, 1069, 1426, 1782, 2138, 2494, 2850, 3206, 3562, 3918, 4275, 4631, 4987, 5343, 5699, 6055, 6411, 6767, 7124, 7480, 7836, 8192],
	  y  => ['0.0003347885826256078', '0.0032292317991629844', '0.019637531736185043', '0.07577302916122375', '0.18820200863993147', '0.3061480277328367', '0.33916392190807865', '0.26905687668454537', '0.16367746472953676', '0.08854614321499475', '0.06420661494988837', '0.08625721521827964', '0.14863155897825855', '0.24566047414037195', '0.36128672344859114', '0.45650196819222205', '0.48139238889766667', '0.4100209399008833', '0.27153122129615626', '0.1345221911811594', '0.047909160686579105', '0.01192507744442713', '0.0020072436724209966', '0.00022248278535344078'] },
);

our $PY_DISCRETISATION_512_ABS = '0.00021208684882023865';   # worst |R - exact| / max(exact)
our $PY_DISCRETISATION_512_REL = '0.0029616184357362926';   # worst relative, where exact > 1% of its max
our $PY_DISCRETISATION_8192_ABS = '9.246747665059386e-07';   # worst |R - exact| / max(exact)
our $PY_DISCRETISATION_8192_REL = '1.2691490003134142e-05';   # worst relative, where exact > 1% of its max
## END GENERATED (Python)
}
