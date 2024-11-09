#!/usr/bin/perl

use 5.006;
use strict;
use warnings;
use Test::More;
use Random::Simple;

########################################################
# Testing random numbers is hard so we do basic sanity #
# checking of the bounds                               #
########################################################

my $min = 100;
my $max = 200;

my $num = random_int($min, $max);

cmp_ok($num, '<', $max, "Less than max");
cmp_ok($num, '>', $min, "More than min");

cmp_ok(random_int(2**16, 2**63), '>', 2**16, "More than 2^16");
cmp_ok(random_int(2**24, 2**63), '>', 2**24, "More than 2^24");
cmp_ok(random_int(2**32, 2**63), '>', 2**32, "More than 2^32");
cmp_ok(random_int(2**48, 2**63), '>', 2**48, "More than 2^48");

is(length(random_bytes(16))   , 16  , "Generate 16 random bytes");
is(length(random_bytes(1))    , 1   , "Generate one random bytes");
is(length(random_bytes(0))    , 0   , "Generate zero random bytes");
is(length(random_bytes(-1))   , 0   , "Generate -1 random bytes");
is(length(random_bytes(49))   , 49  , "Generate 49 random bytes");
is(length(random_bytes(1024)) , 1024, "Generate 1024 random bytes");

done_testing();
