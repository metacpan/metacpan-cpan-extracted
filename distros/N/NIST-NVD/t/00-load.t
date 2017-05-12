#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'NIST::NVD' ) || print "Bail out!
";
    use_ok( 'NIST::NVD::Query' ) || print "Bail out!
";
}

diag( "Testing NIST::NVD $NIST::NVD::VERSION, Perl $], $^X" );
