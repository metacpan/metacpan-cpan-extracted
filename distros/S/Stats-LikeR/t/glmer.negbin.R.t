#!/usr/bin/env perl
# glmer() against lme4::glmer.nb(), negative-binomial responses.
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
#   nb_rd         man/glmer.nb.Rd: y ~ f1*f2 + (1|g) on its set.seed(101) data.
#   nb_ref        tests/test-glmernbref.R: y ~ x + (1|f), set.seed(101).
#   nb_fixed      nb_ref's model with the negative-binomial theta fixed at 2,
#                 glmer(family = negative.binomial(2)).
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
  nb_rd => {
    names => ['Intercept', 'f1a2', 'f1a3', 'f2B', 'f1a2:f2B', 'f1a3:f2B'],
    coef => [1.6500821173401392, 0.7671536566827741, 1.0114713784807137, 1.5124192952888724, -0.6150649352164836, -0.6104045500288675],
    se => [0.12985364204854696, 0.18155430340814266, 0.18115956839135006, 0.1805960714418777, 0.2538182117701201, 0.2534189500508071],
    z => [12.707245567461566, 4.225477679579847, 5.583317444738453, 8.374596873640318, -2.423249816973496, -2.4086776064161324],
    p => [5.389970518338132e-37, 2.384344586063564e-05, 2.3597345651649992e-08, 5.5413224463110465e-17, 0.015382344515660932, 0.01601043404693339],
    theta => [2.805329535531433e-07],
    loglik => -2984.6346362469044,
    lme4_loglik => -2984.6346362469044,
    df => 8,
    vc_grp => ['g'],
    vc_var1 => ['(Intercept)'],
    vc_var2 => [''],
    vc_sdcor => [2.805329535531433e-07],
    fitted => [5.2074074280714475, 11.214816143369475, 35.28889203114431],
    pkg_coef => [1.6500843770634295, 0.7671504855446349, 1.0114681903184797, 1.5124144503364778, -0.6150596794442471, -0.6103980989972893],
    pkg_se => [0.12985363383939744, 0.18155429783826973, 0.1811595752922773, 0.18059607137738584, 0.25381821005065563, 0.2534189580917879],
    pkg_theta => [4.289501378004392e-06],
    pkg_loglik => -2984.6346362479812,
    nb_theta => 0.4797701047007716,
    pkg_nb_theta => 0.4797700780911363,
  },
  nb_ref => {
    names => ['Intercept', 'x'],
    coef => [1.2404820238148702, 1.6507388261506502],
    se => [0.26856657928817274, 0.21896089813403907],
    z => [4.6188994442373605, 7.538966273056362],
    p => [3.8578074333286106e-06, 4.737114553082474e-14],
    theta => [1.0367151538998414],
    loglik => -658.3853945621796,
    lme4_loglik => -658.3853945627634,
    df => 4,
    vc_grp => ['f'],
    vc_var1 => ['(Intercept)'],
    vc_var2 => [''],
    vc_sdcor => [1.0367151538998414],
    fitted => [5.979677944125725, 3.4774794122736585, 13.779791183297515],
    pkg_coef => [1.2404880106972822, 1.6507278044823375],
    pkg_se => [0.2685685565413523, 0.21896013746476803],
    pkg_theta => [1.0367248635279642],
    pkg_loglik => -658.3854685909051,
    nb_theta => 1.9536404977885724,
    pkg_nb_theta => 1.9536565407324111,
  },
  nb_fixed => {
    names => ['Intercept', 'x'],
    coef => [1.2409630097767466, 1.649887595236983],
    se => [0.26807278516233507, 0.21690274965195874],
    z => [4.629201763339254, 7.606577592420501],
    p => [3.670779801029916e-06, 2.8144928514060758e-14],
    theta => [1.0372237910520314],
    loglik => -658.4011472824641,
    lme4_loglik => -658.4011472824641,
    df => 4,
    vc_grp => ['f'],
    vc_var1 => ['(Intercept)'],
    vc_var2 => [''],
    vc_sdcor => [1.0372237910520314],
    fitted => [5.983255816165222, 3.4805328709823224, 13.790165554891129],
    pkg_coef => [1.2409564209287942, 1.6499811723858984],
    pkg_se => [0.2680545661897701, 0.21687722711213067],
    pkg_theta => [1.0371535873014421],
    pkg_loglik => -658.4011361497073,
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

my $nbref = read_csv('glmer.nbref.csv');
check('nb_rd',     glmer(formula => 'y ~ f1 * f2 + (1 | g)', data => read_csv('glmer.nbrd.csv'), family => 'negbin'), 810);
check('nb_ref',    glmer(formula => 'y ~ x + (1 | f)', data => $nbref, family => 'negbin'), 200);
check('nb_fixed',  glmer(formula => 'y ~ x + (1 | f)', data => $nbref, family => 'negbin', theta => 2), 200);
{
	# lme4 drops a fixed-effect column that is a linear combination of the
	# others (check.rankX = "message+drop.cols"); here it is NaN, as lmer()
	# reports one, and the fit is that of the other columns
	my %d = %$nbref;
	$d{x2} = [ map { 2 * $_ } @{ $nbref->{x} } ];
	my $a = glmer(formula => 'y ~ x + x2 + (1 | f)', data => \%d, family => 'negbin', theta => 2);
	my $b = glmer(formula => 'y ~ x + (1 | f)', data => $nbref, family => 'negbin', theta => 2);
	ok($a->{coefficients}{x2} != $a->{coefficients}{x2}, 'an aliased column is NaN');
	close_to($a->{coefficients}{x}, $b->{coefficients}{x}, 1e-9, 'aliased', 'and the rest are the fit without it');
	close_to($a->{loglik}, $b->{loglik}, 1e-12, 'aliased', 'with the same logLik');
}
diag(sprintf('worst relative disagreement, %s: %.3g (%s)', $_, $worst{$_}, $worst_at{$_})) for sort keys %worst;

done_testing();
