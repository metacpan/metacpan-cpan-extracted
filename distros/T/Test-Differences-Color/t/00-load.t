#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Differences::Color' );
}

diag( "Testing Test::Differences::Color $Test::Differences::Color::VERSION, Perl $], $^X" );
