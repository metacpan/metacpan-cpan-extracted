#!/usr/bin/env perl
use warnings;
use strict;
use diagnostics;

#Please use TABSTOP=4 for best view
use PDF::API2;
use PDF::Table;

my $pdftable = new PDF::Table;
my $pdf      = new PDF::API2( -file => "header_repeat_with_cell_props.pdf" );
my $page     = $pdf->page();
$pdf->mediabox('A4');

# A4 as defined by PDF::API2 is h=842 w=545 for portrait

# some data to layout
my $some_data = [
	[ 'Header',              'Row',   'Test' ],
	[ '1 Lorem ipsum dolor', 'Donec', 'consequat quis, tincidunt vel, felis.' ],
	[ '2 Lorem ipsum dolor', 'Donec super long text goes here to provoke a text block', 'consequat quis, tincidunt vel, felis.' ],
	[ '3 Lorem ipsum dolor', 'Donec', 'consequat quis, tincidunt vel, felis.' ],
	[ '4 Lorem ipsum dolor', 'Donec super long text goes here to provoke a text block', 'consequat quis, tincidunt vel, felis.' ],
	[ '5 Lorem ipsum dolor', 'Donec', 'consequat quis, tincidunt vel, felis.' ],
	[ '6 Lorem ipsum dolor', 'Donec', 'consequat quis, tincidunt vel, felis.' ],
	[ '7 Lorem ipsum dolor', 'Donec', 'consequat quis, tincidunt vel, felis.' ],
	[ '8 Lorem ipsum dolor', 'Donec', 'consequat quis, tincidunt vel, felis.' ],
	[ '9 Lorem ipsum dolor', 'Donec', 'consequat quis, tincidunt vel, felis.' ],

];

# build the table layout
my $cell_props = [];
$cell_props->[2][1] = {
	background_color => '#000000',
	font_color       => 'blue',
	justify          => 'left'
};
$cell_props->[4][1] = {
	background_color => '#000000',
	font_color       => 'red',
	justify          => 'center'
};
$cell_props->[6][1] = {
	background_color => '#000000',
	font_color       => 'yellow',
	justify          => 'right'
};

$pdftable->table(

	# required params
	$pdf,
	$page,
	$some_data,
	x       => 10,
	w       => 350,
	start_y => 780,
	next_y  => 780,
	start_h => 200,
	next_h  => 200,
	padding => 10,

	# some optional params
	font_size          => 10,
	padding_right      => 10,
	horizontal_borders => 1,
	header_props       => {
		bg_color   => "silver",
		font       => $pdf->corefont( "Helvetica", -encoding => "utf8" ),
		font_size  => 20,
		font_color => "#006600",
		#justify => 'left',
		repeat  => 1,
	},
	cell_props => $cell_props
);
$pdf->saveas();
