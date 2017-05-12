#!/usr/bin/perl

# Test using our own changes file

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 9;
use File::Spec::Functions ':ALL';
use Module::Changes::ADAMK;





#####################################################################
# Test the Config::Tiny Changes file

SCOPE: {
	my $file = catfile('t', 'data', 'Config-Tiny');
	ok( -f $file, 'Found Config-Tiny Changes file' );
	my $changes = Module::Changes::ADAMK->read($file);
	isa_ok( $changes, 'Module::Changes::ADAMK');
	is( $changes->dist_name,   'Config-Tiny',  '->dist_name ok'   );
	is( $changes->module_name, 'Config::Tiny', '->module_name ok' );
	is( scalar($changes->releases), 26, '->releases is 26' );
	isa_ok( $changes->current, 'Module::Changes::ADAMK::Release' );
	is( $changes->current_version, '2.12', '->current_version ok' );
	is( $changes->current->version, '2.12', '->current_release->version matches' );
	is( $changes->current->date, 'Thu  1 Nov 2007', '->current_release->date ok' );
}
