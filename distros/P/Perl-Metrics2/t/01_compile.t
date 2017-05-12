#!/usr/bin/perl

use 5.008005;
use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;

use_ok( 'Perl::Metrics2'        );
use_ok( 'Perl::Metrics2::Parse' );
