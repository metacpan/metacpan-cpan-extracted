#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Path::Resource' );
}

diag( "Testing Path::Resource $Path::Resource::VERSION, Perl $], $^X" );
