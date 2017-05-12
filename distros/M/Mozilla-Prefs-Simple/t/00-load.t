#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Mozilla::Prefs::Simple' );
}

diag( "Testing Mozilla::Prefs::Simple $Mozilla::Prefs::Simple::VERSION, Perl $], $^X" );
