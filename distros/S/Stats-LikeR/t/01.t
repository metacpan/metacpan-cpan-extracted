#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use feature 'say';
use File::Temp;
use Scalar::Util 'looks_like_number';
use Stats::LikeR;
use Test::Exception; # die_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

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
#--------
# min
#--------
is_approx( min(1,2,2.33,3), 1, 'min of scalars');
no_leaks_ok {
	eval {
		min(1, 2, 2.33, 3)
	}
} 'min(): no memory leaks' unless $INC{'Devel/Cover.pm'};
my @test_data = (-5..5);
is_approx(min(@test_data), $test_data[0], 'min of array');
my $test_data = \@test_data;
is_approx(min($test_data), $test_data[0], 'min of array reference');
my %h = (A => -3, B => 4, C => 9);
is_approx( min(values %h), -3, 'min takes values from hash');
dies_ok { min() } 'min: dies when given 0 elements' ;
if (min(9,'-inf') == '-inf') {
	pass('min: -inf shows as minimum');
} else {
	fail('fail: -inf failed the minimum');
}
if (min(9,'inf') == 9) {
	pass('min: inf is correctly handled');
} else {
	fail('fail: inf is correctly');
}
dies_ok {
	min(1, undef);
} 'min: dies with undefined values as a scalar';
dies_ok {
	min(1, [2,undef]);
} 'min: dies with undefined values inside array references';
#----------------------
#		max
#----------------------
is_approx( max(1,2,3), 3, 'max of scalars');
is_approx(max(@test_data), $test_data[-1], 'max of array');
is_approx(max($test_data), $test_data[-1], 'max of array reference');
is_approx( max(values %h), 9, 'max takes values from hash');
no_leaks_ok {
	eval {
		max(1, 2, 2.33, 3)
	}
} 'max(): no memory leaks' unless $INC{'Devel/Cover.pm'};
if (max(9,'-inf') == 9) {
	pass('max: -inf is interpreted correctly');
} else {
	fail('max fail: -inf is NOT interpreted correctly');
}
if (max(9,'inf') == 'inf') {
	pass('max: inf is correctly handled');
} else {
	fail('max fail: inf is correctly');
}
dies_ok { max() } 'max: dies when given 0 elements' ;
dies_ok {
	max(1, undef);
} 'max: dies with undefined values';
dies_ok {
	max(1, [2,undef]);
} 'max: dies with undefined values inside array references';
#----------------------
#		mean
#----------------------
is_approx(mean(1,2,3), 2, 'mean: simple example works', 0);
my @arr = 1..8;
if (mean(@arr, 4, 5) == 4.5) {
	ok(1, 'Arrays can be given to mean and mixed');
} else {
	fail('Arrays given to mean and mixed failed');
}
if (mean([1,1], [2,2]) == 1.5) {
	ok(1, 'Arrays can be given as references');
} else {
	fail('Arrays as references cannot be given');
}

my @large_data = (1000000000.1, 1000000000.2, 1000000000.3);
# The variance of (0.1, 0.2, 0.3) is exactly 0.01.
is_approx( var(@large_data), 0.01, 'var: handles large magnitude data cleanly' );
is_approx( sd(@large_data), 0.1, 'sd: handles large magnitude data cleanly' );
# Exceptional cases for mean
eval { mean() };
like( $@, qr/mean needs >= 1 element/, 'mean: dies when given empty input' );

no_leaks_ok {
	eval {
		mean(1, 2, 2.33, 3)
	}
} 'mean(): no memory leaks' unless $INC{'Devel/Cover.pm'};
dies_ok {
	mean(1, undef);
} 'mean: dies with undefined values';
dies_ok {
	mean(1, [2,undef]);
} 'mean: dies with undefined values inside array references';
# -------------------------------
# standard deviation
# -------------------------------
my $stdev = sd(2,4,4,4,5,5,7,9);
my $correct = 2.1380899352994;
if (abs($stdev - $correct) < 1e-14) {
	ok(1, 'stdev works');
} else {
	my $diff = $correct - $stdev;
	fail("stdev does not work, got $stdev with an error of $diff");
}
$stdev = sd([2,4,4,4,5,5,7,9]);
if (abs($stdev - $correct) < 1e-14) {
	ok(1, 'stdev works');
} else {
	my $diff = $correct - $stdev;
	fail("stdev does not work, got $stdev with an error of $diff");
}
# Exceptional cases for sd / var
dies_ok {
	sd(1)
} 'sd: dies when given < 2 elements';

dies_ok { var(1) } 'var: dies when given < 2 elements' ;
no_leaks_ok {
	eval {
		sd(1, 2, 2.33, 3);
	}
} 'sd: no memory leaks' unless $INC{'Devel/Cover.pm'};
is_approx( sd(3, 3, 3, 3), 0, 'sd: all identical values returns 0', 0);
dies_ok {
	sd(1, undef);
} 'sd: dies with undefined values';
dies_ok {
	sd(1, [2,undef]);
} 'sd: dies with undefined values inside array references';
#------------------
# t.test
#------------------
@test_data = (
[
	[27.5,21.0,19.0,23.6,17.0,17.9,16.9,20.1,21.9,22.6,23.1,19.6,19.0,21.7,21.4],
	[27.1,22.0,20.8,23.4,23.4,23.5,25.8,22.0,24.8,20.2,21.9,22.1,22.9,20.5,24.4],
],
[
	[17.2,20.9,22.6,18.1,21.7,21.4,23.5,24.2,14.7,21.8],
	[21.5, 22.8, 21.0, 23.0, 21.6, 23.6, 22.5, 20.7, 23.4, 21.8, 20.7, 21.7, 21.5, 22.5, 23.6, 21.5, 22.5, 23.5,21.5,21.8]
],
[
	[19.8,20.4,19.6,17.8,18.5,18.9,18.3,18.9,19.5,22.0],
	[28.2,26.6,20.1,23.3,25.2,22.1,17.7,27.6,20.6,13.7,23.2,17.5,20.6,18.0,23.9,21.6,24.3,20.4, 24.0,13.2]
],
[
	[30.02,29.99,30.11,29.97,30.01,29.99],
	[29.89,29.93,29.72,29.98,30.02,29.98]
],
[
	[3.0,4.0,1.0,2.1],
	[490.2,340.0,433.9]
],
[
	[0.010268,0.000167,0.000167],
	[0.159258,0.136278,0.122389]
],
[
	[1.0/15,10.0/62.0],
	[1.0/10,2/50.0]
],
[
	[9/23.0,21/45.0,0/38.0],
	[0/44.0,42/94.0,0/22.0]
]);
foreach my $i (0..$#test_data) { # single sample t-tests
	foreach my $j (0,1) {
		my $t_test = t_test( 'x' => $test_data[$i][$j], mu => mean( $test_data[$i][$j] ));
		no_leaks_ok {
			eval {
				 t_test( 'x' => $test_data[$i][$j], mu => mean( $test_data[$i][$j] ));
			}
		} 't_test(): no memory leaks' unless $INC{'Devel/Cover.pm'};
		is_approx( $t_test->{p_value}, 1,            "t_test: Testing set $i/$j p-value");
		is_approx( $t_test->{df}, scalar @{ $test_data[$i][$j] } - 1, "t_test: df $i/$j");
		is_approx( $t_test->{statistic}, 0, "t_test: t $i/$j");
		# without key "x"
		$t_test = t_test( $test_data[$i][$j], mu => mean( $test_data[$i][$j] ));
		no_leaks_ok {
			eval {
				 t_test( $test_data[$i][$j], mu => mean( $test_data[$i][$j] ));
			}
		} 't_test(): no memory leaks' unless $INC{'Devel/Cover.pm'};
		is_approx( $t_test->{p_value}, 1,            "t_test: Testing set $i/$j p-value");
		is_approx( $t_test->{df}, scalar @{ $test_data[$i][$j] } - 1, "t_test: df $i/$j");
		is_approx( $t_test->{statistic}, 0, "t_test: t $i/$j");
	}
}
my @correct_t = (
	{ # default
		conf_int     => [
			-3.98409625405368, -0.349237079279662
		],
		df           => 24.9885292902309,
		'estimate_x' => 20.82,
		'estimate_y' => 22.9866666666666,
		p_value      => 0.021378001462867,
		statistic    => -2.45535639828601
	},
	{ # var.equal = True (Student's t-test)
		conf_int     => [
			-3.0124986, -0.0375014
		],
		df           => 28,
		'estimate_x' => 20.610,
		'estimate_y' => 22.135,
		p_value      => 0.04485852,
		statistic    => -2.10004963761047
	},
	{ # paired = true
		conf_int     => [
			-0.06672889, 0.25672889
		],
		df        => 5,
		estimate  => 0.095,
		p_value   => 0.19143688433660,
		statistic => 1.50996688705414
	}
);
my $t_test = t_test(
	'x' => $test_data[0][0],	'y' => $test_data[0][1]
);
foreach my $key (grep {ref $correct_t[0]{$_} eq ''} keys %{ $correct_t[0] }) {
	if (not defined $t_test->{$key}) {
		die "$key isn't defined in test";
	}
	is_approx( $t_test->{$key}, $correct_t[0]{$key}, "t_test var_equal = true; $key");
}
foreach my $j (0,1) {
	is_approx( $t_test->{'conf_int'}[$j], $correct_t[0]{'conf_int'}[$j], "Conf. interval index $j");
}
$t_test = t_test(
	'x'       => $test_data[1][0],
	'y'       => $test_data[1][1],
	var_equal => 1
);
foreach my $key (grep {ref $correct_t[1]{$_} eq ''} keys %{ $correct_t[1] }) {
	if (not defined $t_test->{$key}) {
		die "$key isn't defined in test";
	}
	is_approx( $t_test->{$key}, $correct_t[1]{$key}, "t_test var_equal = true; $key");
}
foreach my $j (0,1) {
	is_approx( $t_test->{'conf_int'}[$j], $correct_t[1]{'conf_int'}[$j], "Conf. interval index $j");
}
# start new test
$t_test = t_test(
	'x'    => $test_data[3][0], 'y' => $test_data[3][1],	paired => 1
);
foreach my $key (grep {ref $correct_t[2]{$_} eq ''} keys %{ $correct_t[2] }) {
	if (not defined $t_test->{$key}) {
		die "$key isn't defined in test";
	}
	is_approx( $t_test->{$key}, $correct_t[2]{$key}, "t_test var_equal = true; $key");
}
foreach my $j (0,1) {
	is_approx( $t_test->{'conf_int'}[$j], $correct_t[2]{'conf_int'}[$j], "Conf. interval index $j");
}
$t_test = t_test(
	$test_data[0][0], #[qw(27.5 21.0 19.0 23.6 17.0 17.9 16.9 20.1 21.9 22.6 23.1 19.6 19.0 21.7 21.4)],
	$test_data[0][1], #[qw(27.1 22.0 20.8 23.4 23.4 23.5 25.8 22.0 24.8 20.2 21.9 22.1 22.9 20.5 24.4)],
	var_equal => 0,
	'conf_level' => 0.99
);
my $idx = 0;
foreach my $val (-4.6264605, 0.2931271) {
	is_approx($t_test->{conf_int}[$idx], $val, "t_test: var_equal = false, conf.int = 0.99 conf_int $idx", 1e-6);
	$idx++;
}
is_approx( $t_test->{p_value}, 0.02137800146287, 't_test: var_equal = false, conf.int = 0.99', 1e-14);
is_approx( $t_test->{df}, 24.98853, 't_test: var_equal = false, conf.int = 0.99', 1e-5);
# t_test exceptions & alternative hypotheses tests
eval { t_test(y => [1..5]) };
like( $@, qr/must be an ARRAY reference/, 't_test: dies when x is missing' );

eval { t_test('x' => [1..5], paired => 1) };
like( $@, qr/'y' must be provided for paired or two-sample tests/, 't_test: dies paired without y' );

eval { t_test('x' => [1..5], 'y' => [1..4], paired => 1) };
like( $@, qr/Paired arrays must be same length/, 't_test: dies on mismatched paired arrays' );

eval { t_test([1..5], conf_level => 1.5) };
like( $@, qr/'conf_level' must be between 0 and 1/, 't_test: dies on invalid conf_level' );

$t_test = t_test('x' => [5, 6, 7, 8, 9], mu => 2, alternative => 'greater');
ok( $t_test->{p_value} < 0.05, 't_test alternative greater works (small p_value)' );

$t_test = t_test('x' => [5, 6, 7, 8, 9], mu => 20, alternative => 'less');
ok( $t_test->{p_value} < 0.05, 't_test alternative less works (small p_value)' );

dies_ok {
	t_test( 'x' => [3,3,3,3] )
} '"t_test" dies when data is constant';

$t_test = t_test(
	'x' => $test_data[0][0],
	mu  => mean( $test_data[0][0] )
);
is_approx( $t_test->{'p_value'}, 1, 't_test: single distribution p-value', 1e-13);
is_approx( $t_test->{statistic}, 0, 't_test: single distribution statistic', 1e-13);
#-repeat without "x"

$t_test = t_test( $test_data[0][0], $test_data[0][1]);
foreach my $key (grep {ref $correct_t[0]{$_} eq ''} keys %{ $correct_t[0] }) {
	if (not defined $t_test->{$key}) {
		die "$key isn't defined in test";
	}
	is_approx( $t_test->{$key}, $correct_t[0]{$key}, "t_test var_equal = true; $key");
}
foreach my $j (0,1) {
	is_approx( $t_test->{'conf_int'}[$j], $correct_t[0]{'conf_int'}[$j], "Conf. interval index $j");
}
$t_test = t_test(
	$test_data[1][0], $test_data[1][1],
	var_equal => 1
);
foreach my $key (grep {ref $correct_t[1]{$_} eq ''} keys %{ $correct_t[1] }) {
	if (not defined $t_test->{$key}) {
		die "$key isn't defined in test";
	}
	is_approx( $t_test->{$key}, $correct_t[1]{$key}, "t_test var_equal = true; $key");
}
foreach my $j (0,1) {
	is_approx( $t_test->{'conf_int'}[$j], $correct_t[1]{'conf_int'}[$j], "Conf. interval index $j");
}
# start new test
$t_test = t_test(	$test_data[3][0], $test_data[3][1],	paired => 1);
foreach my $key (grep {ref $correct_t[2]{$_} eq ''} keys %{ $correct_t[2] }) {
	if (not defined $t_test->{$key}) {
		die "$key isn't defined in test";
	}
	is_approx( $t_test->{$key}, $correct_t[2]{$key}, "t_test var_equal = true; $key");
}
foreach my $j (0,1) {
	is_approx( $t_test->{'conf_int'}[$j], $correct_t[2]{'conf_int'}[$j], "Conf. interval index $j");
}

#----------------------
#		p ajdust
#----------------------
my @pvalues = (4.533744e-01, 7.296024e-01, 9.936026e-02, 9.079658e-02, 1.801962e-01,
8.752257e-01, 2.922222e-01, 9.115421e-01, 4.355806e-01, 5.324867e-01,
4.926798e-01, 5.802978e-01, 3.485442e-01, 7.883130e-01, 2.729308e-01,
8.502518e-01, 4.268138e-01, 6.442008e-01, 3.030266e-01, 5.001555e-02,
3.194810e-01, 7.892933e-01, 9.991834e-01, 1.745691e-01, 9.037516e-01,
1.198578e-01, 3.966083e-01, 1.403837e-02, 7.328671e-01, 6.793476e-02,
4.040730e-03, 3.033349e-04, 1.125147e-02, 2.375072e-02, 5.818542e-04,
3.075482e-04, 8.251272e-03, 1.356534e-03, 1.360696e-02, 3.764588e-04,
1.801145e-05, 2.504456e-07, 3.310253e-02, 9.427839e-03, 8.791153e-04,
2.177831e-04, 9.693054e-04, 6.610250e-05, 2.900813e-02, 5.735490e-03);

my %correct = (
	'Benjamini-Hochberg' => [6.126681e-01, 8.521710e-01, 1.987205e-01, 1.891595e-01, 3.217789e-01,
9.301450e-01, 4.870370e-01, 9.301450e-01, 6.049731e-01, 6.826753e-01,
6.482629e-01, 7.253722e-01, 5.280973e-01, 8.769926e-01, 4.705703e-01,
9.241867e-01, 6.049731e-01, 7.856107e-01, 4.887526e-01, 1.136717e-01,
4.991891e-01, 8.769926e-01, 9.991834e-01, 3.217789e-01, 9.301450e-01,
2.304958e-01, 5.832475e-01, 3.899547e-02, 8.521710e-01, 1.476843e-01,
1.683638e-02, 2.562902e-03, 3.516084e-02, 6.250189e-02, 3.636589e-03,
2.562902e-03, 2.946883e-02, 6.166064e-03, 3.899547e-02, 2.688991e-03,
4.502862e-04, 1.252228e-05, 7.881555e-02, 3.142613e-02, 4.846527e-03,
2.562902e-03, 4.846527e-03, 1.101708e-03, 7.252032e-02, 2.205958e-02],
	'Benjamini-Yekutieli' => [1.000000e+00, 1.000000e+00, 8.940844e-01, 8.510676e-01, 1.000000e+00,
1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00,
1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00,
1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 5.114323e-01,
1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00,
1.000000e+00, 1.000000e+00, 1.754486e-01, 1.000000e+00, 6.644618e-01,
7.575031e-02, 1.153102e-02, 1.581959e-01, 2.812089e-01, 1.636176e-02,
1.153102e-02, 1.325863e-01, 2.774239e-02, 1.754486e-01, 1.209832e-02,
2.025930e-03, 5.634031e-05, 3.546073e-01, 1.413926e-01, 2.180552e-02,
1.153102e-02, 2.180552e-02, 4.956812e-03, 3.262838e-01, 9.925057e-02],
	'Bonferroni' => [1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00,
1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00,
1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00,
1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00,
1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00,
1.000000e+00, 1.000000e+00, 7.019185e-01, 1.000000e+00, 1.000000e+00,
2.020365e-01, 1.516674e-02, 5.625735e-01, 1.000000e+00, 2.909271e-02,
1.537741e-02, 4.125636e-01, 6.782670e-02, 6.803480e-01, 1.882294e-02,
9.005725e-04, 1.252228e-05, 1.000000e+00, 4.713920e-01, 4.395577e-02,
1.088915e-02, 4.846527e-02, 3.305125e-03, 1.000000e+00, 2.867745e-01],

	'Hochberg' => [9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01,
9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01,
9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01,
9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01,
9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01,
9.991834e-01, 9.991834e-01, 4.632662e-01, 9.991834e-01, 9.991834e-01,
1.575885e-01, 1.383967e-02, 3.938014e-01, 7.600230e-01, 2.501973e-02,
1.383967e-02, 3.052971e-01, 5.426136e-02, 4.626366e-01, 1.656419e-02,
8.825610e-04, 1.252228e-05, 9.930759e-01, 3.394022e-01, 3.692284e-02,
1.023581e-02, 3.974152e-02, 3.172920e-03, 8.992520e-01, 2.179486e-01],
	'Holm' => [1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00,
1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00,
1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00,
1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00,
1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00, 1.000000e+00,
1.000000e+00, 1.000000e+00, 4.632662e-01, 1.000000e+00, 1.000000e+00,
1.575885e-01, 1.395341e-02, 3.938014e-01, 7.600230e-01, 2.501973e-02,
1.395341e-02, 3.052971e-01, 5.426136e-02, 4.626366e-01, 1.656419e-02,
8.825610e-04, 1.252228e-05, 9.930759e-01, 3.394022e-01, 3.692284e-02,
1.023581e-02, 3.974152e-02, 3.172920e-03, 8.992520e-01, 2.179486e-01],

	'Hommel' => [9.991834e-01, 9.991834e-01, 9.991834e-01, 9.987624e-01, 9.991834e-01,
9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01,
9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01,
9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01, 9.595180e-01,
9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01, 9.991834e-01,
9.991834e-01, 9.991834e-01, 4.351895e-01, 9.991834e-01, 9.766522e-01,
1.414256e-01, 1.304340e-02, 3.530937e-01, 6.887709e-01, 2.385602e-02,
1.322457e-02, 2.722920e-01, 5.426136e-02, 4.218158e-01, 1.581127e-02,
8.825610e-04, 1.252228e-05, 8.743649e-01, 3.016908e-01, 3.516461e-02,
9.582456e-03, 3.877222e-02, 3.172920e-03, 8.122276e-01, 1.950067e-01]);

foreach my $method ('Hochberg','Benjamini-Hochberg','Benjamini-Yekutieli', 'Bonferroni', 'Holm', 'Hommel') {
	my @q = p_adjust(\@pvalues, $method);
	my $error = 0.0;
	foreach my $q (0..$#q) {
		$error += abs($q[$q] - $correct{$method}[$q]);
	}
	if ($error < 10**-6) {
		ok(1, "$method works with cumulative error of $error");
	} else {
		fail("$method doesn't work for FDR correction with error = $error");
	}
	no_leaks_ok {
		eval {
			 p_adjust( \@pvalues, $method);
		}
	} 'p_adjust(): no memory leaks' unless $INC{'Devel/Cover.pm'};
	my $val = 0.003;
	@q = p_adjust([$val], $method);
	if (scalar @q == 1) {
		pass("p_adjust: $method gives exactly 1 value");
	} else {
		fail('p_adjust has ' . (scalar @q) . ' values, when it should have exactly 1 value');
	}
	is_approx($q[0], $val, "p_adjust: $method with 1 value returns that value", 1e-9);
}

# p_adjust exceptions
eval { p_adjust("not array") };
like( $@, qr/first argument must be an ARRAY reference/, 'p_adjust: dies on non-array' );

eval { p_adjust(\@pvalues, "invalid_method") };
like( $@, qr/Unknown p-value adjustment method/, 'p_adjust: dies on invalid method' );

my @empty_p = p_adjust([]);
is_deeply( \@empty_p, [], 'p_adjust handles empty arrayref gracefully' );
no_leaks_ok {
	eval {
		 p_adjust([]);
	}
} 'p_adjust(): no memory leaks' unless $INC{'Devel/Cover.pm'};
#----------------------
#		var
#----------------------
my @ans = (2.5, 8.3);
$idx = 0;
foreach my $arr ([1..5], [2, 4, 5, 8, 9]) {
	my $var = var( $arr );
	is_approx( $var, $ans[$idx], "Test index $idx for var");
	no_leaks_ok {
		eval {
			 var( $arr );
		}
	} 'var(): no memory leaks' unless $INC{'Devel/Cover.pm'};
	$idx++;
}
is_approx( var(7, 7, 7, 7), 0, 'var: all identical values returns 0' );

dies_ok {
	var(1, undef);
} 'var: dies with undefined values';
dies_ok {
	var(1, [2,undef]);
} 'var: dies with undefined values inside array references';
#----------------------
#		median
#----------------------
@ans = (21, 21.55, 19.2);
$idx = 0;
foreach my $ans (@ans) {
	my $median = median( $test_data[$idx][0] );
	is_approx( $median, $ans, "Median test $idx");
	no_leaks_ok {
		eval {
			 var( $test_data[$idx][0] );
		}
	} 'median(): no memory leaks' unless $INC{'Devel/Cover.pm'};
	$idx++;
}
dies_ok { median() } 'median: dies when given empty data';
is_approx(median(1,2,-1,9), 1.5, 'median: w/ even # of arguments', 0);
is_approx(median([1,2,-1,9]), 1.5, 'median: w/ even # of arguments as array ref argument', 0);
dies_ok {
	median(1, undef);
} 'median: dies with undefined values';
dies_ok {
	median(1, [2,undef]);
} 'median: dies with undefined values inside array references';
#----------------------
#		cor
#----------------------
$test_data[0] = [1, 2, 3, 4, 5,  5, 6,  7,   8];
$test_data[1] = [2, 4, 6, 8, 10, 9, 12, 14, 16];
%correct = (
	pearson  => 0.99736494930655,	spearman => 0.99582461641931,	kendall  => 0.98601329718327
);
foreach my $method (sort keys %correct) {
	my $e;
	if ($correct{$method} =~ m/\.(\d+)$/) {
		$e = 10**(-(length $1));
	} elsif ($correct{$method} =~ m/^\-?\d+$/) {
		$e = 0;
	} else {
		my $sp = sprintf '%.3g', $correct{$method};
		if ($sp =~ m/e\-(\d+)$/) {
			$e = 10**(2-$1);
		} else {
			die "$sp failed regex.";
		}
	}
	is_approx(
		cor($test_data[0], $test_data[1], $method),
		$correct{$method},
		"cor: method = \"$method\"",
		$e
	);
	no_leaks_ok {
		eval {
			 cor($test_data[0], $test_data[1], $method);
		};
	} "cor() with $method: no memory leaks" unless $INC{'Devel/Cover.pm'};
	dies_ok {
		cor([1,1],[1,1], $method);
	} "cor with $method: dies when given standard deviation = 0";
	no_leaks_ok {
		eval {
			cor([1,1],[1,1], $method);
		};
	} "cor with $method: dies w/o memory leaks when given standard deviation = 0";
}

# cor exceptions and matrix support tests
eval { cor([1,2,3], [1,2], 'pearson') };
like( $@, qr/x and y must have the same length/, 'cor: dies on mismatched flat vector lengths' );

