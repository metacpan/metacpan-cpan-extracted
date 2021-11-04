#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD::bcheckpoint_destroyall' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD::bcheckpoint_destroyall $Rex::Virtualization::CBSD::bcheckpoint_destroyall::VERSION, Perl $], $^X" );
