package TetrixPiece;

use strict;
use warnings;

use List::Util qw(min max);
use QtCore4;
use QtGui4;
# Make it a Qt::Object, so we can use 'this'.  I'm lazy :-)
use QtCore4::isa qw( Qt::Object );
use TetrixPiece;
use constant { 
    NoShape => 0,
    ZShape => 1,
    SShape => 2,
    LineShape => 3,
    TShape => 4,
    SquareShape => 5,
    LShape => 6,
    MirroredLShape => 7,
};

# XXX Why doesn't Exporter work?
#require Exporter;
#use base qw( Exporter );
#our @EXPORT = qw( NoShape ZShape SShape LineShape TShape SquareShape LShape 
                 #MirroredLShape );

my @coordsTable = (
    [ [ 0, 0 ],   [ 0, 0 ],   [ 0, 0 ],   [ 0, 0 ] ],
    [ [ 0, -1 ],  [ 0, 0 ],   [ -1, 0 ],  [ -1, 1 ] ],
    [ [ 0, -1 ],  [ 0, 0 ],   [ 1, 0 ],   [ 1, 1 ] ],
    [ [ 0, -1 ],  [ 0, 0 ],   [ 0, 1 ],   [ 0, 2 ] ],
    [ [ -1, 0 ],  [ 0, 0 ],   [ 1, 0 ],   [ 0, 1 ] ],
    [ [ 0, 0 ],   [ 1, 0 ],   [ 0, 1 ],   [ 1, 1 ] ],
    [ [ -1, -1 ], [ 0, -1 ],  [ 0, 0 ],   [ 0, 1 ] ],
    [ [ 1, -1 ],  [ 0, -1 ],  [ 0, 0 ],   [ 0, 1 ] ]
);

sub setX {
    my ( $index, $x ) = @_;
    this->coords->[$index]->[0] = $x;
}

sub setY {
    my ( $index, $x ) = @_;
    this->coords->[$index]->[1] = $x;
}

sub NEW {
    shift->SUPER::NEW();
    this->{coords} = [];
    this->setShape( NoShape );
}

# [0]
sub pieceShape {
    return this->{pieceShape};
}

sub shape {
    return this->{pieceShape};
}

sub x {
    my ( $index ) = @_;
    return this->coords->[$index]->[0];
}

sub y {
    my ( $index ) = @_;
    return this->coords->[$index]->[1];
}

sub coords {
    return this->{coords};
};
# [0]

sub qrand {
    # 2147483647 is the value of RAND_MAX, defined in stdlib.h, at least on my
    # machine.  See the Qt4 4.2 documentation on qrand() for more details.
    return rand(2147483647);
}

# [0]
sub setRandomShape {
    this->setShape(qrand() % 7 + 1);
}
# [0]

# [1]
sub setShape {
    my ($shape) = @_;

    for (my $i = 0; $i < 4 ; $i++) {
        for (my $j = 0; $j < 2; ++$j) {
            this->coords()->[$i]->[$j] = $coordsTable[$shape]->[$i]->[$j];
        }
    }
    this->{pieceShape} = $shape;
# [1] //! [2]
}
# [2]

# [3]
sub minX {
    my $min = this->coords()->[0]->[0];
    for (my $i = 1; $i < 4; ++$i) {
        $min = min($min, this->coords()->[$i]->[0]);
    }
    return $min;
}

sub maxX {
# [3] //! [4]
    my $max = this->coords()->[0]->[0];
    for (my $i = 1; $i < 4; ++$i) {
        $max = max($max, this->coords()->[$i]->[0]);
    }
    return $max;
}
# [4]

# [5]
sub minY {
    my $min = this->coords()->[0]->[1];
    for (my $i = 1; $i < 4; ++$i) {
        $min = min($min, this->coords()->[$i]->[1]);
    }
    return $min;
}

sub maxY {
# [5] //! [6]
    my $max = this->coords()->[0]->[1];
    for (my $i = 1; $i < 4; ++$i) {
        $max = max($max, this->coords()->[$i]->[1]);
    }
    return $max;
}
# [6]

# [7]
sub rotatedLeft {
    if (this->pieceShape() == SquareShape) {
        return this;
    }

    my $result = TetrixPiece();
    $result->{pieceShape} = this->pieceShape();
    for (my $i = 0; $i < 4; ++$i) {
        $result->setX($i, this->y($i));
        $result->setY($i, -(this->x($i)));
    }
# [7]
    return $result;
}

# [9]
sub rotatedRight {
    if (this->pieceShape() == SquareShape) {
        return this;
    }

    my $result = TetrixPiece();
    $result->{pieceShape} = this->pieceShape();
    for (my $i = 0; $i < 4; ++$i) {
        $result->setX($i, -(this->y($i)));
        $result->setY($i, this->x($i));
    }
# [9]
    return $result;
}

1;
