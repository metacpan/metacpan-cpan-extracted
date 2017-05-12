#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 11;
use Test::NoWarnings;
use File::Spec                  ();
use SDL::Tutorial::3DWorld::MTL ();

# Location of the test file
my $file = File::Spec->catfile('t', 'data', 'example.mtl');
ok( -f $file, "Found test file '$file'" );

# Create the MTL object
my $mtl = new_ok( 'SDL::Tutorial::3DWorld::MTL', [
	file => $file,
], 'Created MTL object' );

# Initialise the MTL object
ok( $mtl->init, '->init ok' );
isa_ok( $mtl->asset, 'SDL::Tutorial::3DWorld::Asset' );
like(
	$mtl->asset->directory,
	qr/\bdata$/,
	'->asset refers to the correct directory',
);

# Fetch a material by name
my $material = $mtl->material('shinyred');
ok( $material, 'Found material shinyred' );
ok( $material->{ambient},   'Has an ambient component'  );
ok( $material->{diffuse},   'Has a diffuse component'   );
ok( $material->{specular},  'Has a specular component'  );
ok( $material->{shininess}, 'Has a shinyness component' );
