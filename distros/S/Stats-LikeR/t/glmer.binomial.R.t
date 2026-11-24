#!/usr/bin/env perl
# glmer() against lme4::glmer(), binomial responses.
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
#   cbpp_*        man/glmer.Rd: incidence/size ~ period + (1 | herd), binomial,
#                 by Laplace (gm1), nAGQ = 0 (gm1a), nAGQ = 9, and gm2's
#                 observation-level (1 | obs) beside (1 | herd), which is the
#                 dense path of several grouping factors.
#   gsim_bern,    tests/glmmWeights.R: lme4's gSim() data under set.seed(101),
#   gsim_binom10  Bernoulli (g1) and binomial of 10 trials (g3).
#
# The croaks follow R's binomial()$initialize and poisson()'s, MASS's
# negative.binomial()'s, and lme4's check.response.not.const and nAGQ rule.
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
  cbpp_laplace => {
    names => ['Intercept', 'periodp2', 'periodp3', 'periodp4'],
    coef => [-1.3985321569287859, -0.9923327094236905, -1.128672033507596, -1.5803138625010325],
    se => [0.23247199067085114, 0.30664249736816773, 0.32663784739343954, 0.4274365856468002],
    z => [-6.015916811711386, -3.236122579031355, -3.4554233151925464, -3.6971890464399295],
    p => [1.7887141700119425e-09, 0.0012116534021905897, 0.000549429457691385, 0.0002180000008001985],
    theta => [0.6422614375642705],
    loglik => -92.02628186475708,
    lme4_loglik => -92.02628186475708,
    df => 5,
    vc_grp => ['herd'],
    vc_var1 => ['(Intercept)'],
    vc_var2 => [''],
    vc_sdcor => [0.6422614375642705],
    fitted => [0.30820764217444463, 0.1417482541581363, 0.02904814256482812],
    pkg_coef => [-1.3983428644712235, -0.9919249749756803, -1.1282162159432745, -1.5797454136490972],
    pkg_se => [0.23121400478821952, 0.3031505494624005, 0.32283004043723007, 0.42204896707049294],
    pkg_theta => [0.6420699277294926],
    pkg_loglik => -92.02656638953025,
  },
  cbpp_nagq0 => {
    names => ['Intercept', 'periodp2', 'periodp3', 'periodp4'],
    coef => [-1.360471754687132, -0.9761774716612596, -1.1110768940096536, -1.559680516458915],
    se => [0.22757462149434468, 0.3032873486615978, 0.3235118029502834, 0.42445550124166087],
    z => [-5.978134757530247, -3.21865543013619, -3.4344245986610926, -3.6745442381978255],
    p => [2.257069938583095e-09, 0.0012879314845396384, 0.0005938132499460646, 0.00023827435945443618],
    theta => [0.641815066301542],
    loglik => -92.05429547216413,
    lme4_loglik => -92.05429547216413,
    df => 5,
    vc_grp => ['herd'],
    vc_var1 => ['(Intercept)'],
    vc_var2 => [''],
    vc_sdcor => [0.641815066301542],
    fitted => [0.3092660308315636, 0.14433642993665557, 0.029917508000792934],
    pkg_coef => [-1.3604757276263628, -0.9761732360938308, -1.1110727836429675, -1.5596756837728956],
    pkg_se => [0.22757902289998627, 0.3032861749911408, 0.3235103689514836, 0.42445190952164047],
    pkg_theta => [0.6418385553492219],
    pkg_loglik => -92.05434650122652,
  },
  cbpp_nagq9 => {
    names => ['Intercept', 'periodp2', 'periodp3', 'periodp4'],
    coef => [-1.3992302035683308, -0.9914038449203086, -1.1278196739161621, -1.5794709952310768],
    se => [0.23351140347255078, 0.30676796873802087, 0.3267683571618686, 0.42759448098670283],
    z => [-5.992127933627062, -3.2317710646216953, -3.451434783073207, -3.6938526231356916],
    p => [2.0711288782790003e-09, 0.0012302557777412884, 0.0005576144997012686, 0.00022088184962975647],
    theta => [0.6475177478434743],
    loglik => -50.00501802739893,
    lme4_loglik => -50.00501802739893,
    df => 5,
    vc_grp => ['herd'],
    vc_var1 => ['(Intercept)'],
    vc_var2 => [''],
    vc_sdcor => [0.6475177478434743],
    fitted => [0.3086995910669762, 0.14214228217507585, 0.02896404179454998],
    pkg_coef => [-1.3992194438630683, -0.9914086574328165, -1.127812837138408, -1.5794877735815458],
    pkg_se => [0.23351064415944106, 0.3067678475040666, 0.3267671173058212, 0.42759621416228105],
    pkg_theta => [0.6475178610835888],
    pkg_loglik => -50.005018033405925,
  },
  cbpp_obs => {
    names => ['Intercept', 'periodp2', 'periodp3', 'periodp4'],
    coef => [-1.5002918893665116, -1.2265088374209383, -1.3288404541305892, -1.8662649033068752],
    se => [0.2967132126887338, 0.48031242066982655, 0.4939212988576738, 0.5936117851936835],
    z => [-5.056370344182781, -2.5535646896461532, -2.690389050247258, -3.143914844443243],
    p => [4.273111469371988e-07, 0.010662646974256942, 0.007136876231571733, 0.001667039426598172],
    theta => [0.8910784538495313, 0.18394714884983662],
    loglik => -87.31915554146839,
    lme4_loglik => -87.31915554146839,
    df => 6,
    vc_grp => ['obs', 'herd'],
    vc_var1 => ['(Intercept)', '(Intercept)'],
    vc_var2 => ['', ''],
    vc_sdcor => [0.8910784538495313, 0.18394714884983662],
    fitted => [0.16308370157384658, 0.15290595296052448, 0.024324920141841233],
    pkg_coef => [-1.50028986102184, -1.2264984376739645, -1.3288314817142217, -1.8662478179813755],
    pkg_se => [0.2967075370038777, 0.48029404965399214, 0.49389850961144366, 0.5935804825765107],
    pkg_theta => [0.8910693339270153, 0.18395624482693312],
    pkg_loglik => -87.31916357358173,
  },
  gsim_bern => {
    names => ['Intercept', 'x'],
    coef => [4.450233794750133, 2.754788776652478],
    se => [0.5621558031173007, 0.9513850663388694],
    z => [7.9163708176139505, 2.8955560415232147],
    p => [2.44543564924263e-15, 0.0037848744179801237],
    theta => [1.147265377932493],
    loglik => -104.11687756157559,
    lme4_loglik => -104.11687756157559,
    df => 3,
    vc_grp => ['block'],
    vc_var1 => ['(Intercept)'],
    vc_var2 => [''],
    vc_sdcor => [1.147265377932493],
    fitted => [0.995310616195812, 0.9912196164897767, 0.9989509172763302],
    pkg_coef => [4.449987322897606, 2.7547502190462065],
    pkg_se => [0.561499982075542, 0.9512536810269623],
    pkg_theta => [1.147045127278644],
    pkg_loglik => -104.1169677859674,
  },
  gsim_binom10 => {
    names => ['Intercept', 'x'],
    coef => [4.179038990194629, 2.5867569822425684],
    se => [0.23478506205194602, 0.2779659874790717],
    z => [17.799424519052323, 9.30601979653114],
    p => [7.13987789713765e-71, 1.3271257214973347e-20],
    theta => [0.9714329406772251],
    loglik => -659.992587556633,
    lme4_loglik => -659.992587556633,
    df => 3,
    vc_grp => ['block'],
    vc_var1 => ['(Intercept)'],
    vc_var2 => [''],
    vc_sdcor => [0.9714329406772251],
    fitted => [0.9964462010979328, 0.9559608883383964, 0.9816798067229482],
    pkg_coef => [4.177819186916484, 2.586637605194934],
    pkg_se => [0.23179057846302292, 0.2726576132430538],
    pkg_theta => [0.9704044061638646],
    pkg_loglik => -659.993412650219,
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

my $cb = read_csv('glmer.cbpp.csv');
my @cbw = (data => $cb, family => 'binomial', weights => 'size');
check('cbpp_laplace', glmer(formula => 'prop ~ period + (1 | herd)', @cbw), 56);
check('cbpp_nagq0',   glmer(formula => 'prop ~ period + (1 | herd)', @cbw, nAGQ => 0), 56);
check('cbpp_nagq9',   glmer(formula => 'prop ~ period + (1 | herd)', @cbw, nAGQ => 9), 56);
check('cbpp_obs',     glmer(formula => 'prop ~ period + (1 | herd) + (1 | obs)', @cbw), 56);
my $g1 = read_csv('glmer.gsim.bern.csv');
check('gsim_bern',    glmer(formula => 'y ~ x + (1 | block)', data => $g1, family => 'binomial'), 2600);
my $g3 = read_csv('glmer.gsim.binom10.csv');
check('gsim_binom10', glmer(formula => 'prop ~ x + (1 | block)', data => $g3, family => 'binomial', weights => 'size'), 2600);
{
	# The family's own checks (R's binomial()$initialize and poisson()'s,
	# MASS's negative.binomial()), lme4's, and this function's
	my %b = (y => [0, 1, 1, 0, 1, 0, 1, 1], x => [1 .. 8], g => [qw(a a b b c c d d)]);
	eval { glmer(formula => 'y ~ x + (1 | g)', data => { %b, y => [0, 1, 2, 0, 1, 0, 1, 1] }, family => 'binomial') };
	like($@, qr/^glmer: y values must be 0 <= y <= 1/, 'a binomial response above 1 croaks');
	eval { glmer(formula => 'y ~ x + (1 | g)', data => { %b, y => [0, 1, -1, 0, 1, 0, 1, 1] }, family => 'poisson') };
	like($@, qr/^glmer: negative values not allowed for the 'Poisson' family/, 'a negative count croaks');
	eval { glmer(formula => 'y ~ x + (1 | g)', data => { %b, y => [0, 1, -1, 0, 1, 0, 1, 1] }, family => 'negbin', theta => 1) };
	like($@, qr/^glmer: negative values not allowed for the negative binomial family/, 'and for negbin');
	eval { glmer(formula => 'y ~ x + (1 | g)', data => { %b, y => [(1) x 8] }, family => 'poisson') };
	like($@, qr/^glmer: response is constant/, "lme4's check.response.not.const");
	eval { glmer(formula => 'y ~ x', data => \%b, family => 'binomial') };
	like($@, qr/^glmer: no random-effects terms in the formula; use glm\(\)/, 'no random effects: use glm()');
	eval { glmer(formula => 'y ~ x + (x | g)', data => \%b, family => 'binomial', nAGQ => 5) };
	like($@, qr/^glmer: nAGQ > 1 is only available for models with a single, scalar random-effects term/,
		'nAGQ > 1 with a random slope croaks, as in lme4');
	eval { glmer(formula => 'y ~ x + (1 | g)', data => \%b, family => 'binomial', theta => 2) };
	like($@, qr/theta is the negbin family's dispersion/, 'theta for another family croaks');
	eval { glmer(formula => 'y ~ x + (1 | g)', data => \%b, family => 'negbin', theta => 0) };
	like($@, qr/theta must be positive and finite/, 'theta 0 croaks');
	eval { glmer(formula => 'y ~ x + (1 | g)', data => \%b, family => 'gaussian') };
	like($@, qr/unsupported family 'gaussian'/, "family 'gaussian' croaks: that is lmer()");
	eval { glmer(formula => 'y ~ x + (1 | g)', data => \%b, nAGQ => 1.5) };
	like($@, qr/nAGQ must be a whole number from 0 to 100/, 'a fractional nAGQ croaks');
	eval { glmer(formula => 'y ~ x + (1 | g)', data => { %b, g => [('a') x 8] }) };
	like($@, qr/^glmer: grouping factors must have > 1 sampled level/, 'a one-level factor croaks');
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	eval { glmer(formula => 'y ~ x + (1 | g)', data => { %b, y => [0.5, 1, 0, 0, 1, 0, 1, 1] }, family => 'binomial') };
	like($w[0] // '', qr/^glmer: non-integer #successes in a binomial glm!/, "a non-integer number of successes warns, as R's binomial does");
}
{
	# lme4's allow.n for a model with no scale: a factor with a level per row
	# fits (cbpp_obs above has one beside herd); with it alone too
	my $f = glmer(formula => 'prop ~ period + (1 | obs)', @cbw);
	ok($f->{converged}, 'an observation-level random effect alone fits');
	is($f->{varcor}[0]{levels}, 56, 'with a level per row');
}
SKIP: {
	skip 'Test::LeakTrace not installed', 2 unless eval { require Test::LeakTrace; 1 };
	Test::LeakTrace::no_leaks_ok(sub { glmer(formula => 'prop ~ period + (1 | herd)', @cbw) }, 'no leaks');
	Test::LeakTrace::no_leaks_ok(sub { eval { glmer(formula => 'prop ~ period', @cbw) } }, 'no leaks: croak');
}
diag(sprintf('worst relative disagreement, %s: %.3g (%s)', $_, $worst{$_}, $worst_at{$_})) for sort keys %worst;
# A call of the wrong form dies with the function's argparse-style help screen
# (lib/Stats/LikeR/Usage.pm), then "fn: error: ..." as its last line.
{
	my $err = eval { glmer(formula => 'y ~ x + (1 | g)', data => { x => [1, 2], y => [1, 0], g => [1, 2] }, conf_level => 2); 1 } ? '' : $@;
	like($err, qr/\Ausage: glmer\(.*^example:\n.*\n\nglmer: error: \Qconf_level must be between 0 and 1\E\n\z/ms,
		'glmer: conf_level must be between 0 and 1, under the help screen');
}


done_testing();
