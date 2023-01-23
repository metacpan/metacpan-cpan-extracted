#!/usr/bin/env perl
use warnings;
use strict;
use diagnostics;
use PDF::Table;

# Demonstrate a number of border and rule settings.

# Please use TABSTOP=4 for best view
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

our $VERSION = '1.004'; # VERSION
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
#   $pdf      = PDF::Builder->new( -file => $outfile );
    $pdf      = PDF::Builder->new( -file => $outfile, -compress=>'none' );
}
# -------------
my $page     = $pdf->page();

############################################################################
# illustrate thick border with inherited rules, thin rules, no rules
# -------------------- table 1a
my $table = [
	# rows TTB, LTR 
	[ 'Thick', 'border', ],
	[ 'Inherit', 'rules', ],
];

my $font_size = 15;
my $font  = $pdf->corefont('Helvetica');
my $fontb = $pdf->corefont('Helvetica-Bold');

# build the table layout
$pdftable->table(

	# required params
	$pdf,
	$page,
	$table,
	x  => 10,
	w  => 100,
	y  => 700, 
	h  => 100,

	# some optional params
	justify    => "center",
	font       => $font,
	font_size  => $font_size,
	border_w   => 8,
	# default padding 2 isn't quite enough, but show effect

	cell_props => [
		[],
		[
			{ font => $fontb, },
		],
	],
);

# -------------------- table 1b
$table = [
	# rows TTB, LTR 
	[ 'Thick', 'border', ],
	[ 'Thin', 'rules', ],
];

# build the table layout
$pdftable->table(

	# required params
	$pdf,
	$page,
	$table,
	x  => 160,
	w  => 100,
	y  => 700, 
	h  => 100,

	# some optional params
	justify    => "center",
	font       => $font,
	font_size  => $font_size,
	# borders both black, 8 wide
	border_w   => 8,
	# rules blue, 1 wide
	rule_w     => 1,
	rule_c     => 'blue',

	cell_props => [
		[],
		[
			{ font => $fontb, },
		],
	],
);

# -------------------- table 1c
$table = [
	# rows TTB, LTR 
	[ 'Thick', 'border', ],
	[ 'No', 'rules', ],
];

# build the table layout
$pdftable->table(

	# required params
	$pdf,
	$page,
	$table,
	x  => 310,
	w  => 100,
	y  => 700, 
	h  => 100,

	# some optional params
	justify    => "center",
	font       => $font,
	font_size  => $font_size,
	# vertical borders thick, horizontal borders (override) thinner
	border_w   => 8,
	h_border_w => 3,
	# no visible rules
	rule_w     => 0,

	cell_props => [
		[],
		[
			{ font => $fontb, },
		],
	],
);

############################################################################
# -------------------- table 2
# illustrate lots of row, col, cell color and rules variations
$table = [
	# rows TTB, LTR 
	[ '0,0', '0,1',  '0,2',   '0,3', '0,4',  '0,5',  '0,6', '0,7' ],
	[ '1,0', '1,1',  '1,2',   '1,3', '1,4',  '1,5',  '1,6', '1,7' ],
	[ '2,0', '2,1',  '2,2',   '2,3', '2,4',  '2,5',  '2,6', '2,7' ],
	[ '3,0', '3,1',  '3,2',   '3,3', '3,4',  '3,5',  '3,6', '3,7' ],
	[ '4,0', '4,1',  '4,2',   '4,3', '4,4',  '4,5',  '4,6', '4,7' ],
	[ '5,0', '5,1',  '5,2',   '5,3', '5,4',  '5,5',  '5,6', '5,7' ],
	[ '6,0', '6,1',  '6,2',   '6,3', '6,4',  '6,5',  '6,6', '6,7' ],
	[ '7,0', '7,1',  '7,2',   '7,3', '7,4',  '7,5',  '7,6', '7,7' ],
];

