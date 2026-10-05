#!/usr/bin/env perl
# The critical value every Wald confidence limit in Stats::LikeR is built from,
# cross-validated against R and SciPy and then traced through the functions
# that use it.
#
# PROVENANCE
#
# Block 1 pins z with P(-z < Z < z) = conf_level against two references:
#
#   R 4.6.1  qnorm(1 - (1 - cl)/2), printed at options(digits=17) by
#            Rscript -e 'options(digits=17);
#                        for (cl in c(0.80,0.90,0.95,0.99,0.999,0.9999))
#                          cat(sprintf("%.17g\n", qnorm(1-(1-cl)/2)))'
#            R's own qnorm is Wichura's AS 241 (src/nmath/qnorm.c), documented
#            in src/library/stats/man/Normal.Rd.
#   SciPy 1.18.0 / NumPy 2.5.2  scipy.stats.norm.ppf(1 - (1 - cl)/2), which is
#            Cephes ndtri under scipy/special.  SciPy's own suite tests norm.ppf
#            only through round-trips and through the R-generated corpora in
#            scipy/stats/tests/data/, so these values are taken from the
#            function itself rather than from a test file; the arbiter below is
#            what makes that safe.  Both reference columns are also listed in
#            t/std_qnorm.mpmath.py, which is what scores them.
#
# The two references disagree in the last one or two digits, so neither can be
# the expected value on its own.  t/std_qnorm.mpmath.py is the arbiter: it
# bisects the defining equation erfc(-z/sqrt(2))/2 = p at mp.dps = 60 -- not a
# third library inverse, per CLAUDE.md -- at the *exact double* the C
# expression 1 - (1 - conf_level)/2 forms, and scores all three.  Its verdict,
# as worst relative error over these six conf_levels:
#
#   Moro alone, i.e. Stats::LikeR <= 0.302   1.769e-9   (7968628 ulp)
#   R 4.6.1 qnorm                            4.768e-16  (2.1 ulp)
#   SciPy 1.18.0 norm.ppf                    1.510e-16  (0.7 ulp)
#   Stats::LikeR 0.303                       8.198e-17  (0.4 ulp)
#
# So the expected values frozen below are Stats::LikeR's own, which the arbiter
# finds closer to the truth than either reference, and the references are
# checked against them at a tolerance that reflects the references' error and
# not this module's.  All three columns are the exact doubles those projects
# hold, written dyadically, so the comparison is between the numbers and not
# between two decimal parsers.  Re-run the arbiter with:
#
#   python3 t/std_qnorm.mpmath.py
#
# Nothing here calls it, or R, or python.
#
# Block 2 has no reference equivalent: it is the property that made 0.303 a
# change rather than a rename.  Through 0.302 nine call sites built their own
# critical value by calling inverse_normal_cdf() -- Moro's rational
# approximation -- while qnorm() went through the Newton-polished
# normal_quantile_hp(), so which function you asked decided how many digits you
# got.  All of them now call std_qnorm().  Block 2 recovers the critical value
# back out of each function's *reported* interval and checks it is the one
# qnorm() returns, which is a statement about this module's internal
# consistency that no reference implementation can make for it.
#
# WHY DYADIC LITERALS
#
# Every number in the frozen table is written as the exact ratio M / 2^K.
# perl 5.10.1's atof does not always round a decimal to the nearest double, and
# a critical value is compared here to within a few ulp, so the table cannot
# afford to be re-parsed approximately.  See t/distributions.R.scipy.t, which
# freezes its corpus the same way and for the same reason.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use lib 'blib/lib', 'blib/arch';
use Stats::LikeR qw(qnorm glm cor_test coxph roc survfit epi_2x2 prop_test);

# ---- helpers --------------------------------------------------------------

{
	my $eps;
	# The build's NV_EPSILON, found rather than assumed, so a long-double or
	# __float128 perl scales its own tolerances.
	sub NV_EPS {
		return $eps if defined $eps;
		$eps = 1;
		$eps /= 2 while 1 + $eps / 2 != 1;
		return $eps;
	}
}

# dyad('5771595153042739/2^52'): rebuild M / 2^K exactly, by repeated division
# rather than by 2 ** -$k, so no intermediate can overflow or lose a bit.
sub dyad {
	my ($s) = @_;
	my ($m, $k) = $s =~ m{\A(-?[0-9]+)/2\^([0-9]+)\z}
		or die "dyad: cannot parse '$s'";
	my $v = 0 + $m;
	$v /= 2 for 1 .. $k;
	return $v;
}

