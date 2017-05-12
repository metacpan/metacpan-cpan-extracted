#!perl -T

use Test::More tests => 9;

BEGIN {
    use_ok( 'MongoDBx::Tiny' )            || print "Bail out!\n";
    use_ok( 'MongoDBx::Tiny::Util' )      || print "Bail out!\n";
    use_ok( 'MongoDBx::Tiny::Cursor' )    || print "Bail out!\n";
    use_ok( 'MongoDBx::Tiny::Validator' ) || print "Bail out!\n";
    use_ok( 'MongoDBx::Tiny::GridFS' )    || print "Bail out!\n";
    use_ok( 'MongoDBx::Tiny::Document' )  || print "Bail out!\n";
    use_ok( 'MongoDBx::Tiny::Attributes' )|| print "Bail out!\n";
    use_ok( 'MongoDBx::Tiny::Relation' )  || print "Bail out!\n";
    use_ok( 'MongoDBx::Tiny::Plugin::SingleByCache' )  || print "Bail out!\n";
}

diag( "Testing MongoDBx::Tiny $MongoDBx::Tiny::VERSION, Perl $], $^X" );
