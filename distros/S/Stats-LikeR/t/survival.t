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

#--------------------------------------------------------------------------
# Kaplan-Meier
#--------------------------------------------------------------------------
my $f = survfit(\@time, \@status, group => \@grp);
my $m = $f->{strata}{Maintained};

my @ev_time  = (9, 13, 18, 23, 31, 34, 48);
my @ev_surv  = (0.90909091,0.81818182,0.71590909,0.61363636,0.49090909,0.36818182,0.18409091);
my @ev_lower = (0.75413385,0.61924899,0.48842629,0.37686706,0.25485995,0.15487712,0.03591790);
my @ev_upper = (1.00000000,1.00000000,1.00000000,0.99915760,0.94558496,0.87526068,0.94352577);

my (@t,@s,@lo,@hi);
for my $i (0 .. $#{$m->{time}}) {
	next unless $m->{n_event}[$i] > 0;
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

#--------------------------------------------------------------------------
# Log-rank
#--------------------------------------------------------------------------
my $lr = logrank_test(\@time, \@status, \@grp);
is_approx($lr->{statistic},  3.39638870, 'log-rank chi-squared');
is($lr->{parameter}, 1,                  'log-rank df = groups-1');
is_approx($lr->{p_value},    0.06533932, 'log-rank p-value');
is_approx($lr->{observed}[0], 7,          'observed events group 0');
is_approx($lr->{expected}[0], 10.689336, 'expected events group 0');
is_approx($lr->{expected}[1],  7.310664, 'expected events group 1');

#--------------------------------------------------------------------------
# Cox proportional hazards — single covariate (Maintained vs not) on aml.
# Reference from R coxph(Surv(time,status)~x, ties="efron").
#--------------------------------------------------------------------------
my @x = map { $_ eq 'Maintained' ? 1 : 0 } @grp;
my $cx = coxph(\@time, \@status, \@x, names => ['maintained']);
is_approx($cx->{coef}[0],      -0.91553258, 'Cox coefficient');
is_approx($cx->{exp_coef}[0],   0.40030338, 'Cox hazard ratio');
is_approx($cx->{se}[0],         0.51193428, 'Cox standard error');
is_approx($cx->{z}[0],         -1.78837913, 'Cox Wald z');
is_approx($cx->{p_value}[0],    0.07371486, 'Cox Wald p-value');
is_approx($cx->{conf_int}[0][0],0.14676754, 'Cox HR CI lower');
is_approx($cx->{conf_int}[0][1],1.09181360, 'Cox HR CI upper');
is_approx($cx->{loglik},      -41.032616,   'Cox log-likelihood');
is_approx($cx->{loglik_null}, -42.724839,   'Cox null log-likelihood');
is_approx($cx->{lr_stat},       3.384447,   'Cox likelihood-ratio statistic');
is_approx($cx->{lr_p_value},    0.06581424, 'Cox LR p-value');
is($cx->{names}[0], 'maintained', 'Cox covariate name passthrough');
ok($cx->{converged}, 'Cox model converged');
is($cx->{nevent}, 18, 'Cox event count');

#--------------------------------------------------------------------------
# error paths
#--------------------------------------------------------------------------
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

done_testing();
