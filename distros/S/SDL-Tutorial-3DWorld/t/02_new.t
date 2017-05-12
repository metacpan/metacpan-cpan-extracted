#!/usr/bin/perl

# Simple constructor test

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Test::NoWarnings;
use SDL::Tutorial::3DWorld ();

new_ok( 'SDL::Tutorial::3DWorld', [], 'Created default world' );
