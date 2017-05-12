#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok('SIAM') or BAIL_OUT('');
    use_ok('SIAM::Driver::Simple') or BAIL_OUT('');
}

diag( "Testing SIAM $SIAM::VERSION, Perl $], $^X" );
