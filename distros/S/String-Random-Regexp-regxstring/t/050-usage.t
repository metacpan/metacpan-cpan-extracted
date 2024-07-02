#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '1.00';

use Test::More;

use String::Random::Regexp::regxstring qw/generate_random_strings/;

my $VERBOSITY = 1;

ok defined generate_random_strings('abc', 1), 
	'generate_random_strings()'." : called for sanity checking and succeeded."
or BAIL_OUT();

ok ! defined generate_random_strings(undef, 10), 
	'generate_random_strings()'." : called and failed as expected."
or BAIL_OUT();

ok ! defined generate_random_strings('abc', 0), 
	'generate_random_strings()'." : called and failed as expected."
or BAIL_OUT();

ok ! defined generate_random_strings('abc', -1), 
	'generate_random_strings()'." : called and failed as expected."
or BAIL_OUT();

done_testing;

1;
