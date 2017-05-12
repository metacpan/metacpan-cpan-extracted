#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SystemTray::Applet::Gnome' );
}

diag( "Testing SystemTray::Applet::Gnome $SystemTray::Applet::Gnome::VERSION, Perl $], $^X" );
