#!perl

# taint checks make this thing angry

use Test::More tests => 1;

BEGIN {
    use_ok( 'RDF::KV' ) || print "Bail out!\n";
}

diag( "Testing RDF::KV $RDF::KV::VERSION, Perl $], $^X" );