# build the table layout
$pdftable->table(

	# required params
	$pdf,
	$page,
	$table,
	x  => 10,
	w  => 500,
	y  => 590, 
	h  => 500,

	# some optional params
	justify    => "center",
	font       => $font,
	font_size  => $font_size,
	padding    => 10,
	# thick borders 
	border_w   => 3,
	border_c   => 'green',
	# thin rules
	rule_w     => 1,
	# rule_c inherits from border_c (green)

        # play some games with colors and rules. note that varying rule widths
	# and changes of rule color may not align perfectly nicely in wild
	# examples like this!

	# 1. no rules around 1,1 (also affects 0,1 and 1,2) and bold font
	# 2. 4,5 and 4,6 (overlap pink column) light blue bg
	# 3. 6,3 and 7,3 (overlap yellow row) light green bg
	# 4. 4,1 left and bottom rules thick black
	cell_props => [
		[ # row 0
			{},
			{ h_rule_w => 0, }, # 0,1 no bottom rule (top of 1,1)
		],
		[ # row 1
		  	{}, # 1,0
			{ font => $fontb, rule_w => 0, }, # 1,1
			{ v_rule_w => 0, }, # 1,2 no left rule (right of 1,1)
		],
		[],[],
		[ # row 4
			{},
			{ rule_c => 'black', rule_w => 4, }, # 4,1
			{},{},{},
			{ bg_color => '#EEEEFF', }, # 4,5
			{ bg_color => '#EEEEFF', }, # 4,6
		],
		[],
		[ # row 6
			{},{},{},
			{ bg_color => '#AAFFAA', } # 6,3
		],
		[ # row 7
			{},{},{},
			{ bg_color => '#AAFFAA', } # 7,3
		],
	],

	# 5. col 4 thick left vertical rule (form full line)
	# 6. col 5 thick bottom rule
	# 7. col 6 pink background
	column_props => [
		{},{},{},{},
		{ v_rule_w => 4, v_rule_c => 'black', },
		{ h_rule_w => 4, h_rule_c => '#666666', },
		{ bg_color => 'pink', },
	],
	
	# 8.  row 3 thick left rule
	# 9.  row 5 bottom horizontal rule (form full line), thick red
	# 10. row 7 yellow background
	row_props => [
		{},{},{},
		{ v_rule_w => 5, v_rule_c => '#888888', },
		{},
		{ h_rule_w => 3, h_rule_c => 'red', },
		{},
		{ bg_color => 'yellow', },
	],
);

############################################################################
# -------------------- table 3
# illustrate different kinds of bottom/top borders on row/table splits

# Lorem Ipsum text, borrowed from PDF::Builder::examples/022_truefonts 
$table = [
    [ # 0,0
"Sed ut perspiciatis, unde omnis iste natus error sit ".
"voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, ".
"quae ab illo inventore veritatis et quasi architecto beatae vitae dicta ".
"sunt, explicabo.",
      # 0,1
"Nemo enim ipsam voluptatem, quia voluptas sit, aspernatur ".
"aut odit aut fugit, sed quia consequuntur magni dolores eos, qui ratione ".
"dolor sit, voluptatem sequi nesciunt, neque porro quisquam est, qui dolorem ".
"ipsum, quia amet, consectetur, adipisci velit, sed quia non numquam eius ".
"modi tempora incidunt, ut labore et dolore magnam aliquam quaerat ".
"voluptatem."
    ],
    [ # 1,0
"Ut enim ad minima veniam, quis nostrum exercitationem ullam ".
"corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur?",
      # 1,1
"Quis autem vel eum iure reprehenderit, qui in ea voluptate velit esse, quam ".
"nihil molestiae consequatur, vel illum, qui dolorem eum fugiat, quo voluptas ".
"nulla pariatur?"
    ],
    [ # 2,0
"At vero eos et accusamus et iusto odio dignissimos ducimus, ".
"qui blanditiis praesentium voluptatum deleniti atque corrupti, quos dolores ".
"et quas molestias excepturi sint, obcaecati cupiditate non provident, ".
"similique sunt in culpa, qui officia deserunt mollitia animi, id est laborum ".
"et dolorum fuga.",
      # 2,1
"Et harum quidem rerum facilis est et expedita distinctio."
    ],
    [ # 3,0
"Nam libero tempore, cum soluta nobis est eligendi optio, cumque nihil ".
"impedit, quo minus id, quod maxime placeat, facere possimus, omnis voluptas ".
"assumenda est, omnis dolor repellendus.",
      # 3,1
"Temporibus autem quibusdam et aut ".
"officiis debitis aut rerum necessitatibus saepe eveniet, ut et voluptates ".
"repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur ".
"a sapiente delectus, ut aut reiciendis voluptatibus maiores alias ".
"consequatur aut perferendis doloribus asperiores repellat."
    ]
];

# build the table layout
$pdftable->table(

	# required params
	$pdf,
	$page,
	$table,
	x  => 10,
	w  => 240,
	y  => 200,      # start near bottom
	h  => 150,      # adjust to split in middle of row

	next_y => 700,
	next_h => 500,  # adjust to split at least once at row boundary
	                # 530 is also a good split

	# some optional params
	default_text => ' ',
	justify    => "left",
	font       => $font,
	font_size  => $font_size,
	padding    => 10,
	# thick borders 
	border_w   => 6,
	border_c   => '#222222',
	# thin rules
	rule_w     => 2,  # to distinguish from split-row solid/dashed
	# rule_c inherits from border_c (dark gray)

);

$pdf->save();
