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

######################################################
######################################################

# Check if the UV (unsigned value) Perl type is 64bit
my $has_64bit = ($Config{uvsize} == 8);
# Number of iterations to use for our average testing
my $iterations = 10000;

####################################################

# rand() test
my $num = get_avg_rand(undef, $iterations);
ok($num > 0.45 && $num < 0.55, "rand()") or diag("$num not between 0.45 and 0.55");

# rand(1) test which should be the same as rand()
$num = get_avg_rand(1, $iterations);
ok($num > 0.45 && $num < 0.55, "rand(1)") or diag("$num not between 0.45 and 0.55");

# rand(10) test
$num = get_avg_rand(10, $iterations);
ok($num > 4.5 && $num < 5.5, "rand(10)") or diag("$num not between 4.5 and 5.5");;

done_testing();

###################################################################
###################################################################

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
