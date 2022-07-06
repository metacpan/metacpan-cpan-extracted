#!/usr/bin/env perl
use warnings;
use strict;
use diagnostics;
use PDF::Table;

# Please use TABSTOP=4 for best view
# -------------
# -A or -B on command line to select preferred library (if available)
# then look for PDFpref file and read A or B forms
my ($PDFpref, $rcA, $rcB); # which is available?
my $prefFile = "./PDFpref";
my $prefDefault = "B"; # PDF::Builder default if no prefFile, or both installed
if (@ARGV) {
    # A or -A argument: set PDFpref to A else B
    if ($ARGV[0] =~ m/^-?([AB])/i) {
	$PDFpref = uc($1);
    } else {
	print STDERR "Unknown command line flag $ARGV[0] ignored.\n";
    }
}
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

our $VERSION = '1.003'; # VERSION
our $LAST_UPDATE = '1.000'; # manually update whenever code is changed

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
	background_color => '#000000',  # or bg_color
	font_color       => 'blue',     # or fg_color
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

# note that cell properties taken out-of-line
$pdftable->table(

	# required params
	$pdf,
	$page,
	$some_data,
	x       => 10,
	w       => 350,
	start_y => 780,  # or y
	next_y  => 780,
	start_h => 210,  # or h
	next_h  => 210,

	# some optional params
	font_size          => 10,
	padding            => 10,
       #padding_right      => 10,
	horizontal_borders => 1,
	header_props       => {
		bg_color   => "silver",
		font       => $pdf->corefont( "Helvetica", -encoding => "utf8" ),
		font_size  => 20,
		font_color => "#006600",  # or fg_color
		#justify => 'left',
		repeat  => 1,  # default
	},
	cell_props => $cell_props
);

$pdf->save();
