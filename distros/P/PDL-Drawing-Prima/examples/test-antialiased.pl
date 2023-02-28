use strict;
use warnings;

use Prima::noX11;
use Prima;
use PDL::Drawing::Prima;
use PDL;

# Create two images and draw lines on them with (1) normal drawing
# operations and (2) PDL methods. Compare.

my $basic_image = Prima::Image-> new(
   width => 32,
   height => 32,
   type   => im::RGB,
   lineWidth => 3,
);
print "can antialias\n" if $basic_image->can_draw_alpha;
$basic_image->antialias(1);
$basic_image->clear;

my $pdl_image = Prima::Image-> new(
   width => 32,
   height => 32,
   type   => im::RGB,
   lineWidth => 3,
);
$pdl_image->antialias(1);
$pdl_image->clear;

# Draw multiple lines to/from these coordinates
my @x1s = (0, 10, 20, 30);
my @y1s = (0, 0, 0, 0);
my @x2s = (10, 20, 30, 40);
my @y2s = (30, 30, 30, 30);
my @colors = (cl::Blue, cl::Green, cl::Cyan, cl::Red);

for my $i (0 .. $#x1s) {
	$basic_image->color($colors[$i]);
	$basic_image->line($x1s[$i], $y1s[$i], $x2s[$i], $y2s[$i]);
}
$basic_image->save("basic.bmp");

$pdl_image->pdl_lines(pdl(@x1s), pdl(@y1s), pdl(@x2s), pdl(@y2s),
	colors => pdl(@colors));
$pdl_image->save("pdl.bmp");
