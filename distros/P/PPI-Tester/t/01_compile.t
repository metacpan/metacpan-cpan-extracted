#!/usr/bin/perl

# Compile testing for PPI::Tester

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
BEGIN {
	if ( $ENV{ADAMK_RELEASE} ) {
		plan( skip_all => "Skipping on ADAMK's release automation" );
	} else {
		plan( tests => 3 );
	}
}
use Test::More;
use Test::Script;

ok( $] >= 5.006, 'Your perl is new enough' );

use_ok( 'PPI::Tester' );

script_compiles_ok( 'script/ppitester' );
