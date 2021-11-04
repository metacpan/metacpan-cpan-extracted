#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD::bnic_list' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD::bnic_list $Rex::Virtualization::CBSD::bnic_list::VERSION, Perl $], $^X" );
