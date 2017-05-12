#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sledge::Plugin::QueryHash' );
}

diag( "Testing Sledge::Plugin::QueryHash $Sledge::Plugin::QueryHash::VERSION, Perl $], $^X" );
