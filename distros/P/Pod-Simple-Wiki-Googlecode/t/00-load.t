#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Pod::Simple::Wiki::Googlecode' );
}

diag( "Testing Pod::Simple::Wiki::Googlecode $Pod::Simple::Wiki::Googlecode::VERSION, Perl $], $^X" );