eval { cor([1,2,3], undef, 'unknown_method') };
like( $@, qr/unknown method/, 'cor: dies on unknown method' );

my $mat_x = [[1, 2], [3, 4], [5, 6]];
my $mat_y = [[6, 5], [4, 3], [2, 1]];
my $cor_matrix = cor($mat_x, $mat_y);
is( ref($cor_matrix), 'ARRAY', 'cor with matrices returns an array reference' );

# It flattens the input and returns a standard array
#----------------------
#  SCALE
#----------------------
my @scaled_results = scale(1..5);
no_leaks_ok {
	eval {
		 scale(1..5);
	}
} 'scale: no memory leaks' unless $INC{'Devel/Cover.pm'};
my @correct_scaled = (-1.2649111, -0.6324555, 0.0000000, 0.6324555, 1.2649111);
$idx = 0;
foreach my $correct (@correct_scaled) {
	is_approx($scaled_results[$idx], $correct, "index $idx for scale");
	$idx++;
}
@scaled_results = scale(1..5, { center => 0 });
@correct_scaled = (0.269679944985297, 0.539359889970594, 0.80903983495589, 1.07871977994119, 1.34839972492648);
$idx = 0;
foreach my $correct (@correct_scaled) {
	is_approx($scaled_results[$idx], $correct, "index $idx for scale");
	$idx++;
}
@scaled_results = scale(1..5, {center => 1, scale => 0});
#p @scaled_results;
@correct_scaled = (-2..2);
$idx = 0;
foreach my $correct (@correct_scaled) {
	is_approx($scaled_results[$idx], $correct, "index $idx for scale");
	$idx++;
}

# scale matrix tests and exceptions
eval { scale(1) };
like( $@, qr/scale needs >= 2 elements to calculate SD/, 'scale: dies with 1 element for default SD scale' );

my $scaled_mat = scale([[1, 2], [3, 4], [5, 6]]);
is( ref($scaled_mat), 'ARRAY', 'scale on matrix returns an array reference' );

#-----------------------
#			MATRIX
#-----------------------
my $mat1 = matrix(
	data => [1..6], nrow => 2
);
if (scalar @{ $mat1 } == 2) {
	pass('matrix: makes correct # of rows');
} else {
	fail('matrix: does NOT make correct # of rows');
}
@ans = (
	[1,3,5],
	[2,4,6]
);
foreach my $i (0,1) {
	foreach my $j (0..2) {
		is_approx($mat1->[$i][$j], $ans[$i][$j], "matrix: check on [$i][$j]", 1e-13);
	}
}
no_leaks_ok {
	eval {
		matrix( data => [1..6], nrow => 2 );
	}
} 'matrix: no memory leaks' unless $INC{'Devel/Cover.pm'};
# check without keys

$mat1 = matrix(
	[1..6], # data
	2       # nrow
);
if (scalar @{ $mat1 } == 2) {
	pass('matrix: makes correct # of rows');
} else {
	fail('matrix: does NOT make correct # of rows');
}
foreach my $i (0,1) {
	foreach my $j (0..2) {
		is_approx($mat1->[$i][$j], $ans[$i][$j], "matrix: check on [$i][$j] without keys", 1e-13);
	}
}
no_leaks_ok {
	eval {
		matrix( [1..6], 2	);
	}
} 'matrix: no memory leaks when using positional args' unless $INC{'Devel/Cover.pm'};
$mat1 = matrix(
	data => [1..6], nrow => 2, byrow => 1
);
@ans = (
	[1,2,3],
	[4,5,6]
);
foreach my $i (0,1) {
	foreach my $j (0..2) {
		is_approx($mat1->[$i][$j], $ans[$i][$j], "matrix: check on [$i][$j]", 1e-13);
	}
}
# matrix exceptions
eval { matrix(data => "string", nrow => 2) };
like( $@, qr/must be an array reference/, 'matrix: dies on non-arrayref data' );

eval { matrix(data => [1,2], nrow => 0, ncol => 0) };
like( $@, qr/Dimensions must be greater than 0/, 'matrix: dies on 0 dimensions' );

eval { matrix(data => []) };
like( $@, qr/Data array cannot be empty/, 'matrix: dies on empty data array' );

#$matrix_correct = '[[-0.707106781186547,-0.707106781186547,-0.707106781186547],[0.707106781186547,0.707106781186547,0.707106781186547]]';

#@scaled_results = scale(
#	[1,2,3],
#	[4,5,6]
#);
#p @scaled_results;
# Output: -1.46385, -0.87831, -0.29277, 0.29277, 0.87831, 1.46385
#---------------------------
#       lm
#----------------------------
my $mtcars = {
'Duster 360' => {
	'qsec' => [15.84],'gear' => [3], 'wt' => [3.57],  'disp' => [360],
	'drat' => [3.21], 'cyl' => [8],  'mpg' => [14.3], 'hp' => [245],
	'carb' => [4],    'vs' => [0],
	'am' => [0],
},
'Merc 280' => {
 'carb' => [4],  'mpg' => [19.2], 'hp' => [123], 'vs' => [1],
 'am' => [0],    'drat' => [3.92], 'cyl' => [6], 'disp' => [167.6],
 'wt' => [3.44], 'gear' => [4], 'qsec' => [18.3],
},
'Merc 450SL' => {
 'qsec' => [17.6], 'gear' => [3], 'drat' => [3.07], 'cyl' => [8],
 'mpg' => [17.3], 'wt' => [3.73], 'hp' => [180], 'disp' => [275.8],
 'carb' => [3], 'vs' => [0], 'am' => [0],
},
'Merc 280C' => {
 'cyl' => [6],     'gear' => [4],
 'drat' => [3.92], 'qsec' => [18.9],
 'am' => [0],      'vs' => [1],
 'carb' => [4],    'disp' => [167.6],
 'hp' => [123],    'mpg' => [17.8],
 'wt' => [3.44],
},
'Merc 450SE' => {
 'gear' => [3],     'qsec' => [17.4],  'disp' => [275.8], 'wt' => [4.07],
 'cyl' => [8],      'drat' => [3.07],  'am' => [0],        'vs' => [0],
 'carb' => [3],     'hp' => [180],
 'mpg' => [16.4],
},
'Mazda RX4' => {
 'drat' => [3.9], 'cyl' => [6],  'mpg' => [21],        'hp' => [110],
 'carb' => [4],   'am' => [1],   'vs' => [0],     'qsec' => [16.46],
 'gear' => [4],   'wt' => [2.62], 'disp' => [160],
},
'Cadillac Fleetwood' => {
 'wt' => [5.25],        'disp' => [472], 'qsec' => [17.98],        'gear' => [3],
 'hp' => [205],        'mpg' => [10.4], 'carb' => [4],        'vs' => [0],
 'am' => [0],        'drat' => [2.93],  'cyl' => [8],
},
'Camaro Z28' => {
 'gear' => [3],   'drat' => [3.73], 'qsec' => [15.41],        'cyl' => [8],
 'carb' => [4],   'disp' => [350], 'hp' => [245],        'mpg' => [13.3],
 'wt' => [3.84],  'vs' => [0],  'am' => [0],
},
'Lincoln Continental' => {
 'drat' => [3], 'cyl' => [8],    'mpg' => [10.4], 'hp' => [215],
 'carb' => [4], 'vs' => [0],     'am' => [0], 'qsec' => [17.82],
 'gear' => [3], 'wt' => [5.424], 'disp' => [460],
},
'Hornet 4 Drive' => {
 'gear' => [3],   'drat' => [3.08],  'qsec' => [19.44],  'cyl' => [6],
 'disp' => [258], 'carb' => [1],     'mpg' => [21.4],   'wt' => [3.215],
 'hp' => [110],   'vs' => [1],       'am' => [0],
},
'Ford Pantera L' => {
 'qsec' => [14.5], 'drat' => [4.22], 'gear' => [5],  'cyl' => [8],
 'hp' => [264],    'mpg' => [15.8],  'wt' => [3.17], 'carb' => [4],
 'disp' => [351],  'am' => [1],      'vs' => [0],
},
'Lotus Europa' => {
  'mpg' => [30.4],  'hp' => [113],    'carb' => [2], 'am' => [1],
  'vs' => [1],      'drat' => [3.77], 'cyl' => [4],  'wt' => [1.513],
  'disp' => [95.1], 'qsec' => [16.9], 'gear' => [5],
},
'Merc 230' => {
  'cyl' => [4], 'drat' => [3.92], 'gear' => [4], 'qsec' => [22.9],
  'am' => [0],  'vs' => [1],      'carb' => [2], 'disp' => [140.8],
  'hp' => [95], 'mpg' => [22.8],  'wt' => [3.15],
},
'Pontiac Firebird' => {
  'am' => [0],      'vs' => [0],     'disp' => [400],    'carb' => [2],
  'mpg' => [19.2],  'wt' => [3.845], 'hp' => [175],      'cyl' => [8],
  'drat' => [3.08], 'gear' => [3],   'qsec' => [17.05],
},
'Dodge Challenger' => {
  'mpg' => [15.5], 'wt' => [3.52],   'hp' => [150],      'disp' => [318],
  'carb' => [2],   'vs' => [0],      'am' => [0],        'qsec' => [16.87],
  'gear' => [3],   'drat' => [2.76], 'cyl' => [8],
},
'Datsun 710' => {
  'wt' => [2.32], 'disp' => [108], 'qsec' => [18.61], 'gear' => [4],
  'hp' => [93],   'mpg' => [22.8], 'carb' => [1],     'am' => [1],
  'vs' => [1],    'drat' => [3.85],'cyl' => [4],
},
'Valiant' => {
  'cyl' => [6], 'qsec' => [20.22],  'drat' => [2.76], 'gear' => [3],
  'am' => [0],  'vs' => [1],        'hp' => [105],     'mpg' => [18.1],
  'wt' => [3.46], 'carb' => [1],    'disp' => [225],
},
'Merc 240D' => {
  'disp' => [146.7], 'wt' => [3.19], 'gear' => [4], 'qsec' => [20],
  'carb' => [2],     'hp' => [62], 'mpg' => [24.4],        'vs' => [1],
  'am' => [0],       'drat' => [3.69], 'cyl' => [4],
},
'Mazda RX4 Wag' => {
  'vs' => [0],     'am' => [1],      'hp' => [110],   'mpg' => [21],
  'carb' => [4],   'cyl' => [6],     'drat' => [3.9], 'wt' => [2.875],
  'disp' => [160], 'qsec' => [17.02],'gear' => [4],
},
'Maserati Bora' => {
  'disp' => [301], 'wt' => [3.57],   'gear' => [5], 'qsec' => [14.6],
  'carb' => [8],   'hp' => [335],    'mpg' => [15], 'vs' => [0],
  'am' => [1],     'drat' => [3.54], 'cyl' => [8],
},
'Chrysler Imperial' => {
  'disp' => [440], 'wt' => [5.345], 'gear' => [3],        'qsec' => [17.42],
  'carb' => [4],   'mpg' => [14.7],   'hp' => [230],        'am' => [0],
  'vs' => [0],     'drat' => [3.23],    'cyl' => [8],
},
'Toyota Corona' => {
  'qsec' => [20.01], 'drat' => [3.7], 'gear' => [3],       'cyl' => [4],
  'wt' => [2.465],   'mpg' => [21.5], 'hp' => [97],        'disp' => [120.1],
  'carb' => [1],     'am' => [0],     'vs' => [1]
},
'Toyota Corolla' => {
  'vs' => [1],      'am' => [1],      'wt' => [1.835], 'mpg' => [33.9],
  'hp' => [65],     'disp' => [71.1], 'carb' => [1],   'cyl' => [4],
  'qsec' => [19.9], 'drat' => [4.22], 'gear' => [4],
},
'Fiat X1-9' => {
  'carb' => [1],   'hp' => [66],     'mpg' => [27.3], 'vs' => [1],
  'am' => [1],     'drat' => [4.08], 'cyl' => [4],    'disp' => [79],
  'wt' => [1.935], 'gear' => [4],    'qsec' => [18.9],
},
'Merc 450SLC' => {
  'am' => [0],   'vs' => [0],      'carb' => [3],  'disp' => [275.8],
  'hp' => [180], 'mpg' => [15.2],  'wt' => [3.78], 'cyl' => [8],
  'gear' => [3], 'drat' => [3.07], 'qsec' => [18]
},
'Honda Civic' => {
  'vs' => [1],       'am' => [1],   'hp' => [52],    'mpg' => [30.4],
  'wt' => [1.615],   'carb' => [2], 'disp' => [75.7],'cyl' => [4],
  'qsec' => [18.52], 'gear' => [4], 'drat' => [4.93]
},
'AMC Javelin' => {
  'cyl' => [8],  'drat' => [3.15], 'vs' => [0],   'am' => [0],
  'hp' => [150], 'mpg' => [15.2], 'carb' => [2],  'qsec' => [17.3],
  'gear' => [3], 'wt' => [3.435], 'disp' => [304]
},
'Volvo 142E' => {
  'drat' => [4.11], 'cyl' => [4],    'carb' => [2],  'hp' => [109],
  'mpg' => [21.4],  'vs' => [1],     'am' => [1],    'gear' => [4],
  'qsec' => [18.6], 'disp' => [121], 'wt' => [2.78]
},
'Porsche 914-2' => {
  'qsec' => [16.7], 'gear' => [5],  'drat' => [4.43], 'cyl' => [4],
  'mpg' => [26],    'wt' => [2.14], 'hp' => [91], 'disp' => [120.3],
  'carb' => [2],    'am' => [1],    'vs' => [0]
},
'Ferrari Dino' => {
  'wt' => [2.77],  'disp' => [145],  'qsec' => [15.5], 'gear' => [5],
  'mpg' => [19.7], 'hp' => [175],    'carb' => [6], 'vs' => [0],
  'am' => [1],     'drat' => [3.62], 'cyl' => [6]
},
'Hornet Sportabout' => {
  'hp' => [175],   'wt' => [3.44],   'mpg' => [18.7], 'carb' => [2],
  'disp' => [360], 'vs' => [0],    'am' => [0],  'qsec' => [17.02],
  'gear' => [3],   'drat' => [3.15], 'cyl' => [8]
},
'Fiat 128' => {
  'am' => [1],       'vs' => [1],        'mpg' => [32.4], 'wt' => [2.2],
  'hp' => [66],      'disp' => [78.7],  'carb' => [1],    'cyl' => [4],
  'qsec' => [19.47], 'gear' => [4], 'drat' => [4.08]
},
};
my $lm = lm(formula =>  'mpg ~ wt * hp^2', data => $mtcars);

no_leaks_ok {
	eval {
		lm(formula =>  'mpg ~ wt * hp^2', data => $mtcars);
	}
} 'lm: "mpg ~ wt * hp^2": no memory leaks' unless $INC{'Devel/Cover.pm'};
#p $lm;
%correct = (
	'adj.r.squared' => 0.872417,
	coefficients => {
		Intercept => 49.8084234287587,	hp        => -0.120102090978019,
		wt        => -8.21662429724302,	'wt:hp'   => 0.0278481483187383
	},
	'df.residual' => 28,
	'f.pvalue'    => 2.98094882111855e-13,
	'fitted.values' => {
		'Mazda RX4' => 23.09547, 				'Mazda RX4 Wag' => 21.78138,
		'Datsun 710'    => 25.58488, 			'Hornet 4 Drive' => 20.02924,
		'Hornet Sportabout' => 17.28996, 	Valiant             => 18.88542,
		'Duster 360'        => 15.40745, 	'Merc 240D'         => 21.65887,
		'Merc 450SE'        => 15.14994, 	'Merc 450SL'          => 16.23929,
		'Merc 450SLC'         =>16.07909, 	'Cadillac Fleetwood'  => 12.02179,
		'Lincoln Continental' =>11.89490, 	'Chrysler Imperial'   => 12.50221,
		'Fiat 128'            => 27.84866, 	'Honda Civic'   => 32.63195,
		'Toyota Corolla'   => 30.24587, 		'Toyota Corona'   => 24.56317,
		'Dodge Challenger'   => 17.57441, 	'AMC Javelin'   => 17.91776,
		'Camaro Z28'   => 15.03111, 			'Pontiac Firebird'   => 15.93596,
		'Fiat X1-9'   => 29.53900, 			'Porsche 914-2'   => 26.71871,
		'Lotus Europa'   => 28.56630, 		'Ford Pantera L'   =>15.36033,
		'Ferrari Dino'   => 19.52990, 		'Maserati Bora'   => 13.54587,
		'Volvo 142E'     => 22.31363
	},
	rank => 4,
		residuals  => {
		'AMC Javelin'        =>   -2.7177637422554,	'Cadillac Fleetwood' =>   -1.62178684578001,
		'Camaro Z28'         =>   -1.73111177599938, 'Chrysler Imperial'  =>   2.19779322930961,
		'Datsun 710'         =>   -2.78487707944995,	'Dodge Challenger'   =>   -2.07441456805362,
		'Duster 360'         =>   -1.10744532497053,	'Ferrari Dino'       =>   0.17010189824968,
		'Fiat 128'           =>   4.55133689384449,	'Fiat X1-9'           =>  -2.23900443083033,
		'Ford Pantera L'     => 0.439669246713233,	'Honda Civic'         =>  -2.23195395366212,
		'Hornet 4 Drive'     =>   1.37075604153847,	'Hornet Sportabout'  =>   1.41004478703069,
		'Lincoln Continental' =>  -1.4949003236173,	'Lotus Europa'       =>   1.83369534357951,
		'Maserati Bora'      =>   1.45413280824033,	'Mazda RX4'           =>  -2.09547410785999,
		'Mazda RX4 Wag'       =>  -0.781375472403504,'Merc 230'            =>  1.95008336608675,
		'Merc 240D'           =>  2.74113094560431,	'Merc 280'            =>  0.646212827429729,
		'Merc 280C'           =>  -0.75378717257027,	'Merc 450SE'          =>  1.25006037875687,
		'Merc 450SL'          =>  1.06071479480091,	'Merc 450SLC'         =>  -0.879087325205568,
		'Pontiac Firebird'    =>  3.26404011532368,	'Porsche 914-2'       =>  -0.718705557249944,
		'Toyota Corolla'      =>  3.65413017953585,	'Toyota Corona'       =>  -3.06317321493851,
		Valiant               =>  -0.785416091802773,'Volvo 142E'          =>  -0.913625869362747
	},
	'r.squared' => 0.8847637
);
foreach my $key ('Intercept', 'hp', 'wt', 'wt:hp') {
	unless (defined $lm->{coefficients}{$key}) {
		#p $lm;
		die "\"$key\" isn't defined" ;
	}
	is_approx( $lm->{coefficients}{$key}, $correct{coefficients}{$key}, "Checking lm's $key" );
}
foreach my $key ('adj.r.squared', 'df.residual', 'rank', 'r.squared') {
	unless (defined $lm->{$key}) {
		#p $lm;
		die "\"$key\" isn't defined" ;
	}
	is_approx( $lm->{$key}, $correct{$key}, "Checking \"$key\"");
}
foreach my $key ('fitted.values', 'residuals') {
	foreach my $car (keys %{ $correct{$key} }) {
		unless (defined $lm->{$key}{$car}) {
			#p $lm;
			die "\"$car\" isn't defined in \"fitted.values\"" ;
		}
		is_approx(
			$lm->{$key}{$car},
			$correct{$key}{$car},
			"Checking $key \"$car\"",
			10**-5
		);
	}
}
if ((defined $lm->{fstatistic}) && (ref $lm->{fstatistic} eq 'ARRAY')) {
	pass('lm: fstatistic is defined and is an array');
} else {
	fail('lm: fstatistic is either not defined or not an array');
}
my @fstat = (71.65967238215467, 3, 28);
foreach my $n (0..2) {
	if ($n == 0) {
		is_approx($lm->{fstatistic}[$n], $fstat[$n], "lm: f-statistic index $n", 1e-10);
	} else {
		is_approx($lm->{fstatistic}[$n], $fstat[$n], "lm: f-statistic index $n", 1e-14);
	}
}
$lm = lm(formula =>  'mpg ~ wt + hp', data => $mtcars);
no_leaks_ok {
	eval {
		lm(formula =>  'mpg ~ wt + hp', data => $mtcars);
	};
} 'lm: "mpg ~ wt + hp": no memory leaks' unless $INC{'Devel/Cover.pm'};
%correct = (
	'adj.r.squared' => 0.8148396,
	coefficients => {
		Intercept => 37.22727,
		hp        => -0.03177,
		wt        => -3.87783,
	},
	'f.pvalue' => 9.109e-12,
	rank => 3,
	'df.residual' => 29,
	'r.squared'   => 0.8267855,
	summary => {
		hp => {
  			Estimate      => -0.03177295,
      	'Pr(>|t|)'    => 0.0014512285315694,
       	'Std. Error'  => 0.0090297096758557,
         't value'     => -3.518712
      },
      wt => {
      	Estimate      => -3.87783074,
      	'Pr(>|t|)'    => 1.119647e-06,
       	'Std. Error'  => 0.63273349,
         't value'     => -6.128695
      },
      Intercept => {
      	Estimate      => 37.22727012,
      	'Pr(>|t|)'    => 2.565459e-20,
       	'Std. Error'  => 1.59878754,
         't value'     => 23.284689
      }
	}
);
foreach my $key ('Intercept', 'hp', 'wt') {
	unless (defined $lm->{coefficients}{$key}) {
		#p $lm;
		die "\"$key\" isn't defined" ;
	}
	is_approx(
		$lm->{coefficients}{$key},
		$correct{coefficients}{$key},
		"lm: Checking $key",
		0.1
	);
	unless (defined $lm->{summary}{$key}) {
		die "$key is missing summary";
	}
	foreach my $val ('Estimate', 'Pr(>|t|)', 'Std. Error', 't value') {
		my $e = 10**-7;
		if ($correct{summary}{$key}{$val} =~ m/\.(\d+)$/) {
			$e = 10**(2-length $1);
		}
		is_approx( $lm->{summary}{$key}{$val}, $correct{summary}{$key}{$val}, "lm: Summary $key & $val", $e);
	}
}
foreach my $key ('adj.r.squared', 'df.residual', 'f.pvalue', 'rank', 'r.squared') {
	unless (defined $lm->{$key}) {
		die "\"$key\" isn't defined" ;
	}
	my $e = 1e-7;
	my $sp = sprintf '%.3g', $correct{$key};
	if ($sp =~ m/e\-(\d+)$/) {
		$e = 10**(2-$1);
	}
	is_approx( $lm->{$key}, $correct{$key}, "lm: Checking \"$key\"", $e);
}
@fstat = (69.21121339177765, 2, 29);
foreach my $n (0..2) {
	if ($n == 0) {
		is_approx($lm->{fstatistic}[$n], $fstat[$n], "lm: f-statistic index $n", 1e-10);
	} else {
		is_approx($lm->{fstatistic}[$n], $fstat[$n], "lm: f-statistic index $n", 1e-14);
	}
}
# lm exceptions and additional tests
dies_ok {
	lm(data => $mtcars);
}
'lm: dies without a formula';
no_leaks_ok {
	eval {
		lm(data => $mtcars);
	};
} 'lm: dies without a formula and no memory leaks' unless $INC{'Devel/Cover.pm'};
#--------
dies_ok {
	lm(formula => 'mpg wt');
} 'lm: dies on bad formula lacking ~';
no_leaks_ok {
	eval {
		lm(formula => 'mpg wt');
	};
} 'lm: dies on a bad formula and no memory leaks' unless $INC{'Devel/Cover.pm'};
dies_ok {
	lm(formula => 'mpg ~ wt', data => 'not_a_hash');
} 'lm: dies when given a non-hash';

no_leaks_ok {
	eval {
		lm(formula => 'mpg ~ wt', data => 'not_a_hash') unless $INC{'Devel/Cover.pm'};
	};
} 'lm: dies on a bad formula and no memory leaks' unless $INC{'Devel/Cover.pm'};
lives_ok {                         # was dies_ok — the block is expected to succeed
    my $lm_no_int = lm(formula => 'mpg ~ wt -1', data => $mtcars);
    ok( !defined($lm_no_int->{coefficients}{Intercept}),
        'lm: formula -1 correctly suppresses Intercept' );
} 'lm: formula -1 correctly suppresses Intercept';
#-------------------------------------------------------------------
#  lm: Categorical (String) Predictors
#
#  All expected values are derived analytically from first principles
#  (OLS algebra) and cross-validated against the aov subtests above
#  where noted.  Three scenarios are covered:
#
#    1. Binary predictor (2 groups, n=3 each)
#    2. Three-level predictor (3 groups, n=3 each) — same data as the
#         "aov: One-Way ANOVA with Categorical Factor" subtest
#    3. Non-alphabetical input order — reference level must still be
#         the alphabetically first label
#-------------------------------------------------------------------

# 'lm: Binary categorical predictor (two groups)'
# R: lm(c(1,2,3,7,8,9) ~ c('ctrl','ctrl','ctrl','trt','trt','trt'))
# 'ctrl' < 'trt' alphabetically, so 'ctrl' is the reference (baseline) level.
# One dummy variable is created: 'grptrt'.
$data = {
  'y' => [1, 2, 3, 7, 8, 9],
  grp => ['ctrl', 'ctrl', 'ctrl', 'trt', 'trt', 'trt'],
};
my $lm_bin = lm(formula => 'y ~ grp', data => $data);