my %WORST;
# rel_ok($got, $want, $tol, $block, $name): relative agreement, tracking the
# worst disagreement per block so the diag at the end says how much of each
# tolerance was actually used.
sub rel_ok {
	my ($got, $want, $tol, $block, $name) = @_;
	my $rel = $want == 0 ? abs($got) : abs( $got - $want ) / abs($want);
	$WORST{$block} = $rel
		if !defined $WORST{$block} || $rel > $WORST{$block};
	my $ok = ok( $rel <= $tol, $name );
	diag sprintf "  got  %.17g\n  want %.17g\n  rel  %.3g > tol %.3g",
		$got, $want, $rel, $tol
		unless $ok;
	return $ok;
}

# ---- the frozen table ------------------------------------------------------
#
# conf_level, then z, then what inverse_normal_cdf() alone returns for the same
# p -- kept so this file can assert that 0.303 moved the answer, and by how
# much.  All three as exact doubles; the R and SciPy columns are the decimals
# those projects print, which is all the precision they offer.
# p is frozen as well as conf_level, and block 1 asks qnorm for that p rather
# than for 1 - (1 - conf_level)/2.  The reason is not pedantry: at conf_level
# 0.999 the subtraction 1 - 0.0005 has to round, and it rounds to a different
# number in double than in long double.  Both builds then answer correctly, for
# questions 5e-20 apart -- but the normal density at that quantile is 0.00175,
# so 5e-20 in p is 3e-17 in z, and the two builds' answers differ by 9.5e-15
# relative while both are right.  Freezing p makes every build answer the same
# question, which is the only way a shared literal can be an expected value.
my @CRIT = (
	# conf_level             p = 1 - (1 - cl)/2       z (Stats::LikeR)         Moro alone (<= 0.302)    R 4.6.1 qnorm            SciPy 1.18.0 norm.ppf
	[ '3602879701896397/2^52', '8106479329266893/2^53', '5771595153042739/2^52', '5771595142830531/2^52', '1442898788260685/2^50', '2885797576521369/2^51' ],
	[ '8106479329266893/2^53', '4278419646001971/2^52', '7407762181417659/2^52', '7407762181623911/2^52', '925970272677207/2^49',  '7407762181417659/2^52' ],
	[ '4278419646001971/2^52', '8782019273372467/2^53', '8826893070434179/2^52', '8826893070338885/2^52', '4413446535217089/2^51', '2206723267608545/2^50' ],
	[ '4458563631096791/2^52', '8962163258467287/2^53', '181257873306763/2^46',  '5800251945821607/2^51', '5800251945816415/2^51', '181257873306763/2^46'  ],
	[ '8998192055486251/2^53', '4501347827556811/2^52', '3704803740449923/2^50', '3704803740569041/2^50', '3704803740449923/2^50', '3704803740449923/2^50' ],
	[ '4503149267407759/2^52', '9006748894778255/2^53', '4380417042475201/2^50', '8760834084523859/2^51', '8760834084950401/2^51', '4380417042475201/2^50' ],
);

# ---- block 1: the value itself --------------------------------------------

# 1e-15 = 4.5 double ulp.  The frozen z is the double this build's own
# std_qnorm() returns, and the arbiter puts it 0.4 ulp from the 60-digit truth;
# a long-double or __float128 build is more accurate still and so lands within
# half a double ulp of the same literal.  The tolerance cannot scale with
# NV_EPSILON, because the reference it is compared against is a double no
# matter how wide this perl's NV is.
my $CRIT_TOL = 1e-15;

# 1e-15 = 4.5 double ulp.  The worst disagreement between a reference column
# and the frozen z is 4.05e-16, R's at conf_level 0.9; both sides are exact
# doubles rebuilt by dyad(), so that figure is not an artefact of parsing and
# does not move with NV width either.  2.5x headroom, which is enough to
# survive a reference's own last-digit change and still catch a regression in
# this module of more than a couple of ulp.
my $REF_TOL = 1e-15;

