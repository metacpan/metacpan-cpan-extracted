#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MySQL::QueryMulti' ) || print "Bail out!\n";
}

diag( "Testing MySQL::QueryMulti $MySQL::QueryMulti::VERSION, Perl $], $^X" );
