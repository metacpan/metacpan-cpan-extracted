#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SystemTray::Applet' );
}

diag( "Testing SystemTray::Applet $SystemTray::Applet::VERSION, Perl $], $^X" );
