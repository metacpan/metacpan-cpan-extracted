#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Twitter::Cabal' );
}

diag( "Testing Net::Twitter::Cabal $Net::Twitter::Cabal::VERSION, Perl $], $^X" );
