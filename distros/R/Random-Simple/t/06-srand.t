#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More;
use Random::Simple;
use Config;
use Time::HiRes qw(sleep);

# Use a specific random seed so we can output it via diag for testing later
my $seed      = perl_rand32();
my $srand_ret = srand($seed);

my $rseed = srand();
cmp_ok(srand()       , '>' , 0          , "srand() returns the seed");
cmp_ok(srand(123.456), '==', 123        , "srand() with a float returns the int");
cmp_ok($rseed        , '==', int($rseed), "srand() float returns the int");

# If we pass in a seed, we get it back
is($seed, $srand_ret, "srand(\$num) returns the seed");

done_testing();

###################################################################
###################################################################

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

sub perl_rand32 {
	my $ret = int(rand() * 2**32 - 1);

	return $ret;
}

sub perl_rand64 {
	my $high = int(rand() * 2**32 - 1);
	my $low  = int(rand() * 2**32 - 1);

	my $ret = ($high << 32) | $low;

	return $ret;
}
