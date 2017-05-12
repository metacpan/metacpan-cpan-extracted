#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Plugtools::Plugins::Samba' );
}

diag( "Testing Plugtools::Plugins::Samba $Plugtools::Plugins::Samba::VERSION, Perl $], $^X" );
