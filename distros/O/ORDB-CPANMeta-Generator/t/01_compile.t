#!/usr/bin/perl

use 5.008;
use strict;
use warnings;
BEGIN {
	$| = 1;
}

use Test::More tests => 1;

use_ok( 'ORDB::CPANMeta::Generator' );
