#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use Test::NoWarnings;
use File::Spec                    ();
use SDL::Tutorial::3DWorld::Asset ();

# Location of the test file
my $directory = File::Spec->catdir('share', 'model', 'lollipop');
ok( -d $directory, "Found test directory '$directory'" );

# Create the collection object
my $collection = new_ok( 'SDL::Tutorial::3DWorld::Asset', [
	directory => $directory,
], 'Created Collection object' );

# Fetch various resources
isa_ok(
	$collection->texture('white'),
	'SDL::Tutorial::3DWorld::Texture',
);
isa_ok(
	$collection->model('hflollipop1gr'),
	'SDL::Tutorial::3DWorld::RWX',
);
