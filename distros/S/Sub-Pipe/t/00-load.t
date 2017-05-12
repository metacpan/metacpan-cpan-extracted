#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Sub::Pipe' );
}

diag( "Testing Sub::Pipe $Sub::Pipe::VERSION, Perl $], $^X" );
