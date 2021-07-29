#!/usr/bin/env perl

use TCOD;
use Time::HiRes 'sleep';

TCOD::Console::init_root( 10, 10, 'Test', 0, TCOD::RENDERER_SDL );

my $off1 = TCOD::Console->new( 10, 10 );
TCOD::Console::print( $off1, 1, 1, 'X' );

my $off2 = TCOD::Console->new( 10, 10 );
TCOD::Console::print( $off2, 8, 8, 'X' );

TCOD::Console::print( undef, 2, 3, 'PRESS' );
TCOD::Console::print( undef, 1, 4, 'ANY KEY' );
TCOD::Console::print( undef, 1, 6, 'ESC EXIT' );
TCOD::Console::flush;

my $key   = TCOD::Key->new;
my $mouse = TCOD::Mouse->new;

TCOD::Sys::wait_for_event( TCOD::EVENT_KEY_PRESS, $key, $mouse, 1 );
exit if $key->vk == TCOD::K_ESCAPE;

for ( 1 .. 255 ) {
    $off1->blit( alpha => 1,       );
    $off2->blit( alpha => $_ / 255 );
    TCOD::Console::flush;
    sleep 0.005;
}
