#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Rose::DBx::Object::Renderer' );
}

diag( "Testing Rose::DBx::Object::Renderer $Rose::DBx::Object::Renderer::VERSION, Perl $], $^X" );
