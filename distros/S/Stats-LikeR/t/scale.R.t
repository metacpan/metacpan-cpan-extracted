#!/usr/bin/env perl
#
# Cross-validation of scale() against R's base::scale().
#
# Provenance: R 4.6.1 scale.default (src/library/base/R/scale.R), run by
# t/scale.R.R, which is committed next to this file and prints the table below
# at options(digits = 17); re-run it to regenerate the table.  The test never
# calls R.  The cases are scale.Rd's own example matrix(1:10, ncol = 2), and
# small matrices built to reach every branch of scale.default:
#
#   * a numeric vector for center and/or scale, one value per column.  0.33 read
#     an array ref as "true", so center => [1, 2, -1] centred on the means;
#   * a numeric center with scale = TRUE, which divides by sqrt(sum(x^2)/(n-1))
#     of the centred column -- the sd only when the center is the mean;
#   * center = FALSE, which divides by the root mean square about 0;
#   * NA cells (undef here), which R keeps in place while taking the column's
#     mean and scale over the rest (colMeans(na.rm = TRUE), v[!is.na(v)]).  0.33
#     read an undef cell as 0 in a matrix, and dropped it from a flat list,
#     returning fewer values than it was given;
#   * a column with one non-NA value, which R scales by sqrt(v^2 / max(1, 0));
#   * a 0 in a scale vector, which R divides by: Inf, -Inf, or NaN for 0/0.
#
# The inputs are dyadic or small integers, so every perl reads the same matrix
# R did.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR 'scale';

# Measured worst disagreement with R on a double build: 0, every value R's to
# the bit.  The bound is not 0 because R adds the column sums in long double
# where this build compensates them in the NV (nv_two_sum), and the two can
# part in the mean's last bit on other data; a centred value near 0 then
# inherits that bit as a large relative error, which is why the bound is
# absolute below |want| = 1.  4e-15 is about 20 ulp at 1, room for that and
# for the long-double and __float128 builds, whose arithmetic is wider.
my $TOL = 4e-15;

my $m1  = [ [ 1, 2, -1.5 ], [ 3, 4, 0.25 ], [ 5, 7, 8 ] ];
my $mna = [ [ 1, 2, undef ], [ undef, 4, 0.5 ], [ 5, 7, undef ], [ 9, undef, undef ] ];
my $rd  = [ [ 1, 6 ], [ 2, 7 ], [ 3, 8 ], [ 4, 9 ], [ 5, 10 ] ];	# matrix(1:10, ncol = 2)
sub flat { return [ map { [ $_ ] } @_ ] }	# a flat result as R's one-column matrix

my %CALL = (
	rd_noscale       => sub { scale($rd, scale => 0) },
	rd_default       => sub { scale($rd) },
	m1_default       => sub { scale($m1) },
	m1_cvec_svec     => sub { scale($m1, center => [ 1, 2, -1 ], scale => [ 2, 0.5, 4 ]) },
	m1_cvec          => sub { scale($m1, center => [ 1, 2, -1 ]) },
	m1_nocenter      => sub { scale($m1, center => 0) },
	m1_nocenter_svec => sub { scale($m1, center => 0, scale => [ 2, 0.5, 4 ]) },
	m1_svec          => sub { scale($m1, { scale => [ 2, 0.5, 4 ] }) },
	m1_cvec_noscale  => sub { scale($m1, { center => [ 1, 2, -1 ], scale => 'none' }) },
	m1_svec_zero     => sub { scale($m1, center => [ 3, 4, 1 ], scale => [ 0, 1, 0 ]) },
	mna_default      => sub { scale($mna) },
	mna_nocenter     => sub { scale($mna, center => 0) },
	mna_cvec         => sub { scale($mna, center => [ 1, 2, 3 ]) },
	flat_na          => sub { flat(scale(1, undef, 3, 6)) },
	flat_cvec        => sub { flat(scale(1 .. 5, center => 2)) },
	flat_svec        => sub { flat(scale([ 1 .. 5 ], center => [2], scale => [4])) },
);

