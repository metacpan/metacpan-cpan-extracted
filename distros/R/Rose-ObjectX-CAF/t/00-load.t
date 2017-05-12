#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Rose::ObjectX::CAF' );
}

diag( "Testing Rose::ObjectX::CAF $Rose::ObjectX::CAF::VERSION, Perl $], $^X" );
