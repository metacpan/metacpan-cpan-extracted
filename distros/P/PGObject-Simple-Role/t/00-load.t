#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'PGObject::Simple::Role' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Simple::Role $PGObject::Simple::Role::VERSION, Perl $], $^X" );
