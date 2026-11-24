#!/usr/bin/env perl
# glmer() against lme4::glmer(), Poisson responses.
#
# PROVENANCE
#
# %EXPECT is frozen output of t/glmer.R.R under R 4.6.1 with lme4 2.0-6, MASS
# 7.3-66 and numDeriv 2016.8-1.1 (re-run with `Rscript t/glmer.R.R` from the
# distribution root, which prints one %EXPECT block per glmer test file and
# writes the t/glmer.*.csv files; t/lme4.offset.sim.csv comes from
# t/lmer.offset.weights.R.R).  The models are lme4's own examples and tests,
# from its source tarball:
#
#   gsim_pois*    tests/glmmWeights.R: lme4's gSim() Poisson data under
#                 set.seed(101) (g2), and with every weight 2 (g2W).
#   off_pois*     tests/offset.R, its glmer() half: with and without
#                 offset(3*x).
#   grouse_*      man/grouseticks.Rd: full_mod1 (three crossed factors, 584
#                 random effects; run only under EXTENDED_TESTING, see below)
#                 and the same with (1|BROOD) alone.
#   epil_pois     tests/nbinom.R's MASS epil model with (Visit|subject), by
#                 Poisson.
#
# Each record holds lme4's default fit (pkg_*) and a tight one: lme4's own
# deviance function minimized by nlminb() at its tightest tolerances and
# Nelder-Mead in turn until neither improves, then ten restarts, with tolPwrss
# = 1e-13 and log|L|^2 re-factored at the mode (t/glmer.R.R's exactify(): lme4
# factors it with the weights of the step before, 1.1e-5 off on grouseticks
# however small tolPwrss is).  Standard errors are vcov.merMod()'s 2 H^-1 with
# H numDeriv's Richardson Hessian of that deviance (its default d = 0.1).  The
# models are split over t/glmer.binomial.R.t, t/glmer.poisson.R.t,
# t/glmer.negbin.R.t and t/glmer.negbin_epil.R.t so that no one file is the
# long pole of a parallel run on a __float128 perl, where all four take 184 s.
#
# TOLERANCE
#
# Over all four files, the worst disagreement with the tight fit was the same on
# a double, an x87 long double and a __float128 perl (2026-11-22):
#
#   logLik, deviance, AIC   1e-10 relative   (observed 5.9e-13, epil_nb)
#   fixed effects           1e-5 of their SE (2.9e-6, off_pois3x), and exp()
#                           and the fitted means to 1e-5 relative (6.5e-7)
#   standard errors, z      6e-5 relative    (2.0e-5, epil_nb)
#   p-values                1e-4 on the log scale (1.1e-5, epil_nb)
#   theta, sds, corrs       1e-4 relative, 1e-5 absolute near 0
#   negative-binomial theta 1e-5 relative    (2.7e-7, epil_nb)
#
# Both Hessians are finite differences of a function evaluated through PIRLS,
# and numDeriv's own answer moves by 3e-4 on epil_pois between its steps d =
# 1e-2 and 0.1, so the standard errors are not held to the fixed effects'
# precision.  Against lme4's default fit, which stops its PIRLS early and takes
# its Hessian by deriv12(): fixed effects within 5e-2 SE (observed 5.2e-3,
# gsim_binom10), theta within 2e-2, standard errors within 0.1 (observed 0.062
# on epil_nb, a singular fit whose slope sd lme4's default leaves at 1.7e-5),
# and its logLik() at most 1e-7 relative above the optimum (it can be above:
# 1.7e-8 on nb_fixed, from the lagged log|L|^2).  The worst of each class is
# printed at the end.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Spec;
use Stats::LikeR qw(glmer);

