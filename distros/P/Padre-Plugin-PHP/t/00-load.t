#!perl

use Test::More tests => 2;

BEGIN {
	use_ok( 'Padre::Plugin::PHP' );
	use_ok( 'Padre::Document::PHP' );
}

diag( "Testing Padre::Plugin::PHP $Padre::Plugin::PHP::VERSION, Perl $], $^X" );
