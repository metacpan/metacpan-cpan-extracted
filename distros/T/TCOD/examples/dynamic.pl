#!/usr/bin/env perl

use strict;
use warnings;
use TCOD;
use File::Share 'dist_file';

# This example shows a more advanced setup than that in examples/synopsis.pl.
# A maximized window is created and the console is dynamically scaled to fit
# within it. If the window is resized then the console will be resized to
# match it.
#
# Because a tileset wasn't manually loaded in this example, an OS dependent
# fallback font will be used. This is useful for prototyping but it's not
# recommended to release with this font since it can fail to load on some
# platforms.
#
# The integer_scaling parameter to TCOD::Context->present prevents the
# console from being slightly stretched, since the console will rarely be
# the perfect size a small border will exist. This border is black by default
# but can be changed to another color.
#
# You'll need to consider things like the console being too small for your
# code to handle or the tiles being small compared to an extra large monitor
# resolution. TCOD::Context->new_console can be given a minimum size that it
# will never go below.
#
# You can call TCOD::Context->new_console every frame or only when the window
# is resized. This example creates a new console every frame instead of
# clearing the console every frame and replacing it only on resizing the
# window.
#
# This example is a port of the one bundled in python-tcod, and available at
# https://python-tcod.readthedocs.io/en/latest/tcod/getting-started.html#dynamically-sized-console

use constant {
    WIDTH  => 720,
    HEIGHT => 480,
    #         RESIZABLE    MAXIMIZED
    FLAGS  => 0x00000020 | 0x00000080,
};

my $tileset = TCOD::Tileset->load_tilesheet(
    path    => dist_file( TCOD => 'fonts/dejavu10x10_gs_tc.png' ),
    columns => 32,
    rows    => 8,
    charmap => TCOD::CHARMAP_TCOD,
);

my $context = TCOD::Context->new(
    width            => WIDTH,
    height           => HEIGHT,
    sdl_window_flags => FLAGS,
);

while (1) {
    my $console = $context->new_console;
    $console->print( 0, 0, 'Hello World!' );
    $context->present( $console, integer_scaling => 1 );

    my $iter = TCOD::Event::wait;
    while ( my $event = $iter->() ) {
        $context->convert_event($event);
        print $event->as_string . "\n";
        exit if $event->type eq 'QUIT';
    }
}
