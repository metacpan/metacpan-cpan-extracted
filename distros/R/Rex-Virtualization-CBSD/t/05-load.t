#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD::blist' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD::blist $Rex::Virtualization::CBSD::blist::VERSION, Perl $], $^X" );