# 1. Dummy variable naming ------------------------------------------------
#    Only the non-reference level becomes a coefficient key.
ok(  defined $lm_bin->{coefficients}{Intercept},
  'lm cat 2-level: Intercept is defined' );
ok(  defined $lm_bin->{coefficients}{grptrt},
  'lm cat 2-level: dummy "grptrt" is created for the non-reference level' );
ok( !defined $lm_bin->{coefficients}{grpctrl},
  'lm cat 2-level: reference "grpctrl" is absent from coefficients' );

# 2. Coefficient values (exact by algebra) --------------------------------
#    Design matrix X = [[1,0],[1,0],[1,0],[1,1],[1,1],[1,1]]
#    OLS estimate = (X'X)^{-1} X'y:
#      Intercept = mean('ctrl') = (1+2+3)/3 = 2
#      grptrt    = mean('trt') - mean('ctrl') = (7+8+9)/3 - 2 = 6
is_approx( $lm_bin->{coefficients}{Intercept}, 2,
  'lm cat 2-level: Intercept = mean(ctrl) = 2', 1e-14 );
is_approx( $lm_bin->{coefficients}{grptrt}, 6,
  'lm cat 2-level: grptrt = mean(trt) - mean(ctrl) = 6', 1e-14 );

# 3. Model fit (exact fractions) ------------------------------------------
#    grand_mean = 5
#    SS_between = 3*(2-5)^2 + 3*(8-5)^2 = 27 + 27 = 54
#    SS_res     = (1-2)^2+0+(3-2)^2 + (7-8)^2+0+(9-8)^2 = 4
#    SS_total   = 16+9+4+4+9+16 = 58
#    r.squared     = 54/58 = 27/29
#    adj.r.squared = 1 - (SS_res/df_res)/(SS_total/df_total)
#                  = 1 - (4/4)/(58/5) = 1 - 5/58 = 53/58
is_approx( $lm_bin->{'r.squared'}, 27/29,
  'lm cat 2-level: r.squared = 27/29', 1e-7 );
is_approx( $lm_bin->{'adj.r.squared'}, 53/58,
  'lm cat 2-level: adj.r.squared = 53/58', 1e-7 );
is_approx( $lm_bin->{'df.residual'}, 4,
  'lm cat 2-level: df.residual = n - rank = 6 - 2 = 4', 1e-14 );
is_approx( $lm_bin->{'rank'}, 2,
  'lm cat 2-level: rank = 2 (Intercept + 1 dummy)', 1e-14 );

# 4. F-statistic ----------------------------------------------------------
#    F = (SS_reg/df_reg) / (SS_res/df_res) = (54/1) / (4/4) = 54 on (1, 4) df
#    f.pvalue = I(df2/(df2+df1*F); df2/2, df1/2)
#             = I(4/58; 2, 0.5)
#             = 1 - (3/2)*sqrt(27/29) + (1/2)*(27/29)^(3/2)
#             = 0.0018262607...   [verified analytically in Perl]
if ( (defined $lm_bin->{fstatistic}) && (ref $lm_bin->{fstatistic} eq 'ARRAY') ) {
  pass('lm cat 2-level: fstatistic is defined and is an array');
} else {
  fail('lm cat 2-level: fstatistic is defined and is an array');
}
is_approx( $lm_bin->{fstatistic}[0], 54,
  'lm cat 2-level: F statistic = 54', 1e-14 );
is_approx( $lm_bin->{fstatistic}[1],  1,
  'lm cat 2-level: F numerator df = 1', 1e-14 );
is_approx( $lm_bin->{fstatistic}[2],  4,
  'lm cat 2-level: F denominator df = 4', 1e-14 );
is_approx( $lm_bin->{'f.pvalue'}, 0.0018262607,
  'lm cat 2-level: f.pvalue = I(4/58;2,0.5)', 1e-7 );

# 5. Summary table --------------------------------------------------------
#    MS_res = SS_res / df_res = 4/4 = 1
#    (X'X)^{-1} = [[1/3,-1/3],[-1/3,2/3]]  (det(X'X)=9)
#
#    SE(Intercept) = sqrt(MS_res * 1/3) = 1/sqrt(3)
#    SE(grptrt)    = sqrt(MS_res * 2/3) = sqrt(2/3)
#    t(Intercept)  = 2 / (1/sqrt(3)) = 2*sqrt(3)
#    t(grptrt)     = 6 / sqrt(2/3)   = 6*sqrt(3/2)
#
#    p(Intercept): 2*pt(-2*sqrt(3), df=4) = I(4/16; 2, 0.5)
#                = 1 - (3/2)*sqrt(3/4) + (1/2)*(3/4)^(3/2) = 0.0257214207...
#    p(grptrt):   equals f.pvalue (single predictor, F = t^2)
#                = 0.0018262607...
is_approx( $lm_bin->{summary}{Intercept}{Estimate}, 2,
  'lm cat 2-level: summary Estimate(Intercept) = 2', 1e-14 );
is_approx( $lm_bin->{summary}{grptrt}{Estimate}, 6,
  'lm cat 2-level: summary Estimate(grptrt) = 6', 1e-14 );
is_approx( $lm_bin->{summary}{Intercept}{'Std. Error'}, 1/sqrt(3),
  'lm cat 2-level: SE(Intercept) = 1/sqrt(3)', 1e-7 );
is_approx( $lm_bin->{summary}{grptrt}{'Std. Error'}, sqrt(2/3),
  'lm cat 2-level: SE(grptrt) = sqrt(2/3)', 1e-7 );
is_approx( $lm_bin->{summary}{Intercept}{'t value'}, 2*sqrt(3),
  'lm cat 2-level: t(Intercept) = 2*sqrt(3)', 1e-7 );
is_approx( $lm_bin->{summary}{grptrt}{'t value'}, 6*sqrt(3/2),
  'lm cat 2-level: t(grptrt) = 6*sqrt(3/2)', 1e-7 );
is_approx( $lm_bin->{summary}{Intercept}{'Pr(>|t|)'}, 0.0257214207,
  'lm cat 2-level: p(Intercept) = I(1/4;2,0.5)', 1e-7 );
is_approx( $lm_bin->{summary}{grptrt}{'Pr(>|t|)'}, 0.0018262607,
  'lm cat 2-level: p(grptrt) = f.pvalue (single predictor)', 1e-7 );

no_leaks_ok {
  eval { lm(formula => 'y ~ grp', data => $data) };
} 'lm cat 2-level: no memory leaks' unless $INC{'Devel/Cover.pm'};

#'lm: Three-level categorical predictor (cross-validated against aov)'
# Uses the same data as the 'aov: One-Way ANOVA with Categorical Factor' subtest.
# R: lm(yield_val ~ group) — reference level is 'A' (alphabetically first).
# Two dummy variables are created: 'groupB' and 'groupC'.
my $data = {
  yield_val => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2, 6.1, 6.5, 6.2],
  group     => ['A', 'A', 'A', 'B', 'B', 'B', 'C', 'C', 'C'],
};
my $lm_3 = lm(formula => 'yield_val ~ group', data => $data);

# 1. Dummy variable naming ------------------------------------------------
ok(  defined $lm_3->{coefficients}{Intercept},
  'lm cat 3-level: Intercept is defined' );
ok(  defined $lm_3->{coefficients}{groupB},
  'lm cat 3-level: dummy "groupB" is created' );
ok(  defined $lm_3->{coefficients}{groupC},
  'lm cat 3-level: dummy "groupC" is created' );
ok( !defined $lm_3->{coefficients}{groupA},
  'lm cat 3-level: reference "groupA" is absent from coefficients' );

# 2. Coefficient values (exact by algebra) --------------------------------
#    Intercept = mean(A) = (5.5+5.4+5.8)/3 = 16.7/3 = 5.5666̄
#    groupB    = mean(B) - mean(A) = 4.5 - 16.7/3  = -1.0666̄
#    groupC    = mean(C) - mean(A) = 18.8/3 - 16.7/3 = 2.1/3 = 0.7
is_approx( $lm_3->{coefficients}{Intercept}, 16.7/3,
  'lm cat 3-level: Intercept = mean(A) = 16.7/3', 1e-10 );
is_approx( $lm_3->{coefficients}{groupB}, 4.5 - 16.7/3,
  'lm cat 3-level: groupB = mean(B) - mean(A)', 1e-10 );
is_approx( $lm_3->{coefficients}{groupC}, 2.1/3,
  'lm cat 3-level: groupC = mean(C) - mean(A) = 2.1/3 = 0.7', 1e-10 );

# 3. Model fit (exact fractions) ------------------------------------------
#    mean(A)=16.7/3, mean(B)=4.5, mean(C)=18.8/3; grand_mean=49/9
#    SS_group  = 3*(11/90)^2 + 3*(17/18)^2 + 3*(37/45)^2
#              = (363+21675+16428)/8100 = 38466/8100 = 2137/450
#    SS_res    = 0.0867 + 0.18 + 0.0867 = 53/150
#    SS_total  = 2137/450 + 53/150 = 2296/450 = 1148/225
#    r.squared     = 2137/2296
#    adj.r.squared = 1 - (53/900)/(1148/1800) = 1 - 53/574 = 521/574
is_approx( $lm_3->{'r.squared'}, 2137/2296,
  'lm cat 3-level: r.squared = 2137/2296', 1e-7 );
is_approx( $lm_3->{'adj.r.squared'}, 521/574,
  'lm cat 3-level: adj.r.squared = 521/574', 1e-7 );
is_approx( $lm_3->{'df.residual'}, 6,
  'lm cat 3-level: df.residual = n - rank = 9 - 3 = 6', 1e-14 );
is_approx( $lm_3->{'rank'}, 3,
  'lm cat 3-level: rank = 3 (Intercept + 2 dummies)', 1e-14 );

# 4. F-statistic (cross-validated against aov One-Way result) --------------
#    MS_group = SS_group/2 = 2137/900; MS_res = SS_res/6 = 53/900
#    F = MS_group/MS_res = 2137/53 / 2 = 40.3207547169811...
#    f.pvalue = (df2/(df2+df1*F))^(df2/2) = (6/86.641...)^3 = 0.0003319084
#              [same value as aov Pr(>F) for 'group', verified in R]
if ( (defined $lm_3->{fstatistic}) && (ref $lm_3->{fstatistic} eq 'ARRAY') ) {
  pass('lm cat 3-level: fstatistic is defined and is an array');
} else {
  fail('lm cat 3-level: fstatistic is defined and is an array');
}
is_approx( $lm_3->{fstatistic}[0], 40.3207547169811,
  'lm cat 3-level: F value matches aov One-Way result', 1e-7 );
is_approx( $lm_3->{fstatistic}[1], 2,
  'lm cat 3-level: F numerator df = k - 1 = 2', 1e-14 );
is_approx( $lm_3->{fstatistic}[2], 6,
  'lm cat 3-level: F denominator df = n - k = 6',1e-14 );
is_approx( $lm_3->{'f.pvalue'}, 0.0003319084,
  'lm cat 3-level: f.pvalue matches aov Pr(>F)', 5e-6 );

# 5. Summary table --------------------------------------------------------
#    MS_res = 53/900.
#    (X'X)^{-1} for balanced 3-group design (det=27):
#      diag = [1/3, 2/3, 2/3]   (off-diag elements not needed for SE)
#
#    SE(Intercept) = sqrt(MS_res * 1/3) = sqrt(53/2700)  ≈ 0.140106
#    SE(groupB)    = sqrt(MS_res * 2/3) = sqrt(53/1350)  ≈ 0.198139
#    SE(groupC)    = sqrt(MS_res * 2/3) = sqrt(53/1350)  ≈ 0.198139
#
#    t(Intercept)  = (16.7/3) / sqrt(53/2700) ≈  39.732
#    t(groupB)     = (4.5-16.7/3) / sqrt(53/1350) ≈  -5.383
#    t(groupC)     = (2.1/3)      / sqrt(53/1350) ≈   3.533
#
#    p-value bounds (df=6): t_{6,0.005}=3.707, t_{6,0.002}≈5.208
#      p(groupB): |t|=5.38 > 5.208 → p < 0.005
#      p(groupC): |t|=3.53, between t_{6,0.02} and t_{6,0.01} → p < 0.02
is_approx( $lm_3->{summary}{Intercept}{Estimate}, 16.7/3,
  'lm cat 3-level: summary Estimate(Intercept)', 1e-10 );
is_approx( $lm_3->{summary}{groupB}{Estimate}, 4.5 - 16.7/3,
  'lm cat 3-level: summary Estimate(groupB)', 1e-10 );
is_approx( $lm_3->{summary}{groupC}{Estimate}, 2.1/3,
  'lm cat 3-level: summary Estimate(groupC)', 1e-10 );
is_approx( $lm_3->{summary}{Intercept}{'Std. Error'}, sqrt(53/2700),
  'lm cat 3-level: SE(Intercept) = sqrt(53/2700)', 1e-7 );
is_approx( $lm_3->{summary}{groupB}{'Std. Error'}, sqrt(53/1350),
  'lm cat 3-level: SE(groupB) = sqrt(53/1350)', 1e-7 );
is_approx( $lm_3->{summary}{groupC}{'Std. Error'}, sqrt(53/1350),
  'lm cat 3-level: SE(groupC) = sqrt(53/1350)', 1e-7 );
is_approx( $lm_3->{summary}{Intercept}{'t value'},
  (16.7/3) / sqrt(53/2700),
  'lm cat 3-level: t(Intercept)', 1e-5 );
is_approx( $lm_3->{summary}{groupB}{'t value'},
  (4.5 - 16.7/3) / sqrt(53/1350),
  'lm cat 3-level: t(groupB)', 1e-5 );
is_approx( $lm_3->{summary}{groupC}{'t value'},
  (2.1/3) / sqrt(53/1350),
  'lm cat 3-level: t(groupC)', 1e-5 );
ok( $lm_3->{summary}{groupB}{'Pr(>|t|)'} < 0.005,
  'lm cat 3-level: p(groupB) < 0.005  (|t|=5.38 > t_{6,0.002}=5.208)' );
ok( $lm_3->{summary}{groupC}{'Pr(>|t|)'} < 0.02,
  'lm cat 3-level: p(groupC) < 0.02   (|t|=3.53, between t_{6,0.01} and t_{6,0.02})' );

no_leaks_ok {
  eval { lm(formula => 'yield_val ~ group', data => $data) };
} 'lm cat 3-level: no memory leaks' unless $INC{'Devel/Cover.pm'};


# 'lm: Reference level is alphabetically first regardless of input order' => sub {
# Observations arrive in C/A/B order, but the reference level must be 'A'
# (sorted alphabetically), so dummies are 'grpB' and 'grpC', not 'grpA'.
# R: lm(c(8,9,10,1,2,3,5,6,7) ~ c('C','C','C','A','A','A','B','B','B'))
$data = {
  'y' => [8, 9, 10, 1, 2, 3, 5, 6, 7],
  grp => ['C', 'C', 'C', 'A', 'A', 'A', 'B', 'B', 'B'],
};
my $lm_ref = lm(formula => 'y ~ grp', data => $data);

# 1. Dummy variable naming ------------------------------------------------
#    'A' < 'B' < 'C' alphabetically → 'A' is the reference.
ok(  defined $lm_ref->{coefficients}{Intercept},
  'lm cat ref-level: Intercept is defined' );
ok(  defined $lm_ref->{coefficients}{grpB},
  'lm cat ref-level: dummy "grpB" is created' );
ok(  defined $lm_ref->{coefficients}{grpC},
  'lm cat ref-level: dummy "grpC" is created' );
ok( !defined $lm_ref->{coefficients}{grpA},
  'lm cat ref-level: "grpA" is absent — it is the reference level' );

# 2. Coefficient values (exact by algebra) --------------------------------
#    Intercept = mean(A) = (1+2+3)/3 = 2
#    grpB      = mean(B) - mean(A) = (5+6+7)/3 - 2 = 6 - 2 = 4
#    grpC      = mean(C) - mean(A) = (8+9+10)/3 - 2 = 9 - 2 = 7
is_approx( $lm_ref->{coefficients}{Intercept}, 2,
  'lm cat ref-level: Intercept = mean(A) = 2', 1e-14 );
is_approx( $lm_ref->{coefficients}{grpB}, 4,
  'lm cat ref-level: grpB = mean(B) - mean(A) = 4', 1e-14 );
is_approx( $lm_ref->{coefficients}{grpC}, 7,
  'lm cat ref-level: grpC = mean(C) - mean(A) = 7', 1e-14 );

# 3. Model fit (exact fractions) ------------------------------------------
#    grand_mean = 51/9 = 17/3
#    SS_between: 3*(2-17/3)^2 + 3*(6-17/3)^2 + 3*(9-17/3)^2
#              = 3*(11/3)^2 + 3*(1/3)^2 + 3*(10/3)^2
#              = (363 + 3 + 300)/9 = 666/9 = 74
#    SS_res: within-group SS for three consecutive-integer triples
#              = 2 + 2 + 2 = 6
#    SS_total  = 74 + 6 = 80
#    r.squared     = 74/80 = 37/40 = 0.925
#    adj.r.squared = 1 - (6/6)/(80/8) = 1 - 1/10 = 9/10 = 0.9
is_approx( $lm_ref->{'r.squared'}, 37/40,
  'lm cat ref-level: r.squared = 37/40 = 0.925', 1e-7 );
is_approx( $lm_ref->{'adj.r.squared'}, 9/10,
  'lm cat ref-level: adj.r.squared = 9/10 = 0.9', 1e-7 );
is_approx( $lm_ref->{'df.residual'}, 6,
  'lm cat ref-level: df.residual = n - rank = 9 - 3 = 6', 1e-14 );
is_approx( $lm_ref->{'rank'}, 3,
  'lm cat ref-level: rank = 3 (Intercept + 2 dummies)', 1e-14 );

# 4. F-statistic ----------------------------------------------------------
#    F = (SS_between/df_between) / (SS_res/df_res)
#      = (74/2) / (6/6) = 37  on (2, 6) df
#
#    f.pvalue = I(df2/(df2+df1*F); df2/2, df1/2)
#             = I(6/80; 3, 1)
#             = (6/80)^3           [since I(x;3,1) = x^3]
#             = (3/40)^3 = 27/64000 = 0.000421875  (exact)
if ( (defined $lm_ref->{fstatistic}) && (ref $lm_ref->{fstatistic} eq 'ARRAY') ) {
  pass('lm cat ref-level: fstatistic is defined and is an array');
} else {
  fail('lm cat ref-level: fstatistic is defined and is an array');
}
is_approx( $lm_ref->{fstatistic}[0], 37,
  'lm cat ref-level: F = (74/2)/(6/6) = 37', 1e-14 );
is_approx( $lm_ref->{fstatistic}[1], 2,
  'lm cat ref-level: F numerator df = k - 1 = 2', 1e-14 );
is_approx( $lm_ref->{fstatistic}[2], 6,
  'lm cat ref-level: F denominator df = n - k = 6', 1e-14 );
is_approx( $lm_ref->{'f.pvalue'}, 27/64000,
  'lm cat ref-level: f.pvalue = (3/40)^3 = 27/64000 (exact)', 1e-9 );

# 5. Summary table --------------------------------------------------------
#    MS_res = SS_res / df_res = 6/6 = 1
#    (X'X)^{-1} for balanced 3-group design (same structure as subtest 2):
#      diag = [1/3, 2/3, 2/3]
#
#    SE(Intercept) = sqrt(MS_res * 1/3) = 1/sqrt(3)    ≈ 0.577350
#    SE(grpB)      = sqrt(MS_res * 2/3) = sqrt(2/3)    ≈ 0.816497
#    SE(grpC)      = sqrt(MS_res * 2/3) = sqrt(2/3)    ≈ 0.816497
#    t(Intercept)  = 2 / (1/sqrt(3))   = 2*sqrt(3)     ≈ 3.464102
#    t(grpB)       = 4 / sqrt(2/3)     = 4*sqrt(3/2)   ≈ 4.898979
#    t(grpC)       = 7 / sqrt(2/3)     = 7*sqrt(3/2)   ≈ 8.573214
#
#    p-value bounds (df=6): t_{6,0.001}=5.959
#      p(grpB): |t|=4.90, between t_{6,0.01} and t_{6,0.001} → p < 0.01
#      p(grpC): |t|=8.57 > t_{6,0.001}=5.959              → p < 0.001
is_approx( $lm_ref->{summary}{Intercept}{Estimate}, 2,
  'lm cat ref-level: summary Estimate(Intercept) = 2', 1e-14 );
is_approx( $lm_ref->{summary}{grpB}{Estimate}, 4,
  'lm cat ref-level: summary Estimate(grpB) = 4', 1e-14 );
is_approx( $lm_ref->{summary}{grpC}{Estimate}, 7,
  'lm cat ref-level: summary Estimate(grpC) = 7', 1e-14 );
is_approx( $lm_ref->{summary}{Intercept}{'Std. Error'}, 1/sqrt(3),
  'lm cat ref-level: SE(Intercept) = 1/sqrt(3)', 1e-7 );
is_approx( $lm_ref->{summary}{grpB}{'Std. Error'}, sqrt(2/3),
  'lm cat ref-level: SE(grpB) = sqrt(2/3)', 1e-7 );
is_approx( $lm_ref->{summary}{grpC}{'Std. Error'}, sqrt(2/3),
  'lm cat ref-level: SE(grpC) = sqrt(2/3)', 1e-7 );
is_approx( $lm_ref->{summary}{Intercept}{'t value'}, 2*sqrt(3),
  'lm cat ref-level: t(Intercept) = 2*sqrt(3)', 1e-7 );
is_approx( $lm_ref->{summary}{grpB}{'t value'}, 4*sqrt(3/2),
  'lm cat ref-level: t(grpB) = 4*sqrt(3/2)', 1e-7 );
is_approx( $lm_ref->{summary}{grpC}{'t value'}, 7*sqrt(3/2),
  'lm cat ref-level: t(grpC) = 7*sqrt(3/2)', 1e-7 );
ok( $lm_ref->{summary}{grpB}{'Pr(>|t|)'} < 0.01,
  'lm cat ref-level: p(grpB) < 0.01   (|t|=4.90, df=6)' );
ok( $lm_ref->{summary}{grpC}{'Pr(>|t|)'} < 0.001,
  'lm cat ref-level: p(grpC) < 0.001  (|t|=8.57 > t_{6,0.001}=5.959)' );

no_leaks_ok {
  eval { lm(formula => 'y ~ grp', data => $data) };
} 'lm cat ref-level: no memory leaks';
#---------------------------
#   rnorm
#----------------------------
my ($rmean, $sd, $n) = (10, 2, 9999);
my $normals = rnorm( n => $n, mean => $rmean, sd => $sd);
no_leaks_ok {
	rnorm( n => $n, mean => $rmean, sd => $sd);
} 'rnorm has no memory leaks' unless $INC{'Devel/Cover.pm'};
is_approx(scalar @{ $normals }, $n, 'rnorm sample size');
is_approx(mean($normals), $rmean, 'rnorm mean', 0.1);
is_approx(sd($normals), $sd, 'rnorm sd', 0.1);
# rnorm exceptions
eval { rnorm(n => 10, sd => -1) };
like( $@, qr/standard deviation must be non-negative/, 'rnorm: dies on negative sd' );

