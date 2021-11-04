#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD::cbsd_base_dir' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD::cbsd_base_dir $Rex::Virtualization::CBSD::cbsd_base_dir::VERSION, Perl $], $^X" );
