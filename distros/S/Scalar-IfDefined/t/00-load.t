#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Scalar::IfDefined' ) || print "Bail out!\n";
}

diag( "Testing Scalar::IfDefined $Scalar::IfDefined::VERSION, Perl $], $^X" );
