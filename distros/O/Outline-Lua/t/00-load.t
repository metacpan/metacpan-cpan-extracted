#!perl -T

use strict;
use Test::More tests => 2;

BEGIN {
	use_ok( 'Outline::Lua' );
}

diag( "Testing Outline::Lua $Outline::Lua::VERSION, Perl $], $^X" );

my $lua = Outline::Lua::new();

isa_ok( $lua, "Outline::Lua" );
