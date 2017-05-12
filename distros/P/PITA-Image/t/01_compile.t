#!/usr/bin/perl

# Compile-testing for PITA

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}
use Test::More tests => 6;
use File::Spec::Functions ':ALL';

BEGIN {
	ok( $] > 5.005, 'Perl version is 5.005 or newer' );
	use_ok( 'PITA::Image'           );
	use_ok( 'PITA::Image::Platform' );
	use_ok( 'PITA::Image::Task'     );
	use_ok( 'PITA::Image::Discover' );
	use_ok( 'PITA::Image::Test'     );
}

exit(0);
