#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Plugtools::Plugins::Samba::setPass' );
}

diag( "Testing Plugtools::Plugins::Samba::setPass $Plugtools::Plugins::Samba::setPass::VERSION, Perl $], $^X" );
