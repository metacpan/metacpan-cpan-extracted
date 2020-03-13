#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rtmgr::Gen::Db' ) || print "Bail out!\n";
}

diag( "Testing Rtmgr::Gen::Db $Rtmgr::Gen::Db::VERSION, Perl $], $^X" );
