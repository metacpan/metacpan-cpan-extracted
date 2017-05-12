#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Pod::Simple::Vim' );
}

diag( "Testing Pod::Vim $Pod::Vim::VERSION, Perl $], $^X" );