for my $row (@CRIT) {
	my ( $cl_d, $p_d, $z_d, $moro_d, $r_d, $scipy_d ) = @$row;
	my $cl = dyad($cl_d);
	my $p  = dyad($p_d);
	my $z  = dyad($z_d);

	rel_ok( qnorm($p), $z, $CRIT_TOL, 'qnorm',
		sprintf 'qnorm at the %.17g critical point is the frozen value', $cl );
	rel_ok( dyad($r_d), $z, $REF_TOL, 'R qnorm',
		sprintf "and R 4.6.1's qnorm agrees at conf_level %.17g", $cl );
	rel_ok( dyad($scipy_d), $z, $REF_TOL, 'SciPy norm.ppf',
		sprintf "and SciPy 1.18.0's norm.ppf agrees at conf_level %.17g", $cl );

	# The point of the change: Moro's own answer is nowhere near this
	# tolerance, so block 2 below is testing new behaviour and not a rename.
	my $moro = dyad($moro_d);
	my $moro_rel = abs( $moro - $z ) / $z;
	ok( $moro_rel > 1e-13,
		sprintf 'inverse_normal_cdf() alone is %.3g off, far outside %.3g',
			$moro_rel, $CRIT_TOL );

	# qnorm's two spellings of the same critical value.  prop_test forms
	# (1 + conf_level)/2 where the other eight sites form
	# 1 - (1 - conf_level)/2, and block 2 compares prop_test against the same
	# expected z as the rest, which is only allowed if the two agree.  Both
	# sides are computed by this build -- comparing either against the frozen
	# double would be the mistake the note above @CRIT describes -- and it is
	# rel_ok rather than is() because on a double build both spellings round
	# and there is no reason they must round the same way.
	rel_ok( qnorm( ( 1 + $cl ) / 2 ), qnorm( 1 - ( 1 - $cl ) / 2 ),
		$CRIT_TOL, 'qnorm spellings',
		sprintf '(1 + cl)/2 and 1 - (1 - cl)/2 agree at conf_level %.17g',
			$cl );

	# Symmetry, which is what makes a two-sided interval two-sided -- and the
	# reflection std_qnorm() performs internally, checked from outside.  The
	# tail probability is 1 - $p and not (1 - $cl)/2 on purpose: for $p >= 0.5
	# Sterbenz's lemma makes 1 - $p exact, so this compares the function at two
	# points that really are each other's mirror.  (1 - $cl)/2 would not be:
	# at conf_level 0.9999 it and 1 - (1 - (1 - $cl)/2) differ by 2e-12
	# relative, because 1 - 0.99995 cancels where 1 - 0.99995... does not, and
	# the test would be measuring that rounding instead of this module.
	rel_ok( -qnorm( 1 - $p ), $z, $CRIT_TOL, 'qnorm',
		sprintf 'and -qnorm(1 - p) is the same value at conf_level %.17g',
			$cl );
}

# ---- block 2: the same value, recovered from each function's interval ------
#
# Tolerances, in ulp of the build's NV, against the worst disagreement measured
# on the default double build (5.44.0):
#
#   recovery                     measured   tolerance
#   glm conf_int                  0.8 ulp    32 ulp
#   coxph conf_int                3.6 ulp    32 ulp
#   roc auc_ci                    1.6 ulp    32 ulp
#   epi_2x2 odds_ratio_ci         1.0 ulp    32 ulp
#   epi_2x2 risk_diff_ci          0.5 ulp    32 ulp
#   prop_test conf_int            0.5 ulp    32 ulp
#   survfit lower/upper           1.6 ulp    32 ulp
#   cor_test conf_int            11.8 ulp   128 ulp
#
# 32 ulp is ~9x headroom over the worst of the direct est +/- z*se recoveries.
# cor_test gets its own because its interval is tanh(atanh(r) +/- q*se): the
# recovery has to undo the tanh, and atanh is ill-conditioned as |r| approaches
# 1, so it spends an order of magnitude more of its input's precision than the
# others.  Both scale with NV_EPSILON because nothing frozen is involved --
# both sides of every comparison are computed by this build.
my $CI_TOL   = 32 * NV_EPS();
my $ATANH_TOL = 128 * NV_EPS();

my @LEVELS = map { dyad( $_->[0] ) } @CRIT;

# glm: conf_int is estimate +/- z * `Std. Error`, and both are reported.
{
	my %d = (
		y => [ 0, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1 ],
		x => [ 1 .. 20 ],
	);
	for my $cl (@LEVELS) {
		my $m = glm( data => \%d, formula => 'y ~ x', family => 'binomial',
			'conf_level' => $cl );
		my $se = $m->{summary}{x}{'Std. Error'};
		my $ci = $m->{'conf_int'}{x};
		rel_ok( ( $ci->[1] - $ci->[0] ) / ( 2 * $se ),
			qnorm( 1 - ( 1 - $cl ) / 2 ), $CI_TOL, 'glm',
			sprintf 'glm conf_int implies qnorm at conf_level %.17g', $cl );
	}
}

