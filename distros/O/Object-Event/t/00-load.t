#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Object::Event' );
}

diag( "Testing Object::Event $Object::Event::VERSION, Perl $], $^X" );
