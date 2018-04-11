#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'PGObject::Util::AsyncPool' ) || print "Bail out!\n";
}

diag( "Testing PGObject::Util::AsyncPool $PGObject::Util::AsyncPool::VERSION, Perl $], $^X" );
