#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD::bset' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD::bset $Rex::Virtualization::CBSD::bset::VERSION, Perl $], $^X" );
