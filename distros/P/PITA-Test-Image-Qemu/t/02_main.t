#!/usr/bin/perl

# Main (and basic) testing for PITA::Test::Image::Qemu

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'PITA::Test::Image::Qemu' );

my $file = PITA::Test::Image::Qemu->filename;
ok( -f $file, '->filename returns file that exists' );

exit(0);