#eval { rnorm(n => 10, mean => 0, 'missing_value_key') };
#like( $@, qr/must be even key\/value pairs/, 'rnorm: dies on odd argument count' );
#----------------------
#    quantile
#----------------------
my $quantile = quantile('x' => [1..99], probs => [0.05, 0.1, 0.25]);
no_leaks_ok {
	quantile('x' => [1..99], probs => [0.05, 0.1, 0.25]);
} 'quantile has no memory leaks' unless $INC{'Devel/Cover.pm'};
# R equivalent: quantile(1:99, probs=c(0.01,0.1,0.25))
@ans = (5.9, 10.80, 25.50);
my @quantile_keys = ('5%', '10%', '25%');
foreach my $idx (0..$#ans) {
	is_approx($quantile->{$quantile_keys[$idx]}, $ans[$idx], "quantile: $quantile_keys[$idx]", 10**-14);
}
# works without "x" argument
quantile([1..99], probs => [0.05, 0.1, 0.25]);
no_leaks_ok {
	quantile([1..99], probs => [0.05, 0.1, 0.25]);
} 'quantile has no memory leaks' unless $INC{'Devel/Cover.pm'};
# R equivalent: quantile(1:99, probs=c(0.01,0.1,0.25))
foreach my $idx (0..$#ans) {
	is_approx($quantile->{$quantile_keys[$idx]}, $ans[$idx], "quantile: $quantile_keys[$idx]", 10**-14);
}
$quantile = quantile([1..5], probs => [0,1]);
if (($quantile->{'0%'} == 1) && ($quantile->{'100%'} == 5)) {
	pass('quantile: boundaries return min and max');
} else {
	fail('quantile: boundaries do NOT return min and max');
}
$quantile = quantile([3], probs => [0.33]);
if ($quantile->{'33%'} == 3) {
	pass('single element to quantile returns that element');
} else {
	fail('single element to quantile fails to return that element');
}
# quantile also works without "x => " to simplify
#----------------------
#    Fisher's Test
#----------------------
my $ft = fisher_test([[10, 2],[3, 15]]);
# R equivalent: fisher.test( matrix(c(10,2,3,15), nrow = 2)))
is_approx( 0.00053672411914344, $ft->{p_value}, 'Fisher\'s test p-value', 10**-15);
my $conf_int_range = abs $ft->{conf_int}[0] - $ft->{conf_int}[1];
my $correct_conf_int_range = 301.462337971516 - 2.75338278824932;
if ((0.99*$correct_conf_int_range < $conf_int_range) && ($conf_int_range < 1.01* $correct_conf_int_range)) {
	pass('Fisher\'s test is within 1% of correct: ');
} else {
	fail('Fisher\'s test is *NOT* within 1% of correct: ');
}
is_approx( $ft->{estimate}{'odds ratio'}, 21.30533, 'Fisher\'s test odds ratio', 10**-3);
no_leaks_ok {
	eval {
		fisher_test([[10, 2],[3, 15]]);
	}
} 'Fisher\'s test with array: no leaks' unless $INC{'Devel/Cover.pm'};
#---------
$ft = fisher_test( {
	Guess => {
		Milk => 3, Tea => 1
	},
	Truth => {
		Milk => 1, Tea => 3
	}
});
is_approx($ft->{'p_value'}, 0.48571428571429, 'Fisher Test: hash input p-value', 1e-14);
$conf_int_range = abs $ft->{conf_int}[0] - $ft->{conf_int}[1];
$correct_conf_int_range = 621.9337505 - 0.2117329;
if ((0.99*$correct_conf_int_range < $conf_int_range) && ($conf_int_range < 1.01* $correct_conf_int_range)) {
	pass('Fisher\'s test is within 1% of correct: ');
} else {
	fail('Fisher\'s test is *NOT* within 1% of correct: ');
}
is_approx( $ft->{estimate}{'odds ratio'}, 6.408309, 'Fisher\'s hash input test odds ratio', 10**-3);
no_leaks_ok {
	eval {
		fisher_test( {
			Guess => {
				Milk => 3, Tea => 1
			},
			Truth => {
				Milk => 1, Tea => 3
			}
		});
	}
} 'Fisher\'s test with hash: no leaks' unless $INC{'Devel/Cover.pm'};
#-------
$ft = fisher_test( {
	Guess => {
		Milk => 3, Tea => 1
	},
	Truth => {
		Milk => 1, Tea => 3
	}
}, alternative => 'greater');
is_approx($ft->{'p_value'}, 0.24285714285714, 'Fisher Test: hash input p-value with alternative = "greater"', 1e-14);
is_approx($ft->{conf_int}[0], 0.3135693, 'Fisher test hash input with greater alternative', 10**-4 );
if ($ft->{conf_int}[1] == 'inf') {
	pass('Fisher test: Upper confidence interval is infinite');
} else {
	fail('Fisher test: Upper confidence interval is NOT infinite');
}
no_leaks_ok {
	eval {
		fisher_test( {
			Guess => {
				Milk => 3, Tea => 1
			},
			Truth => {
				Milk => 1, Tea => 3
			}
		}, alternative => 'greater');
	}
} 'Fisher\'s test with hash and "greater" alternative: no leaks' unless $INC{'Devel/Cover.pm'};
$ft = fisher_test( { # taste.ft.less in my Rdata file
	Guess => {
		Milk => 3, Tea => 1
	},
	Truth => {
		Milk => 1, Tea => 3
	}
}, alternative => 'less');
is_approx($ft->{p_value}, 0.98571428571429, 'fisher_test: alternative="less" p.value', 1e-10);
is_approx($ft->{estimate}{'odds ratio'}, 6.40830886700579, 'fisher_test: alternative="less" odds ratio', 1e-4);
$conf_int_range = abs $ft->{conf_int}[0] - $ft->{conf_int}[1];
$correct_conf_int_range = 306.2469 - 0.0000;
if ((0.99*$correct_conf_int_range < $conf_int_range) && ($conf_int_range < 1.01* $correct_conf_int_range)) {
	pass('Fisher\'s test with alternative less confidence interval is within 1% of correct');
} else {
	fail('Fisher\'s test with alternative less confidence interval is *NOT* within 1% of correct');
}

dies_ok {
	fisher_test();
} 'fisher_test: requires a data reference';
$ft = fisher_test([[5, 0], [1, 4]]); # in the R data file, "ft.zero"
is_approx($ft->{p_value}, 0.04761904761905, 'fisher_test: zero inside: p-value', 1e-13);
if ($ft->{estimate}{'odds ratio'} == 'inf') {
	pass('fisher_test: odds ratio with 0 in input is infinite');
} else {
	fail('fisher_test: odds ratio with 0 input is NOT infinite');
}
#----------------------
#    hist
#----------------------
# 1. Basic properties with a simple dataset
# Data: 1, 2, 2, 3, 3, 3, 4, 4, 5 (9 elements)
my $h_data = [1, 2, 2, 3, 3, 3, 4, 4, 5];
my $breaks = 4;
my $res = hist($h_data, breaks => $breaks);
is(ref $res, 'HASH', 'hist: returns a hash reference');
is(scalar @{$res->{counts}}, $breaks, 'hist: correct number of bins (counts)');
is(scalar @{$res->{breaks}}, $breaks+1, 'hist: correct number of breaks (n+1)');
is(scalar @{$res->{mids}},   $breaks, 'hist: correct number of midpoints');

# 2. Verify counts sum to total elements
my $total_counts = 0;
$total_counts += $_ for @{$res->{counts}};
is($total_counts, scalar @$h_data, 'hist: sum of counts matches input size');

# 3. Verify midpoints are mathematically correct
my $mid_ok = 1;
for my $i (0 .. $#{$res->{mids}}) {
  my $expected_mid = ($res->{breaks}->[$i] + $res->{breaks}->[$i+1]) / 2;
  $mid_ok = 0 if abs($res->{mids}->[$i] - $expected_mid) > 1e-12;
}
ok($mid_ok, 'hist: midpoints are correctly calculated between breaks');

# 4. Density check: Total area (sum of density * bin_width) must be 1
my $area = 0;
for my $i (0 .. $#{$res->{counts}}) {
  my $width = $res->{breaks}->[$i+1] - $res->{breaks}->[$i];
  $area += $res->{density}->[$i] * $width;
}
ok(abs($area - 1.0) < 1e-12, 'hist: total area under density curve is 1.0');

# 5. Test with a single value (Edge case)
my $single = hist([10], breaks => 1);
is($single->{counts}->[0], 1, 'hist: handles single-element array');
is($single->{breaks}->[0], 10, 'hist: single-element break starts at value');

#-------------------------------------------------------------------
#  Performance & Edge Cases for hist()
#-------------------------------------------------------------------
#subtest 'hist: O(N) Performance and Edge Cases' => sub {
# 1. Test standard binning boundaries
# Data spans 0 to 10 exactly.
$data = [0, 2.5, 4.9, 5.0, 7.5, 10];
$res = hist($data, breaks => 2);

# With 2 bins spanning 0 to 10, step is 5.
# Bin 0: [0, 5] -> should capture 0, 2.5, 4.9, 5.0 (4 items)
# Bin 1: (5, 10] -> should capture 7.5, 10 (2 items)
is_deeply($res->{counts}, [4, 2], 'hist: correctly assigns boundary values in O(N) logic');
is_deeply($res->{breaks}, [0, 5, 10], 'hist: correct breaks generation');

# 2. Test zero-variance edge case (all identical values)
my $flat_data = [7, 7, 7, 7, 7];
my $flat_res = hist($flat_data, breaks => 1);

is($flat_res->{counts}->[0], 5, 'hist: properly handles flatline data (step = 0)');
is($flat_res->{density}->[0], 1, 'hist: density is 1.0 for a single zero-width bin');

# 3. Scale test: Generate a slightly larger array to ensure no memory segfaults
# and quick processing.
my @large_uniform = seq(1, 1000, 0.5); 
my $large_res = hist(\@large_uniform, breaks => 10);

my $total_counted = 0;
$total_counted += $_ for @{ $large_res->{counts} };

is($total_counted, scalar @large_uniform, 'hist: sum of counts perfectly matches input size on larger datasets');
#----------------------
#    hist exceptions
#----------------------
	# Should die if not an array ref
dies_ok { hist("not an array") } 'hist: dies on string input';
dies_ok { hist({ a => 1 }) }     'hist: dies on hash ref input';
# Should die on empty array
dies_ok { hist([]) }             'hist: dies on empty array ref';
# Should die on non-numeric data (depending on your SVNV strictness)
dies_ok { hist([qw(a b c)]) }    'hist: dies on non-numeric array content';
#----------------------
#   runif
#----------------------
my $unif = runif( n => $n, min => 0, max => 1);
if (scalar @{ $unif } == $n) {
	pass('runif: random uniform distribution has the correct # of elements');
} else {
	fail('runif: random uniform distribution does NOT have the correct # of elements');
}
#---------------
# runif
#---------------
is_approx( min(@{ $unif }), 0, 'Approximately correct minimum', 10**-3);
is_approx( max(@{ $unif }), 1, 'Approximately correct maximum', 10**-3);
{
	my $unif2 = runif( n => $n, min => 0, max => 1);
	my @identical_idx = grep { $unif->[$_] == $unif2->[$_] } 0..$n-1;
	if (scalar @identical_idx == 0) {
		pass('runif does not repeat');
	} else { # > 1 identical value
		fail('runif repeats ' . scalar @identical_idx . "/$n values");
	}
}
no_leaks_ok {
	eval {
		runif( n => $n, min => 0, max => 1);
	};
} 'runif: no memory leaks with named args' unless $INC{'Devel/Cover.pm'};
#single arg
$unif = runif(9);
if (scalar @{ $unif } == 9) {
	pass('runif: random uniform distribution has the correct # of elements');
} else {
	fail('runif: random uniform distribution does NOT have the correct # of elements');
}
no_leaks_ok {
	eval {
		runif( 9 );
	};
} 'runif: no memory leaks with single arg' unless $INC{'Devel/Cover.pm'};
# positional args
$unif = runif(9, 0, 99);
if (scalar @{ $unif } == 9) {
	pass('runif: random uniform distribution has the correct # of elements');
} else {
	fail('runif: random uniform distribution does NOT have the correct # of elements');
}
no_leaks_ok {
	eval {
		runif( 9, 0, 99 );
	};
} 'runif: no memory leaks with positional args' unless $INC{'Devel/Cover.pm'};
#----------------------
#      rbinom
#----------------------
my $binom = rbinom( n => $n, prob => 0.5, size => 9);
if (scalar @{ $binom } == $n) {
	pass('binom has the correct # of elements');
} else {
	fail("binom should have $n elements, but has " . scalar @{ $binom } . ' elements');
}
no_leaks_ok {
	eval {
		rbinom( n => $n, prob => 0.5, size => 9);
	};
} 'rbinom: no memory leaks' unless $INC{'Devel/Cover.pm'};
eval { rbinom(n => 10, size => 10) };
like( $@, qr/'size' and 'prob' are required arguments/, 'rbinom: dies when prob is missing' );

dies_ok {
	rbinom(n => 10, prob => 0.5)
} 'qr/"size" and "prob" are required arguments: rbinom: dies when size is missing';

dies_ok {
	rbinom(n => 10, size => 10, prob => 1.5)
} 'qr/prob must be between 0 and 1: rbinom: dies when prob > 1';

dies_ok {
	rbinom(n => 10, size => 10, prob => -0.1) 
} 'qr/prob must be between 0 and 1: rbinom: dies when prob < 0';
dies_ok {
	rbinom(n => 10, size => 10, prob => 0.5, 'extra_arg');
} 'rbinom: dies on odd argument count';

# 'rbinom: Edge Cases (Deterministic)'
my $n_edge = 100;
# Prob = 0 should strictly return 0
my $binom_p = rbinom(n => $n_edge, size => 10, prob => 0);
is_approx( max($binom_p), 0, 'rbinom: prob=0 always returns 0' );
is_approx( min($binom_p), 0, 'rbinom: prob=0 always returns 0' );

# Prob = 1 should strictly return 'size'
$binom_p = rbinom(n => $n_edge, size => 15, prob => 1);
is_approx( min($binom_p), 15, 'rbinom: prob=1 always returns size' );
is_approx( max($binom_p), 15, 'rbinom: prob=1 always returns size' );

# Size = 0 should strictly return 0
$binom_p = rbinom(n => $n_edge, size => 0, prob => 0.5);
is_approx( max($binom_p), 0, 'rbinom: size=0 always returns 0' );

my $n_stat = 10000;
my $size   = 20;
my $prob   = 0.3;
my $binom_stats = rbinom(n => $n_stat, size => $size, prob => $prob);

is_approx( scalar @{ $binom_stats }, $n_stat, 'rbinom: returns correct number of elements' );

my $expected_mean = $size * $prob;
my $expected_var  = $size * $prob * (1 - $prob);

# Allow a small epsilon (margin of error) for stochasticity
is_approx( mean($binom_stats), $expected_mean, 'rbinom: empirical mean matches theoretical mean', 0.1 );
is_approx( var($binom_stats), $expected_var, 'rbinom: empirical variance matches theoretical variance', 0.5 );

# 'rbinom: Randomness' 
my $n_rand = 100;
my $binom_1 = rbinom(n => $n_rand, size => 10, prob => 0.5);
my $binom_2 = rbinom(n => $n_rand, size => 10, prob => 0.5);

my @identical_idx = grep { $binom_1->[$_] == $binom_2->[$_] } 0..($n_rand-1);

if (scalar @identical_idx < $n_rand) {
	pass('rbinom: consecutive calls generate different non-repeating sequences');
} else {
	fail('rbinom: consecutive calls generated identical arrays (PRNG state not updating)');
}
#----------------------
#       seq
#----------------------
# Example 1: Standard integer sequence
say 'seq(1, 5):';
my @seq = seq(1, 5);
no_leaks_ok {
	eval {
		seq(1,5);
	};
} 'seq: no memory leaks' unless $INC{'Devel/Cover.pm'};
$idx = 0;
foreach my $item (@seq) {
	is_approx( $item, $idx + 1, "seq item $idx", 1e-14);
	$idx++;
}

# Example 2: Fractional steps
say 'seq(1, 2, 0.25):';
@seq = seq(1, 2, 0.25);
no_leaks_ok {
	eval {
		seq(1,2,0.25);
	};
} 'seq: no memory leaks' unless $INC{'Devel/Cover.pm'};
say join(", ", @seq), "\n";
for (my $idx = 2; $idx >= 1; $idx -= 0.25) { # count down to pop
	is_approx(pop @seq, $idx, "seq item $idx with fractional step");
}

# Example 3: Negative steps
say 'seq(10, 5, -1):';
@seq = seq(10, 5, -1);

no_leaks_ok {
	eval {
		seq(10, 5, -1);
	};
} 'seq: no memory leaks' unless $INC{'Devel/Cover.pm'};
say join(", ", @seq), "\n";
for (my $idx = 5; $idx <= 10; $idx++) { # count down to pop
	is_approx(pop @seq, $idx, "seq item $idx with negative step");
}
# Example 4: R-style floating point boundary catch
# (In naive C, 2.0 - 0.2 could cause the last element to drop off)
say 'seq(0, 1, 0.1):';
@seq = seq(0, 1, 0.1);
say join(", ", @seq);

#'seq: Floating-point precision drift'
my @seq_drift = seq(0, 100, 0.1);
# If current += by is used, the 500th element (50.0) might evaluate to 49.999999999999
is_approx( $seq_drift[500], 50.0, 'seq: 500th fractional step maintains exact expected scale without drifting', 10**-12 );
no_leaks_ok {
	eval {
		seq(0, 100, 0.1);
	};
} 'seq: no memory leaks' unless $INC{'Devel/Cover.pm'};

#my $wt_result = wilcox_test( 'x' => [1..4], 'y' => [5..8], {});
#p $wt_result;

#----------------------
#       Shapiro Test
#----------------------
my $shapiro = shapiro_test(
	[1..5]
);
no_leaks_ok {
	shapiro_test(
		[1..5]
	);
} 'Shapiro test: no leaks' unless $INC{'Devel/Cover.pm'};
is_approx( $shapiro->{p_value}, 0.9671739, 'Shapiro p-value');
is_approx( $shapiro->{W}, 0.9867622, 'Shapiro W');
#--------
$shapiro = shapiro_test(
	[1..19]
);
no_leaks_ok {
	shapiro_test(
		[1..19]
	);
} 'Shapiro test: no leaks' unless $INC{'Devel/Cover.pm'};
is_approx( $shapiro->{p_value}, 0.5896506, 'Shapiro p-value: 19 values');
is_approx( $shapiro->{W}, 0.9608707, 'Shapiro W: 19 values');
#--------------------
#     cor_test
#--------------------
my $x = [1, 2, 3, 4, 5];
my $y = [2, 1, 4, 3, 5];

my @correct = (
{ # cor.test(cx, cy, alternative='two.sided', method = 'spearman', continuity=1)
	alternative => 'two.sided',
	estimate    => 0.8,
	'conf.level'=> 0.95,
	'p.value'   => 0.1333333,
	statistic   => 4,
	method      => 'spearman'
},
{ # cor.test(cx, cy, alternative='two.sided', method = 'kendall', continuity=1)
	alternative => 'two.sided',
	estimate    => 0.6, # tau
	method      => 'kendall',
	'p.value'   => 0.2333333,
	statistic   => 8,
},
{# cor.test(cx, cy, alternative='two.sided', method = 'pearson', continuity=1)
	alternative => 'two.sided',
	'conf.int' => [
	 -0.279637693499009, 0.986196123450776
	],
	estimate  =>  0.8,
	method    => 'pearson',
	'p.value' => 0.104088,
	parameter => 3,
	statistic => 2.309401,
},
{ # cor.test(cx, cy, alternative='less', method = 'pearson', continuity=1
	alternative => 'less',
	'conf.int' => [
	 -1, 0.9785289
	],
	estimate  =>  0.8,
	method    => 'pearson',
	'p.value' => 0.947956,
	parameter => 3,
	statistic => 2.309401,
},
{# cor.test(cx, cy, alternative='less', method = 'kendall', continuity=1)
	alternative => 'less',
	estimate    => 0.6, # tau
	method      => 'kendall',
	'p.value'   => 0.9583333,
	statistic   => 8,
},
{# cor.test(cx, cy, conf.level=0.99)
	alternative => 'two.sided',
	'conf.level'=> 0.99,
	estimate    => 0.8,
	method      => 'pearson',
	'p.value'   => 0.10408803866183,
	parameter   => 3,
	statistic   => 2.30940107675850,
}
);
$idx = 0;
foreach my $meth (@correct) {
	$meth->{'conf.level'} = $meth->{'conf.level'} // 0.95; # default 0.95
	say $meth->{'conf.level'};
	my $result = cor_test(
		$x, $y, # first 2 args are positional
		alternative => $meth->{alternative}, # so that it matches the test
		method      => $meth->{method},      # so that it matches the test
		continuity  => 1,
		'conf.level'=> $meth->{'conf.level'}
	);
	my @undef_keys = grep {!defined $result->{$_}} sort keys %{ $result };
	if (scalar @undef_keys > 0) {
		say STDERR join (', ', @undef_keys);
		die "The above keys aren't defined";
	}
	foreach my $key (sort grep {looks_like_number($result->{$_})} keys %{ $result }) {
		if (not defined $meth->{$key}) {
			die "\"$key\" isn't defined in answer key \$meth (index $idx/$#correct)";
		}
		is_approx( $result->{$key}, $meth->{$key}, "cor_test: $meth->{method}/$meth->{alternative} & $key");
	}
	no_leaks_ok {
		eval {
			cor_test(
				$x, $y, # first 2 args are positional
				alternative => $meth->{alternative}, # so that it matches the test
				method      => $meth->{method},      # so that it matches the test
				continuity  => 1,
				'conf.level'=> $meth->{'conf.level'}
			);
		};
	} "cor_test $idx: no memory leaks" unless $INC{'Devel/Cover.pm'};
	$idx++;
}
# NA/undef handling
my $x_na = [1, 2,     3, undef,  5, 5, 6,     undef,7];
my $y_na = [2, undef, 6, 8,     10, 9, undef, 14,  16];
@correct = (
{
	alternative => 'two.sided',
	'conf.level'=> 0.95,
	estimate    => 0.98262751397896,
	method      => 'pearson',
	'p.value'   => 0.00274152275175,
	parameter   => 3,
	statistic   => 9.17060521448829,
}
);
$idx = 0;
foreach my $meth (@correct) {
	$meth->{'conf.level'} = $meth->{'conf.level'} // 0.95; # default 0.95
	my $result = cor_test(
		$x_na, $y_na, # first 2 args are positional
		alternative => $meth->{alternative}, # so that it matches the test
		method      => $meth->{method},      # so that it matches the test
		continuity  => 1,
		'conf.level'=> $meth->{'conf.level'}
	);
	my @undef_keys = grep {!defined $result->{$_}} sort keys %{ $result };
	if (scalar @undef_keys > 0) {
		say STDERR join (', ', @undef_keys);
		die "The above keys aren't defined";
	}
	foreach my $key (sort grep {looks_like_number($result->{$_})} keys %{ $result }) {
		if (not defined $meth->{$key}) {
			die "\"$key\" isn't defined in answer key \$meth (index $idx/$#correct)";
		}
		is_approx( $result->{$key}, $meth->{$key}, "cor_test: $meth->{method}/$meth->{alternative} & $key");
	}
	no_leaks_ok {
		eval {
			cor_test(
				$x_na, $y_na, # first 2 args are positional
				alternative => $meth->{alternative}, # so that it matches the test
				method      => $meth->{method},      # so that it matches the test
				continuity  => 1,
				'conf.level'=> $meth->{'conf.level'}
			);
		};
	} "cor_test $idx: no memory leaks" unless $INC{'Devel/Cover.pm'};
	$idx++;
}

$idx = cor_test([1..5], [1..5], method => 'pearson');
is_approx( $idx->{estimate}, 1.0, 'cor_test: estimate = 1', 1e-13);
if ($idx->{statistic} == 'inf') {
	pass('cor_test: perfect positive correlation: stat is +Inf');
} else {
	fail('cor_test: perfect positive correlation: stat is NOT +Inf');
}
$idx = cor_test([1..5], [reverse 1..5], method => 'pearson');
is_approx( $idx->{estimate}, -1.0, 'cor_test: estimate = 1', 1e-13);
if ($idx->{statistic} == '-inf') {
	pass('cor_test: perfect positive correlation: stat is -Inf');
} else {
	fail('cor_test: perfect positive correlation: stat is NOT -Inf');
}
#if ((!isnan( $idx->{'conf.int'}[0])) && (!isnan( $idx->{'conf.int'}[1]))) {
#	pass('cor_test w/ pearson: CI endpoints are not NaN');
#} else {
#	fail('cor_test w/ pearson: 1 or 2 CI endpoints is/are NaN');
#}
$idx = cor_test([10, 20, 30, 40, 50, 60, 70, 80, 90, 100], [10, 20, 30, 40, 50, 60, 70, 80, 90, 100], method => 'spearman');
is_approx( $idx->{estimate}, 1.0, 'cor_test: spearman estimate', 1e-13);
if ($idx->{statistic} == 'inf') {
	pass('cor_test: spearman has perfect positive correlation: stat is Inf');
} else {
	fail('cor_test: spearman perfect positive correlation: stat is NOT Inf');
}
$idx = cor_test([1..10], [reverse 1..10], method => 'spearman');
is_approx( $idx->{estimate}, -1.0, 'cor_test with spearman: estimate == -1', 1e-13);

if ($idx->{statistic} == '-inf') {
	pass('cor_test w/ spearman: perfect positive correlation: stat = -Inf');
} else {
	fail('cor_test w/ spearman: perfect positive correlation: stat is NOT -Inf');
}
$idx = cor_test([1..200], [reverse 1..200], method => 'kendall', exact => 0);
is_approx( $idx->{estimate}, -1.0, 'cor_test: kendall = -1 for anti-monotone', 1e-13);

#$idx = cor_test( [5,5,5,5,5], [3,3,3,3,3], method => 'kendall', exact => 0);
#if (isnan($idx->{estimate})) {
#	pass('cor_test kendall: estimate is NaN when all pairs are joint ties');
#} else {
#	fail('cor_test kendall: estimate is NOT NaN when all pairs are joint ties');
#}
#--------------------
#  cov
#--------------------
is_approx(2, cov($x, $y), 'default covariance/cov', 1e-14);
@correct = (2,2,12);
$idx = 0;
foreach my $method ('pearson', 'spearman', 'kendall') {
	is_approx(cov($x, $y, $method), $correct[$idx], "cov with $method", 1e-14 );
	$idx++;
}
#--------------------
#  aov
#--------------------
#> yield <- c(5.5, 5.4, 5.8, 4.5, 4.8, 4.2) 
#> ctrl <- c(1, 1, 1, 0, 0, 0)
#> aov(yield ~ ctrl)
#Call:
#   aov(formula = yield ~ ctrl)

#Terms:
#                     ctrl Residuals
#Sum of Squares  1.7066667 0.2666667
#Deg. of Freedom         1         4

