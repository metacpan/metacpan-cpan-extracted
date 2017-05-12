#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Stlgen' ) || print "Bail out!
";
}

diag( "Testing Stlgen $Stlgen::VERSION, Perl $], $^X" );
