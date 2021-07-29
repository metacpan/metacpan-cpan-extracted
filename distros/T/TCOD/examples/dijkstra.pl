#!/usr/bin/env perl

use strict;
use warnings;
use feature 'say';

use TCOD;

use constant {
    WIDTH  => 46,
    HEIGHT => 20,
    START  => [ 20, 10 ], # player position
    GOAL   => [ 24,  1 ], # destination
};

my $map = TCOD::Map->new( WIDTH, HEIGHT );

my $y = 0;
while (<DATA>) {
    chomp;

    my @cols = split //;
    for my $x ( 0 .. $#cols ) {
        my $cell = $cols[$x];

        if ( $cell eq ' ' ) {
            $map->set_properties( $x, $y, 1, 1 ); # ground
        }
        elsif ( $cell eq '=' ) {
            $map->set_properties( $x, $y, 1, 1 ); # window
        }
    }

    $y++;
}

my $path     = TCOD::Path->new_using_map( $map, 1.41 );
my $dijkstra = TCOD::Dijkstra->new(       $map, 1.41 );

$path->compute( @{ +START }, @{ +GOAL } );

for my $i ( 0 .. $path->size - 1 ) {
    my ( $x, $y ) = $path->get($i);

    say "Move to $x, $y";
    # TCOD_console_set_char_background(sample_console, x, y, light_ground, TCOD_BKGND_SET);
}

until ( $path->is_empty ) {
    my ( $x, $y ) = $path->walk;

    say "Move to $x, $y";
    # TCOD_console_set_char_background(sample_console, x, y, light_ground, TCOD_BKGND_SET);
}



__DATA__
##############################################
#######################      #################
#####################    #     ###############
######################  ###        ###########
##################      #####             ####
################       ########    ###### ####
###############      #################### ####
################    ######                  ##
########   #######  ######   #     #     #  ##
########   ######      ###                  ##
########                                    ##
####       ######      ###   #     #     #  ##
#### ###   ########## ####                  ##
#### ###   ##########   ###########=##########
#### ##################   #####          #####
#### ###             #### #####          #####
####           #     ####                #####
########       #     #### #####          #####
########       #####      ####################
##############################################
