#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'MongooseX::JSMethod' ) || print "Bail out!\n";
}

diag( "Testing MongooseX::JSMethod $MongooseX::JSMethod::VERSION, Perl $], $^X" );
