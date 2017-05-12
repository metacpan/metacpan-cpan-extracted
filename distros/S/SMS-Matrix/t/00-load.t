#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'SMS::Matrix' );
}

diag( "Testing SMS::Matrix $SMS::Matrix::VERSION, Perl $], $^X" );
