#!/usr/bin/perl -w

use strict;
use Test::More tests => 15;

use Statistics::Descriptive::LogScale;

my $stat = Statistics::Descriptive::LogScale->new( base => 1.001 );

note " ---- uniform";
$stat->clear;
$stat->add_data(1..100);
abs_error_ok ($stat->skewness, 0, 0.01, "1..100 unskewed");
abs_error_ok ($stat->kurtosis, -1.2, 0.01, "kurt = -1.2");

note " ---- triangle";
$stat->clear;
$stat->add_data(-$_..$_) for 1..100;
abs_error_ok ($stat->skewness, 0, 0.01, "symmetric = unskewed");
abs_error_ok ($stat->kurtosis, -0.6, 0.01, "kurt = -0.6");

note " ---- normal";
$stat->clear;
# See Box-Muller transform
my $pi = atan2(1,1) * 4;
foreach my $angle (0..99) {
	foreach my $radius (1..100) {
		$stat->add_data(
			sin (2*$pi*$angle/100) * sqrt(-2*log $radius/100),
			cos (2*$pi*$angle/100) * sqrt(-2*log $radius/100),
		);
	};
};

# self-test
abs_error_ok ($stat->mean, 0, 1E-3, "self-test: got normal");
abs_error_ok ($stat->standard_deviation, 1, 0.02, "self-test: got normal");

abs_error_ok ($stat->skewness, 0, 0.1, "normal unskewed");
abs_error_ok ($stat->kurtosis, 0, 0.15, "normal zero kurt");

note " ---- exponential";
$stat->clear;
$stat->add_data(-log ($_/20000)) for 1..20000;
	# experiments show kurt & skew approach precalc values
	# as we add more data
abs_error_ok ($stat->skewness, 2, 0.1, "known skewness = 2");
abs_error_ok ($stat->kurtosis, 6, 0.3, "known kurtosis = 6");
my $old_kurt = $stat->kurtosis;

note " ---- exponential rev. sign";
$stat->clear;
$stat->add_data(log ($_/20000)) for 1..20000;
	# experiments show kurt & skew approach precalc values
	# as we add more data
abs_error_ok ($stat->skewness, -2, 0.1, "known skewness = 2");
abs_error_ok ($stat->kurtosis, 6, 0.3, "known kurtosis = 6");
abs_error_ok ($stat->kurtosis, $old_kurt, 0.001, "kurt. old value");

note " ---- bernoulli";
$stat->clear;
$stat->add_data(0, 1) for 1..1000;
is ($stat->skewness, 0, "zero skew");
abs_error_ok ($stat->kurtosis, -2, 0.01, "min. kurtosis");

sub abs_error_ok {
	my ($got, $exp, $err, $msg) = @_;
	my $off = abs ($got - $exp);
	if ($off < $err) {
		pass ("$msg; off by $off");
		return 1;
	} else {
		fail ($msg);
		diag "got=$got, expected=$exp, diff > $err";
		return 0;
	};
};

