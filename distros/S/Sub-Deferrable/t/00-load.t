#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sub::Deferrable' );
}

diag( "Testing Sub::Deferrable $Sub::Deferrable::VERSION, Perl $], $^X" );
