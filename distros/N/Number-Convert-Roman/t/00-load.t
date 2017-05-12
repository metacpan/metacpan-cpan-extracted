#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Number::Convert::Roman' ) || print "Bail out!\n";
}

diag( "Testing Number::Convert::Roman $Number::Convert::Roman::VERSION, Perl $], $^X" );
