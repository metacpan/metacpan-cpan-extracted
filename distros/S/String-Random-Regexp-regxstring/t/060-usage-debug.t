#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '1.04';

use Test::More;

use String::Random::Regexp::regxstring qw/generate_random_strings/;

my $VERBOSITY = 1;

# debug is ON
ok defined generate_random_strings('abc', 1, 1), 
	'generate_random_strings()'." : called for sanity checking and succeeded."
or BAIL_OUT();

# no debug
ok defined generate_random_strings('abc', 1, 0), 
	'generate_random_strings()'." : called for sanity checking and succeeded."
or BAIL_OUT();

# no debug
ok defined generate_random_strings('abc', 1), 
	'generate_random_strings()'." : called for sanity checking and succeeded."
or BAIL_OUT();

done_testing;

1;
