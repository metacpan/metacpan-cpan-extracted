#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Net::KashFlow' );
}

diag( "Testing Net::KashFlow $Net::KashFlow::VERSION, Perl $], $^X" );
