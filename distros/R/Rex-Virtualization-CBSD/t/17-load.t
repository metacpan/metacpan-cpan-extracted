#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD::p9shares_list' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD::p9shares_list $Rex::Virtualization::CBSD::p9shares_list::VERSION, Perl $], $^X" );
