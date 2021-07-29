#!/usr/bin/env perl

use strict;
use warnings;
use TCOD;
use File::Share 'dist_file';

# This example is a hello world script which handles font loading, fixed-sized
# consoles, window contexts, and event handling. This example loads the
# dejavu10x10_gs_tc.png font from the ones bundled with this distribution.
#
# By default this will create a window which can be resized and the fixed-size
# console will be stretched to fit the window. You can add arguments to
# TCOD::Context->present to fix the aspect ratio or only scale the console by
# integer increments.
#
# This example is a port the one bundled with python-tcod, and available at
# https://python-tcod.readthedocs.io/en/latest/tcod/getting-started.html#fixed-size-console

use constant {
    WIDTH  => 80,
    HEIGHT => 60,
};

my $tileset = TCOD::Tileset->load_tilesheet(
    path    => dist_file( TCOD => 'fonts/dejavu10x10_gs_tc.png' ),
    columns => 32,
    rows    => 8,
    charmap => TCOD::CHARMAP_TCOD,
);

my $context = TCOD::Context->new(
    columns => WIDTH,
    rows    => HEIGHT,
    tileset => $tileset,
);

my $console = $context->new_console;

while (1) {
    $console->clear;
    $console->print( 0, 0, 'Hello World!' );
    $context->present( $console );

    my $iter = TCOD::Event::wait;
    while ( my $event = $iter->() ) {
        $context->convert_event($event);
        print $event->as_string . "\n";
        exit if $event->type eq 'QUIT';
    }
}
