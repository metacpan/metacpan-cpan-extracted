#!/usr/bin/perl

# Tests creating an simple invalid object

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use File::Temp   ();
use Mirror::YAML ();

SCOPE: {
	my $bad  = File::Temp->newdir;
	ok( -d $bad, 'Found test directory' );
	my $conf = Mirror::YAML->read($bad->dirname);
	isa_ok( $conf, 'Mirror::YAML' );
	is( $conf->valid, !1, '->valid false' );
}
