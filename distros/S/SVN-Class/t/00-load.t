##!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'SVN::Class' );
}

diag( "Testing SVN::Class $SVN::Class::VERSION, Perl $], $^X" );
