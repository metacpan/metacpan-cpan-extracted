use strict;
use warnings;
use Test::More;

# Tests to ensure that on_paint behaves the way it's supposed to
use PDL::Graphics::Prima;
use Prima::Application;
use PDL;

use Scalar::Util qw(blessed);

sub is_image {
	my ($got, $expected, $test_name) = @_;
	$test_name ||= 'image comparison';
	
	# Make sure we have images
	if (not blessed ($got) or not $got->isa('Prima::Image')) {
		fail($test_name);
		diag('  \$got is not an image');
		return 0;
	}
	if (not blessed ($expected) or not $expected->isa('Prima::Image')) {
		fail($test_name);
		diag('  \$expected is not an image');
		return 0;
	}
	
	# Make sure the dimensions are the same
	if ($got->height != $expected->height) {
		fail($test_name);
		diag('image heights to not match:');
		diag('       got: ' . $got->height);
		diag('  expected: ' . $expected->height);
		return 0;
	}
	if ($got->width != $expected->width) {
		fail($test_name);
		diag('  image widths to not match:');
		diag('       got: ' . $got->width);
		diag('  expected: ' . $expected->width);
		return 0;
	}
	
	# Compare each pixel
	for my $i (0 .. $got->width - 1) {
		for my $j (0 .. $got->height - 1) {
			if ($got->pixel($i, $j) != $expected->pixel($i, $j)) {
				fail($test_name);
				diag("  pixel color mismatch at ($i, $j)");
				return 0;
			}
		}
	}
	
	return pass($test_name);
}

my $x = sequence(20);
my $y = $x**2;

my ($width, $height) = (100, 100);

my $plot = Prima::Plot->new(
	width => $width,
	height => $height,
	-to_plot => ds::Pair($x, $y),
);

# The easiest way to get an image from the plotting library:
my $image_easy = $plot->get_image;
my $image_easy2 = $plot->get_image;

# Make sure the test works
is_image($image_easy, $image_easy, 'Image comparison test function works');
is_image($image_easy2, $image_easy, 'Easy image production is reproducible');

# Create the image manually and draw to it in one of two ways:
my $test_draw_plot = Prima::Image->new(
	width => $width,
	height => $height,
	font => $image_easy->font,
);

# Draw using the draw_plot method
$test_draw_plot->begin_paint;
$test_draw_plot->clear;
$plot->draw_plot($test_draw_plot);
$test_draw_plot->end_paint;

is_image($test_draw_plot, $image_easy,
	'Manual draw_plot gives same output as get_image')
	or do {
		$test_draw_plot->save('test_draw_plot.bmp');
		$image_easy->save('test_expected.bmp');
		diag('  Saving expected result to test_expected, and bad result to test_draw_plot.bmp');
	};

my $test_seperate_font_setup = $test_draw_plot = Prima::Image->new(
	width => $width,
	height => $height,
);
$test_seperate_font_setup->font($plot->font);
# Draw using the draw_plot method
$test_seperate_font_setup->begin_paint;
$test_seperate_font_setup->clear;
$plot->draw_plot($test_seperate_font_setup);
$test_seperate_font_setup->end_paint;

is_image($test_seperate_font_setup, $image_easy,
	'Manual draw_plot with seperate font setup gives same output as get_image')
	or do {
		$test_seperate_font_setup->save('test_seperate_font_setup.bmp');
		$image_easy->save('test_expected.bmp');
		diag('  Saving expected result to test_expected, and bad result to test_seperate_font_setup.bmp');
	};


# Draw using the on_paint method
my $test_paint_event = Prima::Image->new(
	width => $width,
	height => $height,
	font => $image_easy->font,
);
$plot->notify('Paint', $test_paint_event);
$::application->yield;
is_image($test_paint_event, $image_easy,
	'Paint event on alternative canvas gives same output as get_image')
	or do {
		$test_paint_event->save('test_paint_event.bmp');
		$image_easy->save('test_expected.bmp');
		diag('  Saving expected result to test_expected.bmp, and bad result to test_paint_event.bmp');
	};

TODO: {
	# Draw without setting the font:
	local $TODO = 'Needs better font handling';
	my $test_no_font_setup = Prima::Image->new(
		width => $width,
		height => $height,
	);
	$test_no_font_setup->begin_paint;
	$test_no_font_setup->clear;
	$plot->draw_plot($test_no_font_setup);
	$test_no_font_setup->end_paint;
	is_image($test_no_font_setup, $image_easy,
		'Paint event without tweaked font gives same output as get_image')
		or do {
			$test_no_font_setup->save('test_paint_event_no_font.bmp');
			$image_easy->save('test_expected.bmp');
			diag('  Saving expected result to test_expected.bmp, and bad result to test_paint_event_no_font.bmp');
		};
}

unlink qw(test_paint_event_no_font.bmp test_expected.bmp);

done_testing;
