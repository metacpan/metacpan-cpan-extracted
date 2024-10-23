#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '1.04';

use Test::More;

use String::Random::Regexp::regxstring qw/generate_random_strings/;

my $VERBOSITY = 1;

# sanity check : must suceed
ok defined generate_random_strings('abc', 1), 
	'generate_random_strings()'." : called for sanity checking and succeeded."
or BAIL_OUT();

# must fail, regexstr is undef
ok ! defined generate_random_strings(undef, 10), 
	'generate_random_strings()'." : called and failed as expected."
or BAIL_OUT();

# must fail, number of strings to return is 0
ok ! defined generate_random_strings('abc', 0), 
	'generate_random_strings()'." : called and failed as expected."
or BAIL_OUT();

# must fail, number of strings to return is negative
ok ! defined generate_random_strings('abc', -1), 
	'generate_random_strings()'." : called and failed as expected."
or BAIL_OUT();

done_testing;

1;