my %EXPECT = (
  gsim_pois => {
    names => ['Intercept', 'x'],
    coef => [3.5059900486442426, 3.005955513604933],
    se => [0.1753401751272722, 0.004553734210247786],
    z => [19.995360710113292, 660.1078092876588],
    p => [6.0440297557198376e-89, 0],
    theta => [0.8938680346546187],
    loglik => -10296.476384526235,
    lme4_loglik => -10296.476384526235,
    df => 3,
    vc_grp => ['block'],
    vc_var1 => ['(Intercept)'],
    vc_var2 => [''],
    vc_sdcor => [0.8938680346546187],
    fitted => [92.55571761022306, 11.655297865602966, 351.6297875382724],
    pkg_coef => [3.5059781055744246, 3.005955408569813],
    pkg_se => [0.17533593458605462, 0.004553699220084417],
    pkg_theta => [0.893867479032538],
    pkg_loglik => -10296.476384528778,
  },
  gsim_pois_w2 => {
    names => ['Intercept', 'x'],
    coef => [3.5059786256312995, 3.0059524844778176],
    se => [0.17532455697788213, 0.0032199753629489156],
    z => [19.997076770446892, 933.5327589975435],
    p => [5.839649947372987e-89, 0],
    theta => [0.8938858639013969],
    loglik => -20462.36995345607,
    lme4_loglik => -20462.36995345607,
    df => 3,
    vc_grp => ['block'],
    vc_var1 => ['(Intercept)'],
    vc_var2 => [''],
    vc_sdcor => [0.8938858639013969],
    fitted => [92.5561863906747, 11.653873581550602, 351.6337505550081],
    pkg_coef => [3.505986086028435, 3.005952440527956],
    pkg_se => [0.17529134697254437, 0.0032199628002268165],
    pkg_theta => [0.8938868948690045],
    pkg_loglik => -20462.369953457055,
  },
  off_pois => {
    names => ['Intercept', 'x'],
    coef => [4.159562146655147, 3.0007128434892825],
    se => [0.17764644557205386, 0.003480976207203615],
    z => [23.414834635506498, 862.031988980429],
    p => [3.017953305092815e-121, 0],
    theta => [0.905712026290302],
    loglik => -11180.629854328226,
    lme4_loglik => -11180.629854328226,
    df => 3,
    vc_grp => ['block'],
    vc_var1 => ['(Intercept)'],
    vc_var2 => [''],
    vc_sdcor => [0.905712026290302],
    fitted => [485.1171686444659, 10.765370961545903, 342.50338200403337],
    pkg_coef => [4.159555868198366, 3.0007128852542806],
    pkg_se => [0.17763371701235145, 0.003480960706269465],
    pkg_theta => [0.9057128787472185],
    pkg_loglik => -11180.6298543289,
  },
  off_pois3x => {
    names => ['Intercept', 'x'],
    coef => [4.159561886370082, 0.0007128266146469795],
    se => [0.17764648540337352, 0.00348095378257743],
    z => [23.414827920322548, 0.20477910916679154],
    p => [3.018428732515944e-121, 0.8377447095977804],
    theta => [0.9057122309067782],
    loglik => -11180.62985432824,
    lme4_loglik => -11180.62985432824,
    df => 3,
    vc_grp => ['block'],
    vc_var1 => ['(Intercept)'],
    vc_var2 => [''],
    vc_sdcor => [0.9057122309067782],
    fitted => [485.117170854568, 10.76537108375226, 342.50338117643025],
    pkg_coef => [4.159555866569109, 0.0007128852535842161],
    pkg_se => [0.17765630040496494, 0.0034809610292962207],
    pkg_theta => [0.9057126659352538],
    pkg_loglik => -11180.629854328923,
  },
  grouse_brood => {
    names => ['Intercept', 'YEARy96', 'YEARy97', 'cHEIGHT'],
    coef => [0.5091834962856607, 1.1358944206939503, -1.0011349365058435, -0.8581489998211402],
    se => [0.18662066719073228, 0.24238981298532458, 0.2696928242318589, 0.10825490975606844],
    z => [2.7284410882812833, 4.686230030478726, -3.7121304185874555, -7.9271138995433414],
    p => [0.006363445540624824, 2.782834794073201e-06, 0.00020552203396023556, 2.242975514768421e-15],
    theta => [0.9496952308315094],
    loglik => -989.037740526496,
    lme4_loglik => -989.037740526496,
    df => 5,
    vc_grp => ['BROOD'],
    vc_var1 => ['(Intercept)'],
    vc_var2 => [''],
    vc_sdcor => [0.9496952308315094],
    fitted => [0.5636263184770915, 0.5636263184770915, 0.9296625694292145],
    pkg_coef => [0.5091734491505816, 1.1359009046812307, -1.0011299729921235, -0.8581410159215679],
    pkg_se => [0.18661749158230412, 0.24238804355076274, 0.26968662895363404, 0.10825320044356342],
    pkg_theta => [0.9497030826573569],
    pkg_loglik => -989.0377460709215,
  },
  grouse_full => {
    names => ['Intercept', 'YEARy96', 'YEARy97', 'cHEIGHT'],
    coef => [0.3727816395103988, 1.1804102635574711, -0.9786954548528797, -0.8543470292286665],
    se => [0.19637353075956232, 0.2381274726507052, 0.2627885149477974, 0.12363628442370851],
    z => [1.8983293627633995, 4.957051995797829, -3.7242702750814516, -6.910164222509074],
    p => [0.05765270830286881, 7.157082777404428e-07, 0.00019588098675732906, 4.840929685990104e-12],
    theta => [0.5415088339617055, 0.75003368535308, 0.5287199891788974],
    loglik => -890.2713300873966,
    lme4_loglik => -890.2713300873966,
    df => 7,
    vc_grp => ['INDEX', 'BROOD', 'LOCATION'],
    vc_var1 => ['(Intercept)', '(Intercept)', '(Intercept)'],
    vc_var2 => ['', '', ''],
    vc_sdcor => [0.5415088339617055, 0.75003368535308, 0.5287199891788974],
    fitted => [0.5029345730719044, 0.5029345730719044, 0.8146207277698339],
    pkg_coef => [0.3727908176044, 1.1803976199735868, -0.9786949624255823, -0.8543386744414541],
    pkg_se => [0.19636552717645972, 0.2381215533143639, 0.26277497291392427, 0.12363103125266971],
    pkg_theta => [0.5415086054603666, 0.7500282862418324, 0.5287322844821115],
    pkg_loglik => -890.2713534938432,
  },
  epil_pois => {
    names => ['Intercept', 'Base', 'trtprogabide', 'Age', 'Visit', 'Base:trtprogabide'],
    coef => [-1.3700591945175293, 0.8850995804853337, -0.9288145347476212, 0.4772366960009162, -0.2664542270286422, 0.3381124350224717],
    se => [1.1972961960552326, 0.13087817255187545, 0.40114274985630416, 0.3525988956065423, 0.1646572851305904, 0.2038796702344573],
    z => [-1.1442942849325874, 6.762774595851815, -2.3154214679944674, 1.3534832410066724, -1.6182352746634698, 1.6583921027224027],
    p => [0.25250161263123655, 1.3537376844276549e-11, 0.020589877772971298, 0.17590130044795949, 0.10561190354590747, 0.0972383495559077],
    theta => [0.4997990811963388, 0.005851169941417966, 0.7286471350594719],
    loglik => -655.7405820664098,
    lme4_loglik => -655.7405820664098,
    df => 9,
    vc_grp => ['subject', 'subject', 'subject'],
    vc_var1 => ['(Intercept)', 'Visit', '(Intercept)'],
    vc_var2 => ['', '', 'Visit'],
    vc_sdcor => [0.4997990811963388, 0.7286706276638709, 0.008029924247361124],
    fitted => [3.887099912333141, 3.567943147241645, 2.3053105469770294],
    pkg_coef => [-1.3670169295102772, 0.8850407373510172, -0.9281154796138603, 0.476402186907426, -0.2663595954196644, 0.33777047897346285],
    pkg_se => [1.1936822640110567, 0.1305978193351279, 0.3995005714225583, 0.3515124680072009, 0.16335866478483602, 0.20326098136665746],
    pkg_theta => [0.4997781321315584, 0.005837030614405441, 0.7285749848267377],
    pkg_loglik => -655.7413794249328,
  },
);

