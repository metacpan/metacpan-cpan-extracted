#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD $Rex::Virtualization::CBSD::VERSION, Perl $], $^X" );
