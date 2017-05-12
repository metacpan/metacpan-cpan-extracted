#!perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'RDF::Helper::Properties' ) || print "Bail out!
";
}

diag( "Testing RDF::Helper::Properties $RDF::Helper::Properties::VERSION, Perl $], $^X" );
