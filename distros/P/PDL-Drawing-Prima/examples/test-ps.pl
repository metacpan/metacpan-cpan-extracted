;
use strict;
use warnings;
use PDL;
use Prima;
use Prima::PS::Drawable;
use PDL::Drawing::Prima;
use PDL::NiceSlice;

# Generate a table of shapes:
my @dims = (20, 2, 20);
my $N_points = xvals(@dims)->clump(2) + 1;
my $orientation = 0;
my $filled = yvals(@dims)->clump(2);
my $size = 10;
my $skip = zvals(@dims)->clump(2);
my $x = $N_points->xvals * 25 + 25;
my $y = $N_points->yvals * 25 + 25;
my $lineWidths = $ARGV[0] || 1;

# Christmas colors:
my $colors = zeroes(2,10,2,20);
$colors .= pdl (q[255 0 0; 0 255 0]) -> rgb_to_color;
$colors = $colors->clump(3);

# Test bad-value handling:
$N_points->setbadat(20, 15);

# Create the canvas:
my $canvas = Prima::PS::Drawable-> create( onSpool => sub {
	open F, ">> ./test.ps";
	print F $_[1];
	close F;
});
die "error:$@" unless $canvas-> begin_doc;

# Draw the symbols:
$canvas->pdl_symbols($x, $y, $N_points, 0, $filled, 10, $skip
, lineWidths => $lineWidths, colors => $colors);       
$canvas-> font-> size( 30);
$canvas-> text_out( "hello!", 100, 100);
$canvas-> end_doc;
