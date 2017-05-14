#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;		# turn on autoflush
	$^W = 1;		# turn on warnings
}

use Test::More tests => 8;

use_ok( 'OpenGL::QEng::GameState' );

my $g1;
{local $^W = 0; # turn warnings off to stop 'Deep recursion' warn
 $g1 = OpenGL::QEng::GameState->load('maps/default_game.txt');  # load default game
}
ok( defined $g1, 'created game object' );

ok( $g1->isa('OpenGL::QEng::GameState'), 'which is a GameState' );

my $m = $g1->currmap;

ok( defined $m, 'there is a map in g1' );

ok( $m->isa('OpenGL::QEng::Map'), 'which is a Map' );

{local $^W = 0; # turn warnings off to stop 'Deep recursion' warn
 $g1->load('maps/new_quests.gam');  # load future components
}
$m = $g1->currmap;

ok( defined $m, 'there is a new map in g1' );

ok( $m->isa('OpenGL::QEng::Map'), 'which is a Map' );

ok($m->textMap =~ m%maps/new_quests.txt$%, 'Got right map');


