#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MongoDBx::KeyValue' ) || print "Bail out!";
}

diag( "Testing MongoDBx::KeyValue $MongoDBx::KeyValue::VERSION, Perl $], $^X" );
