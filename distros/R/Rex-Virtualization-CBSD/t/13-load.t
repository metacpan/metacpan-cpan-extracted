#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD::bstop' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD::bstop $Rex::Virtualization::CBSD::bstop::VERSION, Perl $], $^X" );
