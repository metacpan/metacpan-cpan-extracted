#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Number::Closest::XS' ) || print "Bail out!\n";
}

diag( "Testing Number::Closest::XS $Number::Closest::XS::VERSION, Perl $], $^X" );
