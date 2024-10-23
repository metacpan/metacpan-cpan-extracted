#!/usr/bin/env perl

use strict;
use warnings;

our $VERSION = '1.04';

use Test::More;

use String::Random::Regexp::regxstring qw/generate_random_strings/;

my $VERBOSITY = 1;

my $regx_str = '^([A-Z]|[0-9]){10}\d{5}xxx(\d{3})?';
my $N = 3;
my $results = generate_random_strings($regx_str, $N);

ok defined $results,
	'generate_random_strings()'." : called and got good results."
or BAIL_OUT();

diag join "\n", @$results;

done_testing;

1;
