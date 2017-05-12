#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	eval "use Test::MinimumVersion";
	if ( $@ ) {
		plan skip_all => 'Test::MinimumVersion required to test minimum perl version';
	} else {
		all_minimum_version_from_metayml_ok();
	}
}
