#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::MyOpera' );
}

diag( "Testing Net::MyOpera $Net::MyOpera::VERSION, Perl $], $^X" );
