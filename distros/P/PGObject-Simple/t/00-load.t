#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'PGObject::Simple' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Simple $PGObject::Simple::VERSION, Perl $], $^X" );
