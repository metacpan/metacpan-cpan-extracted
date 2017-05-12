#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'MongoDBx::Class' ) || print "Bail out!\n";
}

diag( "Testing MongoDBx::Class $MongoDBx::Class::VERSION, Perl $], $^X" );
