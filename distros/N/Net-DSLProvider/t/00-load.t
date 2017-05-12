#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::DSLProvider' );
}

diag( "Testing Net::DSLProvider $Net::DSLProvider::VERSION, Perl $], $^X" );
