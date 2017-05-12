#!/usr/bin/perl

# Load testing for PPI::XS

# Tests to make sure that PPI::XS is autoloaded when PPI itself is loaded.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use PPI;

# Double check PPI itself was loaded
ok( $PPI::VERSION, 'PPI was autoloaded by PPI::XS' );
ok( $PPI::Element::VERSION, 'The PDOM has been loaded' );

# Did PPI::XS get loaded?
ok( $PPI::XS::VERSION, 'PPI::XS was autoloaded ok' );
