#!perl -w
use strict;
use Test::More;

eval q{use Test::Portability::Files 0.05};
plan skip_all => 'Test::Portability::Files required for testing filenames portability'
	if $@;

run_tests();
