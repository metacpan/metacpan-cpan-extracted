#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Quote::Code' );
}

diag( "Testing Quote::Code $Quote::Code::VERSION, Perl $], $^X" );
