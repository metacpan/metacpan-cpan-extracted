#!/usr/bin/perl

# Load test the Template::Plugin::StringTree module and do some super-basic tests

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

# Does everything load?
use Test::More tests => 3;

ok( $] >= 5.005, 'Your perl is new enough' );

use_ok( 'Template::Plugin::StringTree' );
use_ok( 'Template::Plugin::StringTree::Node' );
