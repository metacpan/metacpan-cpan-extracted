#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD::p9shares_rm' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD::p9shares_rm $Rex::Virtualization::CBSD::p9shares_rm::VERSION, Perl $], $^X" );
