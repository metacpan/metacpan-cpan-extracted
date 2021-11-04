#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::CMDB::TOML' ) || print "Bail out!\n";
}

diag( "Testing Rex::CMDB::TOML $Rex::CMDB::TOML::VERSION, Perl $], $^X" );
