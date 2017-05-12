#!/usr/bin/perl

# Load test the SQL::String module

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More 'tests' => 2;

ok( $] >= 5.005, 'Your perl is new enough' );

use_ok( 'SQL::String' );
