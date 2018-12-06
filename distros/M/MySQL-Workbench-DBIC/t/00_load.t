#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'MySQL::Workbench::DBIC' );
}

diag( "Testing MySQL::Workbench::DBIC $MySQL::Workbench::DBIC::VERSION, Perl $], $^X" );
