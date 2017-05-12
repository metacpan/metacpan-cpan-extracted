#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Primeval' ) || print "Bail out!
";
}

diag( "Testing Primeval $Primeval::VERSION, Perl $], $^X" );
