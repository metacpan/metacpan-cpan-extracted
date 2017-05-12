#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Pod::Trial::LinkImg' );
}

diag( "Testing Pod::Trial::LinkImg $Pod::Trial::LinkImg::VERSION, Perl $], $^X" );
