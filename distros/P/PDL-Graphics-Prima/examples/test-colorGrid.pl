use strict;
use warnings;
use PDL;
use Prima qw(Application);
use PDL::Graphics::Prima;
use PDL::NiceSlice;

my @dims = (200, 150);
my $hsv = ones(3, @dims);
$hsv(0;-) .= rvals(@dims, {Center => [$dims[0] / 2, $dims[0] / 2]});
my $colors = $hsv->hsv_to_rgb->rgb_to_color;

use PDL::Image2D;
# Also fill the matrix with a red polygon:
my $color = pdl(255, 0, 0)->rgb_to_color;
my $polygon = pdl q[0,0; 20,25; 10, 80];
$colors->polyfill($polygon, $color);

print "colors dims are ", join (', ', $colors->dims), "\n";

my $wDisplay = Prima::MainWindow->create(
	text    => 'ColorGrid Test',
	size	=> [500, 500],
);

# Make some larger steps where x and y vary in value
my $rgb = zeroes(3, 2, 2);
$rgb(0,0,0) .= 255;
$rgb(1,1,1) .= 255;
$rgb(2,0,1) .= 255;
my $funny_colors = $rgb->rgb_to_color;
my $xs = sequence(3)**2 + 3;
my $ys = $xs**2;

$wDisplay->insert('Plot',
	-spot => ds::Image($colors,
		bounds => [0, 0, 1, 1],
		color_format => 'prima',
	),
	-funny => ds::Image($funny_colors,
		x_edges => $xs,
		y_edges => $ys,
		color_format => 'prima',
	),
	pack => { fill => 'both', expand => 1},
#	y => {scaling => sc::Log},
	-basic => ds::Grid(sequence(20,20),
		bounds => [3,3,4,4],
	),
);

run Prima;

