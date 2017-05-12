#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Term::GnuScreen' );
}

diag( "Testing Term::GnuScreen $Term::GnuScreen::VERSION, Perl $], $^X" );
