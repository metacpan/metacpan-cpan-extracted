#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Script::Carp' );
}

diag( "Testing Script::Carp $Script::Carp::VERSION, Perl $], $^X" );
