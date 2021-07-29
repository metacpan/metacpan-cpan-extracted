#!/usr/bin/env perl

use strict;
use warnings;
use experimental 'signatures';
use constant { WIDTH => 720, HEIGHT => 480 };

use TCOD;
use File::Share 'dist_file';

my $tileset = TCOD::Tileset->load_tilesheet(
    path    => dist_file( TCOD => 'fonts/dejavu10x10_gs_tc.png' ),
    columns => 32,
    rows    => 8,
    charmap => TCOD::CHARMAP_TCOD,
);

my $context = TCOD::Context->new( width => WIDTH, height => HEIGHT );
my $console = new_console( $context );

package My::Dispatch {
    use Role::Tiny::With;
    with 'TCOD::Event::Dispatch';

    sub ev_quit {
        return { exit => 1 }
    }

    sub ev_keydown ($e) {
        return { exit => 1 } if $e->sym == TCOD::Event::K_ESCAPE;
        return;
    }

    sub ev_mousebuttondown ($e) {
        return { paint => [ $e->tilexy ] }
            if $e->button == TCOD::Event::BUTTON_LEFT;

        return { erase => [ $e->tilexy ] }
            if $e->button == TCOD::Event::BUTTON_RIGHT;

        return;
    }

    sub ev_mousemotion ($e) {
        return unless $e->state & (
              TCOD::Event::BUTTON_LMASK
            | TCOD::Event::BUTTON_RMASK
        );

        my @line = TCOD::Line::bresenham(
            $e->tilex - $e->tiledx,
            $e->tiley - $e->tiledy,
            $e->tilex,
            $e->tiley,
        );

        return { paint => \@line }
            if $e->state & TCOD::Event::BUTTON_LMASK;

        return { erase => \@line }
            if $e->state & TCOD::Event::BUTTON_RMASK;
    }

    sub ev_windowresized ($e) {
        $console = new_console( $context );
        return;
    }
}

while (1) {
    $context->present( $console, integer_scaling => 1, clear_color => TCOD::WHITE );

    my $iter = TCOD::Event::wait;
    while ( my $event = $iter->() ) {
        $context->convert_event($event);

        my $action = My::Dispatch->dispatch($event);

        exit if $action->{exit};

        if ( my $tile = $action->{paint} ) {
            $console->print( @$_, ' ', bg => TCOD::BLACK ) for @$tile;
        }
        elsif ( my $erase = $action->{erase} ) {
            $console->print( @$_, ' ', bg => TCOD::WHITE ) for @$erase;
        }
    }
}

sub new_console ($ctx) {
    my $console = $ctx->new_console;
    $console->set_default_background( TCOD::WHITE );
    $console->clear;
    $console;
}
