#!perl
use strict;
use warnings;
use Test::More;
use Prima::noX11;
use Prima;
use PDL::Drawing::Prima;
use PDL;

sub is_image {
	my ($got, $expected, $test_name) = @_;
	
	# check dimensions
	if ($got->width != $expected->width) {
		fail($test_name);
		diag("image widths differ, got " . $got->width . " but expected " . $expected->width);
		return 0;
	}
	my $width = $got->width;
	if ($got->width != $expected->width) {
		fail($test_name);
		diag("image heights differ, got " . $got->height . " but expected " . $expected->height);
		return 0;
	}
	my $height = $got->height;
	
	# perform point-by-point comparison
	my $is_good = 1;
	for my $x (0 .. $width - 1) {
		for my $y (0 .. $height - 1) {
			my $got_pixel = $got->pixel($x, $y);
			my $expected_pixel = $expected->pixel($x, $y);
			if ($got_pixel != $expected_pixel) {
				# only issue fail once
				if ($is_good) {
					fail($test_name);
					$is_good = 0;
				}
				# print the offending pixel
				diag("at ($x, $y) got pixel value $got_pixel but expected $expected_pixel");
			}
		}
	}
	pass($test_name) if $is_good;
	return $is_good;
}

# Create two images and draw lines on them with (1) normal drawing
# operations and (2) PDL methods. Compare.

my $basic_image = Prima::Image-> new(
   width => 32,
   height => 32,
   type   => im::RGB
);

my $pdl_image = Prima::Image-> new(
   width => 32,
   height => 32,
   type   => im::RGB
);

# Draw multiple lines to/from these coordinates
my @colors = (cl::Blue, cl::Green, cl::Cyan, cl::Red);
my $N_lines = @colors;
my @x1s = map { rand(32) } 1 .. $N_lines;
my @y1s = map { rand(32) } 1 .. $N_lines;
my @x2s = map { rand(32) } 1 .. $N_lines;
my @y2s = map { rand(32) } 1 .. $N_lines;

for my $i (0 .. $N_lines - 1) {
	$basic_image->color($colors[$i]);
	$basic_image->line($x1s[$i], $y1s[$i], $x2s[$i], $y2s[$i]);
}

$pdl_image->pdl_lines(pdl(@x1s), pdl(@y1s), pdl(@x2s), pdl(@y2s),
	colors => pdl(@colors));

# Now for the test
is_image($basic_image, $pdl_image, "pdl_lines and Prima lines give same results");

done_testing();
