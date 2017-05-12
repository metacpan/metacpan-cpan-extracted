#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::Bot::IRC::NumericCodes' );
}

diag( "Testing Net::Bot::IRC::NumericCodes $Net::Bot::IRC::NumericCodes::VERSION, Perl $], $^X" );
