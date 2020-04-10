#!/usr/bin/env perl
use strict;
use warnings;

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

my $data = [

    # Row 1, with 3 cols
    [   "(r1c1) Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        "(r1c2) Ut",
        "(r1c3) enim ad minim veniam,"
    ],

    # Row 2, one col with colspan=3
    [   "(r2c1++) quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur."
    ],

    # Row 3, one regular col, one with colspan=2
    [   "(r3c1) Excepteur sint occaecat cupidatat",
        "(r3c2+) non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    ],

    # Row 4, just three regular cols, second empty
    [   "(r4c1) Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        "",
        "(r4c3) Ut enim"
    ],

    # Row 5, colspan in first col, then a regular col
    [   "(r5c1+) Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        undef,
        "(r5c3) Ut enim"
    ],
];

$pdftable->table(
    $pdf, $page, $data,
    w            => 260,    # width of table
    x            => 10,     # position from left
    start_y      => 750,    # position from bottom
    start_h      => 700,    # max height of table
    padding      => 5,      # well, padding...
    column_props => [
        { min_w => 150, background_color => 'grey' },    # col 1
        { background_color => 'red' },                   # col 2
        {}                                               # col 3
    ],
    cell_props => [
        [   {},    # row 1 cell 2 & 3 overrides
            { background_color => 'pink' },
            { background_color => 'blue', colspan => 1 }
        ],
        [ { colspan => 3 } ],    # row 2 cell 1 override
        [ {}, { colspan => 2 } ],    # row 3 cell 2 override
        [ ],    # row 4
        [ { colspan => 2 } ],    # row 5 cell 1 override
    ],
);
$pdf->saveas();

