#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'STEVEB::Dist::Mgr' ) || print "Bail out!\n";
}

diag( "Testing STEVEB::Dist::Mgr $STEVEB::Dist::Mgr::VERSION, Module $], $^X" );
