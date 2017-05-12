#!/usr/bin/perl -T

use Test::More tests => 2;

BEGIN {
	use lib 'lib';
	use_ok( 'Printer::EVOLIS' );
	use_ok( 'Printer::EVOLIS::Parallel' );
}

diag( "Testing Printer::EVOLIS $Printer::EVOLIS::VERSION, Perl $], $^X" );
