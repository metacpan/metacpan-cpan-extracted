#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;
use Test::NoWarnings;
use File::Spec ();
use OpenGL::RWX;

# Locate the test file
my $file = File::Spec->catfile( 't', 'data', 'pan4test', 'pan4test.rwx' );
ok( -f $file, "Found test file $file" );

# Create the object
my $rwx = new_ok( 'OpenGL::RWX', [
	file => $file,
], 'Created RWX object' );

# Load the model
ok( $rwx->init, '->init ok' );
ok( defined $rwx->list, '->list ok' );
