#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Sub::Monkey' ) || print "Bail out!\n";
}

diag( "Testing Sub::Monkey $Sub::Monkey::VERSION, Perl $], $^X" );
