#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'NIST::NVD::Store::SQLite3' ) || print "Bail out!
";
}

diag( "Testing NIST::NVD::Store::SQLite3 $NIST::NVD::Store::SQLite3::VERSION, Perl $], $^X" );
