#!/usr/bin/env perl

use Test2::V0;
use TCOD;

use constant {
    WIDTH  => 46,
    HEIGHT => 20,
};

subtest 'Dijkstra' => sub {
    my $path = TCOD::Dijkstra->new( load_map(), 1.41 );

    $path->compute(  20, 10 );
    $path->path_set( 24,  1 );

    is $path->size, 9, 'Got expected path length';
    is $path->is_empty, F, 'Path is not empty';

    is $path->get_distance( 24, 1 ), within(11.460000038147), 'Got approximate distance';

    is [ map [ $path->get($_) ], 0 .. $path->size - 1 ] => [
        [ 20, 9 ],
        [ 19, 8 ],
        [ 19, 7 ],
        [ 19, 6 ],
        [ 20, 5 ],
        [ 21, 4 ],
        [ 22, 3 ],
        [ 23, 2 ],
        [ 24, 1 ],
    ] => 'Got expected path';
};

subtest 'TCOD::Dijkstra->walk' => sub {
    my $path = TCOD::Dijkstra->new( load_map(), 1.41 );

    $path->compute( 20, 10 );
    $path->path_set( 24, 1 );

    is $path->is_empty, F, 'Path is not empty';

    my @cells;
    push @cells, [ $path->walk ] until $path->is_empty;

    is \@cells => [
        [ 20, 9 ],
        [ 19, 8 ],
        [ 19, 7 ],
        [ 19, 6 ],
        [ 20, 5 ],
        [ 21, 4 ],
        [ 22, 3 ],
        [ 23, 2 ],
        [ 24, 1 ],
    ] => 'Got expected path';
};

subtest 'Dijkstra - no diagonals' => sub {
    my $path = TCOD::Dijkstra->new( load_map(), 0 );

    $path->compute(  20, 10 );
    $path->path_set( 24,  1 );

    is $path->size, 15, 'Got expected path length';
    is $path->is_empty, F, 'Path is not empty';

    is $path->get_distance( 24, 1 ), 15, 'Got approximate distance';

    is [ map [ $path->get($_) ], 0 .. $path->size - 1 ] => [
        [ 20, 9 ],
        [ 19, 9 ],
        [ 19, 8 ],
        [ 19, 7 ],
        [ 19, 6 ],
        [ 19, 5 ],
        [ 19, 4 ],
        [ 20, 4 ],
        [ 21, 4 ],
        [ 22, 4 ],
        [ 22, 3 ],
        [ 22, 2 ],
        [ 23, 2 ],
        [ 23, 1 ],
        [ 24, 1 ],
    ] => 'Got expected path';
};

done_testing;

sub load_map {
    my $map = TCOD::Map->new( WIDTH, HEIGHT );

    my $data = <<'DATA';
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
DATA

    my $y = 0;
    for my $line ( split /\n/, $data ) {
        my @cells = split //, $line;

        my $x = 0;
        for my $cell (@cells) {
            if ( $cell eq ' ' ) {
                $map->set_properties( $x, $y, 1, 1 ); # ground
            }
            elsif ( $cell eq '=' ) {
                $map->set_properties( $x, $y, 1, 0 ); # window
            }

            $x++;
        }

        $y++;
    }

    $map;
}