# cor_test: conf_int is tanh(atanh(r) +/- q / sqrt(n - 3)), so the recovery
# undoes the tanh.  atanh by hand: 5.10 has no Math::Trig import here.
{
	my @x = ( 1 .. 10 );
	my @y = ( 2, 1, 4, 3, 6, 5, 8, 7, 10, 9 );
	my $atanh = sub { 0.5 * log( ( 1 + $_[0] ) / ( 1 - $_[0] ) ) };
	my $se = 1 / sqrt( @x - 3 );
	for my $cl (@LEVELS) {
		my $c  = cor_test( \@x, \@y, 'conf_level' => $cl );
		my $ci = $c->{'conf_int'};
		rel_ok( ( $atanh->( $ci->[1] ) - $atanh->( $ci->[0] ) ) / ( 2 * $se ),
			qnorm( 1 - ( 1 - $cl ) / 2 ), $ATANH_TOL, 'cor_test',
			sprintf 'cor_test conf_int implies qnorm at conf_level %.17g', $cl );
	}
}

# coxph: conf_int is on the hazard ratio, exp(coef +/- z * se), so the recovery
# takes logs.  Both covariates, because the critical value is shared and a
# per-coefficient mistake would show on only one.
{
	my @time   = ( 6, 7, 10, 15, 19, 25, 4, 6, 11, 14, 20, 24 );
	my @status = ( 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1 );
	my @trt    = ( 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1 );
	my @age    = ( 55, 60, 45, 50, 65, 58, 62, 49, 53, 66, 57, 61 );
	for my $cl (@LEVELS) {
		my $cx = coxph( \@time, \@status, [ \@trt, \@age ],
			conf_level => $cl, names => [ 'trt', 'age' ] );
		for my $k ( 0, 1 ) {
			my ( $lo, $hi ) = @{ $cx->{'conf_int'}[$k] };
			rel_ok( ( log($hi) - log($lo) ) / ( 2 * $cx->{se}[$k] ),
				qnorm( 1 - ( 1 - $cl ) / 2 ), $CI_TOL, 'coxph',
				sprintf 'coxph conf_int[%s] implies qnorm at conf_level %.17g',
					$cx->{names}[$k], $cl );
		}
	}
}

# roc: auc_ci is auc +/- z * auc_se, clamped into [0, 1].  40 observations and
# an AUC near 0.5 keep the upper limit inside 1 even at conf_level 0.9999, so
# the recovery is never reading a clamp instead of a critical value.
{
	my @score = map { $_ / 40 } 1 .. 40;
	my @label = map { ( $_ % 3 == 0 ) ? 1 : 0 } 1 .. 40;
	for my $cl (@LEVELS) {
		my $r = roc( \@score, \@label, conf_level => $cl );
		my ( $lo, $hi ) = @{ $r->{'auc_ci'} };
		# Guard the guard: if this ever clamps, say so instead of silently
		# testing the clamp.
		cmp_ok( $hi, '<', 1,
			sprintf 'roc auc_ci is unclamped at conf_level %.17g', $cl );
		rel_ok( ( $hi - $lo ) / ( 2 * $r->{'auc_se'} ),
			qnorm( 1 - ( 1 - $cl ) / 2 ), $CI_TOL, 'roc',
			sprintf 'roc auc_ci implies qnorm at conf_level %.17g', $cl );
	}
}

# epi_2x2: two different recoveries out of one call.  odds_ratio_ci is
# multiplicative, or * exp(+/- z * sqrt(1/a + 1/b + 1/c + 1/d)), and
# risk_diff_ci is additive; the shared critical value has to come back out of
# both.  No zero cell, so no Haldane-Anscombe shift -- asserted, because the
# variance below is computed from the raw counts.
{
	my ( $a, $b, $c, $d ) = ( 36, 14, 30, 25 );
	my ( $n1, $n0 ) = ( $a + $b, $c + $d );
	my ( $p1, $p0 ) = ( $a / $n1, $c / $n0 );
	my $se_lor = sqrt( 1 / $a + 1 / $b + 1 / $c + 1 / $d );
	my $se_rd  = sqrt( $p1 * ( 1 - $p1 ) / $n1 + $p0 * ( 1 - $p0 ) / $n0 );
	for my $cl (@LEVELS) {
		my $e = epi_2x2( $a, $b, $c, $d, conf_level => $cl );
		is( $e->{correction}, 0, 'epi_2x2 applied no continuity correction' );
		my ( $olo, $ohi ) = @{ $e->{'odds_ratio_ci'} };
		rel_ok( ( log($ohi) - log($olo) ) / ( 2 * $se_lor ),
			qnorm( 1 - ( 1 - $cl ) / 2 ), $CI_TOL, 'epi_2x2',
			sprintf 'epi_2x2 odds_ratio_ci implies qnorm at conf_level %.17g',
				$cl );
		my ( $dlo, $dhi ) = @{ $e->{'risk_diff_ci'} };
		rel_ok( ( $dhi - $dlo ) / ( 2 * $se_rd ),
			qnorm( 1 - ( 1 - $cl ) / 2 ), $CI_TOL, 'epi_2x2',
			sprintf 'epi_2x2 risk_diff_ci implies qnorm at conf_level %.17g',
				$cl );
	}
}

