#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::HTML' );
}

diag( "Testing Padre::Plugin::HTML $Padre::Plugin::HTML::VERSION, Perl $], $^X" );
