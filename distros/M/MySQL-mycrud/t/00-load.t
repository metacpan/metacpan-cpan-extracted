#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MySQL::mycrud' ) || print "Bail out!\n";
}

diag( "Testing MySQL::mycrud $MySQL::mycrud::VERSION, Perl $], $^X" );
