# Hey Emacs, this is -*- perl -*-
use Test::More tests => 1;

BEGIN {
	use_ok( 'OCS::Client' );
}

diag( "Testing OCS::Client $OCS::Client::VERSION, Perl $], $^X" );
