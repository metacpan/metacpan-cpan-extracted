#!/usr/bin/perl

use Test::More;

# AUTHOR test
if ( not $ENV{TEST_AUTHOR} ) {
	plan skip_all => 'Author test. Sent $ENV{TEST_AUTHOR} to a true value to run.';
} else {
	eval "use Test::CheckManifest";
	if ( $@ ) {
		plan skip_all => 'Test::CheckManifest required for validating the MANIFEST';
	} else {
		ok_manifest( {
			'filter'	=>	[ qr/\.svn/, qr/\.git/, qr/\.tar\.gz$/ ],
		} );
	}
}
