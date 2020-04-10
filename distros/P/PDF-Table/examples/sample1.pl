#!/usr/bin/env perl
use warnings;
use strict;
use diagnostics;

=pod 

This example file gives an overview of the functionalities provided by PDF::Table
Also it can be used to bootstrap your code.

=cut

#Please use TABSTOP=4 for best view
use PDF::Table;
# -------------
my ($PDFpref, $rcA, $rcB); # which is available?
my $prefFile = "./PDFpref";
my $prefDefault = "B"; # PDF::Builder default if no prefFile, or both installed
if (-f $prefFile && -r $prefFile) {
    open my $FH, '<', $prefFile or die "error opening $prefFile: $!\n";
    $PDFpref = <$FH>;
    if      ($PDFpref =~ m/^A/i) {
	# something starting with A, assume want PDF::API2
	$PDFpref = 'A';
    } elsif ($PDFpref =~ m/^B/i) {
	# something starting with B, assume want PDF::Builder
	$PDFpref = 'B';
    } elsif ($PDFpref =~ m/^PDF:{1,2}A/i) {
	# something starting with PDF:A or PDF::A, assume want PDF::API2
	$PDFpref = 'A';
    } elsif ($PDFpref =~ m/^PDF:{1,2}B/i) {
	# something starting with PDF:B or PDF::B, assume want PDF::Builder
	$PDFpref = 'B';
    } else {
	print STDERR "Don't see A... or B..., default to $prefDefault\n";
	$PDFpref = $prefDefault;
    }
    close $FH;
} else {
    # no preference expressed, default to PDF::Builder
    print STDERR "No preference file found, so default to $prefDefault\n";
    $PDFpref = $prefDefault;
}
foreach (1 .. 2) {
    if ($PDFpref eq 'A') { # A(PI2) preferred
        $rcA = eval {
            require PDF::API2;
            1;
        };
        if (!defined $rcA) { $rcA = 0; } # else is 1;
        if ($rcA) { $rcB = 0; last; }
	$PDFpref = 'B';
    } 
    if ($PDFpref eq 'B') { # B(uilder) preferred
        $rcB = eval {
            require PDF::Builder;
            1;
        };
        if (!defined $rcB) { $rcB = 0; } # else is 1;
	if ($rcB) { $rcA = 0; last; }
	$PDFpref = 'A';
    }
}
if (!$rcA && !$rcB) {
    die "Neither PDF::API2 nor PDF::Builder is installed!\n";
}
# -------------

our $VERSION = '0.12'; # VERSION
my $LAST_UPDATE = '0.12'; # manually update whenever code is changed

my $outfile = $0;
if ($outfile =~ m#[\\/]([^\\/]+)$#) { $outfile = $1; }
$outfile =~ s/\.pl$/.pdf/;

my $pdftable = PDF::Table->new();
# -------------
my $pdf;
if ($rcA) {
    print STDERR "Using PDF::API2 library\n";
    $pdf      = PDF::API2->new( -file => $outfile );
} else {
    print STDERR "Using PDF::Builder library\n";
    $pdf      = PDF::Builder->new( -file => $outfile );
}
# -------------
my $page     = $pdf->page();
$pdf->mediabox('A4');

# A4 as defined by PDF::API2 is h=842 w=545 for portrait

# some data to layout
my $some_data = [
	[ 'Header', 'Row', 'Test' ],
	[
		'1 Lorem ipsum dolor',
		'Donec odio neque, faucibus vel',
		'consequat quis, tincidunt vel, felis.'
	],
	[ 'Nulla euismod sem eget neque.', 'Donec odio neque', 'Sed eu velit.' ],
	[
		'Az sym bulgarin',
		"i ne razbiram DESI\ngorniq \nezik",
		"zatova reshih
		da dobavq
		edin ili dva
		novi reda"
	],
	[
		'da dobavq edin dva reda',
		'v tozi primer',
		'na bulgarski ezik s latinica'
	],
	[
		'1 Lorem ipsum dolor',
		'Donec odio neque, faucibus vel',
		'consequat quis, tincidunt vel, felis.'
	],
	[ 'Nulla euismod sem eget neque.', 'Donec odio neque', 'Sed eu velit.' ],
	[ 'Az sym bulgarin', 'i ne razbiram gorniq ezik', 'zatova reshih' ],
	[
		'da dobavq edin dva reda',
		'v tozi primer',
		'na bulgarski ezik s latinica'
	],
];

# build the table layout
$pdftable->table(

	# required params
	$pdf,
	$page,
	$some_data,

	# Geometry of the document
	x  => 50,
	-w => 495
	, # dashed params supported for backward compatibility. dash/non-dash params can be mixed
	start_y  => 792,
	next_y   => 700,
	-start_h => 400,
	next_h   => 500,

	# some optional params for fancy results
	-padding              => 3,
	padding_right         => 10,
	background_color_odd  => 'lightblue',
	background_color_even => "#EEEEAA",     #cell background color for even rows
	header_props          => {
		bg_color   => "#F0AAAA",
		font       => $pdf->corefont( "Helvetica", -encoding => "utf8" ),
		font_size  => 14,
		font_color => "#006600",
		repeat     => 1
	},
	column_props => [
		{},                                 #no properties for the first column
		{
			min_w      => 250,
			justify    => "right",
			font       => $pdf->corefont( "Times", -encoding => "latin1" ),
			font_size  => 14,
			font_color => 'white',
			background_color => '#8CA6C5',
		},
	],
	cell_props => [
		[ #This is the first(header) row of the table and here wins %header_props
			{
				background_color => '#000000',
				font_color       => 'blue',
			},

			# etc.
		],
		[    #Row 2
			{    #Row 2 cell 1
				background_color => '#000000',
				font_color       => 'white',
			},
			{    #Row 2 cell 2
				background_color => '#AAAA00',
				font_color       => 'red',
			},
			{    #Row 2 cell 3
				background_color => '#FFFFFF',
				font_color       => 'green',
			},

			# etc.
		],
		[        #Row 3
			{    #Row 3 cell 1
				background_color => '#AAAAAA',
				font_color       => 'blue',
			},

			# etc.
		],

		# etc.
	],
);
$pdf->saveas();
