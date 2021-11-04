#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Rex::Virtualization::CBSD::vm_os_profiles' ) || print "Bail out!\n";
}

diag( "Testing Rex::Virtualization::CBSD::vm_os_profiles $Rex::Virtualization::CBSD::vm_os_profiles::VERSION, Perl $], $^X" );
