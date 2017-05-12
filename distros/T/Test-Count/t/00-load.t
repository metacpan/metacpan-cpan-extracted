#!perl -T

use Test::More tests => 3;

BEGIN {
    # TEST
	use_ok( 'Test::Count' );
    # TEST
	use_ok( 'Test::Count::Parser' );
    # TEST
	use_ok( 'Test::Count::Filter::ByFileType::App');
}

diag( "Testing Test::Count $Test::Count::VERSION, Perl $], $^X" );