sub read_csv {
	my $f = File::Spec->catfile('t', shift);
	my %d;
	open my $fh, '<', $f or die "cannot open $f: $!";
	my $h = <$fh>; $h =~ s/[\r\n"]+//g;
	my @c = split /,/, $h;
	while (my $l = <$fh>) {
		$l =~ s/[\r\n]+//; $l =~ s/"//g;
		my @v = split /,/, $l;
		push @{ $d{ $c[$_] } }, $v[$_] for 0 .. $#c;
	}
	return \%d;
}

my (%worst, %worst_at);
sub close_to {
	my ($got, $want, $tol, $class, $name, $abs) = @_;
	my $r = !defined $got ? 9**9**9 : $got == $want ? 0
	      : defined $abs && abs($got - $want) <= $abs ? 0 : abs($got - $want) / (abs($want) || 1);
	($worst{$class}, $worst_at{$class}) = ($r, $name) if $r > ($worst{$class} // 0) && $r < 9**9**9;
	ok($r <= $tol, $name) or diag('got ' . ($got // 'undef') . ", want $want, relative $r > $tol");
}

# See the header for each tolerance.
my %TOL = (loglik => 1e-10, coef => 1e-5, se => 6e-5, p => 1e-4, theta => 1e-4, nbth => 1e-5,
           pkg_coef => 5e-2, pkg_se => 0.1, pkg_theta => 2e-2, pkg_loglik => 1e-7);

sub check {
	my ($key, $fit, $nrow) = @_;
	my $e = $EXPECT{$key};
	ok($fit->{converged}, "$key: converged");
	is($fit->{nobs}, $nrow, "$key: nobs");
	is($fit->{vcov_method}, $fit->{nAGQ} ? 'Hessian' : 'RX', "$key: vcov from the " . ($fit->{nAGQ} ? 'Hessian' : 'RX'));
	for my $j (0 .. $#{ $e->{names} }) {
		my $nm = $e->{names}[$j];
		my $s = $fit->{summary}{$nm};
		# a fixed effect moves with theta, so its disagreement is measured
		# in its own standard errors
		my $r = abs($fit->{coefficients}{$nm} - $e->{coef}[$j]) / $e->{se}[$j];
		($worst{'coef (SE units)'}, $worst_at{'coef (SE units)'}) = ($r, "$key: coef $nm")
			if $r > ($worst{'coef (SE units)'} // 0);
		ok($r <= $TOL{coef}, "$key: coef $nm") or diag("got $fit->{coefficients}{$nm}, want $e->{coef}[$j]: $r SE");
		close_to($s->{'Std. Error'}, $e->{se}[$j], $TOL{se}, 'se, z', "$key: se $nm");
		close_to($s->{'z value'}, $e->{z}[$j], $TOL{se}, 'se, z', "$key: z $nm", $TOL{se});
		if ($e->{p}[$j] == 0) { is($s->{'Pr(>|z|)'}, 0, "$key: p $nm is 0, past R's cut-off at z = -38.47") }
		else { close_to(log($s->{'Pr(>|z|)'}), log($e->{p}[$j]), $TOL{p}, 'p (log)', "$key: p $nm (log scale)", $TOL{p}) }
		my $rp = abs($fit->{coefficients}{$nm} - $e->{pkg_coef}[$j]) / $e->{se}[$j];
		($worst{"lme4 default: coef (SE units)"}, $worst_at{"lme4 default: coef (SE units)"}) = ($rp, "$key: coef $nm")
			if $rp > ($worst{"lme4 default: coef (SE units)"} // 0);
		ok($rp <= $TOL{pkg_coef}, "$key: coef $nm near lme4's default fit") or diag("$rp SE from $e->{pkg_coef}[$j]");
		close_to($s->{'Std. Error'}, $e->{pkg_se}[$j], $TOL{pkg_se}, 'lme4 default: se, theta', "$key: se $nm near lme4's default fit");
		my $ex = $fit->{exp}{$nm};
		close_to($ex->{estimate}, exp($e->{coef}[$j]), $TOL{coef}, 'exp', "$key: exp $nm");
	}
	for my $j (0 .. $#{ $e->{theta} }) {
		close_to($fit->{theta}[$j], $e->{theta}[$j], $TOL{theta}, 'theta', "$key: theta $j", 1e-5);
		close_to($fit->{theta}[$j], $e->{pkg_theta}[$j], $TOL{pkg_theta}, 'lme4 default: se, theta', "$key: theta $j near lme4's default fit", 1e-3);
	}
	close_to($fit->{loglik}, $e->{loglik}, $TOL{loglik}, 'loglik', "$key: logLik");
	close_to($fit->{deviance}, -2 * $e->{loglik}, $TOL{loglik}, 'loglik', "$key: deviance is -2 logLik");
	close_to($fit->{AIC}, -2 * $e->{loglik} + 2 * $e->{df}, $TOL{loglik}, 'loglik', "$key: AIC, with lme4's df $e->{df}");
	# lme4's own logLik() is of log|L|^2 at the weights of the step before the
	# mode, which can put it above the optimum (see the header)
	ok($fit->{loglik} >= $e->{pkg_loglik} - $TOL{pkg_loglik} * abs($e->{pkg_loglik}), "$key: at or above lme4's default optimum");
	if (defined $e->{nb_theta}) {
		close_to($fit->{nb_theta}, $e->{nb_theta}, $TOL{nbth}, 'nb theta', "$key: negative-binomial theta");
	}
	# VarCorr: match R's rows to the terms by group and column
	for my $r (0 .. $#{ $e->{vc_grp} }) {
		my ($g, $v1, $v2, $sd) = ($e->{vc_grp}[$r], $e->{vc_var1}[$r], $e->{vc_var2}[$r], $e->{vc_sdcor}[$r]);
		(my $gb = $g) =~ s/\.\d+$//;
		$_ = ($_ eq '(Intercept)') ? 'Intercept' : $_ for $v1, $v2;
		my ($term) = grep { $_->{group} eq $gb && grep({ $_ eq $v1 } @{ $_->{names} }) } @{ $fit->{varcor} };
		if (!$term) { fail("$key: no term for $g $v1"); next; }
		if ($v2 eq '') {
			close_to($term->{sd}{$v1}, $sd, $TOL{theta}, 'theta', "$key: sd $g $v1", 1e-5);
		} else {
			my @n = @{ $term->{names} };
			my ($a) = grep { $n[$_] eq $v1 } 0 .. $#n;
			my ($b) = grep { $n[$_] eq $v2 } 0 .. $#n;
			close_to($term->{corr}[$a][$b], $sd, $TOL{theta}, 'theta', "$key: corr $g $v1 $v2", 1e-4);
		}
	}
	my @at = (1, 2, $nrow);
	close_to($fit->{fitted_values}{ $at[$_] }, $e->{fitted}[$_], $TOL{coef}, 'fitted', "$key: fitted mean of row $at[$_]")
		for 0 .. 2;
}

my $g2 = read_csv('glmer.gsim.pois.csv');
check('gsim_pois',    glmer(formula => 'y ~ x + (1 | block)', data => $g2, family => 'poisson'), 2600);
check('gsim_pois_w2', glmer(formula => 'y ~ x + (1 | block)', data => $g2, family => 'poisson', weights => 'w2'), 2600);
my $off = read_csv('lme4.offset.sim.csv');
check('off_pois',     glmer(formula => 'ycount ~ x + (1 | block)', data => $off, family => 'poisson'), 2600);
check('off_pois3x',   glmer(formula => 'ycount ~ x + (1 | block) + offset(3 * x)', data => $off, family => 'poisson'), 2600);
check('off_pois3x',   glmer(formula => 'ycount ~ x + (1 | block)', offset => 'I(3*x)', data => $off, family => 'poisson'), 2600);
my $gt = read_csv('glmer.grouseticks.csv');
check('grouse_brood', glmer(formula => 'TICKS ~ YEAR + cHEIGHT + (1 | BROOD)', data => $gt, family => 'poisson'), 403);
SKIP: {
	# 584 random effects over three crossed factors: the dense path, whose
	# cost is cubic in them at every PIRLS step (see the README); 781 s on a
	# double perl, 2026-11-22
	skip 'grouseticks with three crossed factors takes 13 minutes; set EXTENDED_TESTING', 1
		unless $ENV{EXTENDED_TESTING} || $ENV{AUTHOR_TESTING};
	check('grouse_full', glmer(formula => 'TICKS ~ YEAR + cHEIGHT + (1 | BROOD) + (1 | INDEX) + (1 | LOCATION)',
		data => $gt, family => 'poisson'), 403);
}
{
	# The dense path's cap is this module's own, not lme4's: 1000 random
	# effects for glmer() (lmer() takes 4000), since glmer() refactors at every
	# PIRLS step. 600 + 401 crossed levels is one over; the check is made
	# before any fitting, so this costs nothing.
	my %big;
	for my $i (0 .. 1199) {
		push @{ $big{y} }, $i % 3;
		push @{ $big{a} }, 'a' . ($i % 600);
		push @{ $big{b} }, 'b' . (int($i / 2) % 401);
	}
	eval { glmer(formula => 'y ~ 1 + (1 | a) + (1 | b)', data => \%big, family => 'poisson') };
	like($@, qr/^glmer: 1001 random effects over more than one grouping factor is more than the dense method takes \(at most 1000;/,
		'glmer refuses more than 1000 crossed random effects before fitting');
}
my $ep = read_csv('glmer.epil.csv');
check('epil_pois', glmer(formula => 'y ~ Base * trt + Age + Visit + (Visit | subject)', data => $ep, family => 'poisson'), 236);
diag(sprintf('worst relative disagreement, %s: %.3g (%s)', $_, $worst{$_}, $worst_at{$_})) for sort keys %worst;

done_testing();
