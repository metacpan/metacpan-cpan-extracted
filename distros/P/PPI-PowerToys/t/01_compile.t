#!/usr/bin/perl

# Compile-testing for Perl::PowerToys

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 6;
use Test::Script;

ok( $] > 5.006, 'Perl version is 5.006 or newer' );

use_ok( 'PPI::PowerToys'          );
use_ok( 'PPI::App::ppi_version'   );
use_ok( 'PPI::App::ppi_copyright' );

script_compiles_ok( 'script/ppi_version'   );
script_compiles_ok( 'script/ppi_copyright' );
