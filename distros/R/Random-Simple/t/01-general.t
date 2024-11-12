#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More;
use Random::Simple;
use Config;

########################################################
# Testing random numbers is hard so we do basic sanity #
# checking of the bounds                               #
########################################################

my $has_64bit = ($Config{uvsize} == 8);

my $min = 100;
my $max = 200;

my $num = random_int($min, $max);

cmp_ok($num, '<', $max + 1, "Less than max");
cmp_ok($num, '>', $min - 1, "More than min");

cmp_ok(random_int(2**8, 2**32 -1) , '>', 2**8 - 1 , "More than 2^8");
cmp_ok(random_int(2**16, 2**32 -1), '>', 2**16 - 1, "More than 2^16");
cmp_ok(random_int(2**24, 2**32 -1), '>', 2**24 - 1, "More than 2^24");

is(length(random_bytes(16))   , 16  , "Generate 16 random bytes");
is(length(random_bytes(1))    , 1   , "Generate one random bytes");
is(length(random_bytes(0))    , 0   , "Generate zero random bytes");
is(length(random_bytes(-1))   , 0   , "Generate -1 random bytes");
is(length(random_bytes(49))   , 49  , "Generate 49 random bytes");
is(length(random_bytes(1024)) , 1024, "Generate 1024 random bytes");

# Pick a bunch of random numbers to give us a sample
my $data = {};
$min     = -5;
$max     = 5;
for (0 .. 10000) {
	my $num = random_int($min, $max);
	$data->{$num}++;
}

# Make sure we contain the lower and upper bounds (inclusive)
ok(defined($data->{$min}), "random_int() contains lower bound") or diag("$min not in sample");
ok(defined($data->{$max}), "random_int() contains upper bound") or diag("$max not in sample");

###################################################################
# Logic: generate a bunch of randoms and calculate the average
# to see if we fall in a logical threshold
###################################################################

my $i     = 0;
my $total = 0;
my $count = 10000;
while ($i < $count) {
	my $num = Random::Simple::_rand32();
	$total += $num;
	$i++;
}

my $avg_32 = int($total / $count);
#print "32: $avg_32\n";

cmp_ok($avg_32, '>', 0    , "rand32() generates numbers");
cmp_ok($avg_32, '<', 2**32, "rand32() generates the right size numbers");

###################################################################

if ($has_64bit) {
	$i     = 0;
	$total = 0;
	while ($i < $count) {
		my $num = Random::Simple::_rand64();
		$total += $num;
		$i++;
	}

	my $avg_64 = int($total / $count);
	#print "64: $avg_64\n";

	cmp_ok($avg_64, '>', 2**32, "rand64() generates the right size numbers");
	cmp_ok($avg_64, '<', 2**64, "rand64() generates the right size numbers");
}

done_testing();
