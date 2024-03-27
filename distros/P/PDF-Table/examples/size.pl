#!/usr/bin/env perl
use warnings;
use strict;
use diagnostics;
use PDF::Table;

=pod 

This example file gives an overview of the functionality of the 'size' 
parameter for PDF::Table.

=cut

# Please use TABSTOP=4 for best view
# -------------
# -A or -B on command line to select preferred library (if available)
# then look for PDFpref file and read A or B forms
my ($PDFpref, $rcA, $rcB); # which is available?
my $prefFile = "examples/PDFpref";
my $prefix = 0;  # by default, do not add a prefix to the output name
my $prefDefault = "B"; # PDF::Builder default if no prefFile, or both installed

# command line selection of preferred library? A..., -A..., B..., or -B...
if (@ARGV) {
    # A or -A argument: set PDFpref to A else B
    if ($ARGV[0] =~ m/^-?([AB])/i) {
	$PDFpref = uc($1);
	$prefix = 1;
    } else {
	print STDERR "Unknown command line flag $ARGV[0] ignored.\n";
    }
}
# environment variable selection of preferred library?
# A..., B..., PDF:[:]A..., or PDF:[:]B...
if (!defined $PDFpref) {
    if (defined $ENV{'PDF_prefLib'}) {
        $PDFpref = $ENV{'PDF_prefLib'};
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
        }
    }
}
# PDF preference file selecting preferred library?
# A..., B..., PDF:[:]A..., or PDF:[:]B...
if (!defined $PDFpref) {
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
        }
        close $FH;
    }
}
# still no preferred library indicated? use the default
if (!defined $PDFpref) {
        # no preference expressed, default to PDF::Builder
        print STDERR "No library preference given, so default to ".
	  (($prefDefault eq 'A')? 'PDF::API2': 'PDF::Builder')." as preferred.\n";
        $PDFpref = $prefDefault;
}

# try to use the preferred library, if available
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

our $VERSION = '1.006'; # VERSION
our $LAST_UPDATE = '1.006'; # manually update whenever code is changed

