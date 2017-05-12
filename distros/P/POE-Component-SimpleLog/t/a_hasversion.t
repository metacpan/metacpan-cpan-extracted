#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	eval "use Test::HasVersion";
	if ( $@ ) {
		plan skip_all => 'Test::HasVersion required for testing for version numbers';
	} else {
		all_pm_version_ok();
	}
}
