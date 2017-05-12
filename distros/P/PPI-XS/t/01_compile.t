#!/usr/bin/perl

# Load testing for PPI::XS

# This test script only tests that the tree compiles

use strict;
BEGIN {
	$| = 1;
	$^W = 1;
}

use Test::More tests => 4;

ok( $] >= 5.005, "Your perl is new enough" );

# Load PPI::XS, which should also load
# PPI and do everything properly
use_ok( 'PPI::XS' );

# Did PPI itself get loaded?
ok( $PPI::VERSION, 'PPI was autoloaded by PPI::XS'     );
ok( $PPI::Element::VERSION, 'The PDOM has been loaded' );
