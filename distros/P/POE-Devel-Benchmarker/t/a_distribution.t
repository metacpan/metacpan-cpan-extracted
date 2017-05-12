#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	eval "require Test::Distribution";
	if ( $@ ) {
		plan skip_all => 'Test::Distribution required for validating the dist';
	} else {
		Test::Distribution->import( not => 'podcover' );
	}
}
