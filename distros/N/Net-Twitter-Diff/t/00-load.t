#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Twitter::Diff' );
}

diag( "Testing Net::Twitter::Diff $Net::Twitter::Diff::VERSION, Perl $], $^X" );
