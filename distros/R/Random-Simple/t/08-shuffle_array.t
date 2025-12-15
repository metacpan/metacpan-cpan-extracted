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

# Check if the UV (unsigned value) Perl type is 64bit
my $has_64bit = ($Config{uvsize} == 8);

###################################################################
###################################################################

my @arr   = qw(red yellow blue green black white orange purple);
my @mixed = shuffle_array(@arr);

# Make sure we stay the same size
cmp_ok(scalar(@arr), '==', scalar(@mixed), "Shuffled array is the same size");

# Confirm all elements from original array are still in the shuffled array
my $ok = 1;
foreach my $item (@arr) {
	if (!in_array($item, @mixed)) {
		diag("Missing: '$item'\n");
		$ok = 0;
	}
}

ok($ok, "All items in original array still present");

done_testing();

###################################################################
###################################################################

sub in_array {
	my ($needle, @haystack) = @_;

	my $ret = grep { $_ eq $needle; } @haystack;

	return $ret;
}

sub perl_rand64 {
	my $high = int(rand() * 2**32 - 1);
	my $low  = int(rand() * 2**32 - 1);

	my $ret = ($high << 32) | $low;

	return $ret;
}
