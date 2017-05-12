#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Norma' ) || print "Bail out!
";
}

diag( "Testing Norma $Norma::VERSION, Perl $], $^X" );
