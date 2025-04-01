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

# Check if the UV (unsigned value) Perl type is 64bit
my $has_64bit = ($Config{uvsize} == 8);

my $min = 100;
my $max = 200;
my $num = 0; # placeholder for re-usable var

# Number of iterations to use for our average testing
my $iterations = 10000;

# Use a specific random seed so we can output it via diag for testing later
my $seed1 = perl_rand64();
my $seed2 = perl_rand64();

# If we want to recreate tests we can set the seeds manually here:
#$seed1 = 127;
#$seed2 = 489;
Random::Simple::seed($seed1,$seed2);
diag("Random Seeds: $seed1 / $seed2");

###################################################################
###################################################################

# _rand32() average should be about 2**31
$num = get_avg_randX(32, $iterations);
ok($num > 2**30 && $num < 2**32, "rand32() generates the right size numbers") or diag("rand32(): $num not in range");

# Only do the 64bit tests on platforms that support it
if ($has_64bit) {
	# _rand64() average should be about 2**63
	$num = get_avg_randX(64, $iterations);
	ok($num > 2**62 && $num < 2**64, "rand64() generates the right size numbers") or diag("rand64(): $num not in range");
} else {
	diag("Skipping 64bit tests on 32bit platform");
}

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

sub perl_rand64 {
	my $high = int(rand() * 2**32 - 1);
	my $low  = int(rand() * 2**32 - 1);

	my $ret = ($high << 32) | $low;

	return $ret;
}
