#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Rose::DBx::Role::NestTransaction' ) || print "Bail out!\n";
}

diag( "Testing Rose::DBx::Role::NestTransaction $Rose::DBx::Role::NestTransaction::VERSION, Perl $], $^X" );
