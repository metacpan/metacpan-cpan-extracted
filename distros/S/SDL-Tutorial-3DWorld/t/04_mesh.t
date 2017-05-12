#!/usr/bin/perl

# General tests for our mesh abstraction

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 8;
use Test::NoWarnings;
use SDL::Tutorial::3DWorld::Mesh ();





######################################################################
# Main Tests

# Create a simple square
my $mesh = new_ok( 'SDL::Tutorial::3DWorld::Mesh' => [], '->new ok' );
$mesh->add_vertex( -1, 0, 2 );
$mesh->add_vertex(  1, 0, 2 );
$mesh->add_vertex(  1, 1, 2 );
$mesh->add_vertex( -1, 1, 2 );
$mesh->add_quad(
	0,          # Material
	1, 2, 3, 4, # Vertexes
);

# Does the mesh look right?
is( $mesh->max_vertex, 4, '->max_vertex ok' );
is_deeply( [ $mesh->box ], [ -1, 0, 2, 1, 1, 2 ], '->box ok' );

# Generate an OpenGL display list
is( $mesh->as_list, 0, '->as_list ok' );

# Generate an OGA set (OpenGL::Array)
my $oga = $mesh->as_oga;
is( ref($oga), 'HASH', '->as_oga returns a HASH' );
isa_ok( $oga->{vertex}, 'OpenGL::Array' );
is( $oga->{vertex}->elements, 12, '->elements matches expected' );
