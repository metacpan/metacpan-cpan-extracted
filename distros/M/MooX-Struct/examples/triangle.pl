use strict;
use Data::Printer;
use MooX::Struct
	Triangle => [qw/ $a! $b! $c! /],
	Quad     => [qw/ $a! $b! $c! $d! /],
	Point    => [qw/ +x +y /],
;

my $triangle = Triangle[
	Point[0, 0],
	Point[1, 1],
	Point[1, 0],
];

my $square = Quad[
	Point[0, 0],
	Point[0, 1],
	Point[1, 1],
	Point[1, 0],
];

my %shapes = ( three_sided => [$triangle] , four_sided => [$square] );
p %shapes;