# label => R's result, row by row: undef for NA, 'NaN' and 'Inf' as R prints them
my @R = (
	[ 'rd_noscale', [ [ -2, -2 ], [ -1, -1 ], [ 0, 0 ], [ 1, 1 ], [ 2, 2 ] ] ],
	[ 'rd_default', [ [ -1.2649110640673518, -1.2649110640673518 ], [ -0.63245553203367588, -0.63245553203367588 ], [ 0, 0 ], [ 0.63245553203367588, 0.63245553203367588 ], [ 1.2649110640673518, 1.2649110640673518 ] ] ],
	[ 'm1_default', [ [ -1, -0.92717264994553061, -0.74170226465122313 ], [ 0, -0.13245323570650427, -0.39557454114731899 ], [ 1, 1.0596258856520353, 1.1372768057985421 ] ] ],
	[ 'm1_cvec_svec', [ [ 0, 0, -0.125 ], [ 1, 4, 0.3125 ], [ 2, 10, 2.25 ] ] ],
	[ 'm1_cvec', [ [ 0, 0, -0.077702868988581128 ], [ 0.63245553203367588, 0.52522573143889018, 0.19425717247145283 ], [ 1.2649110640673518, 1.3130643285972254, 1.3986516417944603 ] ] ],
	[ 'm1_nocenter', [ [ 0.23904572186687872, 0.34050261230349943, -0.26050049703180445 ], [ 0.71713716560063612, 0.68100522460699886, 0.043416749505300743 ], [ 1.1952286093343936, 1.1917591430622481, 1.3893359841696238 ] ] ],
	[ 'm1_nocenter_svec', [ [ 0.5, 4, -0.375 ], [ 1.5, 8, 0.0625 ], [ 2.5, 14, 2 ] ] ],
	[ 'm1_svec', [ [ -1, -4.6666666666666661, -0.9375 ], [ 0, -0.66666666666666607, -0.5 ], [ 1, 5.3333333333333339, 1.4375 ] ] ],
	[ 'm1_cvec_noscale', [ [ 0, 0, -0.5 ], [ 2, 2, 1.25 ], [ 4, 5, 9 ] ] ],
	[ 'm1_svec_zero', [ [ '-Inf', -2, '-Inf' ], [ 'NaN', 0, '-Inf' ], [ 'Inf', 3, 'Inf' ] ] ],
	[ 'mna_default', [ [ -1, -0.92717264994553061, undef ], [ undef, -0.13245323570650427, 'NaN' ], [ 0, 1.0596258856520353, undef ], [ 1, undef, undef ] ] ],
	[ 'mna_nocenter', [ [ 0.13671718540493266, 0.34050261230349943, undef ], [ undef, 0.68100522460699886, 1 ], [ 0.68358592702466325, 1.1917591430622481, undef ], [ 1.2304546686443938, undef, undef ] ] ],
	[ 'mna_cvec', [ [ 0, 0, undef ], [ undef, 0.52522573143889018, -1 ], [ 0.63245553203367588, 1.3130643285972254, undef ], [ 1.2649110640673518, undef, undef ] ] ],
	[ 'flat_na', [ [ -0.92717264994553061 ], [ undef ], [ -0.13245323570650441 ], [ 1.0596258856520349 ] ] ],
	[ 'flat_cvec', [ [ -0.5163977794943222 ], [ 0 ], [ 0.5163977794943222 ], [ 1.0327955589886444 ], [ 1.5491933384829668 ] ] ],
	[ 'flat_svec', [ [ -0.25 ], [ 0 ], [ 0.25 ], [ 0.5 ], [ 0.75 ] ] ],
);

my $worst = 0;
for my $c (@R) {
	my ($label, $want) = @$c;
	my $got = $CALL{$label}->();
	my ($bad, $where) = (0, '');
	for my $r (0 .. $#$want) {
		for my $j (0 .. $#{ $want->[$r] }) {
			my ($w, $g) = ($want->[$r][$j], $got->[$r][$j]);
			my $ok;
			if    (!defined $w)  { $ok = !defined $g }
			elsif ($w eq 'NaN')  { $ok = defined $g && $g != $g }
			elsif ($w eq 'Inf')  { $ok = defined $g && $g == 9**9**9 }
			elsif ($w eq '-Inf') { $ok = defined $g && $g == -9**9**9 }
			else {
				my $e = defined $g ? abs($g - $w) / (abs($w) > 1 ? abs($w) : 1) : 9**9**9;
				$worst = $e if $e > $worst;
				$ok = $e <= $TOL;
			}
			next if $ok;
			$bad++;
			$where ||= "[$r][$j]: got " . (defined $g ? $g : 'undef') . ', want ' . (defined $w ? $w : 'undef');
		}
	}
	is(scalar @$got, scalar @$want, "$label: one row per input row");
	is($bad, 0, "$label: matches R's scale()" . ($bad ? " -- $where" : ''));
}
diag(sprintf 'worst error vs R: %.3g', $worst);

# The same call in its three spellings: trailing pairs, a trailing hashref,
# and the data as one array ref rather than a list.
is_deeply([ scale(1, undef, 3, 6) ], [ scale([ 1, undef, 3, 6 ]) ], 'flat list and array ref agree, undef in place');
is_deeply(scale($m1, center => [ 1, 2, -1 ]), scale($m1, { center => [ 1, 2, -1 ] }),
	'a center vector reads the same as a pair and in a hashref');

done_testing();
