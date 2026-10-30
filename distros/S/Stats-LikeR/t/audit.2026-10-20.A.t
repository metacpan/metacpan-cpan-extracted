#!/usr/bin/env perl
# Regressions for the quantile(), p_adjust(), scale() and prcomp() bugs the
# 2026-10-20 audit of LikeR.xs recorded, all fixed in 0.331.  Each block names
# the function and what used to happen.  The R cross-validation tables for the
# same fixes are in t/quantile.R.t, t/p_adjust.R.t, t/scale.R.t and
# t/prcomp.R.t; this file holds the Perl-side surface: croaks, leaks, tied
# arrays and the audit's own repros.
#
# Provenance of every expected number that is not structural: R 4.6.1
# (2026-06-24) at options(digits = 17), printed with sprintf("%.17g"):
#
#   quantile(1:10, c(0.001, 0.0014, 0.0012))
#       0.1% = 1.0089999999999999, 0.14% = 1.0125999999999999,
#       0.12% = 1.0107999999999999
#   quantile(1:10, c(0.0004, 0))           0.04% = 1.0036, 0% = 1
#   quantile(1:10, 0.5)                    50% = 5.5
#   quantile(1:10, c(NA, NaN, 0.5))        NA, NaN, 5.5, named "", "", "50%"
#   quantile(1:10, 1e-17)                  0.000000000000001% = 1
#   p.adjust(c(0.01, NaN, 0.04, 0.03, NaN, 0.02), "holm")
#       0.040000000000000001 NaN 0.059999999999999998 0.059999999999999998
#       NaN 0.059999999999999998
#   p.adjust(c(0.01, NaN, 0.04), "bonferroni")    0.02 NaN 0.08
#   prcomp(rbind(c(1,2),c(3,5),c(4,4),c(7,9)), center = FALSE, scale. = TRUE)
#       $scale 5 6.4807406984078604
#       $sdev  1.4098019150779262 0.11161792079505777
#   prcomp(cbind(1:4, c(2,4,6,8), c(3,6.5,9,12.25)))$sdev
#       4.8601214167495579 0.14087162401373760 6.0245343150990788e-18
#
# Tolerance: 1e-14 relative on the R values; every one matched to the last
# bit on perl-5.44.0 (double) except prcomp's sdev, 1.1e-15 out, which is the
# rounding of two different backward-stable SVDs.
#
# The leak checks need Test::LeakTrace, which is optional, and skip without
# it as the sibling suites do.  Test::LeakTrace counts SVs, not malloc()ed
# blocks, so the buffers quantile() lost to a FETCH that died are checked
# separately by the process's resident size, on a system with /proc only.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Config;
use Test::More;
use Stats::LikeR qw(quantile p_adjust scale prcomp);

my $HAVE_LEAKTRACE;
BEGIN {
	if (eval { require Test::LeakTrace; 1 }) {
		Test::LeakTrace->import('no_leaks_ok');
		$HAVE_LEAKTRACE = 1;
	} else {
		no strict 'refs';
		*{'main::no_leaks_ok'} = sub (&;$) { SKIP: { skip 'Test::LeakTrace not installed', 1 } };
	}
}
$HAVE_LEAKTRACE = 0 if $INC{'Devel/Cover.pm'};	# Devel::Cover perturbs refcounts

