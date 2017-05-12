#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	eval "use Test::Compile";
	if ( $@ ) {
		plan skip_all => 'Test::Compile required for validating the perl files';
	} else {
		all_pm_files_ok();
	}
}
