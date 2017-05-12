#!perl -T

use Test::More tests => 5;

BEGIN {
	use_ok( 'Getopt::Long' );
	use_ok( 'Pod::Usage' );
	use_ok( 'Class::Accessor::Fast' );
	use_ok( 'Net::NNTP' );
	use_ok( 'News::Search' );
}

diag( "Testing News::Search $News::Search::VERSION, Perl $], $^X" );
