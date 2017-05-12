#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;

require_ok( 'ORLite::Migrate'        );
require_ok( 'ORLite::Migrate::Timeline' );
require_ok( 'ORLite::Migrate::Patch' );
