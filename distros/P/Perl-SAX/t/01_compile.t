#!/usr/bin/perl

# Compile testing for Perl::SAX

# This test script only tests that all modules compile

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Class::Autouse ':devel'; # Load immediately

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Does the module load
use_ok( 'Perl::SAX' );
