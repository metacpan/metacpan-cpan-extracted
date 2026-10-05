#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-6 if not defined $epsilon;
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) { pass("$test_name: within $epsilon"); return 1; }
	fail($test_name);
	diag("         got: $got\n    expected: $expected; diff = $diff");
	return 0;
}

# R survival::aml (leukemia) dataset — reference values from
# survfit(Surv(time,status)~x, conf.type="log") and survdiff().
my @time   = (9,13,13,18,23,28,31,34,45,48,161, 5,5,8,8,12,16,23,27,30,33,43,45);
my @status = (1, 1, 0, 1, 1, 0, 1, 1, 0, 1,  0, 1,1,1,1, 1, 0, 1, 1, 1, 1, 1, 1);
my @grp    = (("Maintained") x 11, ("Nonmaintained") x 12);

# Kaplan-Meier
my $f = survfit(\@time, \@status, group => \@grp);
my $m = $f->{strata}{Maintained};

my @ev_time  = (9, 13, 18, 23, 31, 34, 48);
my @ev_surv  = (0.90909091,0.81818182,0.71590909,0.61363636,0.49090909,0.36818182,0.18409091);
my @ev_lower = (0.75413385,0.61924899,0.48842629,0.37686706,0.25485995,0.15487712,0.03591790);
my @ev_upper = (1.00000000,1.00000000,1.00000000,0.99915760,0.94558496,0.87526068,0.94352577);

my (@t,@s,@lo,@hi);
for my $i (0 .. $#{$m->{time}}) {
	next unless $m->{'n_event'}[$i] > 0;
	push @t,  $m->{time}[$i];  push @s,  $m->{surv}[$i];
	push @lo, $m->{lower}[$i]; push @hi, $m->{upper}[$i];
}
is_deeply(\@t, \@ev_time, 'KM event times (Maintained)');
is_approx($s[$_],  $ev_surv[$_],  "KM survival step $_")  for 0..$#ev_surv;
is_approx($lo[$_], $ev_lower[$_], "KM lower CI step $_")  for 0..$#ev_lower;
is_approx($hi[$_], $ev_upper[$_], "KM upper CI step $_")  for 0..$#ev_upper;

is_approx($f->{strata}{Maintained}{median},    31, 'median survival (Maintained)');
is_approx($f->{strata}{Nonmaintained}{median}, 23, 'median survival (Nonmaintained)');
is($m->{n},      11, 'group n (Maintained)');
is($m->{events},  7, 'group events (Maintained)');

