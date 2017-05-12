#!/usr/bin/perl

# Texture tests that don't require displaying anything.
# This is mainly to test image type compatibility.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 3;
use Test::NoWarnings;
use File::Spec                      ();
use File::ShareDir                  ();
use SDL::Tutorial::3DWorld::Texture ();

# Create the object (which only tests the file exists)
my $jpg = new_ok( 'SDL::Tutorial::3DWorld::Texture', [
	file => File::Spec->catfile(
		File::ShareDir::dist_dir('SDL-Tutorial-3DWorld'),
		'skybox',
		'up.jpg',
	),
], 'Created jpg texture handle' );

# Initialise the object into OpenGL
ok( $jpg->init, 'Initialised jpg texture' );
