#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Plugtools::Plugins::HomeOU' );
}

diag( "Testing Plugtools::Plugins::HomeOU $Plugtools::Plugins::HomeOU::VERSION, Perl $], $^X" );
