#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PGObject::Util::BulkLoad' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Util::BulkLoad $PGObject::Util::BulkLoad::VERSION, Perl $], $^X" );
