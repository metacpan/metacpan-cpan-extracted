#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD::bpause' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD::bpause $Rex::Virtualization::CBSD::bpause::VERSION, Perl $], $^X" );
