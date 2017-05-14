#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;		# turn on autoflush
	$^W = 1;		# turn on warnings
}

use Test::More tests => 8;

use_ok( 'OpenGL::QEng::GameState' );

my $g = OpenGL::QEng::GameState->new();

ok( defined $g, 'made a GameState' );

ok( $g->isa('OpenGL::QEng::GameState'), 'of the correct class' );

open(my $mf,'>','/tmp/gs_testmap.txt');
print $mf "map 0 0 0 xsize=>24, zsize=>24;\n";
print $mf "in_last;\n";
print $mf "   wall 16 0 270;\n";
print $mf "done;\n";
close $mf;

ok( -f('/tmp/gs_testmap.txt'), 'file exists' );

my $g1 = OpenGL::QEng::GameState->load('/tmp/gs_testmap.txt');

ok( defined $g1, 'made GameState while loading a map' );

my $m = $g1->{maps}{'/tmp/gs_testmap.txt'};

ok( defined $m, 'there is a map in g1' );

ok( $m->isa('OpenGL::QEng::Map'), 'which is a Map' );

ok( $m->textMap eq '/tmp/gs_testmap.txt', 'with the right name' );