# prop_test: correct => 0, because the Yates term is added to the half-width
# and would be indistinguishable from the critical value here.  This is the one
# site that spells its argument (1 + conf_level)/2; block 1 checked that
# spelling gives the same double.
{
	my @x = ( 36, 30 );
	my @n = ( 50, 55 );
	for my $cl (@LEVELS) {
		my $pt = prop_test( \@x, \@n, correct => 0, conf_level => $cl );
		my @est = @{ $pt->{estimate} };
		my $se  = sqrt( $est[0] * ( 1 - $est[0] ) / $n[0]
		              + $est[1] * ( 1 - $est[1] ) / $n[1] );
		my ( $lo, $hi ) = @{ $pt->{'conf_int'} };
		cmp_ok( $hi, '<', 1,
			sprintf 'prop_test conf_int is unclamped at conf_level %.17g', $cl );
		rel_ok( ( $hi - $lo ) / ( 2 * $se ), qnorm( ( 1 + $cl ) / 2 ),
			$CI_TOL, 'prop_test',
			sprintf 'prop_test conf_int implies qnorm at conf_level %.17g',
				$cl );
	}
}

# survfit: lower/upper are S * exp(-/+ z * sqrt(vterm)) on the log scale, and
# std_err is S * sqrt(vterm), so sqrt(vterm) is std_err/S.  Only the risk-set
# points where the upper limit is inside 1 and the survival is still positive
# can say anything; the count is asserted so this cannot quietly test nothing.
{
	my @time = ( 6, 7, 10, 15, 19, 25, 4, 6, 11, 14, 20, 24,
	             8, 9, 17, 22, 5, 13 );
	my @status = ( 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1 );
	for my $cl (@LEVELS) {
		my $sf = survfit( \@time, \@status, conf_level => $cl );
		my ($stratum) = keys %{ $sf->{strata} };
		my $s = $sf->{strata}{$stratum};
		my $checked = 0;
		for my $i ( 0 .. $#{ $s->{surv} } ) {
			next unless $s->{surv}[$i] > 0
				&& $s->{upper}[$i] < 1
				&& $s->{lower}[$i] > 0;
			my $sq = $s->{'std_err'}[$i] / $s->{surv}[$i];
			next unless $sq > 0;
			$checked++;
			rel_ok(
				( log( $s->{upper}[$i] ) - log( $s->{lower}[$i] ) )
					/ ( 2 * $sq ),
				qnorm( 1 - ( 1 - $cl ) / 2 ), $CI_TOL, 'survfit',
				sprintf 'survfit t = %s implies qnorm at conf_level %.17g',
					$s->{time}[$i], $cl );
		}
		# At conf_level 0.9999 the log-scale upper limit clears 1 at every
		# risk-set point on this curve (0.585 * exp(3.89 * 0.38) is about 2.5,
		# so nothing is borderline at any NV width) and the clamp leaves
		# nothing to recover.  Asserting which levels are usable, rather than
		# just skipping the empty one, is what stops this block from quietly
		# testing nothing if the clamp ever widened.
		if ( $cl > 0.999 ) {
			is( $checked, 0, sprintf 'survfit upper limits all clamp to 1 at '
				. 'conf_level %.17g', $cl );
		} else {
			cmp_ok( $checked, '>', 0,
				sprintf 'survfit had usable risk-set points at conf_level %.17g',
					$cl );
		}
	}
}

# cmh_test is the ninth site and is not here: its interval is
# or_mh * exp(+/- z * sqrt(var_mh)), and var_mh is the Robins-Breslow-Greenland
# variance, which the function does not report.  Recovering the critical value
# would mean reimplementing that variance in the test, which would test the
# reimplementation.  t/cmh_test.*.t pins its interval against R instead.

diag sprintf 'NV_EPSILON %.3g; worst relative error by block:', NV_EPS();
diag sprintf '  %-16s %.3g', $_, $WORST{$_} for sort keys %WORST;

done_testing();
