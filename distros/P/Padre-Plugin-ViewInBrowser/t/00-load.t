#!perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'Padre::Plugin::ViewInBrowser' );
}

diag( "Testing Padre::Plugin::ViewInBrowser $Padre::Plugin::ViewInBrowser::VERSION, Perl $], $^X" );
