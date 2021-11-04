#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD::binfo' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD::binfo $Rex::Virtualization::CBSD::binfo::VERSION, Perl $], $^X" );
