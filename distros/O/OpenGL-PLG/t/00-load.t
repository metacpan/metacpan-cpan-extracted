#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'OpenGL::PLG' );
}

diag( "Testing OpenGL::PLG $OpenGL::PLG::VERSION, Perl $], $^X" );
