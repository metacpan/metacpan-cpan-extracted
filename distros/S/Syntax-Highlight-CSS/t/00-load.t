#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Syntax::Highlight::CSS' );
}

diag( "Testing Syntax::Highlight::CSS $Syntax::Highlight::CSS::VERSION, Perl $], $^X" );
