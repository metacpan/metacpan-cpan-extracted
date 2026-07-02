#!/usr/bin/env perl

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok / lives_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Stats::LikeR::binom_test returns a hashref:
#   { p_value, statistic, parameter, estimate, null_value,
#     conf_int => [lo, hi], conf_level, alternative, method }
#
# Every expected value below was produced by R's stats::binom.test().
# CI bounds match R to full double precision because the XS solver inverts the
# same regularized incomplete beta (Clopper-Pearson), and the two-sided p-value
# uses Catherine Loader's saddle-point dbinom (R's dbinom_raw).

# Relative-tolerance compare that also handles an expected value of exactly 0.
# Custom helper for floating-point comparisons
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	my $i = 0;
	foreach my $arg ($got, $expected, $test_name) {
		next if defined $arg;
		die "\$arg[$i] (see subroutine signature for name) isn't defined in $current_sub";
		$i++;
	}
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) {
		pass("$test_name: within $epsilon");
		return 1;
	} else {
		fail($test_name);
		diag("         got: $got\n    expected: $expected; diff = $diff");
		return 0;
	}
}
#	two.sided
{
	my $r = binom_test(8, 20);                       # p = 0.5 default
	is($r->{method},      'Exact binomial test', 'C1 method');
	is($r->{alternative}, 'two.sided',           'C1 alternative');
	is($r->{statistic},   8,                     'C1 statistic (successes)');
	is($r->{parameter},   20,                    'C1 parameter (trials)');
	is_approx($r->{estimate},   0.4,             'C1 estimate');
	is_approx($r->{null_value}, 0.5,             'C1 null value');
	is_approx($r->{p_value},    0.503444671631,  'C1 two.sided p-value');
	is_approx($r->{conf_int}[0], 0.191190060725, 'C1 CI lower');
	is_approx($r->{conf_int}[1], 0.639457412693, 'C1 CI upper');
}

# Exact rational p-value: 2*(C(10,0)+C(10,1)+C(10,2))/2^10 = 112/1024
{
	my $r = binom_test(2, 10);
	is_approx($r->{p_value},     0.109375,        'C2 two.sided p-value (exact)');
	is_approx($r->{conf_int}[0], 0.0252107263268, 'C2 CI lower');
	is_approx($r->{conf_int}[1], 0.556095462308,  'C2 CI upper');
}

# Boundary x == 0
{
	my $r = binom_test(0, 10);
	is_approx($r->{p_value},     0.001953125,     'C3 two.sided p-value (x=0)');
	is_approx($r->{conf_int}[0], 0,               'C3 CI lower is 0');
	is_approx($r->{conf_int}[1], 0.308497107819,  'C3 CI upper');
}

# Boundary x == n, with p != 0.5  (p-value = 0.3^10)
{
	my $r = binom_test(10, 10, p => 0.3);
	is_approx($r->{p_value},     5.9049e-06,      'C4 two.sided p-value (x=n)', 1e-6);
	is_approx($r->{conf_int}[0], 0.691502892181,  'C4 CI lower');
	is_approx($r->{conf_int}[1], 1,               'C4 CI upper is 1');
}

# Larger n, non-default p
{
	my $r = binom_test(683, 1000, p => 0.7);
	is_approx($r->{p_value},     0.240871445717,  'C5 two.sided p-value (n=1000)');
	is_approx($r->{conf_int}[0], 0.653152969441,  'C5 CI lower');
	is_approx($r->{conf_int}[1], 0.711765143274,  'C5 CI upper');
}

#	one-sided
{
	my $r = binom_test(3, 10, p => 0.1, alternative => 'greater');
	is($r->{alternative}, 'greater',              'C6 alternative');
	is_approx($r->{p_value},     0.0701908264,    'C6 greater p-value');
	is_approx($r->{conf_int}[0], 0.0872644339142, 'C6 greater CI lower');
	is_approx($r->{conf_int}[1], 1,               'C6 greater CI upper is 1');
}
{
	my $r = binom_test(15, 20, alternative => 'less');
	is_approx($r->{p_value},     0.994091033936,  'C7 less p-value');
	is_approx($r->{conf_int}[0], 0,               'C7 less CI lower is 0');
	is_approx($r->{conf_int}[1], 0.89591916409,   'C7 less CI upper');
}
{
	my $r = binom_test(8, 20, alternative => 'greater');
	is_approx($r->{p_value},     0.868412017822,  'C8 greater p-value');
	is_approx($r->{conf_int}[0], 0.21706858937,   'C8 greater CI lower');
}

#	array-ref form: x = [successes, failures]
{
	my $r = binom_test([8, 12]);                     # same as binom_test(8, 20)
	is($r->{parameter}, 20,                        'C9 trials derived from [s,f]');
	is_approx($r->{estimate}, 0.4,                 'C9 estimate from [s,f]');
	is_approx($r->{p_value}, 0.503444671631,       'C9 p-value matches scalar form');
}

#	conf_level / conf.level spellings agree
{
	my $x = binom_test(8, 20, conf_level => 0.99);
	my $y = binom_test(8, 20, 'conf.level' => 0.99);
	is_approx($x->{conf_int}[0], $y->{conf_int}[0], 'C10 conf_level == conf.level (lo)');
	is_approx($x->{conf_int}[1], $y->{conf_int}[1], 'C10 conf_level == conf.level (hi)');
	cmp_ok($x->{conf_int}[1] - $x->{conf_int}[0], '>',
	       0.639457412693 - 0.191190060725,
	       'C10 99% interval wider than 95%');
}

#	input validation
dies_ok { binom_test(5) }                       'E1 scalar x without n dies';
dies_ok { binom_test(25, 20) }                  'E2 successes > trials dies';
dies_ok { binom_test(-1, 20) }                  'E3 negative successes dies';
dies_ok { binom_test(2.5, 20) }                 'E4 non-integer successes dies';
dies_ok { binom_test(8, 20, p => 1.5) }         'E5 p out of range dies';
dies_ok { binom_test(8, 20, conf_level => 0) }  'E6 conf_level out of range dies';
dies_ok { binom_test(8, 20, alternative => 'two') } 'E7 bad alternative dies';
dies_ok { binom_test(8, 20, bogus => 1) }       'E8 unknown argument dies';
dies_ok { binom_test([1, 2, 3]) }               'E9 wrong-length array ref dies';
lives_ok { binom_test(0, 1, p => 0) }           'E10 degenerate p=0 lives';

#	binom_test: memory  (inputs hoisted out of the closures)
unless ($INC{'Devel/Cover.pm'}) {
	no_leaks_ok {
		eval { binom_test(8, 20) }
	} 'binom_test(): no memory leaks (scalar form)';
	my @sf = (8, 12);
	no_leaks_ok {
		eval { binom_test(\@sf, p => 0.3) }
	} 'binom_test(): no memory leaks (array-ref form)';

	no_leaks_ok {
		eval { binom_test(15, 20, alternative => 'less', conf_level => 0.99) }
	} 'binom_test(): no memory leaks (named options)';

	no_leaks_ok {
		eval { binom_test(683, 1000, p => 0.7, alternative => 'greater') }
	} 'binom_test(): no memory leaks (large n)';

	no_leaks_ok {
		eval { binom_test(25, 20) }     # the croak path must not leak either
	} 'binom_test(): no memory leaks (error path)';
}
done_testing();
