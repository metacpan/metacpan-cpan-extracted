#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'PGObject::Type::BigFloat' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Type::BigFloat $PGObject::Type::BigFloat::VERSION, Perl $], $^X" );
