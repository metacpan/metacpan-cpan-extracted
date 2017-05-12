#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PGObject::Composite::Role' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Composite::Role $PGObject::Composite::Role::VERSION, Perl $], $^X" );
