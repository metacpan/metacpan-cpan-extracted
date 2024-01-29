#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::CMDB::YAMLwithRoles' ) || print "Bail out!\n";
}

diag( "Testing Rex::CMDB::YAMLwithRoles $Rex::CMDB::YAMLwithRoles::VERSION, Perl $], $^X" );
