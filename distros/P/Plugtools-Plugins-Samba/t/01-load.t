#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Plugtools::Plugins::Samba::SIDupdate' );
}

diag( "Testing Plugtools::Plugins::Samba::SIDupdate $Plugtools::Plugins::Samba::SIDupdate::VERSION, Perl $], $^X" );