#Residual standard error: 0.2581989
#Estimated effects may be unbalanced
#> summary(aov(yield ~ ctrl))
#            Df Sum Sq Mean Sq F value  Pr(>F)   
#ctrl         1 1.7067  1.7067    25.6 0.00718 **
#Residuals    4 0.2667  0.0667                   
#---
#Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1
my $aov_res = 
aov(
	{
		yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
		ctrl  => [1,     1,   1,   0,   0,   0]
	},
'yield ~ ctrl');
%correct = (
	ctrl => {
		Df        => 1,
		'F value' => 25.6000000000001,
		'Mean Sq' => 1.70666666666667,
		'Pr(>F)'  => 0.007182329,
		'Sum Sq'  => 1.70666666666667
	 },
	 Residuals => {
		Df        => 4,
		'Mean Sq' => 0.0666666666666729,
		'Sum Sq'  => 0.266666666666692
	 }
);
foreach my $k1 ('ctrl', 'Residuals') {
	foreach my $k2 (sort keys %{ $correct{$k1} }) {
		my $e = 10**-7;
		if ($correct{$k1}{$k2} =~ m/\.(\d+)$/) {
			$e = 10**(2-length $1);
		}
		is_approx( $aov_res->{$k1}{$k2}, $correct{$k1}{$k2}, "AOV: $k1/$k2");
	}
}
if (defined $aov_res->{group_stats}) {
	pass('aov: group_stats are defined');
} else {
	fail('aov: group_stats are NOT defined');
}
# omitting formula results in stacking
$aov_res = aov(
	{
		yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
		ctrl  => [1,     1,   1,   0,   0,   0]
	}
);
foreach my $key ('Group', 'group_stats', 'Residuals') {
	if (defined $aov_res->{$key}) {
		pass("aov: \"$key\" hash reference is defined");
	} else {
		fail("aov: \"$key\" hash reference is NOT defined");
	}
}
# go through Group
@correct = ('Df', 'F value', 'Mean Sq', 'Pr(>F)', 'Sum Sq');
@ans = (1, 177.504798464491216, 61.653333333333329, 0.000000108622655, 61.653333333333329);
foreach my $i (0..$#ans) {
	die "$correct[$i] is missing" unless defined $aov_res->{Group}{$correct[$i]};
	is_approx( $aov_res->{Group}{$correct[$i]}, $ans[$i], "aov: Group $correct[$i]", 1e-9);
}
foreach my $key ('mean', 'size') {
	if (defined $aov_res->{group_stats}{$key}) {
		pass("aov: group_stats \"$key\" hash reference is defined");
	} else {
		fail("aov: group_stats \"$key\" hash reference is NOT defined");
	}
}
@correct = ('ctrl', 'yield');
@ans = (0.5, 5.03333333333333);
foreach my $i (0..$#ans) {
	is_approx( $aov_res->{group_stats}{mean}{$correct[$i]}, $ans[$i], "aov: group_stats mean $correct[$i]", 1e-13);
}
@ans = (6, 6);
foreach my $i (0..$#ans) {
	is_approx( $aov_res->{group_stats}{size}{$correct[$i]}, $ans[$i], "aov: group_stats size $correct[$i]", 1e-13);
}
# go through Residuals
@correct = ('Df', 'Mean Sq', 'Sum Sq');
@ans = (10, 0.347333333333334, 3.473333333333336);
foreach my $i (0..$#ans) {
	die "$correct[$i] is missing" unless defined $aov_res->{Residuals}{$correct[$i]};
	is_approx( $aov_res->{Residuals}{$correct[$i]}, $ans[$i], "aov: Residual $correct[$i]", 1e-13);
}
no_leaks_ok {
	eval {
		aov(
			{
				yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
				ctrl  => [1,     1,   1,   0,   0,   0]
			}
		);
	};
} 'aov: no memory leaks with formula omission and stacking' unless $INC{'Devel/Cover.pm'};
#-------------------------------------------------------------------
#  glm: Generalized Linear Models
#-------------------------------------------------------------------
#'glm: Gaussian matches lm' => sub {
# Check that gaussian glm is mathematically identical to OLS lm
my $lm_res = lm(formula => 'mpg ~ wt + hp', data => $mtcars);
no_leaks_ok {
	eval {
		lm(formula => 'mpg ~ wt + hp', data => $mtcars);
	};
} 'lm: no leaks';
my $glm_res = glm(formula => 'mpg ~ wt + hp', data => $mtcars, family => 'gaussian');
no_leaks_ok {
	eval {
		glm(formula => 'mpg ~ wt + hp', data => $mtcars);
	};
} 'glm: no leaks';
is_approx($glm_res->{coefficients}{Intercept}, $lm_res->{coefficients}{Intercept}, 'glm gaussian matches lm intercept');
is_approx($glm_res->{coefficients}{wt}, $lm_res->{coefficients}{wt}, 'glm gaussian matches lm wt');
is_approx($glm_res->{deviance}, $lm_res->{rss}, 'glm gaussian deviance matches lm RSS');
is($glm_res->{family}, 'gaussian', 'glm stored family correctly');

#-------------------------------------------------------------------
#  glm: Generalized Linear Models
#-------------------------------------------------------------------
#'glm: Gaussian matches lm' => sub {
	# Check that gaussian glm is mathematically identical to OLS lm
$lm_res = lm(formula => 'mpg ~ wt + hp', data => $mtcars);
$glm_res = glm(formula => 'mpg ~ wt + hp', data => $mtcars, family => 'gaussian');

is_approx($glm_res->{coefficients}{Intercept}, $lm_res->{coefficients}{Intercept}, 'glm gaussian matches lm intercept');
is_approx($glm_res->{coefficients}{wt}, $lm_res->{coefficients}{wt}, 'glm gaussian matches lm wt');
is_approx($glm_res->{deviance}, $lm_res->{rss}, 'glm gaussian deviance matches lm RSS');
is($glm_res->{family}, 'gaussian', 'glm stored family correctly');

#'glm: Binomial (Logistic Regression)' => sub {
# Test dataset matching exact output from R's glm(am ~ wt + hp, data=mtcars, family=binomial)
my $glm_bin = glm(formula => 'am ~ wt + hp', data => $mtcars, family => 'binomial');
# 1. Convergence & Integrity
ok($glm_bin->{converged}, 'glm binomial converged');
ok($glm_bin->{iter} < 25, 'glm binomial converged under iteration limit');
# 2. Coefficients (matching R precisely)
my %correct_bin_coefs = (
  Intercept => 18.86630,
  wt        => -8.08348,
  hp        =>  0.03626
);
foreach my $coef (keys %correct_bin_coefs) {
  is_approx(
	   $glm_bin->{coefficients}{$coef},
	   $correct_bin_coefs{$coef},
	   "glm binomial matches R coef for $coef",
	   0.001
  );
}
# 3. Summary standard errors & z-values
is_approx($glm_bin->{summary}{Intercept}{'Std. Error'}, 7.44356, 'glm binomial Std. Error for Intercept', 0.001);
is_approx($glm_bin->{summary}{wt}{'z value'}, -2.634, 'glm binomial z value for wt', 0.001);

# 4. Deviance metrics
is_approx($glm_bin->{deviance}, 10.059, 'glm binomial residual deviance', 0.001);
is_approx($glm_bin->{'null.deviance'}, 43.229, 'glm binomial null deviance', 0.001);
is($glm_bin->{'df.residual'}, 29, 'glm binomial residual degrees of freedom');
is_approx($glm_bin->{'df.null'}, 31, 'glm binomial null degrees of freedom', 1e-14);
my %tooth_growth = (
	dose => [qw(0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0
1.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5
0.5 0.5 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 1.0 2.0 2.0 2.0 2.0 2.0 2.0 2.0
2.0 2.0 2.0)],
	len  => [qw(4.2 11.5  7.3  5.8  6.4 10.0 11.2 11.2  5.2  7.0 16.5 16.5 15.2 17.3 22.5
17.3 13.6 14.5 18.8 15.5 23.6 18.5 33.9 25.5 26.4 32.5 26.7 21.5 23.3 29.5
15.2 21.5 17.6  9.7 14.5 10.0  8.2  9.4 16.5  9.7 19.7 23.3 23.6 26.4 20.0
25.2 25.8 21.2 14.5 27.3 25.5 26.4 22.4 24.5 24.8 30.9 26.4 27.3 29.4 23.0)],
	supp => [qw(VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC VC
VC VC VC VC VC OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ
OJ OJ OJ OJ OJ OJ OJ OJ OJ OJ)]
);
%correct = (
	aic => 357.3958,
	coefficients => {
		dose      => 9.763571,
		Intercept => 7.4225
	},
	deviance        => 1227.905,
	'df.null'       => 59,
	'df.residual'   => 58,
	iter            => 2,
	'null.deviance' => 3452.209,
	rank            => 2,
	summary => {
		dose  => {
			Estimate     => 9.7636,
			'Pr(>|t|)'   => 1.23*10**-14,
			'Std. Error' => 0.952532934814911,
			't value'    => 10.250114270819
		},
		Intercept => {
			Estimate     => 7.4225,
			'Pr(>|t|)'   => 2.06e-07,
			'Std. Error' => 1.2601,
			't value'    => 5.89
		}
	}
);
$idx = 0;
my @v = qw(-8.1042857 -0.8042857 -5.0042857 -6.5042857 -5.9042857 -2.3042857 -1.1042857 
-1.1042857 -7.1042857 -5.3042857 -0.6860714 -0.6860714 -1.9860714  0.1139286 
 5.3139286  0.1139286 -3.5860714 -2.6860714  1.6139286 -1.6860714 -3.3496429 
-8.4496429  6.9503571 -1.4496429 -0.5496429  5.5503571 -0.2496429 -5.4496429 
-3.6496429  2.5503571  2.8957143  9.1957143  5.2957143 -2.6042857  2.1957143 
-2.3042857 -4.1042857 -2.9042857  4.1957143 -2.6042857  2.5139286  6.1139286 
 6.4139286  9.2139286  2.8139286  8.0139286  8.6139286  4.0139286 -2.6860714 
10.1139286 -1.4496429 -0.5496429 -4.5496429 -2.4496429 -2.1496429  3.9503571 
-0.5496429  0.3503571  2.4503571 -3.9496429);
foreach my $val (@v) {
	$correct{'deviance.resid'}{$idx+1} = $val;
	$idx++;
}
$idx = 0;
@v = qw(12.30429 12.30429 12.30429 12.30429 12.30429 12.30429 12.30429 12.30429 
12.30429 12.30429 17.18607 17.18607 17.18607 17.18607 17.18607 17.18607 
17.18607 17.18607 17.18607 17.18607 26.94964 26.94964 26.94964 26.94964 
26.94964 26.94964 26.94964 26.94964 26.94964 26.94964 12.30429 12.30429 
12.30429 12.30429 12.30429 12.30429 12.30429 12.30429 12.30429 12.30429 
17.18607 17.18607 17.18607 17.18607 17.18607 17.18607 17.18607 17.18607 
17.18607 17.18607 26.94964 26.94964 26.94964 26.94964 26.94964 26.94964 
26.94964 26.94964 26.94964 26.94964);
foreach my $val (@v) {
	$correct{'fitted.values'}{$idx+1} = $val;
	$idx++;
}
my $glm_teeth = glm(
	data    => \%tooth_growth,
	formula => 'len ~ dose',
	family  => 'gaussian'
);

foreach my $term (sort keys %{ $correct{coefficients} }) {
	my $e = 10**-7;
	if ($correct{coefficients}{$term} =~ m/\.(\d+)$/) {
		$e = 10**(1-length $1);
	}
	is_approx( $glm_teeth->{coefficients}{$term}, $correct{coefficients}{$term}, "generalized Linear Models (glm) coefficients->$term within $e", $e);
}
foreach my $term (sort keys %{ $correct{summary} }) {
	foreach my $stat ('Estimate', 'Pr(>|t|)', 'Std. Error', 't value') {
		my $e = 10**-7;
		if ($correct{summary}{$term}{$stat} =~ m/\.(\d+)$/) {
			$e = 10**(1-length $1);
		} else {
			my $sp = sprintf '%.3g', $correct{summary}{$term}{$stat};
			if ($sp =~ m/e\-(\d+)$/) {
				$e = 10**(2-$1);
			} else {
				die "$sp failed regex.";
			}
		}
		is_approx( $glm_teeth->{summary}{$term}{$stat}, $correct{summary}{$term}{$stat}, "generalized Linear Models (glm) coefficients->$term/$stat within $e", $e);
	}
}
foreach my $key (sort grep {ref $correct{$_} eq '' } keys %correct) {
	my $e;
	if ($correct{$key} =~ m/\.(\d+)$/) {
		$e = 10**(-length $1);
	} elsif ($correct{$key} =~ m/^\-?\d+$/) {
		$e = 10**-199;
	} else {
		my $sp = sprintf '%.3g', $correct{$key};
		if ($sp =~ m/e\-(\d+)$/) {
			$e = 10**(2-$1);
		} else {
			die "$sp failed regex.";
		}
	}
	is_approx( $glm_teeth->{$key}, $correct{$key}, "$key within $e", $e);
}
foreach my $k1 ('deviance.resid', 'fitted.values') {
	foreach my $key (sort keys %{ $correct{$k1} } ) {
		my $e;
		if ($correct{$k1}{$key} =~ m/\.(\d+)$/) {
			$e = 10**(-(length $1));
		} elsif ($correct{$k1}{$key} =~ m/^\-?\d+$/) {
			$e = 10**-199;
		} else {
			my $sp = sprintf '%.3g', $correct{$k1}{$key};
			if ($sp =~ m/e\-(\d+)$/) {
				$e = 10**(2-$1);
			} else {
				die "$sp failed regex.";
			}
		}
		is_approx( $glm_teeth->{$k1}{$key}, $correct{$k1}{$key}, "$k1 $key within $e", $e);
	}
}
$glm_teeth = glm(
	data    => \%tooth_growth,
	formula => 'len ~ dose + supp',
	family  => 'gaussian'
);
no_leaks_ok {
	eval {
		glm(
			data    => \%tooth_growth,
			formula => 'len ~ dose + supp',
			family  => 'gaussian'
		);
	};
} 'glm with teeth dataset: no memory leaks' unless $INC{'Devel/Cover.pm'};
%correct = (
	aic        => 348.41553291891,
	deviance   => 1022.5550357143,
	'df.null'     => 59,
	'df.residual' => 57,
#	dispersion => 17.93956,
	coefficients => {
		dose      => 9.763571,
		Intercept => 9.272500,
		suppVC    => -3.700000
	},
	iter         => 2,
	summary => {
		dose  => {
			Estimate     => 9.763571,
			'Pr(>|t|)'   => 6.313519e-16,
			'Std. Error' => 0.8768343,
			't value'    => 11.135025
		},
		Intercept => {
			Estimate     => 9.272500,
			'Pr(>|t|)'   => 1.312335e-09,
			'Std. Error' => 1.2823649,
			't value'    => 7.230781
		},
		suppVC    => {
			Estimate     => -3.700000,
			'Pr(>|t|)'   => 1.300662e-03,
			'Std. Error' => 1.0936045,
			't value'    => -3.383307
		}
	}
);
$idx = 0;
foreach my $val ( qw(
-6.2542857  1.0457143 -3.1542857 -4.6542857 -4.0542857 -0.4542857  0.7457143 
 0.7457143 -5.2542857 -3.4542857  1.1639286  1.1639286 -0.1360714  1.9639286 
 7.1639286  1.9639286 -1.7360714 -0.8360714  3.4639286  0.1639286 -1.4996429 
-6.5996429  8.8003571  0.4003571  1.3003571  7.4003571  1.6003571 -3.5996429 
-1.7996429  4.4003571  1.0457143  7.3457143  3.4457143 -4.4542857  0.3457143 
-4.1542857 -5.9542857 -4.7542857  2.3457143 -4.4542857  0.6639286  4.2639286 
 4.5639286  7.3639286  0.9639286  6.1639286  6.7639286  2.1639286 -4.5360714 
 8.2639286 -3.2996429 -2.3996429 -6.3996429 -4.2996429 -3.9996429  2.1003571 
-2.3996429 -1.4996429  0.6003571 -5.7996429)) {
	$correct{'deviance.resid'}{$idx+1} = $val;
	$idx++;
}
$idx = 0;
foreach my $val ( qw(
10.45429 10.45429 10.45429 10.45429 10.45429 10.45429 10.45429 10.45429 
10.45429 10.45429 15.33607 15.33607 15.33607 15.33607 15.33607 15.33607 
15.33607 15.33607 15.33607 15.33607 25.09964 25.09964 25.09964 25.09964 
25.09964 25.09964 25.09964 25.09964 25.09964 25.09964 14.15429 14.15429 
14.15429 14.15429 14.15429 14.15429 14.15429 14.15429 14.15429 14.15429 
19.03607 19.03607 19.03607 19.03607 19.03607 19.03607 19.03607 19.03607 
19.03607 19.03607 28.79964 28.79964 28.79964 28.79964 28.79964 28.79964 
28.79964 28.79964 28.79964 28.79964
)) {
	$correct{'fitted.values'}{$idx + 1} = $val;
	$idx++;
}
foreach my $term (sort keys %{ $correct{coefficients} }) {
	my $e = 10**-7;
	if ($correct{coefficients}{$term} =~ m/\.(\d+)$/) {
		$e = 10**(-length $1);
	} elsif ($correct{coefficients}{$term} =~ m/^\-?\d+$/) {
		$e = 10**-199;
	} else {
		my $sp = sprintf '%.3g', $correct{coefficients}{$term};
		if ($sp =~ m/e\-(\d+)$/) {
			$e = 10**(2-$1);
		} else {
			die "$sp failed regex.";
		}
	}
	is_approx( $glm_teeth->{coefficients}{$term}, $correct{coefficients}{$term}, "generalized Linear Models (glm) coefficients->$term = $glm_teeth->{coefficients}{$term} within $e of $correct{coefficients}{$term}", $e);
}
foreach my $key (sort grep {ref $correct{$_} eq '' } keys %correct) {
	my $e;
	if ($correct{$key} =~ m/\.(\d+)$/) {
		$e = 10**(-length $1);
	} elsif ($correct{$key} =~ m/^\-?\d+$/) {
		$e = 0;
	} else {
		my $sp = sprintf '%.3g', $correct{$key};
		if ($sp =~ m/e\-(\d+)$/) {
			$e = 10**(2-$1);
		} else {
			die "$sp failed regex.";
		}
	}
	is_approx( $glm_teeth->{$key}, $correct{$key}, "$key within $e of $correct{$key}", $e);
}
foreach my $term (sort keys %{ $correct{summary} }) {
	foreach my $stat ('Estimate', 'Pr(>|t|)', 'Std. Error', 't value') {
		my $e = 10**-7;
		if ($correct{summary}{$term}{$stat} =~ m/\.(\d+)$/) {
			$e = 10**(1-length $1);
		} else {
			my $sp = sprintf '%.3g', $correct{summary}{$term}{$stat};
			if ($sp =~ m/e\-(\d+)$/) {
				$e = 10**(2-$1);
			} else {
				die "$sp failed regex.";
			}
		}
		is_approx( $glm_teeth->{summary}{$term}{$stat}, $correct{summary}{$term}{$stat}, "glm coefficients->$term/$stat: $glm_teeth->{summary}{$term}{$stat}, $correct{summary}{$term}{$stat}", $e);
	}
}
foreach my $k1 ('fitted.values', 'deviance.resid') {
	foreach my $key (sort keys %{ $correct{$k1} } ) {
		my $e;
		if ($correct{$k1}{$key} =~ m/\.(\d+)$/) {
			$e = 10**(-(length $1));
		} elsif ($correct{$k1}{$key} =~ m/^\-?\d+$/) {
			$e = 10**-199;
		} else {
			my $sp = sprintf '%.3g', $correct{$k1}{$key};
			if ($sp =~ m/e\-(\d+)$/) {
				$e = 10**(2-$1);
			} else {
				die "$sp failed regex.";
			}
		}
		is_approx( $glm_teeth->{$k1}{$key}, $correct{$k1}{$key}, "$k1 $key within $e", $e);
	}
}
#-------------------
#     read_table
#-------------------
$test_data = read_table('t/HepatitisCdata.csv');
if (ref $test_data eq 'ARRAY') {
	pass('"aoh" is an array');
} else {
	fail('"aoh" is not an array');
}
no_leaks_ok {
	eval {
		read_table('t/HepatitisCdata.csv');
	};
} 'read_table: basic with no memory leaks' unless $INC{'Devel/Cover.pm'};
if (
	($test_data->[0]{Age} == 32)   && ($test_data->[0]{Sex} eq 'm') &&
   ($test_data->[0]{ALB} == 38.5) && ($test_data->[0]{ALP} == 52.5) &&
   ($test_data->[0]{ALT} == 7.7)  && ($test_data->[0]{AST} == 22.1) &&
   ($test_data->[0]{BIL} == 7.5)  && ($test_data->[0]{Category} eq '0=Blood Donor') &&
   ($test_data->[0]{CHE} == 6.93) && ($test_data->[0]{CHOL} == 3.23) &&
   ($test_data->[0]{CREA} == 106) && ($test_data->[0]{GGT} == 12.1) &&
   ($test_data->[0]{PROT} == 69)  && ($test_data->[614]{Category} eq '3=Cirrhosis')
	)
	{
	pass('"read_table" reads into array of hash ("aoh") correctly');
} else {
	fail('"read_table" failed to read into array of hash ("aoh") correctly');
}
$test_data = read_table('t/HepatitisCdata.csv', 'output.type' => 'hoa');
if (
	(($test_data->{Sex}[0] eq $test_data->{Sex}[2]) && ($test_data->{Sex}[0] eq 'm') && ($test_data->{Sex}[3] eq 'm'))
	&&
	($test_data->{PROT}[0] == 69) && ($test_data->{PROT}[1] == 76.5)
	&&
	($test_data->{Age}[0] == 32) && (32 == $test_data->{Age}[9]) && (32 == $test_data->{Age}[8])
	) {
	pass('"read_table" reads into hash of array correctly');
} else {
	fail('"read_table" fails to read into hash of array correctly');
}
no_leaks_ok {
	eval {
		read_table('t/HepatitisCdata.csv', 'output.type' => 'hoa');
	};
} 'read_table: basic with no memory leaks with hash of array' unless $INC{'Devel/Cover.pm'};
$test_data = read_table('t/HepatitisCdata.csv', 'output.type' => 'hoh');
#foreach my $col ('Category', 'Age', 'Sex', 'ALB', 'ALP', 'ALT', 'AST', 'BIL','CHE', 'CHOL', 'CREA', 'GGT', 'PROT') {
#	if (defined $test_data->{$col}) {
#		pass("\"$col\" is defined from \"read_table\"");
#	} else {
#		fail("\"$col\" isn't defined from \"read_table\"");
#	}
#}
no_leaks_ok {
	eval {
		read_table('t/HepatitisCdata.csv', 'output.type' => 'hoh');
	};
} 'read_table: basic with no memory leaks with hash of hash' unless $INC{'Devel/Cover.pm'};
if (
	($test_data->{1}{Sex} eq 'm') && ('m' eq $test_data->{2}{Sex}) && ('m' eq $test_data->{3}{Sex})
	&&
	($test_data->{1}{PROT} == 69) && ($test_data->{2}{PROT} == 76.5)
	&&
	($test_data->{1}{Age} == 32) && (32 == $test_data->{8}{Age}) && (32 == $test_data->{7}{Age})
	) {
	pass('"read_table" reads into hash of hash (hoh) correctly');
} else {
	fail('"read_table" fails to read into hash of hash correctly');
	die;
}
dies_ok {
	read_table('t/HepatitisCdata.csv', 'output.type' => 'not_real_type')
} 'dies when given non-accepted type of output';
#------- again, with delim
$test_data = read_table('t/HepatitisCdata.csv', 'output.type' => 'hoh', delim => ',');
foreach my $col ('Category', 'Age', 'Sex', 'ALB', 'ALP', 'ALT', 'AST', 'BIL','CHE', 'CHOL', 'CREA', 'GGT', 'PROT') {
	if (defined $test_data->{1}{$col}) {
		pass("\"$col\" is defined from \"read_table\"");
	} else {
		fail("\"$col\" isn't defined from \"read_table\"");
	}
}
no_leaks_ok {
	eval {
		read_table('t/HepatitisCdata.csv', 'output.type' => 'hoh');
	};
} 'read_table: basic with no memory leaks with hash of hash' unless $INC{'Devel/Cover.pm'};
if (
	($test_data->{1}{Sex} eq 'm') && ('m' eq $test_data->{2}{Sex}) && ('m' eq $test_data->{3}{Sex})
	&&
	($test_data->{1}{PROT} == 69) && ($test_data->{2}{PROT} == 76.5)
	&&
	($test_data->{1}{Age} == 32) && (32 == $test_data->{8}{Age}) && (32 == $test_data->{7}{Age})
	) {
	pass('"read_table" reads into hash of hash (hoh) correctly');
} else {
	fail('"read_table" fails to read into hash of hash correctly');
	die;
}
#------- again, with sep
$test_data = read_table('t/HepatitisCdata.csv', 'output.type' => 'hoh', sep => ',');
foreach my $col ('Category', 'Age', 'Sex', 'ALB', 'ALP', 'ALT', 'AST', 'BIL','CHE', 'CHOL', 'CREA', 'GGT', 'PROT') {
	if (defined $test_data->{1}{$col}) {
		pass("\"$col\" is defined from \"read_table\"");
	} else {
		fail("\"$col\" isn't defined from \"read_table\"");
	}
}
no_leaks_ok {
	eval {
		read_table('t/HepatitisCdata.csv', 'output.type' => 'hoh');
	};
} 'read_table: basic with no memory leaks with hash of hash' unless $INC{'Devel/Cover.pm'};
if (
	($test_data->{1}{Sex} eq 'm') && ('m' eq $test_data->{2}{Sex}) && ('m' eq $test_data->{3}{Sex})
	&&
	($test_data->{1}{PROT} == 69) && ($test_data->{2}{PROT} == 76.5)
	&&
	($test_data->{1}{Age} == 32) && (32 == $test_data->{8}{Age}) && (32 == $test_data->{7}{Age})
	) {
	pass('"read_table" reads into hash of hash (hoh) correctly');
} else {
	fail('"read_table" fails to read into hash of hash correctly');
	die;
}
#----------
$test_data = read_table('t/bodyfat.csv', 'output.type' => 'hoa');
no_leaks_ok {
	eval {
		read_table('t/bodyfat.csv', 'output.type' => 'hoa');
	};
} 'read_table: no memory leaks with bodyfat hash-of-array' unless $INC{'Devel/Cover.pm'};
my @col = qw(Density	BodyFat Age Weight Height Neck Chest Abdomen	Hip Thigh Knee Ankle	Biceps Forearm	Wrist);
my @err = grep {!defined $test_data->{$_}} @col;
if (scalar @err == 0) {
	pass('read_table: bodyfat has no missing columns');
} else {
	say STDERR join (', ', @err);
	fail('read_table: bodyfat has missing columns (see above)');
}
@err = grep {ref $test_data->{$_} ne 'ARRAY'} @col;
if (scalar @err == 0) {
	pass('all columns/keys are arrays');
} else {
	say STDERR join (', ', @err);
	fail('at least some columns/keys are not arrays after bodyfat.csv');
}
@err = grep {scalar @{ $test_data->{$_} } != 252} @col;
if (scalar @err == 0) {
	pass('all columns/keys are arrays');
} else {
	say STDERR join (', ', @err);
	fail('at least some columns/keys are not arrays after bodyfat.csv');
}
@correct = qw(1.0271	31.9 74	207.5	70	40.8 112.4 108.5	107.1	59.3	42.2	24.6	33.7 30 20.9);
$idx = 0;
foreach my $col (@col) {
	is_approx($test_data->{$col}[251], $correct[$idx], "Last row: column/key $col", 1e-14);
	$idx++;
}

