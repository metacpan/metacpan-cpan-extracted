#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More;
use Random::Simple;
use Config;
use Time::HiRes qw(sleep);

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

########################################################
# Testing random numbers is hard so we do basic sanity #
# checking of the bounds                               #
########################################################

# Check if the UV (unsigned value) Perl type is 64bit
my $has_64bit = ($Config{uvsize} == 8);
my $num       = 0; # placeholder for re-usable var

# Number of iterations to use for our average testing
my $iterations = 10000;

###################################################################
###################################################################

my $data = {};

my @arr = qw(red yellow blue green black white orange purple);
for (my $i = 0; $i < $iterations; $i++) {
	my $elem = random_elem(@arr);

	$data->{$elem}++;
}

# Make sure random_elem() includes the ends of the array
cmp_ok($data->{red}   , '>', 20, "Contains first element");
cmp_ok($data->{purple}, '>', 20, "Contains last element");

done_testing();

###################################################################
###################################################################

sub perl_rand64 {
	my $high = int(rand() * 2**32 - 1);
	my $low  = int(rand() * 2**32 - 1);

	my $ret = ($high << 32) | $low;

	return $ret;
}
