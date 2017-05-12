package SDL::Tutorial::Tetris::Model::Pieces;

use strict;
use warnings;

use Carp;

my %pieces  = (
    SQUARE => [
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 2, 1, 0],
            [0, 0, 1, 1, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 2, 1, 0],
            [0, 0, 1, 1, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 2, 1, 0],
            [0, 0, 1, 1, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 2, 1, 0],
            [0, 0, 1, 1, 0],
            [0, 0, 0, 0, 0]
        ]
    ],
    LINE => [
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 1, 2, 1, 1],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 2, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 1, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [1, 1, 2, 1, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 1, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 2, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 0, 0, 0]
        ]
    ],
    L_SHAPE => [
        [
            [0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 2, 0, 0],
            [0, 0, 1, 1, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 1, 2, 1, 0],
            [0, 1, 0, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 1, 1, 0, 0],
            [0, 0, 2, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 1, 0],
            [0, 1, 2, 1, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
        ]
    ],
    L_SHAPE_MIRROR => [
        [
            [0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 2, 0, 0],
            [0, 1, 1, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 1, 0, 0, 0],
            [0, 1, 2, 1, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 1, 1, 0],
            [0, 0, 2, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 1, 2, 1, 0],
            [0, 0, 0, 1, 0],
            [0, 0, 0, 0, 0]
        ]
    ],
    N_SHAPE => [
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 1, 0],
            [0, 0, 2, 1, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 1, 2, 0, 0],
            [0, 0, 1, 1, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 1, 2, 0, 0],
            [0, 1, 0, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 1, 1, 0, 0],
            [0, 0, 2, 1, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
        ]
    ],
    N_SHAPE_MIRROR => [
        [
            [0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 2, 1, 0],
            [0, 0, 0, 1, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 2, 1, 0],
            [0, 1, 1, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 1, 0, 0, 0],
            [0, 1, 2, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 1, 1, 0],
            [0, 1, 2, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
        ]
    ],
    T_SHAPE => [
        [
            [0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 2, 1, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0],
            [0, 1, 2, 1, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 1, 2, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 0, 0, 0, 0]
        ],
        [
            [0, 0, 0, 0, 0],
            [0, 0, 1, 0, 0],
            [0, 1, 2, 1, 0],
            [0, 0, 0, 0, 0],
            [0, 0, 0, 0, 0]
        ]
    ]
);

my %pieces_init = (
    SQUARE => [
        [-2, -3],
        [-2, -3],
        [-2, -3],
        [-2, -3]
    ],
    LINE => [
        [-2, -2],
        [-2, -3],
        [-2, -2],
        [-2, -3]
    ],
    L_SHAPE => [
        [-2, -3],
        [-2, -3],
        [-2, -3],
        [-2, -2]
    ],
    L_SHAPE_MIRROR => [
        [-2, -3],
        [-2, -2],
        [-2, -3],
        [-2, -3]
    ],
    N_SHAPE => [
        [-2, -3],
        [-2, -3],
        [-2, -3],
        [-2, -2]
    ],
    N_SHAPE_MIRROR => [
        [-2, -3],
        [-2, -3],
        [-2, -3],
        [-2, -2]
    ],
    T_SHAPE => [
        [-2, -3],
        [-2, -3],
        [-2, -3],
        [-2, -2]
    ]
);

sub piece {
    my ($self, $piece, $rotation) = @_;
    croak "Invalid piece '$piece'"       if !defined $pieces{$piece} or !defined $piece;
    croak "Invalid rotation '$rotation'" if !defined $pieces{$piece}[$rotation] or !defined $rotation;
    return $pieces{$piece}[$rotation];
}

sub init_xy {
    my ($self, $piece, $rotation) = @_;
    croak "Invalid piece '$piece'"       if !defined $pieces{$piece} or !defined $piece;
    croak "Invalid rotation '$rotation'" if !defined $pieces{$piece}[$rotation] or !defined $rotation;
    return @{ $pieces_init{$piece}[$rotation] };
}

sub block_color {
    my ($self, $piece, $rotation, $x, $y) = @_;
    croak "Invalid piece '$piece'"       if !defined $pieces{$piece} or !defined $piece;
    croak "Invalid rotation '$rotation'" if !defined $pieces{$piece}[$rotation] or !defined $rotation;
    croak "Invalid coordinates ($x,$y)"  if !defined $pieces{$piece}[$rotation][$x][$y] or (!defined $x or !defined $y);
    return $pieces{$piece}[$rotation][$x][$y];
}

sub random {
    my @pieces = keys %pieces;
    my $piece    = $pieces[ rand(@pieces) ];
    my $rotation = int(rand(4));
    return ($piece,$rotation);
}

1;

__END__

=head1 NAME
SDL::Tutorial::Tetris::Model::Pieces - the tetris pieces

=head1 SYNOPSIS

    use SDL::Tutorial::Tetris::Model::Pieces;

    my ($piece, $rotation) = SDL::Tutorial::Tetris::Model::Pieces->random();
    my ($init_x, $init_y)  = SDL::Tutorial::Tetris::Model::Pieces->init_xy($piece,$rotation);

    for my $y (0..4) {
        for my $x (0..4) {
            print SDL::Tutorial::Tetris::Model::Pieces->block_color($piece,$rotation,$x,$y);
        }
        print "\n";
    }

=head1 DESCRIPTION

This modules holds the game data, and the means to interact to it.

Basically, we have a set of named pieces (SQUARE, LINE, T_SHAPE; 
L_SHAPE, N_SHAPE; L_SHAPE_MIRROR, N_SHAPE_MIRROR).

=head2 random

Returns a random piece and rotation.

=head2 init_xy

Returns the initial (x,y) coordinates for each block and rotation.

=head2 block_color

Given a block, rotation, and (x,y) coordinates, it returns the
color of the block in that point.
