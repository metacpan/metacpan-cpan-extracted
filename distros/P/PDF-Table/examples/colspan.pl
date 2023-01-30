#!/usr/bin/env perl
use strict;
use warnings;
use PDF::Table;

# -------------
# -A or -B on command line to select preferred library (if available)
# then look for PDFpref file and read A or B forms
my ($PDFpref, $rcA, $rcB); # which is available?
my $prefFile = "./PDFpref";
my $prefix = 0;  # by default, do not add a prefix to the output name
my $prefDefault = "B"; # PDF::Builder default if no prefFile, or both installed
if (@ARGV) {
    # A or -A argument: set PDFpref to A else B
    if ($ARGV[0] =~ m/^-?([AB])/i) {
	$PDFpref = uc($1);
	$prefix = 1;
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

our $VERSION = '1.005'; # VERSION
our $LAST_UPDATE = '1.004'; # manually update whenever code is changed

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
    $pdf      = PDF::Builder->new( -file => $outfile );
}
# -------------
my $page     = $pdf->page();
$pdf->mediabox('A4');

my $data = [

    # Row 1, with 3 cols
    [   "(r1c1) Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        "(r1c2) Ut",
        "(r1c3) enim ad minim veniam, [3 cols in row 1]"
    ],

    # Row 2, one col with colspan=3
    [   "(r2c1++) quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. [spans 3 columns]"
    ],

    # Row 3, one regular col, one with colspan=2
    [   "(r3c1) Excepteur sint occaecat cupidatat",
        "(r3c2+) non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. [spans cols 2 and 3]"
    ],

    # Row 4, just three regular cols, second empty
    [   "(r4c1) Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        " ",    # if "", get warning about inserting default text
        "(r4c3) Ut enim. [3 columns, second empty]"
    ],

    # Row 5, colspan in first col, then a regular col
    [   "(r5c1+) Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        undef,
        "(r5c3) Ut enim. [span first two cols]"
    ],
];

$pdftable->table(
    $pdf, $page, $data,
    w            => 265,    # width of table
    x            => 10,     # position from left
    start_y      => 750,    # or y. position from bottom
    start_h      => 700,    # or h. max height of table
    padding      => 5,      # padding on all 4 sides of a cell
    column_props => [
        { min_w => 150, background_color => 'grey' },    # col 1
        { background_color => 'red' },                   # col 2, including
	                    # colspanned col 3 on row 3
        {}                                               # col 3 (nothing)
    ],
    cell_props => [  # no header, so data row 0 is actually row 1
        [   {},    # row 1 cell 2 & 3 overrides
            { background_color => 'pink' },   # or bg_color
            { background_color => 'blue', colspan => 1 }
        ],
        [ { colspan => 3 } ],        # row 2 cell 1 override
        [ {}, { colspan => 2 } ],    # row 3 cell 2 override
        [ ],                         # row 4
        [ { colspan => 2 } ],        # row 5 cell 1 override
    ],
);

$pdf->save();

