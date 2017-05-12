#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SystemTray::Applet::Win32' );
}

diag( "Testing SystemTray::Applet::Win32 $SystemTray::Applet::Win32::VERSION, Perl $], $^X" );
