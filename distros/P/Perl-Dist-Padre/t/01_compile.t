#!/usr/bin/perl

use Test::More tests => 2;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
	ok( $] >= 5.008001, 'Perl version is new enough' ) or BAIL_OUT('Perl version not new enough.');
	use_ok( 'Perl::Dist::Padre' ) or BAIL_OUT('Could not load Perl::Dist::Padre.');
}

diag( "Testing Perl::Dist::Padre $Perl::Dist::Padre::VERSION" );

