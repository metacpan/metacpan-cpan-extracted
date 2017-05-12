#!/usr/bin/perl

use strict;

BEGIN {
	$|  = 1;
	$^W = 1;

	# Twice to avoid a warning
	$DB::single = $DB::single = 1;
}

use Test::More tests => 3;
use Test::NoWarnings;

ok( $] >= 5.008, 'Perl version is new enough' );
use_ok('Padre::Plugin::ShellScript');