# The corrected call:
sub file2string {
	my $file = shift;
	open my $fh, '<', $file;
	return do { local $/; <$fh> };
}
#---------
# read_table with filter: aoh
#---------
$test_data = read_table(
	't/HepatitisCdata.csv',
	filter => {
		Sex => sub {$_ eq 'f'}
	},
	'output.type' => 'aoh'
);
if (scalar @{ $test_data } == 238) {
	pass('filter on hepatitis/female has the correct number of rows: 238');
} else {
	fail('filter on hepatitis/female has ' . scalar @{ $test_data } . ' rows, when it should have 238');
}
no_leaks_ok {
	eval {
		read_table(
			't/HepatitisCdata.csv',
			filter => {
				Sex => sub {$_ eq 'f'}
			},
			'output.type' => 'aoh'
		);
	};
} 'read_table: reads hepatitis data without leaks with filter: aoh' unless $INC{'Devel/Cover.pm'};
@correct = (39.9,	35.2,	22,	29.8,	6.3,	8.16,	4.37,	60,	4.5, 72.5);
@col = qw(ALB	ALP	ALT	AST	BIL	CHE	CHOL	CREA	GGT	PROT);
$idx = 0;
foreach my $col (@col) {
	is_approx( $test_data->[0]{$col}, $correct[$idx], "read_table: Column $col after filter", 1e-14);
	$idx++;
}
#---------
# read_table with filter: hoa
#---------
$test_data = read_table(
	't/HepatitisCdata.csv',
	filter => {
		Sex => sub {$_ eq 'f'}
	},
	'output.type' => 'hoa'
);
if (defined $test_data->{Sex}) {
	pass('read_table: "Sex" column is output after filter');
} else {
	fail('read_table: "Sex" column is NOT output after filter');
}
no_leaks_ok {
	eval {
		read_table(
			't/HepatitisCdata.csv',
			filter => {
				Sex => sub {$_ eq 'f'}
			},
			'output.type' => 'hoa'
		);
	};
} 'read_table: reads hepatitis data without leaks with filter: hoa' unless $INC{'Devel/Cover.pm'};
$n = 0;
foreach my $sex (@{ $test_data->{Sex} }) {
	$n++ if $sex eq 'f';
}
if ($n == 238) {
	pass('read_table: filter shows that all are female, which was intended');
} else {
	$n = 238 - $n;
	fail("read_table: filter shows that $n individuals are NOT female, which was NOT intended");
}
foreach my $col (sort keys %{ $test_data }) {
	my $n = scalar @{ $test_data->{$col} };
	if ($n == 238) {
		pass("filter on hepatitis/female $col has the correct number of rows: 238");
	} else {
		fail("filter on hepatitis/female $col has $n rows, when it should have 238");
	}
}
$idx = 0;
foreach my $col (@col) {
	is_approx( $test_data->{$col}[0], $correct[$idx], "read_table: Column $col after filter", 1e-14);
	$idx++;
}
#---------
# read_table with filter: hoh
#---------
$test_data = read_table(
	't/HepatitisCdata.csv',
	filter => {
		Sex => sub {$_ eq 'f'}
	},
	'output.type' => 'hoh'
);
no_leaks_ok {
	read_table(
		't/HepatitisCdata.csv',
		filter => {
			Sex => sub {$_ eq 'f'}
		},
		'output.type' => 'hoh'
	);
} 'read_table: no memory leaks with filter and female sex' unless $INC{'Devel/Cover.pm'};
$n = scalar keys %{ $test_data };
if ($n == 238) {
	pass("filter on hepatitis/female has the correct number of rows: 238");
} else {
	fail("filter on hepatitis/female has $n rows, when it should have 238");
}
#$idx = 0;
#foreach my $col (@col) {
#	is_approx( $test_data->{$col}{319}, $correct[$idx], "read_table: Column $col after filter", 1e-14);
#	$idx++;
#}
# === TEST 3: ARRAY OF HASHES (positional) ===
# Demonstrates: AoH, preserves original array order (no sorting of rows),
#               row names become 1, 2, 3..., quoting when separator ("\t") or " appears inside data
$tmp_file = '/tmp/test_aoh.tsv';
my @data_aoh = (
	{ 'c1' => 42,          'c2' => 'hello,world' },
	{ 'c1' => 99,          'c3' => 'quote"here' },
	{ 'c2' => "tab\tin" },
);

write_table(\@data_aoh, $tmp_file, sep => "\t", 'row.names' => 1, 'undef.val' => 'NA');
$str = file2string($tmp_file);
$expected = "\tc1\tc2\tc3\n1\t42\thello,world\tNA\n2\t99\tNA\t\"quote\"\"here\"\n3\tNA\t\"tab\tin\"\tNA\n";
if (is($str, $expected, 'write_table successfully wrote a tab-delimited file (Array of Hashes)')) {
	unlink $tmp_file;
} else {
	diag("see $tmp_file");
	die;
}
#-------------------------------------------------------------------
#  read_table & write_table specific bug checks
#-------------------------------------------------------------------

#'read_table / write_table: Escaped quote handling' => sub {
my $tmp_csv = File::Temp->new(DIR => '/tmp', SUFFIX => '.csv', UNLINK => 1);
close $tmp_csv;
my @data_out = (
	{ 'c1' => 42, 'c2' => 'Normal String' },
	{ 'c1' => 99, 'c2' => 'String with "quotes" inside' }
);
# Write the table. write_table should turn "quotes" into ""quotes""
write_table(\@data_out, $tmp_csv->filename, sep => ',', 'row.names' => 0);
# Read the table back. read_table should turn ""quotes"" back into "quotes"
my $data_in = read_table($tmp_csv->filename, 'output.type' => 'aoh');
is($data_in->[1]{c2}, 'String with "quotes" inside', 'read_table correctly unescapes internal quotes');

#'write_table: Nested reference stringification protection' => sub {
$fh = File::Temp->new( DIR => '/tmp', SUFFIX => '.csv', UNLINK => 1);
close $fh;
my %bad_data = (
	'r1' => { 'c1' => 42, 'c2' => [1, 2, 3] } # Arrayref inside the hash
);
dies_ok {
	write_table(\%bad_data, $fh->filename);
} 'write_table dies to prevent silent stringification of nested references';
#'write_table: col.names feature validation' => sub {
$fh = File::Temp->new(DIR => '/tmp', SUFFIX => '.tsv', UNLINK => 1);
close $fh;
$tmp_file = $fh->filename;
# Test 1: AoH filtering and reordering
my @data_col_names = (
	{ 'a' => 1, 'b' => 2, 'c' => 3 },
	{ 'a' => 4, 'b' => 5, 'c' => 6 },
);

# Extract only 'c' and 'a', in that exact order
write_table(\@data_col_names, $tmp_file, sep => "\t", 'row.names' => 0, 'col.names' => ['c', 'a']);
$str = file2string($fh->filename);
my $expected_str = "c\ta\n3\t1\n6\t4\n";

is($str, $expected_str, 'write_table: col.names correctly filters and reorders Array of Hashes');
unlink $tmp_file if -f $tmp_file;

# Test 2: HoH enforcing order and padding missing columns
my %data_hoh_col = (
	'Row1' => { 'X' => 10, 'Y' => 20 },
	'Row2' => { 'Y' => 30, 'Z' => 40 },
);

# Requesting a column 'Z' missing in Row1, and 'X' missing in Row2
write_table(\%data_hoh_col, $tmp_file, sep => ',', 'row.names' => 1, 'col.names' => ['Y', 'Z', 'X'], 'undef.val' => 'NA');
$str = file2string($tmp_file);

$expected_str = ",Y,Z,X\nRow1,20,NA,10\nRow2,30,40,NA\n";
is($str, $expected_str, 'write_table: col.names correctly forces order and pads NAs for Hash of Hashes');
# Test 3: Exceptions
dies_ok {
	write_table(\%data_hoh_col, $tmp_file, 'col.names' => 'Not an array ref');
} 'write_table: dies when col.names is not an array reference';

my %hoa = (A => [1..4], B => [-3..3], C => [9,3,4]);
no_leaks_ok {
	eval {
		write_table(
			\%hoa,
			'/tmp/hoa.test.tsv',
			sep => "\t"
		);
	};
} 'write_table: no leaks with hash-of-array input'  unless $INC{'Devel/Cover.pm'};
my $f = '/tmp/hoa.test2.tsv';
write_table(
	\%hoa, $f,	sep => "\t", 'col.names' => ['B', 'C', 'A'], 'undef.val' => 'NA'
);
$str = file2string($f);
$expected = "\tB\tC\tA\n1\t-3\t9\t1\n2\t-2\t3\t2\n3\t-1\t4\t3\n4\t0\tNA\t4\n5\t1\tNA\tNA\n6\t2\tNA\tNA\n7\t3\tNA\tNA\n";
is($str, $expected, 'write_table: hoa with "col.names"');
no_leaks_ok {
	eval {
		\%hoa, $f,	sep => "\t", 'col.names' => ['B', 'C', 'A']
	};
} 'write_table: no leaks with hash-of-array input and "col.names"'  unless $INC{'Devel/Cover.pm'};
#----- repeat above with nondigit
%hoa = (A => ['x',1..4], B => ['y',-3..3], C => ['z',9,3,4]);
write_table(
	\%hoa, $f,	sep => "\t", 'col.names' => ['B', 'C', 'A'], 'undef.val' => 'NA'
);
$str = file2string($f);
$expected = "\tB\tC\tA\n1\ty\tz\tx\n2\t-3\t9\t1\n3\t-2\t3\t2\n4\t-1\t4\t3\n5\t0\tNA\t4\n6\t1\tNA\tNA\n7\t2\tNA\tNA\n8\t3\tNA\tNA\n";
is($str, $expected, 'write_table: hoa input with col.names and nondigit input');
%correct = (
	'r1' => [42, 'hello,world', undef, undef],
	'r2' => [99, undef, 'quote"here', undef],
	'r3' => [undef, "tab\tin", undef, undef],
);
$fh = File::Temp->new(DIR => '/tmp', SUFFIX => '.tsv', UNLINK => 0);
close $fh;
write_table(
	\%correct,	$fh->filename,	sep => "\t"
);
$test_data = read_table( $fh->filename, sep => "\t", 'output.type' => 'hoa');

foreach my $key (sort keys %correct) {	
	my $max_i_hoa = scalar @{ $correct{$key} } - 1;
	my $max_i_table = scalar @{ $test_data->{$key} } - 1;
	if ($max_i_hoa == $max_i_table) {
		pass("read_table: $key has the same number of elements");
	} else {
		fail("read_table: $key does not have the same number of elements.");
	}
	foreach my $i (0..$max_i_hoa) {
		if (
				(defined $correct{$key}[$i])
				&&
				(defined $test_data->{$key}[$i])
				&&
				($correct{$key}[$i] eq $test_data->{$key}[$i])
			) {
			pass("read_table: $key element $i has the correct value");
		} elsif (
				(defined $correct{$key}[$i])
				&&
				(defined $test_data->{$key}[$i])
				&&
				($correct{$key}[$i] ne $test_data->{$key}[$i])
			) {
			fail("read_table: $key element $i has the correct value");
		} elsif (
				(not defined $correct{$key}[$i])
				&&
				(defined $test_data->{$key}[$i])
				&&
				('NA' eq $test_data->{$key}[$i])
			) {
			pass("read_table: $key element $i correctly takes undefined values to \"NA\"");
		}
	}
}
# automatically detect .tsv extension

$test_data = read_table( $fh->filename, 'output.type' => 'hoa');

foreach my $key (sort keys %correct) {	
	my $max_i_hoa = scalar @{ $correct{$key} } - 1;
	my $max_i_table = scalar @{ $test_data->{$key} } - 1;
	if ($max_i_hoa == $max_i_table) {
		pass("read_table: $key has the same number of elements when suffix is automatically determined");
	} else {
		fail("read_table: $key does not have the same number of elements when suffix is automatically determined.");
	}
}
write_table(
	\%correct,   $fh->filename,
	sep => "\t", 'row.names' => 0, 'undef.val' => 'NA'
);
$str = file2string($fh->filename);
$expected = "r1\tr2\tr3\n42\t99\tNA\nhello,world\tNA\t\"tab\tin\"\nNA\t\"quote\"\"here\"\tNA\nNA\tNA\tNA\n";
is($str, $expected, 'write_table was successful')
	or die 'write_table failed';
no_leaks_ok {
	eval {
		write_table(
			\%correct,
			$fh->filename,
			sep => "\t",
			'row.names' => 0
		);
	}
} 'write_table: no memory leaks w/ tab separator and "row.names" set to false' unless $INC{'Devel/Cover.pm'};
#
#  aov: Categorical Variables & Interactions (Bug Fix Validations)
#

# 'aov: One-Way ANOVA with Categorical Factor (>2 Levels)' => sub {
# If the bug is present, 'group' is evaluated as a string (yielding 0.0), 
# resulting in Df=1, Sum Sq=0.0, and F value=NaN.
# A correct implementation must expand 'group' into 2 dummy variables (Df=2).
my $data_1way = {
	yield_val => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2, 6.1, 6.5, 6.2],
	group     => ['A',   'A',   'A',   'B',   'B',   'B',   'C',   'C',   'C']
};
my $res_1way = aov($data_1way, 'yield_val ~ group');

# Validate the 'group' term (k=3 levels -> Df=2)
is($res_1way->{group}{Df}, 2, 'aov 1-way: Df is correct for a 3-level factor');
is_approx($res_1way->{group}{'Sum Sq'},  4.74888888888889,  'aov 1-way: Sum Sq');
is_approx($res_1way->{group}{'Mean Sq'}, 2.37444444444444,  'aov 1-way: Mean Sq');
is_approx($res_1way->{group}{'F value'}, 40.3207547169811,  'aov 1-way: F value');
is_approx($res_1way->{group}{'Pr(>F)'},  0.0003319084,      'aov 1-way: Pr(>F)', 1e-6);

# Validate Residuals
is($res_1way->{Residuals}{Df}, 6, 'aov 1-way: Residuals Df');
is_approx($res_1way->{Residuals}{'Sum Sq'},  0.353333333333333, 'aov 1-way: Residuals Sum Sq');
is_approx($res_1way->{Residuals}{'Mean Sq'}, 0.058888888888889, 'aov 1-way: Residuals Mean Sq');

# 'aov: Two-Way ANOVA with Categorical Interactions'
# If the bug is present, the parser fails to understand the '*' operator 
# and fails to map "supp:dose" correctly.
my $data_2way = {
  len  => [4.2, 11.5, 7.3, 5.8, 6.4, 16.5, 16.5, 15.2, 17.3, 22.5, 
	        15.2, 21.5, 17.6, 9.7, 14.5, 19.7, 23.3, 23.6, 26.4, 20.0],
  supp => ['VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 'VC', 
	        'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ', 'OJ'],
  dose => ['D0.5', 'D0.5', 'D0.5', 'D0.5', 'D0.5', 'D1', 'D1', 'D1', 'D1', 'D1', 
	        'D0.5', 'D0.5', 'D0.5', 'D0.5', 'D0.5', 'D1', 'D1', 'D1', 'D1', 'D1']
};

# The formula `supp * dose` implicitly tests `supp + dose + supp:dose`
my $res_2way = aov($data_2way, 'len ~ supp * dose');

# 1. Validate the 'supp' term
is($res_2way->{supp}{Df}, 1, 'aov 2-way: supp Df');
is_approx($res_2way->{supp}{'Sum Sq'}, 233.2445, 'aov 2-way: supp Sum Sq', 1e-4);
is_approx($res_2way->{supp}{'F value'}, 22.175219, 'aov 2-way: supp F value', 1e-4);

# 2. Validate the 'dose' term
is($res_2way->{dose}{Df}, 1, 'aov 2-way: dose Df');
is_approx($res_2way->{dose}{'Sum Sq'}, 381.0645, 'aov 2-way: dose Sum Sq', 1e-4);
is_approx($res_2way->{dose}{'F value'}, 36.228888, 'aov 2-way: dose F value', 1e-4);

# 3. Validate the 'supp:dose' interaction term
ok(defined $res_2way->{'supp:dose'}, 'aov 2-way: Interaction term supp:dose exists');
is($res_2way->{'supp:dose'}{Df}, 1, 'aov 2-way: supp:dose Df');
is_approx($res_2way->{'supp:dose'}{'Sum Sq'}, 16.7445, 'aov 2-way: supp:dose Sum Sq', 1e-4);
is_approx($res_2way->{'supp:dose'}{'F value'}, 1.591947, 'aov 2-way: supp:dose F value', 1e-4);
is_approx($res_2way->{'supp:dose'}{'Pr(>F)'}, 0.225133, 'aov 2-way: supp:dose Pr(>F)', 1e-5);

# 4. Validate the Residuals
is($res_2way->{Residuals}{Df}, 16, 'aov 2-way: Residuals Df');
is_approx($res_2way->{Residuals}{'Sum Sq'}, 168.2920, 'aov 2-way: Residuals Sum Sq', 1e-4);
is_approx($res_2way->{Residuals}{'Mean Sq'}, 10.51825, 'aov 2-way: Residuals Mean Sq', 1e-4);

#  aov: Robustness, Rank Deficiency & Parsing Exceptions
# 'aov: Collinearity and Rank Deficiency' => sub {
my $data_collinear = {
	'y'  => [1.2, 2.3, 3.1, 4.0, 5.1],
	x1 => [1,   2,   3,   4,   5],
	x2 => [2,   4,   6,   8,  10] # perfectly collinear with x1
};
$res = aov($data_collinear, 'y ~ x1 + x2');

# x2 is completely redundant. It should be silently dropped by Householder QR.
is($res->{x2}{Df}, 0, 'aov: Collinear term properly receives 0 Df');
is_approx($res->{x2}{'Sum Sq'}, 0, 'aov: Collinear term properly receives 0 Sum Sq', 1e-7);

# Residuals should account for Intercept (1) and x1 (1). Total valid rank is 2. Df = 5 - 2 = 3.
is($res->{Residuals}{Df}, 3, 'aov: Residual Df correctly ignores aliased/collinear columns');