my $TOL = 1e-14;	# see the header
my $NaN = 9**9**9 / 9**9**9;
sub near {
	my ($got, $want, $name) = @_;
	my $err = $want == 0 ? abs($got) : abs($got - $want) / abs($want);
	ok(defined $got && $err <= $TOL, $name) or diag(sprintf('got %s, want %.17g', $got // 'undef', $want));
}
sub is_nan { my $v = shift; return defined $v && $v != $v }
sub dies_like {
	my ($code, $re, $name) = @_;
	my $lived = eval { $code->(); 1 };
	ok(!$lived && $@ =~ $re, $name) or diag($lived ? 'lived' : "died: $@");
}

{	# A tied array whose FETCH dies at one index, and counts its calls.
	package DieAt;
	sub TIEARRAY  { my ($c, $data, $at) = @_; return bless { d => $data, at => $at }, $c }
	sub FETCH     { my ($s, $i) = @_; die "FETCH $i\n" if defined $s->{at} && $i == $s->{at}; return $s->{d}[$i] }
	sub FETCHSIZE { return scalar @{ $_[0]{d} } }
}

# ---- quantile ---------------------------------------------------------------
{
	# Keys were "%.1f%%", so close probabilities collided: these three came back
	# as one key, "0.1%".  They are R's format_perc() names now.
	my $q = quantile([1 .. 10], probs => [0.001, 0.0014, 0.0012]);
	is_deeply([ sort keys %$q ], [ '0.1%', '0.12%', '0.14%' ], 'quantile: close probs keep three keys');
	near($q->{'0.1%'},  1.0089999999999999, 'quantile: 0.1%');
	near($q->{'0.14%'}, 1.0125999999999999, 'quantile: 0.14%');
	near($q->{'0.12%'}, 1.0107999999999999, 'quantile: 0.12%');
	# Any p below 0.0005 printed as "0.0%" and overwrote... nothing, or "0%".
	$q = quantile([1 .. 10], probs => [0.0004, 0]);
	is_deeply([ sort keys %$q ], [ '0%', '0.04%' ], 'quantile: p = 0.0004 is "0.04%", apart from "0%"');
	near($q->{'0.04%'}, 1.0036, 'quantile: its value is R\'s');
	is($q->{'0%'}, 1, 'quantile: and 0% is still the minimum');
	# The same probability twice is one key.
	$q = quantile([1 .. 10], probs => [0.5, 0.25, 0.5]);
	is_deeply([ sort keys %$q ], [ '25%', '50%' ], 'quantile: a repeated prob is one key');
	# Different probabilities R names alike: 0.99999999 and 1 are both "100%".
	dies_like(sub { quantile([1 .. 10], probs => [0.99999999, 1]) },
		qr/^quantile: probs at index 0 and 1 are different probabilities that are both named '100%'/,
		'quantile: two probs with one name croak rather than lose a value');
}
{
	# A scalar or a hashref probs used to be ignored, and the five defaults
	# returned.  A number is a one-element probs, as quantile(x, 0.5) is in R.
	is_deeply(quantile([1 .. 10], probs => 0.5), { '50%' => 5.5 }, 'quantile: probs => 0.5 is one prob');
	is_deeply(quantile([1 .. 10], probs => '0.25'), { '25%' => 3.25 }, 'quantile: a numeric string too');
	for my $bad ([ 'a hashref', { a => 1 } ], [ 'a code ref', sub { 1 } ], [ 'a word', 'median' ], [ 'undef', undef ]) {
		dies_like(sub { quantile([1 .. 10], probs => $bad->[1]) },
			qr/'probs' must be a number or an array reference of numbers/, "quantile: probs as $bad->[0] croaks");
	}
	dies_like(sub { quantile([1 .. 10], probs => [0.5, 'abc']) },
		qr/probs at index 1 is not a number/, 'quantile: a non-numeric prob croaks, naming it');
}
{
	# A NaN prob passed the range check and reached (size_t)NaN; an undef one
	# read as 0.  R gives NaN and NA, both named "".
	my $q = quantile([1 .. 10], probs => [$NaN, 0.5]);
	is_deeply([ sort keys %$q ], [ '', '50%' ], 'quantile: a NaN prob is named ""');
	ok(is_nan($q->{''}), 'quantile: ... and its quantile is NaN');
	$q = quantile([1 .. 10], probs => [undef, 0.5]);
	ok(exists $q->{''} && !defined $q->{''}, 'quantile: an undef prob is R\'s NA: named "", value undef');
	is($q->{'50%'}, 5.5, 'quantile: the defined prob is untouched');
	dies_like(sub { quantile([1 .. 10], probs => [undef, $NaN]) },
		qr/both named ''/, 'quantile: NA and NaN together share "" and croak');
	# h was (n-1)p, so a tiny p interpolated; R's 1 + (n-1)p rounds back to 1.
	# On a double NV 1 + 9e-17 rounds to 1 and the answer is exactly R's 1; a
	# wider NV keeps the 9e-17 and interpolates by it, 1.00000000000000009.
	my @v = values %{ quantile([1 .. 10], probs => [1e-17]) };
	if ($Config{nvtype} eq 'double') { is($v[0], 1, 'quantile: p = 1e-17 is x[1] exactly, as R') }
	else { near($v[0], 1, 'quantile: p = 1e-17 is x[1] to the NV\'s rounding') }
	is_deeply([ keys %{ quantile([1 .. 10], probs => [1e-17]) } ], [ '0.000000000000001%' ],
		'quantile: ... named as R names it');
}
{
	# x and probs were freed by hand, so a FETCH that died leaked both.  The
	# SV side is checked here; the malloc() side by resident size below.
	my @x = (1 .. 50);
	tie my @tx, 'DieAt', \@x, 25;
	tie my @tp, 'DieAt', [0.1, 0.5, 0.9], 1;
	dies_like(sub { quantile(\@tx) }, qr/^FETCH 25/, 'quantile: a dying FETCH on x propagates');
	dies_like(sub { quantile([1 .. 5], probs => \@tp) }, qr/^FETCH 1/, 'quantile: and on probs');
	no_leaks_ok { eval { quantile(\@tx) } } 'quantile: no SV leak when x\'s FETCH dies';
	no_leaks_ok { eval { quantile([1 .. 5], probs => \@tp) } } 'quantile: nor when probs\'s FETCH dies';
	no_leaks_ok { eval { quantile([1 .. 10], probs => [0.99999999, 1]) } } 'quantile: nor on the name collision croak';
	no_leaks_ok { eval { quantile([1 .. 10], probs => { a => 1 }) } } 'quantile: nor on a bad probs';
	no_leaks_ok { quantile([1 .. 10], probs => [undef, 0.5, 0.25]) } 'quantile: nor with an undef prob';
	SKIP: {
		skip 'no /proc/self/statm to read the resident size from', 1 unless -r '/proc/self/statm';
		my $rss = sub { open my $f, '<', '/proc/self/statm' or return 0; my @f = split ' ', scalar <$f>; return $f[1] };
		# 2e5 values is a 1.6 MB buffer per call on a double build; 60 calls
		# lost 96 MB before 0.331.  Measured since: no growth at all after
		# the warm-up.  32 MB allows for allocator noise and a __float128 NV.
		my @big = map { $_ / 7 } 1 .. 200_000;
		tie my @tb, 'DieAt', \@big, 199_999;
		eval { quantile(\@tb) } for 1 .. 5;	# warm-up: let the allocator settle
		my $before = $rss->();
		eval { quantile(\@tb) } for 1 .. 60;
		my $grown_mb = ($rss->() - $before) * 4096 / 2**20;
		cmp_ok($grown_mb, '<', 32, sprintf('quantile: 60 dying FETCHes on a 2e5 column grow RSS by %.1f MB, not ~96', $grown_mb));
	}
}

# ---- p_adjust ---------------------------------------------------------------
{
	# A NaN made cmp_pval inconsistent, qsort scrambled the order, and the
	# NaNs counted in n: holm gave 0.06 0.06 0.12 0.12 0.12 0.12.
	my @h = p_adjust([0.01, $NaN, 0.04, 0.03, $NaN, 0.02], 'holm');
	near($h[0], 0.040000000000000001, 'p_adjust holm: [0] is R\'s');
	ok(is_nan($h[1]), 'p_adjust holm: [1] stays NaN');
	near($h[$_], 0.059999999999999998, "p_adjust holm: [$_] is R's") for 2, 3, 5;
	ok(is_nan($h[4]), 'p_adjust holm: [4] stays NaN');
	# The same in a frame, which shares the kernel.
	my $f = p_adjust([ { p => 0.01 }, { p => $NaN }, { p => 0.04 } ], 'bonferroni', columns => 'p');
	near($f->[0]{p}, 0.02, 'p_adjust frame: NaN is out of n');
	ok(is_nan($f->[1]{p}), 'p_adjust frame: and back in its place');
	near($f->[2]{p}, 0.08, 'p_adjust frame: n = 2');
	# undef is not NA: README documents it as a p-value of 1, in the family.
	my @u = p_adjust([0.01, undef, 0.04], 'bonferroni');
	is_deeply([ map { sprintf '%.4f', $_ } @u ], [ '0.0300', '1.0000', '0.1200' ],
		'p_adjust: undef still counts as 1, as documented');
	no_leaks_ok { my @r = p_adjust([0.01, $NaN, 0.04], 'hommel') } 'p_adjust: no leak with NaN in the family';
}

# ---- scale ------------------------------------------------------------------
{
	# A ragged row was padded with 0 (or cut short); a non-array row read as
	# zeros.  Both croak now.
	dies_like(sub { scale([[1, 2], [3], [5, 7]]) },
		qr/^scale: row 1 has 1 values where row 0 has 2/, 'scale: a short row croaks');
	dies_like(sub { scale([[1, 2], [3, 4, 9], [5, 7]]) },
		qr/^scale: row 1 has 3 values where row 0 has 2/, 'scale: a long row croaks');
	dies_like(sub { scale([[1, 2], 'x', [5, 7]]) },
		qr/^scale: row 1 of the matrix is not an array reference/, 'scale: a string row croaks');
	dies_like(sub { scale([[1, 2], [3, 'abc'], [5, 7]]) },
		qr/^scale: non-numeric value at row 1, column 1/, 'scale: a non-numeric cell croaks');
	# center/scale vectors were read as "true"; now R's per-column numbers.
	dies_like(sub { scale([[1, 2], [3, 4]], center => [1, 2, 3]) },
		qr/^scale: length of 'center' \(3\) must equal the number of columns of 'x' \(2\)/,
		'scale: a center vector of the wrong length croaks, as R');
	dies_like(sub { scale([[1, 2], [3, 4]], scale => [1]) },
		qr/^scale: length of 'scale' \(1\)/, 'scale: so does a scale vector');
	dies_like(sub { scale([[1, 2], [3, 4]], center => [1, 'x']) },
		qr/^scale: 'center' at index 1 is not a number/, 'scale: a non-numeric center element croaks');
	dies_like(sub { scale(1, 2, 3, center => [1, 2]) },
		qr/length of 'center' \(2\) must equal the number of columns of 'x' \(1\)/,
		'scale: a flat list is one column');
	# undef in place, both modes; the matrix used to read it as 0 and the flat
	# list to drop it.
	my @s = scale(1, undef, 3, 6);
	is(scalar @s, 4, 'scale: an undef keeps its place in a flat list');
	ok(!defined $s[1], 'scale: ... as undef');
	my $m = scale([[1, 2], [undef, 4], [5, 7]]);
	ok(!defined $m->[1][0], 'scale: an undef matrix cell stays undef');
	near($m->[0][0], -0.70710678118654746, 'scale: and the column is scaled over the rest, as R');
	# A one-row matrix croaked after building its output rows: 3 SVs a call.
	dies_like(sub { scale([[1, 2, 3]]) }, qr/scale needs >= 2 rows/, 'scale: one row still croaks');
	no_leaks_ok { eval { scale([[1, 2, 3]]) } } 'scale: ... without leaking the rows it had built';
	no_leaks_ok { eval { scale([[1, 2], [3]]) } } 'scale: no leak on the ragged-row croak';
	no_leaks_ok { eval { scale([[1, 2], [3, 4]], center => [1]) } } 'scale: nor on a wrong-length vector';
	no_leaks_ok { my @r = scale([[1, 2], [undef, 4], [5, 7]], center => [1, 2], scale => [2, 3]) }
		'scale: nor on the vector path';
}

# ---- prcomp -----------------------------------------------------------------
{
	# center => 0, scale => 1 divided by the sd about the mean; R's
	# scale(center = FALSE) divides by sqrt(sum(x^2)/(n-1)).
	my $p = prcomp([[1, 2], [3, 5], [4, 4], [7, 9]], center => 0, scale => 1);
	near($p->{scale}[0], 5, 'prcomp center => 0: scale[0] is R\'s 5, not 2.5');
	near($p->{scale}[1], 6.4807406984078604, 'prcomp center => 0: scale[1]');
	ok(abs($p->{sdev}[0] / 1.4098019150779262 - 1) < 1e-13, 'prcomp center => 0: sdev[0] is R\'s');
	ok(abs($p->{sdev}[1] / 0.11161792079505777 - 1) < 1e-13, 'prcomp center => 0: sdev[1] is R\'s');
	# rank and tol cut sdev too; R keeps every one.
	$p = prcomp([[1, 2], [3, 5], [4, 4], [7, 9]], rank => 1);
	is(scalar @{ $p->{sdev} }, 2, 'prcomp rank => 1: sdev keeps both');
	is(scalar @{ $p->{rotation}[0] }, 1, 'prcomp rank => 1: rotation has 1 column');
	# sdev from X'X floored a null direction near 1e-8; R's SVD gives ~6e-18.
	$p = prcomp([[1, 2, 3], [2, 4, 6.5], [3, 6, 9], [4, 8, 12.25]]);
	ok(abs($p->{sdev}[1] / 0.14087162401373760 - 1) < 1e-13, 'prcomp: the small sdev is R\'s to 1e-13 (was 6e-14 out)');
	cmp_ok($p->{sdev}[2], '<', 1e-14 * $p->{sdev}[0], 'prcomp: the null direction is at rounding level, as R\'s');
	no_leaks_ok { prcomp([[1, 2, 3], [2, 4, 6.5], [3, 6, 9], [4, 8, 12.25]], center => 0, scale => 1, rank => 2) }
		'prcomp: no leak through the SVD path';
}

done_testing();
