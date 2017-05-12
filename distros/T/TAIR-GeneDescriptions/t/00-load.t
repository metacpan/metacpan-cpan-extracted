#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'TAIR::GeneDescriptions' ) || print "Bail out!
";
}

diag( "Testing TAIR::GeneDescriptions $TAIR::GeneDescriptions::VERSION, Perl $], $^X" );