my $outfile = $0;
if ($outfile =~ m#[\\/]([^\\/]+)$#) { $outfile = $1; }
$outfile =~ s/\.pl$/.pdf/;
# command line -A or -B adds A_ or B_ to outfile
if ($prefix) { $outfile = $PDFpref . "_" . $outfile; }

my $pdftable = PDF::Table->new();
# -------------
my $pdf;
if ($rcA) {
    print STDERR "Using PDF::API2 library\n";
    $pdf      = PDF::API2->new( -file => $outfile );
} else {
    print STDERR "Using PDF::Builder library\n";
    $pdf      = PDF::Builder->new( -file => $outfile, -compress => 'none' );
}
# -------------
my $page     = $pdf->page();
$pdf->mediabox('A4');
my $txt      = $page->text();
my $font     = $pdf->corefont("Times-Roman");
$txt->font($font, 12);

# A4 as defined by PDF::API2 is h=842 w=545 for portrait

# some data to lay out. emphasis is on size string.
my $some_dataX = [
	# header shows size entries
	[ '*', '2.1cm', '27mm', '5em', '.99in', '7.5ex', '1.9*' ],
	[
		'1 Lorem ipsum dolor',
		'Donec odio neque, fauci bus vel',
		'1 conse quat quis, tinci dunt vel, felis.',
		'1 Lorem ipsum dolor',
		'Donec odio neque, fauci bus vel',
		'1 conse quat quis, tinci dunt vel, felis.',
		'1 Lorem ipsum dolor',
	],
	[ 
		'Nulla euis mod sem eget neque.', 
		'Donec odio neque', 
		'Sed eu velit.',
		'Nulla euis mod sem eget neque.', 
		'Donec odio neque', 
		'Sed eu velit.',
		'Nulla euis mod sem eget neque.', 
       	],
];
my $some_data;

my $yCur = 800;
my $size = '* 2.1cm 27mm 5em .99in 7.5ex 1.9*';
my $title = "Normal operation";
for (my $row = 0; $row < 3; $row++) {
    $some_data->[$row] = $some_dataX->[$row];
}
makeTable($pdftable, $pdf, $page, $txt, $some_data, $yCur, $size, $title);

# do some others where 'size' has to be adjusted, etc.
$yCur -= 250;
$size = '50pt 50 50 50 50pt 50 *';
$title = "implicit and explicit pt widths";
for (my $row = 0; $row < 3; $row++) {
    $some_data->[$row] = $some_dataX->[$row];
}
makeTable($pdftable, $pdf, $page, $txt, $some_data, $yCur, $size, $title);

$yCur -= 250;
$size = '60pt 60 60 60 60pt 60 60pt';
$title = "all explicit widths, falls short of overall width (reduce overall)";
for (my $row = 0; $row < 3; $row++) {
    $some_data->[$row] = $some_dataX->[$row];
}
makeTable($pdftable, $pdf, $page, $txt, $some_data, $yCur, $size, $title);

# new page
$page     = $pdf->page();
$pdf->mediabox('A4');
$txt      = $page->text();
$font     = $pdf->corefont("Times-Roman");
$txt->font($font, 12);

$yCur = 800;
#$yCur -= 250;
$size = '75pt 75 75 75 75pt 75 75pt';
$title = "all explicit widths, too wide (increase width)";
for (my $row = 0; $row < 3; $row++) {
    $some_data->[$row] = $some_dataX->[$row];
}
makeTable($pdftable, $pdf, $page, $txt, $some_data, $yCur, $size, $title);

#$yCur = 800;
$yCur -= 250;
$size = '* * * * * * *';
$title = "evenly allocated widths";
for (my $row = 0; $row < 3; $row++) {
    $some_data->[$row] = $some_dataX->[$row];
}
makeTable($pdftable, $pdf, $page, $txt, $some_data, $yCur, $size, $title);

#$yCur = 800;
$yCur -= 250;
$size = '* 2* 3* 1.5* .95* * 2*';
$title = "unevenly allocated widths";
for (my $row = 0; $row < 3; $row++) {
    $some_data->[$row] = $some_dataX->[$row];
}
makeTable($pdftable, $pdf, $page, $txt, $some_data, $yCur, $size, $title);

# new page
$page     = $pdf->page();
$pdf->mediabox('A4');
$txt      = $page->text();
$font     = $pdf->corefont("Times-Roman");
$txt->font($font, 12);

# recoverable errors (warnings)
$yCur = 800;
#$yCur -= 250;
$size = '82.42 82.42 82.42 82.42 82.42 82.42 *';
$title = "insufficient space left for allocated column (widen table)";
for (my $row = 0; $row < 3; $row++) {
    $some_data->[$row] = $some_dataX->[$row];
}
makeTable($pdftable, $pdf, $page, $txt, $some_data, $yCur, $size, $title);

#$yCur = 800;
$yCur -= 250;
$size = '-75pt 37zg 3.4.2in 100 in 2CM *';
# -75 number whole entry not recognized (use *)
# zg unit not recognized, use mm instead
# 3.4.2 number not recognized, use 1 instead
# 100 and in recognized as two columns (100pt and 1in)
# CM OK (treat as cm)
$title = "various number and unit errors to ignore";
for (my $row = 0; $row < 3; $row++) {
    $some_data->[$row] = $some_dataX->[$row];
}
makeTable($pdftable, $pdf, $page, $txt, $some_data, $yCur, $size, $title);

if (0) {
    # fatal errors
    #$yCur = 800;
    $yCur -= 250;
# one of possibly several cases
if (1) {
    $size = '       ';
    $title = "no column width elements in size string";
}
    for (my $row = 0; $row < 3; $row++) {
        $some_data->[$row] = $some_dataX->[$row];
    }
    makeTable($pdftable, $pdf, $page, $txt, $some_data, $yCur, $size, $title);
}

$pdf->save();
# -------------------------------------

# build the table layout. like the data (text), the various properties and
# settings could be pulled out of line.
sub makeTable {
    my ($pdftable, $pdf, $page, $txt, $some_data, $yCur, $size, $title) = @_;

    print "--------- $title -------------\n";
    $txt->translate(10, $yCur+20);
    $txt->text($title);
    my @size_vec = split /\s+/, $size;
    $some_data->[0] = \@size_vec;

    $pdftable->table(

	# required params
	$pdf,
	$page,
	$some_data,

	# Geometry of the document
	x        => 50,
	w        => 495,  # width: most of an A4 page
	y        => $yCur,
	next_y   => 800,
	h        => 250, # reduce to force overflow to new page
	next_h   => 250,

	# some optional params for fancy results
        size           => $size,
	bg_color_odd   => 'lightblue',
	bg_color_even  => "#EEEEAA",
	# using default font (Times-Roman 12pt)
	
	header_props          => {
		bg_color   => "#F0AAAA",
		font       => $pdf->corefont( "Helvetica", -encoding => "latin1" ),
		font_size  => 10,
		fg_color   => "#006600",
		repeat     => 1  # default
		# note that col 2 inherits RJ from column_props setting
	},
	column_props => [
		{},                    # no properties for the first column
		{                      # column 2 overrides: force wider,
			               # larger font, right-justified, own bg.
			min_w      => 250, # ignored
			justify    => "right",
			font       => $pdf->corefont( "Times-Roman", -encoding => "latin1" ),
			font_size  => 10, 
			fg_color   => 'white',
			bg_color   => '#8CA6C5',
		},
		                       # column 3 no overrides
	],
	cell_props => [
		[ # This is the first(header) row of the table and here 
		  # %header_prop has priority, so no effect with these settings
			{
				bg_color   => '#000000',
				fg_color   => 'blue',
			},

			# etc.
		],
		[ # Row 2 (first data row)
			{ # Row 2 col 1
				bg_color   => '#000000',
				fg_color   => 'white',
			},
			{ # Row 2 col 2
				bg_color   => '#AAAA00',
				fg_color   => 'red',
			},
			{ # Row 2 col 3
				bg_color   => '#FFFFFF',
				fg_color   => 'green',
			},

			# etc.
		],
		[ # Row 3 (second data row)
			{ # Row 3 cell 1
				bg_color   => '#AAAAAA',
				fg_color   => 'blue',
			},

			# etc. rest of columns are normal
		],

		# etc. rest of rows are normal
	],
    );  # end of table() call
    
    return;
} # end of makeTable()
