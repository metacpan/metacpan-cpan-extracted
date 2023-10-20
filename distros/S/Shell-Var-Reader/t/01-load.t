#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Shell::Var::Reader::CMDB' ) || print "Bail out!\n";
}

diag( "Testing Shell::Var::Reader::CMDB $Shell::Var::Reader::CMDB::VERSION, Perl $], $^X" );
