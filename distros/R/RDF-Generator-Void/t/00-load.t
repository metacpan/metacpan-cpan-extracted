#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'RDF::Generator::Void' ) || print "Bail out!\n";
}

diag( "Testing RDF::Generator::Void $RDF::Generator::Void::VERSION, Perl $], $^X" );
