#!/usr/bin/perl

# Compile testing for Mirror::URI

use 5.006;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

use_ok( 'Mirror::URI'  );
use_ok( 'Mirror::YAML' );
use_ok( 'Mirror::JSON' );
use_ok( 'Mirror::CPAN' );
