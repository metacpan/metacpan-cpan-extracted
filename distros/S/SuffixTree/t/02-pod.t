#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

plan( skip_all => 
	'Author test: Set $ENV{RELEASE_TESTING} to a true value to run.' )
	if ! $ENV{RELEASE_TESTING};

# Ensure a recent version of Test::Pod

my $min_tp = 1.22;
eval "use Test::Pod $min_tp;"; ## no critic (eval)

plan skip_all => "Test::Pod $min_tp required for testing POD" 
	if $@;

all_pod_files_ok();
