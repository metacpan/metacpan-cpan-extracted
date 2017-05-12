#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	eval "use Test::Dependencies exclude => [ qw/ POE::Devel::Benchmarker Module::Build / ], style => 'light';";
	if ( $@ ) {
		plan skip_all => 'Test::Dependencies required to test perl module deps';
	} else {
		ok_dependencies();
	}
}
