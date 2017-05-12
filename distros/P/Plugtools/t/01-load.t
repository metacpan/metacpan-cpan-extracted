#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Plugtools::Plugins::Dump' );
}

diag( "Testing Plugtools::Plugins::Dump $Plugtools::Plugins::Dump::VERSION, Perl $], $^X" );