# 'aov: Interaction Missing Main Effects Exception' => sub {
my $data_interact = {
	'y' => [1, 2, 3, 4],
	A   => ['a', 'b', 'a', 'b'],
	B   => ['x', 'x', 'y', 'y']
};
# Without explicit A and B added, Cartesian cross-product dummy building fails.
eval { aov($data_interact, 'y ~ A:B') };
like($@, qr/requires its main effects to be explicitly included/, 'aov: cleanly croaks when main effects are missing for interaction evaluation');
#-----------------------
# chi-squared test
#-----------------------
# https://www.rdocumentation.org/packages/stats/versions/3.6.2/topics/chisq.test
@test_data = ([762, 327, 468], [484, 239, 477]);
$test_data = chisq_test(\@test_data);
#p $test_data;
is_approx($test_data->{parameter}{df}, 2, 'degrees of freedom for Chi-squared', 1e-14);
is_approx($test_data->{'p.value'}, 2.9535891832118e-07, 'Chi-squared p-value', 1e-17);
is_approx($test_data->{statistic}{'X-squared'}, 30.070149095755, 'Chi-squared statistic');
no_leaks_ok {
	eval {
		chisq_test(\@test_data)
	};
} 'chisq_test: no memory leaks' unless $INC{'Devel/Cover.pm'};
dies_ok {
	chisq_test('not an array');
} 'chisq_test: dies without array reference ';
#------------------------
# Wilcoxon test
#------------------------
$test_data = wilcox_test(
	'x' => [1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
	'y' => [0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29]
);
is_approx($test_data->{statistic}, 58, 'Wilcox test statistic', 1e-14);
is_approx($test_data->{'p_value'}, 0.132919458185319, 'Wilcox test p-value', 1e-15);
no_leaks_ok {
	eval {
		$test_data = wilcox_test(
			'x' => [1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
			'y' => [0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29]
		);
	};
} 'wilcox test: no leaks' unless $INC{'Devel/Cover.pm'};
#-----
$test_data = wilcox_test( # test paired version
	'x' => [1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
	'y' => [0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29],
	paired => 1
);
is_approx($test_data->{statistic}, 40, 'Wilcox test (paired) statistic',1e-4);
is_approx($test_data->{'p_value'}, 0.0390625, 'Wilcox test (paired) statistic', 1e-7);
# test without "x" and "y"
$test_data = wilcox_test(
	[1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
	[0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29]
);
is_approx($test_data->{statistic}, 58, 'Wilcox test statistic', 1e-14);
is_approx($test_data->{'p_value'}, 0.132919458185319, 'Wilcox test p-value', 1e-15);
no_leaks_ok {
	eval {
		$test_data = wilcox_test(
			'x' => [1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
			'y' => [0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29],
			paired => 1
		);
	};
} 'wilcox test: no leaks' unless $INC{'Devel/Cover.pm'};
#-----
$test_data = wilcox_test(
	[1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30],
	[0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29],
	paired => 1
);
is_approx($test_data->{statistic}, 40, 'Wilcox test (paired) statistic', 1e-14);
is_approx($test_data->{'p_value'}, 0.0390625, 'Wilcox test (paired) statistic', 1e-7);
#$test_data = ks_test('x' => $x, 'y' => $y);
#p $test_data;
#-------------------------------------------------------------------
# 'wilcox_test: Extended and Edge Cases'
# 1. One-sample exact test
# R equivalent: wilcox.test(c(1, 2, 3, 4, 5), mu = 0)
# V = 15, p-value = 0.0625
my $wt_onesample = wilcox_test('x' => [1, 2, 3, 4, 5], mu => 0);
is_approx($wt_onesample->{statistic}, 15, 'wilcox_test: one-sample statistic (exact)');
is_approx($wt_onesample->{p_value}, 0.0625, 'wilcox_test: one-sample p-value (exact)');
like($wt_onesample->{method}, qr/exact/, 'wilcox_test: one-sample uses exact method by default');

# 2. Ties trigger approximation and continuity correction
my $wt_ties = wilcox_test('x' => [1, 2, 2, 3], 'y' => [2, 3, 3, 4]);
ok(defined $wt_ties->{p_value}, 'wilcox_test: completes with ties using normal approx');
like($wt_ties->{method}, qr/continuity correction/, 'wilcox_test: uses continuity correction with ties');

# 3. Alternative hypotheses
my $wt_less = wilcox_test('x' => [1, 2, 3], 'y' => [10, 11, 12], alternative => 'less');
is_approx($wt_less->{p_value}, 0.05, 'wilcox_test: alternative less works properly', 1e-14);

my $wt_greater = wilcox_test('x' => [1, 2, 3], 'y' => [10, 11, 12], alternative => 'greater');
ok($wt_greater->{p_value} > 0.95, 'wilcox_test: alternative greater works properly');

# 4. Exceptions and Error Handling
eval { wilcox_test('y' => [1..5]) };
like($@, qr/'x' is a required argument/, 'wilcox_test: dies when x is missing');

eval { wilcox_test('x' => [1..5], 'y' => [1..4], paired => 1) };
like($@, qr/same length for paired test/, 'wilcox_test: dies on length mismatch for paired');

#  chisq_test: Goodness of Fit and Yates Continuity
#-------------------------------------------------------------------
# 'chisq_test: Goodness of Fit and Yates Continuity'
# 1. 1D Array (Goodness of Fit)
# R equivalent: chisq.test(c(10, 20, 30))
# X-squared = 10, df = 2, p-value = 0.006737947
my $chisq_1d = chisq_test([10, 20, 30]);
is_approx($chisq_1d->{statistic}{'X-squared'}, 10, 'chisq_test: 1D Goodness of Fit statistic');
is_approx($chisq_1d->{parameter}{df}, 2, 'chisq_test: 1D Goodness of Fit df');
is_approx($chisq_1d->{'p.value'}, 0.006737947, 'chisq_test: 1D Goodness of Fit p-value', 1e-6);
like($chisq_1d->{method}, qr/Chi-squared test for given probabilities/, 'chisq_test: correct 1D method name');

# 2. 2x2 Matrix (Yates' Continuity Correction applied automatically)
# R equivalent: chisq.test(matrix(c(12, 5, 7, 14), nrow=2))
# X-squared = 4.1404, df = 1, p-value = 0.04187
my $chisq_2x2 = chisq_test([[12, 7], [5, 14]]);
is_approx($chisq_2x2->{statistic}{'X-squared'}, 3.831933, 'chisq_test: 2x2 Yates statistic', 1e-5);
is_approx($chisq_2x2->{parameter}{df}, 1, 'chisq_test: 2x2 df', 1e-14);
is_approx($chisq_2x2->{'p.value'}, 0.05028492, 'chisq_test: 2x2 p-value', 1e-7);
like($chisq_2x2->{method}, qr/Yates' continuity correction/, 'chisq_test: method includes Yates correction');
#-------------
# power t-test
#-------------
$test_data = power_t_test(#ptt <- power.t.test(n = 30, delta=0.5, sd = 1, sig.level=0.05)
	n  => 30,	delta     => 0.5, 
	sd => 1.0,	sig_level => 0.05
);
is_approx($test_data->{power}, 0.47784098594094, 'power_t_test: power', 1e-9);
no_leaks_ok {
	eval {
		power_t_test(#ptt <- power.t.test(n = 30, delta=0.5, sd = 1, sig.level=0.05)
			n  => 30,	delta     => 0.5, 
			sd => 1.0,	sig_level => 0.05
		);
	};
} 'power_t_test: calculating power' unless $INC{'Devel/Cover.pm'};
$test_data = power_t_test( power => 0.8, delta => 0.5, sd => 1 );
is_approx($test_data->{n}, 63.76576, 'power_t_test: n', 1e-4);
no_leaks_ok {
	eval {
		power_t_test( power => 0.8, delta => 0.5, sd => 1 );
	};
} 'power_t_test: calculating n' unless $INC{'Devel/Cover.pm'};
@ans = (63.76576371427387, 33.36720408802200, 33.36720408802200);
$idx = 0;
foreach my $type ('two.sample', 'one.sample', 'paired') {
	$test_data = power_t_test( power => 0.8, delta => 0.5, sd => 1, type => $type);
	is_approx( $test_data->{n}, $ans[$idx], "power_t_test: n w/ type = \"$type\"", 1e-4);
	no_leaks_ok {
		eval {
			power_t_test( power => 0.8, delta => 0.5, sd => 1, type => $type );
		};
	} "power_t_test: calculating n with type = \"$type\"" unless $INC{'Devel/Cover.pm'};
	$idx++;
}
@ans = (63.76576371427387, 50.15079949213846);
$idx = 0;
foreach my $alt ('two.sided', 'one.sided') {
	$test_data = power_t_test( power => 0.8, delta => 0.5, sd => 1, alternative => $alt);
	is_approx( $test_data->{n}, $ans[$idx], "power_t_test: n with alternative = \"$alt\"", 1e-4);
	no_leaks_ok {
		eval {
			power_t_test( power => 0.8, delta => 0.5, sd => 1, alternative => $alt);
		};
	} "power_t_test: n with alternative = \"$alt\" with no leaks" unless $INC{'Devel/Cover.pm'};
	$idx++;
}
#---------------------------------------
#  lm & aov: Dot (.) Operator Expansion
#---------------------------------------
#subtest 'lm & aov: Dot (.) operator formula expansion' => sub {
my $dot_data = {
	'y'  => [10, 15, 20, 25, 30],
	x1 => [1,  2,  3,  4,  5],
	x2 => [2,  1,  4,  3,  5]
};

# Test lm: Coefficients should match regardless of order
my $lm_explicit = lm(formula => 'y ~ x1 + x2', data => $dot_data);
my $lm_dot      = lm(formula => 'y ~ .',       data => $dot_data);
is_approx($lm_dot->{coefficients}{x1}, $lm_explicit->{coefficients}{x1}, 'lm: dot operator correctly expands to x1');
is_approx($lm_dot->{coefficients}{x2}, $lm_explicit->{coefficients}{x2}, 'lm: dot operator correctly expands to x2');
is_approx($lm_dot->{'r.squared'}, $lm_explicit->{'r.squared'}, 'lm: dot operator produces identical r.squared');
no_leaks_ok {
	eval {
		lm(formula => 'y ~ .', data => $dot_data);
	};
} 'lm: no leaks with "."' unless $INC{'Devel/Cover.pm'};
# Test aov: Compare Total SS and Residuals to avoid Type I SS ordering issues
my $aov_explicit = aov($dot_data, 'y ~ x1 + x2');
my $aov_dot      = aov($dot_data, 'y ~ .');
no_leaks_ok {
	eval {
		 aov($dot_data, 'y ~ .');
	};
} 'aov with ".": no memory leaks' unless $INC{'Devel/Cover.pm'};

# Sum of all non-residual SS should be equal
my $sum_ss_explicit = $aov_explicit->{x1}{'Sum Sq'} + $aov_explicit->{x2}{'Sum Sq'};
my $sum_ss_dot      = $aov_dot->{x1}{'Sum Sq'}      + $aov_dot->{x2}{'Sum Sq'};

is_approx($sum_ss_dot, $sum_ss_explicit, 'aov: total explained Sum Sq matches regardless of variable order');
is_approx($aov_dot->{Residuals}{'Sum Sq'}, $aov_explicit->{Residuals}{'Sum Sq'}, 'aov: dot operator produces identical Residual Sum Sq');
#
#  lm: Relative Tolerance / Collinearity (Bug Fix #3)
#
# 'lm: Relative collinearity tolerance on unscaled data'
# 1. Microscopic Variance Test
my $micro_data = {
	'y'  => [1.1, 2.1, 3.1, 4.1, 5.1],
	x1 => [1e-8, 2e-8, 3e-8, 4e-8, 5e-8]
};
# Variance of x1 is tiny (~ 1e-16). The old absolute tolerance of 1e-10 
# would falsely flag this as collinear/aliased and assign it a NaN coefficient.

my $lm_micro = lm(formula => 'y ~ x1', data => $micro_data);

ok(defined $lm_micro->{coefficients}{x1}, 'lm: micro-variance predictor is successfully parsed');
ok($lm_micro->{coefficients}{x1} ne 'NaN', 'lm: micro-variance coefficient is calculated (not aliased)');
is_approx($lm_micro->{coefficients}{x1}, 1e8, 'lm: micro-variance coefficient value is perfectly estimated', 1e-3);

# 2. True Collinearity Validation
my $coll_data = {
	'y' => [1, 2, 3, 4, 5],
	x1 => [1, 2, 3, 4, 5],
	x2 => [2, 4, 6, 8, 10] # x2 is perfectly linearly dependent on x1
};

my $lm_coll = lm(formula => 'y ~ x1 + x2', data => $coll_data);

# Ensure one of them was properly targeted and aliased by the sweep operator
my $x1_is_nan = (!defined $lm_coll->{coefficients}{x1} || $lm_coll->{coefficients}{x1} =~ m/nan/i);
my $x2_is_nan = (!defined $lm_coll->{coefficients}{x2} || $lm_coll->{coefficients}{x2} =~ m/nan/i);

ok($x1_is_nan || $x2_is_nan, 'lm: perfectly collinear variables are still properly aliased and dropped');
#----------------------------------------------
#  lm & aov: Memory-safe Exception Pathways
#----------------------------------------------
# 'lm & aov: Memory-safe croak and validation'
# 1. 0 Degrees of Freedom (Parameters >= Observations)
# In the previous architecture, these would allocate large C arrays and then leak them when croaking.
# Now, they extract data first, realize there's not enough df, and croak cleanly.
my $short_data = { 
	'y'  => [1, 2],
	x1 => [3, 4],
	x2 => [5, 6]
};
dies_ok { 
	lm(formula => 'y ~ x1 + x2', data => $short_data) 
} 'lm: dies safely on 0 degrees of freedom (too few rows)';

dies_ok { 
	aov($short_data, 'y ~ x1 + x2') 
} 'aov: dies safely on 0 degrees of freedom (too few rows)';
# 2. Listwise Deletion resulting in 0 DF
my $na_data = { 
	'y' => [undef, undef, undef, 1], 
	'x' => [1, 2, 3, 4] 
};
dies_ok { 
	lm(formula => 'y ~ x', data => $na_data) 
} 'lm: dies safely when listwise deletion (NAs) drops rows below parameter count';

# 3. Bad Formula parsing
dies_ok { 
	lm(formula => 'y = x1 + x2', data => $short_data) 
} 'lm: dies safely on invalid formula (missing tilde)';
dies_ok { 
	aov($short_data, 'y = x1 + x2') 
} 'aov: dies safely on invalid formula (missing tilde)';
#------------------------
# Kolmogorov-Smirnov
#------------------------
my $ksx = [qw(2.29258933  0.18126998 -0.35344691 -1.11263431 -1.27008776 -0.25430767
-0.42543048  0.93866464 -0.20838470  1.23049681  2.00720734 -1.90505316
-0.01565043  0.75832509 -0.16071642 -0.12233682  1.96816567  1.12870747
2.65888437  0.28593201  0.77703726 -0.04010983  0.76615094  0.54587695
-0.05254988  0.38800321 -1.17422679  1.23959021  0.69485302 -0.11265354
-0.24885903 -0.08385566  1.31638004  0.26217220  0.54655099 -0.93221413
0.25564497  0.93769895  0.03296175  0.40248836 -0.29519459  0.50047151
-0.83870281  1.12315212 -0.54269950  1.11397783 -0.54257221  0.28592571
1.50792125  0.08526939)];
my $ksy = [qw(0.12691328 0.90138032 0.24332833 0.43789166 0.84998830 0.81363851
0.86952816 0.59003408 0.16147129 0.20170704 0.49802479 0.55526988
0.66574521 0.38529607 0.84985111 0.59408528 0.39516660 0.70785236
0.53252618 0.62963267 0.53251903 0.18885578 0.61922322 0.07602336
0.28763359 0.10201167 0.16455688 0.68249714 0.20168356 0.01536685)];
# R: kst.g <- ks.test(x, y, alternative='greater')
my $ks = ks_test($ksx, $ksy);
is_approx($ks->{p_value}, 0.001825518, 'Kolmogorov-Smirnov test: p-value', 1e-9); # two-sided
is_approx($ks->{statistic}, 0.42, 'Kolmogorov-Smirnov test: statistic', 1e-14);
no_leaks_ok {
	eval {
		ks_test($ksx, $ksy);
	}
} 'Kolmogorov-Smirnov test ok without memory leaks' unless $INC{'Devel/Cover.pm'};
$ks = ks_test($ksx, $ksy, alternative => 'less');
no_leaks_ok {
	eval {
		ks_test($ksx, $ksy);
	}
} 'Kolmogorov-Smirnov test ok without memory leaks; with less alternative' unless $INC{'Devel/Cover.pm'};
is_approx($ks->{p_value}, 0.06784844, 'Kolmogorov-Smirnov test: p-value (alternative = less)', 1e-8);
is_approx($ks->{statistic}, 0.26, 'Kolmogorov-Smirnov test: statistic (alternative = less)', 1e-14);
# alternative = 'greater'
$ks = ks_test($ksx, $ksy, alternative => 'greater');
is_approx($ks->{statistic}, 0.42, 'Kolmogorov-Smirnov test alternative = "greater", statistic', 1e-14);
is_approx($ks->{'p_value'}, 0.0009127589, 'Kolmogorov-Smirnov test alternative = "greater", statistic', 1e-8);
#------------
$ks = ks_test($ksx, 'pnorm');
is_approx($ks->{p_value}, 0.05937757067668, 'Kolmogorov-Smirnov test: 1d array vs pnorm p-value', 1e-8);
is_approx($ks->{statistic}, 0.1839226, 'Kolmogorov-Smirnov test: 1d array vs pnorm statistic', 1e-6);
no_leaks_ok {
	eval {
		$ks = ks_test($ksx, 'pnorm');
	};
} 'Kolmogorov-Smirnov test with 1 array and a named distribution: no memory leaks' unless $INC{'Devel/Cover.pm'};
#---------------
#  Kruskal test (kruskal.R)
#---------------
my @xk = (2.9, 3.0, 2.5, 2.6, 3.2); # normal subjects
my @yk = (3.8, 2.7, 4.0, 2.4);      # with obstructive airway disease
my @zk = (2.8, 3.4, 3.7, 2.2, 2.0); # with asbestosis
my @x = (@xk, @yk, @zk);
my @g = (
	(map {'Normal subjects'} 0..4),
	(map {'Subjects with obstructive airway disease'} 0..3),
	map {'Subjects with asbestosis'} 0..4
);
my $kt = kruskal_test(\@x, \@g);
is_approx($kt->{'p_value'}, 0.67996477357889, 'kruskal: p-value', 1e-13);
is_approx($kt->{statistic}, 0.77142857142857, 'kruskal: statistic', 1e-13);
is_approx($kt->{parameter}, 2, 'kruskal: parameter', 1e-14);

if (defined $kt->{group_stats}) {
	pass('kruskal: group_stats are defined');
} else {
	fail('kruskal: group_stats are NOT defined');
}
no_leaks_ok {
	eval {
		$kt = kruskal_test(\@x, \@g);
	}
} 'kruskal test: no memory leaks' unless $INC{'Devel/Cover.pm'};
# same but with named args
kruskal_test('x' => \@x, 'g' => \@g);
is_approx($kt->{'p_value'}, 0.67996477357889, 'kruskal: p-value', 1e-13);
is_approx($kt->{statistic}, 0.77142857142857, 'kruskal: statistic', 1e-13);
is_approx($kt->{parameter}, 2, 'kruskal: parameter', 1e-14);
no_leaks_ok {
	eval {
		$kt = kruskal_test('x' => \@x, 'y' => \@g);
	}
} 'kruskal test: no memory leaks' unless $INC{'Devel/Cover.pm'};
#---------
my %x = (
	'normal.subjects' => [2.9, 3.0, 2.5, 2.6, 3.2],
	'obs. airway disease' => [3.8, 2.7, 4.0, 2.4],
	'asbestosis' => [2.8, 3.4, 3.7, 2.2, 2.0]
);
$kt = kruskal_test(\%x);
is_approx($kt->{'p_value'}, 0.67996477357889, 'kruskal HOA: p-value', 1e-13);
is_approx($kt->{statistic}, 0.77142857142857, 'kruskal HOA: statistic', 1e-13);
is_approx($kt->{parameter}, 2, 'kruskal HOA: parameter', 1e-14);
no_leaks_ok {
	eval {
		$kt = kruskal_test(\@x, \@g);
	}
} 'kruskal test: no memory leaks with HOA input' unless $INC{'Devel/Cover.pm'};
#-------------
#    sum
#-------------
foreach my $n (3,8) {
	is_approx(sum(1..$n), ($n*($n+1))/2, "sum of 1..$n", 1e-14);
}
$test_data = [1..8];
is_approx(sum($test_data), 36, 'sum to 8 using array reference', 1e-14);
no_leaks_ok {
	sum([1..9]);
} 'sum: no leaks' unless $INC{'Devel/Cover.pm'};
dies_ok {
	sum(1, undef);
} 'sum: dies with undefined values';
dies_ok {
	sum(1, [2,undef]);
} 'sum: dies with undefined values inside array references';
#----------------------
# var_test (var.test.R)
#----------------------
# simplest case
$test_data = var_test(\@xk, \@yk);
is_approx( $test_data->{conf_int}[0], 0.008735893, 'var_test: lower bound of confidence interval', 1e-8);
is_approx( $test_data->{conf_int}[1], 1.316461157, 'var_test: lower bound of confidence interval', 1e-8);
@ans = (0.131920529801325, 0.0795981508839616, 0.131920529801325);
$idx = 0;
foreach my $key ('estimate', 'p_value', 'statistic') {
	is_approx( $test_data->{$key}, $ans[$idx], "var_test: $key", 1e-14);
	$idx++;
}
no_leaks_ok {
	$test_data = var_test(\@xk, \@yk);
} 'var_test: no leaks' unless $INC{'Devel/Cover.pm'};

# with ratio
$test_data = var_test(\@xk, \@yk, ratio => 2);
@ans = (0.13192052980132, 0.02383452765940, 0.06596026490066);
$idx = 0;
foreach my $key ('estimate', 'p_value', 'statistic') {
	is_approx( $test_data->{$key}, $ans[$idx], "var_test with set ratio: $key", 1e-14);
	$idx++;
}
no_leaks_ok {
	$test_data = var_test(\@xk, \@yk, ratio => 2);
} 'var_test: no leaks with set ratio' unless $INC{'Devel/Cover.pm'};
# conf.level = 0.99
$test_data = var_test(\@xk, \@yk, conf_level => 0.99);
@ans = (0.13192052980132, 0.07959815088396, 0.13192052980132);
$idx = 0;
foreach my $key ('estimate', 'p_value', 'statistic') {
	is_approx( $test_data->{$key}, $ans[$idx], "var_test with set ratio: $key", 1e-14);
	$idx++;
}
no_leaks_ok {
	$test_data = var_test(\@xk, \@yk, conf_level => 0.99);
} 'var_test: no leaks with conf.level = 0.99' unless $INC{'Devel/Cover.pm'};
dies_ok {
	var_test(\@xk, [1,1,1,1]);
} 'var_test: dies when variance of y is 0';
dies_ok {
	var_test([1], \@yk);
} 'var_test: dies with insufficient # of observations in x';
dies_ok {
	var_test(\@xk, [1]);
} 'var_test: dies with insufficient # of observations in y';
#----------
# sample
#----------
%h = (a => 1, b => 2, c => 3, d => 4);

@arr = qw(apple banana cherry date elderberry);
foreach my $s (1..3) {
	# hash
	my $sa = sample(\%h, $s);
	if (scalar keys %{ $sa } == $s) {
		pass("sample: $s number of slices makes $s hash keys");
	} else {
		fail("sample: $s number of slices does NOT make $s hash keys");
	}
	foreach my $key (keys %{ $sa }) {
		if (defined $h{$key}) {
			pass("sample: $key is defined in both original hash and sample hash reference with $s keys");
		} else {
			fail("sample: $key is NOT defined in both original hash and sample hash reference with $s keys");
		}
		if ($h{$key} == $sa->{$key}) {
			pass("sample: $key is equal in both original and sample with $s samples");
		} else {
			fail("sample: $key is NOT equal in both original and sample with $s samples");
		}
	}
	no_leaks_ok {
		eval {
			$sa = sample(\%h, $s);
		}
	} "sample: hash with $s samples doesn't have leaks" unless $INC{'Devel/Cover.pm'};
	# array
	$sa = sample(\@arr, $s);
	if (scalar @{ $sa } == $s) {
		pass("sample: array sample with $s samples: $s samples in array reference");
	} else {
		fail("sample: array sample with $s samples: $s samples are NOT in array reference");
	}
	foreach my $i (@{ $sa }) {
		if (grep {$_ eq $i} @arr) {
			pass("sample: $i is in both array and sample array reference");
		} else {
			fail("sample: $i isn't in both array and sample array reference");
		}
	}
	no_leaks_ok {
		eval {
			$sa = sample(\@arr, $s);
		}
	} "sample: array with $s samples doesn't have leaks" unless $INC{'Devel/Cover.pm'};
}
#---------------
#   oneway_test
#---------------
# hash of array
$test_data = oneway_test({
	yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
	ctrl  => [1,     1,   1,   0,   0,   0]
});
foreach my $key ('Group', 'Residuals', 'group_stats') {
	if (defined $test_data->{$key}) {
		pass("oneway_test: no formula; \"$key\" exists");
	} else {
		fail("oneway_test: no formula; \"$key\" does NOT exist");
	}
}

is_approx( $test_data->{Group}{Df}, 1, 'oneway_test: no formula df', 1e-13);
is_approx( $test_data->{Group}{'F value'}, 177.504798464491358, 'oneway_test: no formula F value', 1e-13);
is_approx( $test_data->{Group}{'Pr(>F)'}, 0.000000131343255, 'oneway_test: no formula p-value', 1e-13);
is_approx( $test_data->{Residuals}{Df}, 9.817673483264731, 'oneway_test: no formula parameter', 1e-13);

foreach my $key ('mean', 'size') {
	if (defined $test_data->{group_stats}{$key}) {
		pass("oneway_test: group_stats \"$key\" hash reference is defined");
	} else {
		fail("oneway_test: group_stats \"$key\" hash reference is NOT defined");
	}
}
@correct = ('ctrl', 'yield');
@ans = (0.5, 5.03333333333333);
foreach my $i (0..$#ans) {
	is_approx( $test_data->{group_stats}{mean}{$correct[$i]}, $ans[$i], "oneway_test: group_stats mean $correct[$i]", 1e-13);
}
@ans = (6, 6);
foreach my $i (0..$#ans) {
	is_approx( $test_data->{group_stats}{size}{$correct[$i]}, $ans[$i], "oneway_test: group_stats size $correct[$i]", 1e-13);
}
no_leaks_ok {
	eval {
		oneway_test({
			yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
			ctrl  => [1,     1,   1,   0,   0,   0]
		});
	}
} 'oneway_test: no leaks without formula'  unless $INC{'Devel/Cover.pm'};
# array of array
$test_data = oneway_test([
	[5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
	[1,     1,   1,   0,   0,   0]
]);
foreach my $key ('Group', 'Residuals', 'group_stats') {
	if (defined $test_data->{$key}) {
		pass("oneway_test: no formula; \"$key\" exists");
	} else {
		fail("oneway_test: no formula; \"$key\" does NOT exist");
	}
}

is_approx( $test_data->{Group}{Df}, 1, 'oneway_test: no formula df', 1e-13);
is_approx( $test_data->{Group}{'F value'}, 177.504798464491358, 'oneway_test: no formula F value', 1e-13);
is_approx( $test_data->{Group}{'Pr(>F)'}, 0.000000131343255, 'oneway_test: no formula p-value', 1e-13);
is_approx( $test_data->{Residuals}{Df}, 9.817673483264731, 'oneway_test: no formula parameter', 1e-13);

foreach my $key ('mean', 'size') {
	if (defined $test_data->{group_stats}{$key}) {
		pass("oneway_test: group_stats \"$key\" hash reference is defined");
	} else {
		fail("oneway_test: group_stats \"$key\" hash reference is NOT defined");
	}
}
@correct = ('Index 0','Index 1');
@ans = (5.03333333333333, 0.5);
foreach my $i (0..$#ans) {
	is_approx( $test_data->{group_stats}{mean}{$correct[$i]}, $ans[$i], "oneway_test: group_stats mean $correct[$i]", 1e-13);
}
@ans = (6, 6);
foreach my $i (0..$#ans) {
	is_approx( $test_data->{group_stats}{size}{$correct[$i]}, $ans[$i], "oneway_test: group_stats size $correct[$i]", 1e-13);
}
no_leaks_ok {
	eval {
		oneway_test([
			[5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
			[1,     1,   1,   0,   0,   0]
		]);
	}
} 'oneway_test: AoA: no leaks without formula'  unless $INC{'Devel/Cover.pm'};
#-------- now, hash of array with a formula
$test_data = oneway_test({
	yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
	ctrl  => [1,     1,   1,   0,   0,   0]
}, formula => 'yield ~ ctrl');
foreach my $key ('ctrl', 'Residuals', 'group_stats') {
	if (defined $test_data->{$key}) {
		pass("oneway_test: no formula; \"$key\" exists");
	} else {
		fail("oneway_test: no formula; \"$key\" does NOT exist");
	}
}
is_approx( $test_data->{ctrl}{Df}, 1, 'oneway_test: w/ formula df', 1e-13);
is_approx( $test_data->{ctrl}{'F value'}, 25.600000000000030, 'oneway_test: w/ formula F value', 1e-13);
is_approx( $test_data->{ctrl}{'Pr(>F)'}, 0.009707504058380, 'oneway_test: w/ formula p-value', 1e-13);
is_approx( $test_data->{Residuals}{Df}, 3.563474387527839, 'oneway_test: w/ formula parameter', 1e-13);

# dies_ok variants
dies_ok {
	oneway_test();
} 'oneway_test: dies with empty data';

dies_ok {
	oneway_test({ 'y' => [1,2,3], g => [1,2] }, formula => 'y ~ g')
} 'oneway_test: dies with mismatched lengths';
dies_ok {
	oneway_test({
		yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
		ctrl  => [1,     1,   1,   0,   0,   0]
	}, formula => 'yield');
} 'oneway_test: dies with bad formula';
dies_ok {
	oneway_test({
		yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
		ctrl  => [1,     1,   1,   0,   0,   0]
	}, formula => 'weight ~ ctrl');
} 'oneway_test: dies with non-existent key in formula';
#---------------
# summary
#---------------
$unif = [0.216281301648454, 0.109465371442155, 0.152664169241813, 0.000945096692653635, 0.297535893169954, 0.139163636355065, 0.433281186173499, 0.408562817186144, 0.407467355710114, 0.544592780352787, 0.487398883576855, 0.643468442596237, 0.68575522492846, 0.151846994960366, 0.0108012662535621, 0.765504103474193, 0.170995624940421, 0.100078161688572, 0.167327253677694, 0.178543828268637, 0.767033648977208, 0.0661950819672228, 0.581462013571265, 0.584800690627297, 0.762539213217881, 0.233645411264945, 0.693534299360277, 0.513290613560038, 0.41433325215603, 0.73243812858739, 0.478323977378576, 0.798072957187451, 0.237619591881074, 0.0780442614619403, 0.0360511965325365, 0.660791977980871, 0.912043981453014, 0.415870135589202, 0.831491877016528, 0.737746524987607, 0.663143394629547, 0.777232190070094, 0.816913688077346, 0.352381995029283, 0.744148647065789, 0.729401956002121, 0.465347760265214, 0.0785176667616199, 0.181269420249411, 0.679185700779414, 0.953224347579702, 0.567208135290578, 0.292655755357845, 0.105132055128408, 0.659550831920821, 0.260928737252719, 0.0114517904292804, 0.351924227264533, 0.539668158788782, 0.923435653386754, 0.679118775225493, 0.541537731065048, 0.235382321740357, 0.443470864148644, 0.49701302243216, 0.124681475319193, 0.403251186205477, 0.587374376354269, 0.0806932538910878, 0.613866141439061, 0.285459073394659, 0.882170197671563, 0.729358588888918, 0.872760579993155, 0.0726024246860497, 0.599972473528148, 0.857066010638153, 0.767531044559306, 0.877534848570345, 0.520403080150906, 0.115952349478963, 0.0624610171846882, 0.869999228452524, 0.294535850510563, 0.735723449504025, 0.727797725687921, 0.232053652861307, 0.486724559407229, 0.497430051763761, 0.65156677164174, 0.456347032400441, 0.785195872302019, 0.120408844445638, 0.45376514163452, 0.198314702590377, 0.144783732275236, 0.064735910938797, 0.30123682582493, 0.437664391094597];
$test_data = summary( $unif );
if (
	($test_data->[0] eq
	'---------------------------------------------------------------------------'
	)
	&&
	($test_data->[1] eq
	' # values      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. ')
	&&
	($test_data->[2] eq
	'---------------------------------------------------------------------------')
	) {
	pass('summary: takes array reference and prints correct results');
} else {
	fail('summary: failed to take array reference');
}
$test_data = summary( @{ $unif } );
if (
	($test_data->[0] eq
	'---------------------------------------------------------------------------'
	)
	&&
	($test_data->[1] eq
	' # values      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. ')
	&&
	($test_data->[2] eq
	'---------------------------------------------------------------------------')
	) {
	pass('summary: takes array and prints correct results');
} else {
	fail('summary: failed to take array');
}
%hoa = (A => runif(9),B => runif(9));
$test_data = summary(\%hoa);
if (
	($test_data->[0] =~ m/^\-+$/)
	&& ($test_data->[1] =~ m/^\h*Key\h*/)
	&& ($test_data->[2] =~ m/^\-+$/)
	&& ($test_data->[3] =~ m/^\h*A\h*9/)
	&& ($test_data->[4] =~ m/^\h*B\h*9/)
	&& (scalar @{ $test_data } == 5)
	){
	pass('summary: takes hash reference');
} else {
	fail('summary: failed to take hash reference');
}
%hoa = (A => runif(9),B => runif(9), C => runif(9));
$test_data = summary(
	\%hoa,
	nrows => 1
);
if (scalar @{ $test_data } == 4) {
	pass('summary: "nrows" limits rows of output');
} else {
	fail('summary: "nrows" does NOT limit rows of output');
}
$test_data = summary([runif(9), runif(9)]);
if (
	($test_data->[0] =~ m/^\-+$/)
	&&	($test_data->[1] =~ m/^\h*Index\h*/)
	&&	($test_data->[2] =~ m/^\-+$/)
	&&	($test_data->[3] =~ m/^\h*0\h*9\h+/)
	&&	($test_data->[4] =~ m/^\h*1\h*9\h+/)
	&&	(scalar @{ $test_data } == 5)
	){
	pass('summary: takes array reference');
} else {
	fail('summary: failed to take array reference');
}
#------
#   mode
#------
@arr = mode(1,3,3,3);
$size = scalar @arr;
if ($size == 1) {
	pass('mode: correctly returns a single value for this array');
} else {
	fail("mode: returns $size instead of a single value");
}
is_approx($arr[0], 3, 'mode: mode is correct number', 1e-14);

#------
@arr = mode([1,3,3,3]);
$size = scalar @arr;
if ($size == 1) {
	pass('mode: correctly returns a single value for this array');
} else {
	fail("mode: returns $size instead of a single value");
}
is_approx($arr[0], 3, 'mode: mode is correct number', 1e-14);
#--- non-numeric data
@arr = mode('a','a','c','c','z');
$size = scalar @arr;
if ($size == 2) {
	pass('mode: correctly returns a single value for this array');
} else {
	fail("mode: returns $size instead of a single value");
}
if ((grep {$_ eq 'a'} @arr) && (grep {$_ eq 'c'} @arr)) {
	pass('mode: both letters correctly show as modes');
} else {
	fail('mode: both letters are not showing correctly as modes');
}
dies_ok {
	mode(1, undef)
} 'mode: dies with an undefined value';
no_leaks_ok {
	mode(1, 2);
} 'mode: no leaks with scalars entered' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	mode([1, 2]);
} 'mode: no leaks with array reference entered' unless $INC{'Devel/Cover.pm'};
dies_ok {
	mode()
} 'mode: dies with 0 values entered';
#---------
# aoh2hoh
#---------
#@arr = (
#	{
#		a => 'A',
#		b => 'B',
#		r => '1st'
#	},
#	{
#		a => 'C',
#		b => 'D',
#		r => '2nd'
#	}
#);
#$test_data = aoh2hoh( \@arr,  'r' );
#if ((scalar keys %{ $test_data }) == scalar @arr) {
#	pass('aoh2hoh: 1 index in @arr is 1 hash key in the resulting hash-of-hash');
#} else {
#	fail('aoh2hoh: 1 index in @arr is NOT 1 hash key in the resulting hash-of-hash');
#}
#foreach my $hashkey ('1st', '2nd') {
#	if (defined $test_data->{$hashkey}) {
#		pass("aoh2hoh: \"$hashkey\" is defined in hoh");
#	} else {
#		fail("aoh2hoh: \"$hashkey\" is NOT defined in hoh");
#	}
#	if ((scalar keys %{ $test_data->{$hashkey} }) == 2) {
#		pass("aoh2hoh: \"$hashkey\" has the correct # of elements");
#	} else {
#		fail("aoh2hoh: \"$hashkey\" does NOT have the correct # of elements");
#	}
#	if ((defined $test_data->{$hashkey}{a}) && (defined $test_data->{$hashkey}{b})) {
#		pass("aoh2hoh: $hashkey has both keys defined");
#	} else {
#		fail("aoh2hoh: $hashkey does NOT have both keys defined");
#	}
#}
#if ($test_data->{'1st'}{a} eq 'A') {
#	pass('aoh2hoh: 1st key "a" is correct');
#} else {
#	fail('aoh2hoh: 1st key "a" is NOT correct');
#}
#if ($test_data->{'1st'}{b} eq 'B') {
#	pass('aoh2hoh: 1st key "b" is correct');
#} else {
#	fail('aoh2hoh: 1st key "b" is NOT correct');
#}
#if ($test_data->{'2nd'}{a} eq 'C') {
#	pass('aoh2hoh: 2nd key "a" is correct');
#} else {
#	fail('aoh2hoh: 2nd key "a" is NOT correct');
#}
#if ($test_data->{'2nd'}{b} eq 'D') {
#	pass('aoh2hoh: 2nd key "b" is correct');
#} else {
#	fail('aoh2hoh: 2nd key "b" is NOT correct');
#}
#$test_data = aoh2hoh( \@arr );
#if ((scalar keys %{ $test_data }) == scalar @arr) {
#	pass('aoh2hoh: 1 index in @arr is 1 hash key in the resulting hash-of-hash');
#} else {
#	fail('aoh2hoh: 1 index in @arr is NOT 1 hash key in the resulting hash-of-hash');
#}
#foreach my $hashkey (0, 1) {
#	if (defined $test_data->{$hashkey}) {
#		pass("aoh2hoh: \"$hashkey\" is defined in hoh");
#	} else {
#		fail("aoh2hoh: \"$hashkey\" is NOT defined in hoh");
#	}
#	if ((scalar keys %{ $test_data->{$hashkey} }) == 3) {
#		pass("aoh2hoh: \"$hashkey\" has the correct # of elements");
#	} else {
#		fail("aoh2hoh: \"$hashkey\" does NOT have the correct # of elements");
#	}
#	if ( 3 == scalar grep {defined $test_data->{$hashkey}{$_}} ('a', 'b', 'r')) {
#		pass("aoh2hoh: $hashkey has all 3 keys defined");
#	} else {
#		fail("aoh2hoh: $hashkey does NOT have all 3 keys defined");
#	}
#}
#if (
#	($test_data->{0}{a} eq 'A') &&	($test_data->{0}{b} eq 'B') &&
#	($test_data->{0}{r} eq '1st') &&	($test_data->{1}{a} eq 'C') &&
#	($test_data->{1}{b} eq 'D') &&	($test_data->{1}{r} eq '2nd')
#) {
#	pass('aoh2hoh: values are all correct without pivot key defined');
#} else {
#	fail('aoh2hoh: values are NOT all correct without pivot key defined');
#}
#-----------
# dnorm
#-----------
@ans = (0.000001486719515, 0.000133830225765, 0.004431848411938, 0.053990966513188,
0.241970724519143, 0.398942280401433, 0.241970724519143, 0.053990966513188, 0.004431848411938,
0.000133830225765, 0.000001486719515);
$idx = -5;
foreach my $i (0..$#ans) {
	is_approx(dnorm($idx), $ans[$i], "dnorm: dnorm($idx)", 1e-13);
	$idx++;
}
%h = (
-3 => 0.004431848411938,   -2.5 => 0.017528300493569, 
-1.5 => 0.129517595665892, -0.5 => 0.352065326764300, 
0.5 => 0.352065326764300,  1.5 => 0.129517595665892, 2.5 => 0.017528300493569);
foreach my $v (sort {$a <=> $b} keys %h) {
	is_approx(dnorm($v), $h{$v}, "dnorm: dnorm($v)", 1e-13);
}
$data = dnorm([1,2,3]);
@ans = (0.241970725, 0.053990967, 0.004431848);
if (scalar @{ $data } == 3) {
	pass('dnorm: passing a vector/array reference has the correct # of elements');
} else {
	my $nelem = scalar @{ $data };
	fail("dnorm: has $nelem elements, but should have 3");
}
foreach my $i (0..$#ans) {
	is_approx($data->[$i], $ans[$i], "dnorm, passed array reference index $i", 1e-7);
}
$data = dnorm(0, sd => 2);
is_approx($data, 0.199471140200716, 'dnorm: with sd = 2', 1e-13);
$data = dnorm(0, sd => 2, mean => 0);
is_approx($data, 0.199471140200716, 'dnorm: with sd = 2 and mean passed as key', 1e-13);
$data = dnorm(0, sd => 2, mean => 0, 'log' => 0);
is_approx($data, 0.199471140200716, 'dnorm: with sd = 2 and mean and log passed as key', 1e-13);
$data = dnorm(0, sd => 2, mean => 0, 'log' => 1);
is_approx($data, -1.612085713764618, 'dnorm: with log passed', 1e-13);
#-------
# ljoin
#-------
$data = { 'Jack Smith' => { age => 30 } };
$n = { 'Jack Smith' => { dept => 'Engineering' }, 'Jane Doe' => { age => 25 } };

ljoin($data, $n);
$size = scalar keys %{ $data };
if ($size == 1) {
	pass('ljoin: only 1 key in $data');
} else {
	fail("ljoin: should have 1 key, but has $size keys");
}
if (defined $data->{'Jack Smith'}) {
	pass('ljoin: correct key is defined');
} else {
	fail('ljoin: correct key is NOT defined');
}
foreach my $key ('age', 'dept') {
	if (defined $data->{'Jack Smith'}{$key}) {
		pass("ljoin: \"$key\" is defined");
	} else {
		fail("ljoin: \"$key\" is NOT defined");
	}
}
if (
	(abs($data->{'Jack Smith'}{age} - 30) < 1e-13)
	&&
	($data->{'Jack Smith'}{dept} eq 'Engineering')
	) {
	pass('ljoin: values are correct');
} else {
	fail('ljoin: values are NOT correct');
}
# --- Test: Hash of Arrays support in secondary hash ---
$data = { 'Sarah Connor' => { role => 'Leader' } };
$n    = { 'Sarah Connor' => [ 'status', 'Active', 'target', 'Skynet' ] };

ljoin($data, $n);

if (defined $data->{'Sarah Connor'}{status} && $data->{'Sarah Connor'}{status} eq 'Active') {
	pass('ljoin (HoA): "status" key from array is defined and correct');
} else {
	fail('ljoin (HoA): "status" key from array is NOT correct');
}

if (defined $data->{'Sarah Connor'}{target} && $data->{'Sarah Connor'}{target} eq 'Skynet') {
	pass('ljoin (HoA): "target" key from array is defined and correct');
} else {
	fail('ljoin (HoA): "target" key from array is NOT correct');
}
# --- Test: Overwriting existing columns ---
$data = { 'Bob Brown' => { score => 50, active => 1 } };
$n    = { 'Bob Brown' => { score => 99 } };

ljoin($data, $n);

if (abs($data->{'Bob Brown'}{score} - 99) < 1e-13) {
	pass('ljoin: existing column value is overwritten correctly');
} else {
	fail('ljoin: existing column value was NOT overwritten');
}

if (defined $data->{'Bob Brown'}{active} && (abs($data->{'Bob Brown'}{active} - 1) < 1e-13)) {
	pass('ljoin: untouched existing column remains intact');
} else {
	fail('ljoin: untouched existing column was lost or modified');
}
# --- Test: Invalid inner structures (Segfault protection) ---
$data = { 'Eve' => 'Just a string, not a hash' };
$n    = { 'Eve' => { status => 'Online' } };

# If the XS is unsafe, the next line will immediately segfault and kill the test script.
ljoin($data, $n);

if (!ref($data->{'Eve'}) && $data->{'Eve'} eq 'Just a string, not a hash') {
	pass('ljoin: gracefully ignores rows where primary value is a string');
} else {
	fail('ljoin: improperly modified a non-reference row value');
}
#---------
# add_data
#---------
$data = { 'Jack Smith' => { age => 30 } };
$n = { 
    'Jack Smith' => { dept => 'Engineering' },             # Update existing (Hash)
    'Jane Doe'   => { age => 25, dept => 'Sales' },        # Add new (Hash)
    'Bob Brown'  => [ 'age', 40, 'dept', 'IT' ],           # Add new (Array)
    'Invalid'    => 'Not a reference'                      # Edge case safety
};

add_data($data, $n);

# --- Test 1: Total key count ---
$size = scalar keys %{ $data };
if ($size == 3) {
	pass('add_data: correct number of keys (3) in $data');
} else {
	fail("add_data: should have 3 keys, but has $size keys");
}

# --- Test 2: Existing row updated correctly ---
if (defined $data->{'Jack Smith'} && 
	(abs($data->{'Jack Smith'}{age} - 30) < 1e-13) && 
	$data->{'Jack Smith'}{dept} eq 'Engineering') {
	pass('add_data: existing row updated correctly');
} else {
	fail('add_data: existing row was NOT updated correctly');
}

# --- Test 3: New row added from Hash ---
if (defined $data->{'Jane Doe'}) {
	pass('add_data: new row from hash is defined');
	if ((abs($data->{'Jane Doe'}{age} - 25) < 1e-13) && $data->{'Jane Doe'}{dept} eq 'Sales') {
		pass('add_data: new row from hash has correct values');
	} else {
		fail('add_data: new row from hash has INCORRECT values');
	}
} else {
	fail('add_data: new row from hash is NOT defined');
}

# --- Test 4: New row added from Array ---
if (defined $data->{'Bob Brown'}) {
	pass('add_data: new row from array is defined');
	if ((abs($data->{'Bob Brown'}{age} - 40) < 1e-13) && $data->{'Bob Brown'}{dept} eq 'IT') {
		pass('add_data: new row from array has correct values');
	} else {
		fail('add_data: new row from array has INCORRECT values');
	}
} else {
	fail('add_data: new row from array is NOT defined');
}

# --- Test 5: Safety check for invalid inner data ---
if (!defined $data->{'Invalid'}) {
	pass('add_data: gracefully skipped non-reference data without crashing');
} else {
	fail('add_data: improperly added a row for non-reference data');
}

#--------
# group_by
#--------
dies_ok {
	group_by( undef, 'a', 'b');
} 'group_by: dies when given an undefined data reference';
#dies_ok {
#	group_by('not a data ref', 'a', 'b');
#} 'group_by: dies when data is not a data reference';
dies_ok {
	group_by( { A => [1,2] }, undef, 'b');
} 'group_by: dies when target key reference (row name in HoH) is not defined';
dies_ok {
	group_by( { A => [1,2] }, 'b', undef);
} 'group_by: dies when target key reference (col. name in HoH) is not defined';

#
# TEST SET 1: Array of Hashes (AoH)
#
my $aoh_data = [
 { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
 { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
 { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
 { 'Gender' => 'Female' } # Intentional missing target value
];

my $res1 = group_by($aoh_data, 'Testosterone, total (nmol/L)', 'Gender');

if (scalar keys %{ $res1 } == 2) {
	pass('group_by (AoH): correct number of group keys created');
} else {
	fail('group_by (AoH): incorrect number of group keys');
}

if (scalar @{ $res1->{'Male'} } == 2 &&
(abs($res1->{'Male'}[0] - 20.5) < 1e-13) &&
(abs($res1->{'Male'}[1] - 18.2) < 1e-13)
){
	pass('group_by (AoH): Male target values grouped correctly');
} else {
	fail('group_by (AoH): Male target values NOT grouped correctly');
}

if (scalar @{ $res1->{'Female'} } == 1 && abs($res1->{'Female'}[0] - 1.8) < 1e-13) {
	pass('group_by (AoH): Female target values grouped correctly (including undef values)');
} else {
	fail('group_by (AoH): Female target values NOT grouped correctly');
}
no_leaks_ok {
	eval {
		group_by($aoh_data, 'Testosterone, total (nmol/L)', 'Gender')
	};
} 'group_by: no leaks with Array of hashes input' unless $INC{'Devel/Cover.pm'};
#
# TEST SET 2: Hash of Arrays (HoA)
#
my $hoa_data = {
	'Gender'                       => ['Male', 'Female', 'Male', 'Female'],
	'Testosterone, total (nmol/L)' => [22.1,   2.5,      19.4,   undef   ]
};

my $res2 = group_by($hoa_data, 'Testosterone, total (nmol/L)', 'Gender');

no_leaks_ok {
	eval {
		group_by($hoa_data, 'Testosterone, total (nmol/L)', 'Gender')
	};
} 'group_by: no leaks with Hash of arrays input' unless $INC{'Devel/Cover.pm'};
if (scalar keys %$res2 == 2) {
	pass('group_by (HoA): correct number of group keys created');
} else {
	fail('group_by (HoA): incorrect number of group keys');
}

if (scalar @{ $res2->{'Male'} } == 2
&& abs($res2->{'Male'}[0] - 22.1) < 1e-13
&& abs($res2->{'Male'}[1] - 19.4) < 1e-13) {
	pass('group_by (HoA): Male target values grouped correctly');
} else {
	fail('group_by (HoA): Male target values NOT grouped correctly');
}

if (!defined $res2->{'Female'}[1]) {
	pass('group_by (HoA): gracefully handled undefined target arrays element');
} else {
	fail('group_by (HoA): failed to handle undefined target array element');
}
# ==========================================
# TEST SET 3: Hash of Hashes (HoH)
# ==========================================
$test_data = {
 'Patient_A' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 20.5 },
 'Patient_B' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => 1.8 },
 'Patient_C' => { 'Gender' => 'Male',   'Testosterone, total (nmol/L)' => 18.2 },
 'Patient_D' => { 'Gender' => 'Female' }, # Intentional missing target value
 'Patient_E' => { 'Gender' => 'Female', 'Testosterone, total (nmol/L)' => undef } # Explicit undef
};

my $res3 = group_by($test_data, 'Testosterone, total (nmol/L)', 'Gender');

if (scalar keys %$res3 == 2) {
	pass('group_by (HoH): correct number of group keys created');
} else {
	fail('group_by (HoH): incorrect number of group keys');
}

# Sort the array to protect the test against randomized hash iteration order
my @males = sort { $a <=> $b } @{ $res3->{'Male'} };

if (scalar @males == 2 && (abs($males[0] - 18.2) < 1e-13) && abs($males[1] - 20.5) < 1e-13) {
	pass('group_by (HoH): Male target values grouped correctly');
} else {
	fail('group_by (HoH): Male target values NOT grouped correctly');
}

my @females = @{ $res3->{'Female'} };

if (scalar @females == 1 && abs($females[0] - 1.8) < 1e-13) {
	pass('group_by (HoH): Female target correctly handled missing and undef values');
} else {
	fail('group_by (HoH): Female target improperly included undefined/missing values');
}
no_leaks_ok {
	eval {
		group_by($test_data, 'Testosterone, total (nmol/L)', 'Gender')
	};
} 'group_by: no leaks with Hash of hash input' unless $INC{'Devel/Cover.pm'};
#
# TEST SET 4: Group By with Code Filters
#

# Data representing males and females, where we only want to keep Sex => 'f'
$test_data = [
 { 'Gender' => 'Group 1', 'Sex' => 'm', 'Testosterone' => 20.5 },
 { 'Gender' => 'Group 1', 'Sex' => 'f', 'Testosterone' => 1.8 },
 { 'Gender' => 'Group 2', 'Sex' => 'm', 'Testosterone' => 18.2 },
 { 'Gender' => 'Group 2', 'Sex' => 'f', 'Testosterone' => 2.1 }
];

$test_data = group_by($test_data, 'Testosterone', 'Gender', { Sex => sub { $_ eq 'f' } });

# Verification: Only 1 item should exist in each group array (the females)
if (scalar @{ $test_data->{'Group 1'} } == 1 && abs($test_data->{'Group 1'}[0] - 1.8) < 1e-13) {
	pass('group_by (filter AoH): successfully evaluated $_ eq "f" and filtered out Group 1 Male');
} else {
	fail('group_by (filter AoH): failed to filter Group 1');
}

if (scalar @{ $test_data->{'Group 2'} } == 1 && abs($test_data->{'Group 2'}[0] - 2.1) < 1e-13) {
	pass('group_by (filter AoH): successfully evaluated $_ eq "f" and filtered out Group 2 Male');
} else {
	fail('group_by (filter AoH): failed to filter Group 2');
}

$test_data = {
 'Gender'       => [ 'Group 1', 'Group 1', 'Group 2', 'Group 2' ],
 'Sex'          => [ 'm',       'f',       'm',       'f'       ],
 'Testosterone' => [ 20.5,      1.8,       18.2,      2.1       ]
};

$test_data = group_by($test_data, 'Testosterone', 'Gender', { Sex => sub { $_ eq 'f' } });

if (scalar @{ $test_data->{'Group 1'} } == 1 && abs($test_data->{'Group 1'}[0] - 1.8) < 1e-13) {
	pass('group_by (filter HoA): successfully evaluated $_ eq "f" and filtered HoA columns');
} else {
	fail('group_by (filter HoA): failed to filter HoA array parallelly');
}
no_leaks_ok {
	eval {
		group_by($test_data, 'Testosterone', 'Gender', { Sex => sub { $_ eq 'f' } });
	};
} 'group_by: no leaks with filter' unless $INC{'Devel/Cover.pm'};
done_testing();

