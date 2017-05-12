#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

ok( $] >= 5.008, 'Perl version is new enough' );

use_ok( 'Perl::Dist::Chocolate' );
use_ok( 't::lib::Test'          );
