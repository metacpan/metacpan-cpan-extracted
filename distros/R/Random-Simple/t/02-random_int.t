#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More;
use Random::Simple;
use Config;
use Time::HiRes qw(sleep);

########################################################
# Testing random numbers is hard so we do basic sanity #
# checking of the bounds                               #
########################################################

# Use a specific random seed so we can output it via diag for testing later
my $seed1 = perl_rand64();
my $seed2 = perl_rand64();

# If we want to recreate tests we can set the seeds manually here:
#$seed1 = 127;
#$seed2 = 489;
Random::Simple::seed($seed1,$seed2);
diag("Random Seeds: $seed1 / $seed2");

# Check if the UV (unsigned value) Perl type is 64bit
my $has_64bit = ($Config{uvsize} == 8);
my $min       = 100;
my $max       = 200;
my $num       = 0; # placeholder for re-usable var

# Number of iterations to use for our average testing
my $iterations = 10000;

# Test integer range that's positive
$num = get_avg_random_int($min, $max, $iterations);
ok($num >= $min && $num <= $max, "Random int between $min and $max") or diag("$num not between $min and $max");

# Test that we generate big numbers
cmp_ok(get_avg_random_int(2**8 , 2**32 -1, $iterations), '>', 2**8 - 1 , "More than 2^8");
cmp_ok(get_avg_random_int(2**16, 2**32 -1, $iterations), '>', 2**16 - 1, "More than 2^16");
cmp_ok(get_avg_random_int(2**24, 2**32 -1, $iterations), '>', 2**24 - 1, "More than 2^24");

# Test with a zero minimum
$num = get_avg_random_int(0, 10, $iterations);
ok($num > 4.7 && $num < 5.3, "random_int(0, 10) a zero min") or diag("$num not between 4.7 and 5.3");

# Test with zero maximum
$num = get_avg_random_int(-50, 0, $iterations);
ok($num > -26 && $num < -24, "random_int(-50, 0) a zero maximum") or diag("$num not between -26 and -24");

# Negative range
$num = get_avg_random_int(-100, -75, $iterations);
ok($num > -88 && $num < -87, "random_int(-100, -75) fully negative range") or diag("$num not between -88 and -87");

# Positive range that does NOT start at zero
$num = get_avg_random_int(1, 10, $iterations);
ok($num > 5.3 && $num < 5.6, "random_int(1, 10)") or diag("$num not between 5.3 and 5.6");

# Build a list of a bunch of random numbers
my @nums;
for (my $i = 0; $i < $iterations; $i++) {
	push(@nums, random_int($min, $max));
}

# Check if ANY of the items are the mim/max
my $has_min = int(grep { $_ == $min } @nums);
my $has_max = int(grep { $_ == $max } @nums);

# Make sure we contain the lower and upper bounds (inclusive)
ok($has_min, "random_int() contains lower bound") or diag("$min not in sample");
ok($has_max, "random_int() contains upper bound") or diag("$max not in sample");

done_testing();

###################################################################
###################################################################

sub get_avg_randX {
	my ($bits, $count) = @_;

	$count ||= 50000;

	my $total = 0;
	for (my $i = 0; $i < $count; $i++) {
		my $num;
		if ($bits == 32) {
			$num = Random::Simple::_rand32();
		} elsif ($bits == 64) {
			$num = Random::Simple::_rand64();
		} else {
			$num = 0; # bees?
		}

		$total += $num;
	}

	my $ret = $total / $count;

	return $ret;
}

sub get_avg_random_int {
	my ($min, $max, $count) = @_;

	$count ||= 50000;

	my $total = 0;
	for (my $i = 0; $i < $count; $i++) {
		my $num = random_int($min, $max);

		$total += $num;
	}

	my $ret = $total / $count;
	#print "($min, $max) $num / $count = $ret\n";

	return $ret;
}

sub get_avg_random_float {
	my ($count) = @_;

	$count ||= 50000;

	my $total = 0;
	for (my $i = 0; $i < $count; $i++) {
		my $num = random_float();

		$total += $num;
	}

	my $ret = $total / $count;
	#print "FF: $total / $count = $ret\n";

	return $ret;
}

sub get_avg_rand {
	my ($one, $count) = @_;

	$count ||= 50000;

	my $total = 0;
	for (my $i = 0; $i < $count; $i++) {
		my $num;
		if (defined $one) {
			$num = rand($one);
		} else {
			$num = rand();
		}

		$total += $num;
	}

	my $ret = $total / $count;
	#print "($min, $max) $num / $count = $ret\n";

	return $ret;
}

sub perl_rand64 {
	my $high = int(rand() * 2**32 - 1);
	my $low  = int(rand() * 2**32 - 1);

	my $ret = ($high << 32) | $low;

	return $ret;
}
