use strict;
use SVG::Plot;
use Test::More tests => 8;

my $points = [ [1, 1], [3, 1], [2, 5], [4, 3], [5, 10] ];

my $plot = SVG::Plot->new( points     => $points,
                           scale      => 1,
                           point_size => "AUTO" );
isa_ok( $plot, "SVG::Plot" );

my $output = $plot->plot;
unlike( $output, qr/r="AUTO"/, "AUTO argument not treated as number" );
like( $output, qr/r="1"/, "plot circles auto-sized" );

$plot = SVG::Plot->new( points         => $points,
                        scale          => 1,
                        point_size     => "AUTO",
                        min_point_size => 2 );
isa_ok( $plot, "SVG::Plot" );
$output = $plot->plot;
like( $output, qr/r="2"/, "min_point_size respected" );

$points = [ [0, 1], [4, 1] ];
$plot = SVG::Plot->new( points         => $points,
                        point_size     => "AUTO",
                        max_point_size => 1 );
isa_ok( $plot, "SVG::Plot" );
$output = $plot->plot;
like( $output, qr/r="1"/, "max_point_size respected" );

$points = [ [0, 1] , [4000, 1], [40000, 1] ];
$plot = SVG::Plot->new( points     => $points,
                        max_width  => 100,
                        max_point_size => 15,
                        point_size => "AUTO" );
$output = $plot->plot;
like( $output, qr/r="4"/, "plot circles don't overlap even when scaling" );

# min and max ignored if not AUTO
