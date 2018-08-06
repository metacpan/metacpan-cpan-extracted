#!/usr/bin/perl 

use 5.12.0;

use Term::Caca::Constants qw/ :colors :events /;
use Term::Caca;

use experimental qw/
    signatures
    postderef
    smartmatch
/;

my $term = Term::Caca->new();

$term->title( 'cave' );

my( $w, $h ) = $term->canvas_size->@*;

my $cave = [];

# generate the seed cave 
for my $x ( 1..$w ) {
    for my $y ( 1..$h ) {
        $cave->[$x-1][$y-1] = ( $y == 1 || $y == $h || $x == 1 || $x == $w ) ? 1 : rand() > 0.5;
    }
}

sub show_cave {
    for my $x ( 0..$w-1 ) {
        for my $y ( 0..$h-1 ) {
            $term->char( [$x, $y], $cave->[$x][$y] ? '#' : ' ' );
        }
    }
}

sub mutate_cell {
    my( $x, $y ) = @_;

    use List::Util qw/ sum /;
    my $n = sum map { $cave->[$x+$_->[0]][$y+$_->[1]] } [-1,-1], [-1,0], [-1,1], [0,-1], [0,1], [1,-1],[1,0],[1,1];

    return $n < 4 ? 0 : $n > 5 ? 1 : $cave->[$x][$y];
}

sub update_cave {
    my $new = [];

    for my $x ( 1..$w ) {
        for my $y ( 1..$h ) {
            $new->[$x-1][$y-1] = ( $y == 1 || $y == $h || $x == 1 || $x == $w ) ? 1 : mutate_cell( $x-1, $y-1 );
        }
    }

    $cave = $new;

}

while() {
    show_cave();
    $term->refresh;

    my $event = $term->wait_for_event( 
        KEY_PRESS | QUIT,
        -1,
    ) or next;  

    exit if $event->isa( 'Term::Caca::Event::Quit' );

    exit if $event->isa('Term::Caca::Event::Key::Press')
            and $event->char eq 'q';

    update_cave();

}

__END__
