#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'PGObject::Type::DateTime' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Type::DateTime $PGObject::Type::DateTime::VERSION, Perl $], $^X" );
