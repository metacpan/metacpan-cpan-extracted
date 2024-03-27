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
    $pdf      = PDF::Builder->new( -file => $outfile );
}
# -------------
my $page     = $pdf->page();
$pdf->mediabox('A4');

# A4 as defined by PDF::API2 is h=842 w=545 for portrait

# some data to lay out. notice that there are 9 rows with the raw data for
# 'two' and 'four' being split up into multiple lines = multiple single rows,
# as well as 'four' being split on max_word_length
my $some_data = [
	# H. dk blue on yellow, underlined (each page)
	[ 'HeaderA', 'HeaderB' ],
	# 1. white on red,blue  underlined (page 1)
	[ 'foo',     'bar Aye' ],
	# 2. dk gray on light gray, underlined (page 2)
	[ 'one',     'twosie' ],
	# 3. light gray on dk gray, col 2 underlined, split multiple pages 3-6
	[ 'two',     'four score and seven years ago our forefathers brought forth' ],
	# 4. dk gray on light gray, underlined (page 7)
	[ 'three',   'six pack' ],
	# 5. light gray on dk gray, underlined, split multiple pages 8-9
	[ 'four',    'abcdefghijklmnopqrstuvwxyz' ],
];

# build the table layout
# this will show the header and one line (row), meaning two rows will be
# split up into multiple pages
$pdftable->table(

	# required params
	$pdf,
	$page,
	$some_data,
	x       => 10,
	w       => 255,
	start_y => 700,  # or y
	next_y  => 700,
	start_h => 69,   # or h. just enough height for two rows per page 
	next_h  => 69,   # (repeated header + next data row single line)

	# some optional params
	bg_color_odd => "#666666",
	bg_color_even => "#EEEEEE",
	fg_color_odd => "#EEEEEE",
	fg_color_even => "#666666",
        padding_left =>  10,    # new  
        padding_right => 10,
	border          => 0,   # no frame or rules (default thin line)
	font_size       => 20,  # default leading about 25
       #font_underline  => 'auto',   # underline everything with thin line
	font_underline  => [3, 2],   # or underline. thick underline for all 
	                             # text (including header) unless override
	max_word_length => 13,  # force alphabet row to split in half

	header_props    => {
		# font size defaults to 22, leading to 27.5
		background_color => 'yellow',  # or bg_color
		repeat           => 1  # is now default
	},
	cell_props => [
		[],   # header row no cell overrides
		[  # first data row (foo  bar Aye)
			{ background_color => 'red', fg_color => 'white'  }, 
			{ background_color => 'blue', fg_color => 'white' } 
		],
		[], # second data row, no cell overrides
		[  # third data row, no underline first column 'two  four...'
			{ underline => [] }  # 'none' OK for PDF::Builder
		],
	],
);

$pdf->save();
