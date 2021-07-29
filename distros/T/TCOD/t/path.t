#!/usr/bin/env perl

use Test2::V0;
use TCOD;
use feature 'state';

use constant {
    WIDTH  => 46,
    HEIGHT => 20,
};

subtest 'TCOD::Path->get' => sub {
    my $path = TCOD::Path->new_using_map( load_map(), 1.41 );

    $path->compute( 20, 10, 24, 1 );

    is [ $path->get_origin      ], [ 20, 10 ], 'Got origin';
    is [ $path->get_destination ], [ 24,  1 ], 'Got destination';

    is $path->size, 9, 'Got expected path length';

    is [ map [ $path->get($_) ], 0 .. $path->size - 1 ] => [
        [ 20, 9 ],
        [ 19, 8 ],
        [ 19, 7 ],
        [ 20, 6 ],
        [ 21, 5 ],
        [ 22, 4 ],
        [ 23, 3 ],
        [ 24, 2 ],
        [ 24, 1 ],
    ] => 'Got expected path';

    $path->reverse;

    is [ $path->get_origin      ], [ 24,  1 ], 'Got inverted origin';
    is [ $path->get_destination ], [ 20, 10 ], 'Got inverted destination';
};

subtest 'TCOD::Path->walk' => sub {
    my $path = TCOD::Path->new_using_map( load_map(), 1.41 );

    $path->compute( 20, 10, 24, 1 );

    is $path->is_empty, F, 'Path is not empty';

    my @cells;
    push @cells, [ $path->walk ] until $path->is_empty;

    is \@cells => [
        [ 20, 9 ],
        [ 19, 8 ],
        [ 19, 7 ],
        [ 20, 6 ],
        [ 21, 5 ],
        [ 22, 4 ],
        [ 23, 3 ],
        [ 24, 2 ],
        [ 24, 1 ],
    ] => 'Got expected path';
};

subtest 'Path - no diagonals' => sub {
    my $path = TCOD::Path->new_using_map( load_map(), 0 );

    $path->compute( 20, 10, 24, 1 );

    is [ $path->get_origin      ], [ 20, 10 ], 'Got origin';
    is [ $path->get_destination ], [ 24,  1 ], 'Got destination';

    is $path->size, 15, 'Got expected path length';

    is [ map [ $path->get($_) ], 0 .. $path->size - 1 ] => [
        [ 20, 9 ],
        [ 19, 9 ],
        [ 19, 8 ],
        [ 19, 7 ],
        [ 19, 6 ],
        [ 19, 5 ],
        [ 20, 5 ],
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
