#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Samba::SIDhelper' );
}

diag( "Testing Samba::SIDhelper $Samba::SIDhelper::VERSION, Perl $], $^X" );
