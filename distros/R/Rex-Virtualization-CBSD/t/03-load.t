#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD::freejname' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD::freejname $Rex::Virtualization::CBSD::freejname::VERSION, Perl $], $^X" );
