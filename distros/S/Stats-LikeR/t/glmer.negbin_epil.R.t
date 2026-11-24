#!/usr/bin/env perl
# glmer() against lme4::glmer.nb() on the epilepsy data, a random slope.
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
#   epil_nb       tests/nbinom.R: MASS's epil with (Visit|subject), negative
#                 binomial (its g4, run there only at testLevel > 2).  That
#                 file's reference, logLik -624.48418 "for now ... not *the*
#                 truth", is from an older lme4; lme4 2.0-6 gives
#                 -624.5910591, and so does this.
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
  epil_nb => {
    names => ['Intercept', 'Base', 'trtprogabide', 'Age', 'Visit', 'Base:trtprogabide'],
    coef => [-1.3415487765981056, 0.884042873799647, -0.9257936924749006, 0.4751310494850016, -0.26370807234578225, 0.334735915887487],
    se => [1.1953753386960615, 0.13107508065520854, 0.4013857912632027, 0.3522788549456102, 0.17526889097231863, 0.2040934160945435],
    z => [-1.1222824607219126, 6.744553345918676, -2.3064934350599007, 1.3487356473846808, -1.504591435952153, 1.6401112896871948],
    p => [0.2617423611646012, 1.5349848613427294e-11, 0.021083076537024518, 0.17742189124454508, 0.1324291494143177, 0.10098202946423028],
    theta => [0.4662660587391106, -0.00890438734653828, 7.377344054193846e-08],
    loglik => -624.5910590595089,
    lme4_loglik => -624.5910590606708,
    df => 10,
    vc_grp => ['subject', 'subject', 'subject'],
    vc_var1 => ['(Intercept)', 'Visit', '(Intercept)'],
    vc_var2 => ['', '', 'Visit'],
    vc_sdcor => [0.4662660587391106, 0.008904387346843888, -0.999999999965679],
    fitted => [3.6961388850808996, 3.5056664791160146, 2.1971943996432266],
    pkg_coef => [-1.341554861478958, 0.8840435072164241, -0.9257914984311434, 0.4751316784131274, -0.26370693381857935, 0.3347344051350447],
    pkg_se => [1.1757795062744791, 0.13077317013282866, 0.3993408620145174, 0.345124018527505, 0.16497404248167072, 0.2026100586839728],
    pkg_theta => [0.466266992018595, -0.00890498307628222, 1.7225444737402394e-05],
    pkg_loglik => -624.591120119796,
    nb_theta => 7.4624055126332385,
    pkg_nb_theta => 7.462392783589426,
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

my $ep = read_csv('glmer.epil.csv');
check('epil_nb',   glmer(formula => 'y ~ Base * trt + Age + Visit + (Visit | subject)', data => $ep, family => 'negbin'), 236);
diag(sprintf('worst relative disagreement, %s: %.3g (%s)', $_, $worst{$_}, $worst_at{$_})) for sort keys %worst;

done_testing();
