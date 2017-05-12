#!/usr/bin/env perl

use strict;
use warnings;

use SVG::Grid;

# ------------

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
$svg -> image_link
(
	href	=> 'http://savage.net.au/Flowers/Chorizema.cordatum.html',
	image	=> 'http://savage.net.au/Flowers/images/Chorizema.cordatum.0.jpg',
	target	=> 'new_window',
	x		=> 1, # Cell co-ord.
	y		=> 2, # Cell co-ord.
);
$svg -> rectangle_link
(
	href	=> 'http://savage.net.au/Flowers/Alyogyne.huegelii.html',
	target	=> 'new_window',
	x		=> 2, # Cell co-ord.
	y		=> 3, # Cell co-ord.
);
$svg -> text_link
(
	href	=> 'http://savage.net.au/Flowers/Aquilegia.McKana.html',
	stroke	=> 'rgb(255, 0, 0)',
	target	=> 'new_window',
	text	=> '3,1',
	x		=> 3, # Cell co-ord.
	y		=> 1, # Cell co-ord.
);
$svg -> write(output_file_name => 'data/synopsis.svg');