# Survival is non-increasing over time within a stratum.
my $mono = 1;
for my $i (1 .. $#{$m->{surv}}) { $mono = 0 if $m->{surv}[$i] > $m->{surv}[$i-1] + 1e-12; }
ok($mono, 'KM survival curve is non-increasing');

# Log-rank
my $lr = logrank_test(\@time, \@status, \@grp);
is_approx($lr->{statistic},  3.39638870, 'log-rank chi-squared');
is($lr->{parameter}, 1,                  'log-rank df = groups-1');
is_approx($lr->{'p_value'},    0.06533932, 'log-rank p-value');
is_approx($lr->{observed}[0], 7,          'observed events group 0');
is_approx($lr->{expected}[0], 10.689336, 'expected events group 0');
is_approx($lr->{expected}[1],  7.310664, 'expected events group 1');

# Cox proportional hazards — single covariate (Maintained vs not) on aml.
# Reference from R coxph(Surv(time,status)~x, ties="efron").
my @x = map { $_ eq 'Maintained' ? 1 : 0 } @grp;
my $cx = coxph(\@time, \@status, \@x, names => ['maintained']);
is_approx($cx->{coef}[0],      -0.91553258, 'Cox coefficient');
is_approx($cx->{'exp_coef'}[0],   0.40030338, 'Cox hazard ratio');
is_approx($cx->{se}[0],         0.51193428, 'Cox standard error');
is_approx($cx->{z}[0],         -1.78837913, 'Cox Wald z');
is_approx($cx->{'p_value'}[0],    0.07371486, 'Cox Wald p-value');
is_approx($cx->{'conf_int'}[0][0],0.14676754, 'Cox HR CI lower');
is_approx($cx->{'conf_int'}[0][1],1.09181360, 'Cox HR CI upper');
is_approx($cx->{loglik},      -41.032616,   'Cox log-likelihood');
is_approx($cx->{'loglik_null'}, -42.724839,   'Cox null log-likelihood');
is_approx($cx->{'lr_stat'},       3.384447,   'Cox likelihood-ratio statistic');
is_approx($cx->{'lr_p_value'},    0.06581424, 'Cox LR p-value');
is($cx->{names}[0], 'maintained', 'Cox covariate name passthrough');
ok($cx->{converged}, 'Cox model converged');
is($cx->{nevent}, 18, 'Cox event count');

# error paths
dies_ok { survfit(\@time) }                          'survfit: missing status dies';
dies_ok { survfit(\@time, [1,0,1]) }                 'survfit: length mismatch dies';
dies_ok { survfit([-1,2], [1,1]) }                   'survfit: negative time dies';
dies_ok { logrank_test(\@time, \@status) }           'logrank: missing group dies';
dies_ok { logrank_test([1,2],[1,1],["a","a"]) }      'logrank: single group dies';
dies_ok { coxph(\@time, \@status) }                  'coxph: missing covariates dies';
dies_ok { coxph(\@time, \@status, [1,2,3]) }         'coxph: covariate length mismatch dies';

unless ($INC{'Devel/Cover.pm'}) {
	no_leaks_ok { eval { survfit(\@time, \@status, group => \@grp) } } 'survfit: no leaks';
	no_leaks_ok { eval { logrank_test(\@time, \@status, \@grp) } }     'logrank: no leaks';
	no_leaks_ok { eval { coxph(\@time, \@status, \@x) } }              'coxph: no leaks';
}

# ---------------------------------------------------------------------------
# The curve reaching zero.
#
# Greenwood's next variance term is d / (n_risk * (n_risk - d)), and the last
# event takes every remaining subject, so n_risk == d and the variance of S(t)
# is not defined from that point on.  R's survfit() reports std.err as Inf
# there -- s$std.err * s$surv, the standard error of S itself, is NaN -- and
# both confidence limits as NA.  Through 0.311 all three came back 0, which is
# a number where there is no answer, and a plausible-looking one.
#
# Provenance: R 4.6.1 (2026-06-24) with survival 3.8-3, at options(digits=17):
#   t <- c(4,3,1,1,2,2,3,7,8,10,12,5,6,9,11,13,2,4,6,8)
#   d <- c(1,1,1,0,1,1,0,1,0,1, 1, 0,1,1, 0, 1,1,0,1,1)
#   s <- survfit(Surv(t,d)~1); s$time; s$surv; s$std.err*s$surv; s$lower; s$upper
# The frozen values are the row before the curve hits zero and the row at it.
{
	my @t = (4,3,1,1,2,2,3,7,8,10,12,5,6,9,11,13,2,4,6,8);
	my @d = (1,1,1,0,1,1,0,1,0,1, 1, 0,1,1, 0, 1,1,0,1,1);
	my $s = survfit(\@t, \@d)->{strata}{''};

	is(scalar @{ $s->{time} }, 13, 'thirteen distinct event/censor times');
	is($s->{surv}[12], 0, 'the curve reaches exactly zero at the last time');

	# the row before: still defined, and equal to R's
	is_approx($s->{'std_err'}[11], 0.10452809445658001, 'std_err at t = 12');
	is_approx($s->{lower}[11],     0.023139826547207372, 'lower at t = 12');
	is_approx($s->{upper}[11],     0.65135682814734119,  'upper at t = 12');

	# the row at zero: undef, where R gives NaN for the error and NA for both
	# limits.  Perl has one spelling for "no value", so all three are undef.
	ok(!defined $s->{'std_err'}[12], 'std_err is undef once S(t) is 0, as R gives NaN');
	ok(!defined $s->{lower}[12],     'lower is undef there, as R gives NA');
	ok(!defined $s->{upper}[12],     'upper is undef there, as R gives NA');

	# the estimate itself is still reported, and so is everything counting
	is($s->{'n_risk'}[12],  1, 'n_risk is still reported at that time');
	is($s->{'n_event'}[12], 1, 'and n_event');
	is($s->{events}, 14, 'total events unaffected: sum(status)');
}

done_testing();
