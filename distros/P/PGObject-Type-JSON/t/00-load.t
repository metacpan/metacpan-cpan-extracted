#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'PGObject::Type::JSON' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Type::JSON $PGObject::Type::JSON::VERSION, Perl $], $^X" );
