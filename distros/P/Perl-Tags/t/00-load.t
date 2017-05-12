use strict; use warnings;

use Test::More tests => 1;

BEGIN {
	use_ok( 'Perl::Tags' );
}

diag( "Testing Perl::Tags $Perl::Tags::VERSION, Perl $], $^X" );
