#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 7;
use Test::NoWarnings;
use File::Spec                  ();
use SDL::Tutorial::3DWorld::RWX ();

# Location of the test file
my $file = File::Spec->catfile('share', 'model', 'lollipop', 'hflollipop1gr.rwx');
ok( -f $file, "Found test file '$file'" );

# Create the RWX object
my $rwx = new_ok( 'SDL::Tutorial::3DWorld::RWX', [
	file => $file,
], 'Created RWX object' );

# Initialise the RWX object
ok( $rwx->init, '->init ok' );
ok( defined $rwx->list, '->list ok' );
isa_ok( $rwx->asset, 'SDL::Tutorial::3DWorld::Asset' );
like(
	$rwx->asset->directory,
	qr/\blollipop$/,
	'->asset refers to the correct directory',
);
