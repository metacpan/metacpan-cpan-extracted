#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Perl::Critic::Itch' );
}

diag( "Testing Perl::Critic::Itch $Perl::Critic::Itch::VERSION, Perl $], $^X" );
