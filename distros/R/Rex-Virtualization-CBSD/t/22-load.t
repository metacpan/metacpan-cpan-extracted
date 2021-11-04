#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD::bsnapshot_removeall' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD::bsnapshot_removeall $Rex::Virtualization::CBSD::bsnapshot_removeall::VERSION, Perl $], $^X" );
