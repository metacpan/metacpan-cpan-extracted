#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Plugtools::Plugins::Samba::makeSambaAccount' );
}

diag( "Testing Plugtools::Plugins::Samba::makeSambaAccount $Plugtools::Plugins::Samba::makeSambaAccount::VERSION, Perl $], $^X" );
