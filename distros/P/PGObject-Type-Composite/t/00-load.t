#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PGObject::Type::Composite' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Type::Composite $PGObject::Type::Composite::VERSION, Perl $], $^X" );
