#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PGObject::Util::Catalog::Types' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Util::Catalog::Types $PGObject::Util::Catalog::Types::VERSION, Perl $], $^X" );
