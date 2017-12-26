#!/usr/bin/env perl

use strict;
use utf8;
use warnings;

use File::Slurper 'read_binary';
use File::Spec;
use File::Temp;

use SVG::Grid;

use Test::More;

# ------------------------------------------------

my($cell_width)		= 40;
my($cell_height)	= 40;
my($x_cell_count)	=  3;
my($y_cell_count)	=  3;
my($x_offset)		= 40;
my($y_offset)		= 40;
my($svg)			= SVG::Grid -> new
(
	cell_width		=> $cell_width,
	cell_height		=> $cell_height,
	x_cell_count	=> $x_cell_count,
	y_cell_count	=> $y_cell_count,
	x_offset		=> $x_offset,
	y_offset		=> $y_offset,
);
my($width) =
(
	$x_cell_count * $cell_width
		+ 2 * $x_offset
		+ 2 * $cell_width
);
my($height) =
(
	$y_cell_count * $cell_height
		+ 2 * $y_offset
		+ 2 * $cell_height
);

ok($x_cell_count == $svg -> x_cell_count, "Comparing x_cell_counts");
ok($y_cell_count == $svg -> y_cell_count, "Comparing y_cell_counts");
ok($x_offset == $svg -> x_offset, "Comparing x_offset");
ok($y_offset == $svg -> y_offset, "Comparing y_offset");
ok($width == $svg -> width, "Comparing widths");
ok($height == $svg -> height, "Comparing heigths");

$svg -> frame('stroke-width' => 3);
$svg -> text
(
	'font-size'		=> 20,
	'font-weight'	=> '400',
	text			=> 'Front Garden',
	x				=> $svg -> x_offset,     # Pixel co-ord.
	y				=> $svg -> y_offset / 2, # Pixel co-ord.
);
$svg -> text
(
	'font-size'		=> 14,
	'font-weight'	=> '400',
	text			=> '--> N',
	x				=> $svg -> width - 2 * $svg -> cell_width, # Pixel co-ord.
	y				=> $svg -> y_offset / 2,                   # Pixel co-ord.
);
$svg -> grid(stroke => 'blue');

# These tests use http://savage.net.au despite the fact that CPANTesters can run setups
# which are not connected to the internet. It's safe because the tests don't assume that.

$svg -> image_link
(
	href	=> 'http://savage.net.au/Flowers/Chorizema.cordatum.html',
	image	=> 'http://savage.net.au/Flowers/images/Chorizema.cordatum.0.jpg',
	target	=> 'new_window',
	title	=> 'MouseOver® an image',
	x		=> 1, # Cell co-ord.
	y		=> 2, # Cell co-ord.
);
$svg -> rectangle_link
(
	href	=> 'http://savage.net.au/Flowers/Alyogyne.huegelii.html',
	target	=> 'new_window',
	title	=> 'MouseOver™ a rectangle',
	x		=> 2, # Cell co-ord.
	y		=> 3, # Cell co-ord.
);
$svg -> text_link
(
	href	=> 'http://savage.net.au/Flowers/Aquilegia.McKana.html',
	stroke	=> 'rgb(255, 0, 0)',
	target	=> 'new_window',
	text	=> '3,1',
	title	=> 'MouseOvér some text',
	x		=> 3, # Cell co-ord.
	y		=> 1, # Cell co-ord.
);

# The EXLOCK option is for BSD-based systems.

my($temp_dir)			= File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
my($output_file_name)	= File::Spec -> catfile($temp_dir, 'test.svg');
$output_file_name		= '/tmp/test.svg';

$svg -> write(output_file_name => $output_file_name);

# For this test we have to zap the SVG modules' version #s
# which are embedded in the 2 files.

my($got)				= read_binary($output_file_name);
$got					= "$1$2" if ($got =~ /(.+)<!--.+-->(.+)/ms);
my($input_file_name)	= File::Spec -> catfile('data', 'synopsis.svg');
my($expected)			= read_binary($input_file_name);
$expected				= "$1$2" if ($expected =~ /(.+)<!--.+-->(.+)/ms);
my($result)			 	= $got eq $expected;

ok($result, "$output_file_name matches $input_file_name");

done_testing;
