#!/usr/bin/env perl

use warnings;
use strict;

use TCOD;
use File::Share 'dist_file';

use constant {
    WIDTH  => 80,
    HEIGHT => 50,
};

TCOD::Console::set_custom_font(
    dist_file( TCOD => 'arial10x10.png' ),
    TCOD::FONT_TYPE_GREYSCALE | TCOD::FONT_LAYOUT_TCOD,
);

TCOD::Console::init_root( WIDTH, HEIGHT, 'libtcod tutorial', 0 );

until ( TCOD::Console::is_window_closed ) {
    TCOD::Console::set_default_foreground( undef, TCOD::WHITE );

    TCOD::Console::put_char( undef, 1, 1, ord('@'), TCOD::BKGND_NONE );

    TCOD::Console::flush;

    my $key = TCOD::Console::check_for_keypress(TCOD::EVENT_ANY);
    last if $key->vk == TCOD::K_ESCAPE;
}
