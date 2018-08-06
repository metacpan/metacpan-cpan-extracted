#!/usr/bin/perl 

use 5.12.0;

use Games::Maze;
use Term::Caca::Constants qw/ :colors :events /;
use Term::Caca;

use experimental qw/
    signatures
    postderef
    smartmatch
/;

my $term = Term::Caca->new();

$term->title( 'maze' );

my( $w, $h ) = $term->canvas_size->@*;

# generate the maze
my $maze = Games::Maze->new( 
    dimensions => [ ($w-1)/3, ($h-1)/2 , 1 ], 
    entry => [1,1,1] 
);
$maze->make;
my @maze = map { [ split '' ] }  split "\n", $maze->to_ascii;

# display the maze itself
$term->set_color( LIGHTBLUE, BLACK );
for my $x ( 0..$w ) {
    for my $y ( 0..$h ) {
        $term->char( [$x, $y], $maze[$y][$x] );
    }
}


$term->set_color( RED, BLACK );

my @pos = (1,0);

# TODO work with a coord class

while (1) {
    $term->char( \@pos, '@' );
    $term->refresh;
    $term->char( \@pos, '.' );

    my $event = $term->wait_for_event( 
        KEY_PRESS | QUIT,
        -1,
    );  

    exit if $event->isa( 'Term::Caca::Event::Quit' )
         or $event->char eq 'q';

    # move using the keypad (2, 4, 6, 8)
    given ( $event->char ) {
        when ( 2 ) { 
            if ( $pos[1] < $w and $maze[$pos[1]+1][$pos[0]] eq ' ' ) {
                $pos[1]++;
            }
        }
        when ( 8 ) { 
            if ( $pos[1] > 0 and $maze[$pos[1]-1][$pos[0]] eq ' ' ) {
                $pos[1]--;
            }
        }
        when ( 4 ) { 
            if ( $pos[0] > 0 and $maze[$pos[1]][$pos[0]-1] eq ' ' ) {
                $pos[0]--;
            }
        }
        when ( 6 ) { 
            if ( $pos[0] < $w and $maze[$pos[1]][$pos[0]+1] eq ' ' ) {
                $pos[0]++;
            }
        }
    }
}
