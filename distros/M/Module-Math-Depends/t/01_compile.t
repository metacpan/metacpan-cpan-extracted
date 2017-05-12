#!/usr/bin/perl

# Load testing for Module::Math::Depends

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

# Check their perl version
ok( $] >= 5.005, "Your perl is new enough" );

# Load the module
use_ok( 'Module::Math::Depends' );
