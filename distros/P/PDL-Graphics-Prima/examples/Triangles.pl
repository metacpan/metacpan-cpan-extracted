use strict;
use warnings;
use PDL;
use PDL::Graphics::Prima::Simple;
use PDL::NiceSlice;

my $x = 3 * grandom(30);
my $y = 3 * grandom(30);
my $y_err = grandom(30);
my $white = pdl(255, 255, 255)->rgb_to_color->at(0);
my $red = pdl(255, 0, 0)->rgb_to_color->at(0);
my $black = pdl(0,0,0)->rgb_to_color->at(0);

# Plots error bars and triangles at the point.
plot(
	title => 'Simple Error Bars',
	-data => ds::Pair(
		$x, $y,
		plotType => [
			ppair::ErrorBars(y_err => $y_err, color => $black),
			ppair::Triangles(color => $red, size => 10),
		],
	),
);

# Notice that the error bars ran through the middle of the triangles in
# the last example. Here, I plot white filled triangles, then the red
# triangle outlines.
plot(
	title => '"Unfilled" Triangles',
	-data => ds::Pair(
		$x, $y,
		plotType => [
			ppair::ErrorBars(y_err => $y_err, color => $black),
			ppair::Triangles(
				filled => 'yes',
				color => $white,
				orientation => 'up',
				size => 10,
			),
			ppair::Triangles(color => $red, size => 10),
		],
	),
);

# I can achieve the same thing using PDL threading, which I'll use to even
# greater effect in the next exampe:
my $colors = pdl($white, $red)->transpose;
plot(
	title => 'Threaded Error Bars',
	-data => ds::Pair(
		$x, $y,
		plotType => [
			ppair::ErrorBars(y_err => $y_err, color => $black),
			ppair::Triangles(
				filled => pdl(1, 0)->transpose,
				colors => $colors,
				size => 10,
			),
		],
	),
);

# You may notice (it's particularly obvious if you zoom out) that triangles
# plotted over each other do not blot each other out. I can get that by
# reversing the order of the threaded drawing operations for the triangles:
plot(
	title => 'Better-looking Threaded',
	-data => ds::Pair(
		$x->transpose, $y->transpose,
		plotType => [
			ppair::ErrorBars(y_err => $y_err->transpose, color => $black),
			ppair::Triangles(
				filled => pdl(1, 0),
				colors => $colors->transpose,
				size => 10,
			),
		],
	),
);

