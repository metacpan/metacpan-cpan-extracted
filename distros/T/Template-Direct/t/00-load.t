#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Template::Direct' );
}

diag( "Testing Template::Direct $Template::Direct::VERSION, Perl $], $^X" );
