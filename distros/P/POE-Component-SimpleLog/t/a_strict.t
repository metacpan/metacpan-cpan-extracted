#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	eval "use Test::Strict";
	if ( $@ ) {
		plan skip_all => 'Test::Strict required to test strictness';
	} else {
		all_perl_files_ok( 'lib/' );
	}
}
