#!/usr/bin/perl

# Compile-testing for Process

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use File::Spec::Functions ':ALL';
use lib catdir('t', 'lib');

ok( $] > 5.005, 'Perl version is 5.005 or newer' );

use_ok( 'Process::Backgroundable' );

use_ok( 'MyBackgroundProcess'  );
