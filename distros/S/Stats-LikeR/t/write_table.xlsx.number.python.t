#!/usr/bin/env perl

# write_table's .xlsx output: a string is a number cell only when the number
# Excel shows is the text that was written ("A string is a number cell only
# when Excel would show it as it stands", the POD).  Up to 0.3425 these were
# all written as <v> number cells, and shown as something else, as the
# maintainer reported of that release:
#
#   text written          openpyxl 3.1.5      LibreOffice
#   6.10 1.0 0.50 1.000   6.1 1.0 0.5 1.0     6.1 1 0.5 1
#   1.  10.               1.0 10.0            1 10
#   .5  -.5               0.5 -0.5            0.5 -0.5
#   1e5 1E5 2.5e-3        100000.0 100000.0 0.0025    100000 100000 0.0025
#   -0  -0.0  0.0         0 -0.0 0.0          0 0 0
#
# Now a trailing 0 after the point, a point with no digit after it or none
# before it, any exponent and a minus sign on zero make the string text, so a
# string cell holds exactly what was written.
#
# Provenance of the frozen values: every row of @case was written by this
# module's 0.3426 write_table() as a one-column workbook, header 'v', and read
# back with openpyxl 3.1.5 (openpyxl.load_workbook(), cell.value and
# cell.data_type) and with LibreOffice 24.2.7.2 (soffice --headless
# --convert-to csv, which writes each cell as shown), both on 2026-11-19.  The
# generator is t/write_table.xlsx.number.python.py, which says how to re-run
# it; this test never calls it, and needs neither python nor LibreOffice.
# openpyxl's value for a number cell is the Python number, written here as its
# perl literal; for a string cell it is the string itself.
#
# The sheet XML is read directly, not round-tripped through read_table(),
# which returns a <v>'s text as it stands ("6.10" reads back as "6.10") and so
# cannot tell a number cell from a string cell.  "6.12", "007" and the plain
# numbers are the unchanged cases.

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';
use Stats::LikeR qw(write_table);

my $have_unzip = eval { require IO::Uncompress::Unzip; 1 };
plan skip_all => 'IO::Uncompress::Unzip (core) is needed' unless $have_unzip;

my $dir = File::Temp->newdir;
my $seq = 0;
sub xlsx_path { $seq++; return "$dir/t$seq.xlsx" }
sub sheet {
	my $z = IO::Uncompress::Unzip->new($_[0], Name => 'xl/worksheets/sheet1.xml') or die "no sheet1";
	my ($out, $buf) = ('', '');
	$out .= $buf while $z->read($buf) > 0;
	$z->close;
	return $out;
}
sub cell_a {
	my ($xml, $row) = @_;
	return $xml =~ m{(<c r="A$row"[^>]*>.*?</c>)}s ? $1 : undef;
}

# [text written, 's' (a string) or 'n' (a number) as openpyxl reads the cell,
#  what openpyxl returns for it, what LibreOffice shows]
my @case = (
	# the strings 0.3425 wrote as numbers, and why they are text now
	['6.10',   's', '6.10',   '6.10'],		# a trailing 0 after the point
	['1.0',    's', '1.0',    '1.0'],
	['0.50',   's', '0.50',   '0.50'],
	['1.000',  's', '1.000',  '1.000'],
	['0.10',   's', '0.10',   '0.10'],
	['-1.50',  's', '-1.50',  '-1.50'],
	['1.',     's', '1.',     '1.'],		# a point with no digit after it
	['10.',    's', '10.',    '10.'],
	['.5',     's', '.5',     '.5'],		# no digit before the point
	['-.5',    's', '-.5',    '-.5'],
	['1e5',    's', '1e5',    '1e5'],		# any exponent
	['1E5',    's', '1E5',    '1E5'],
	['2.5e-3', 's', '2.5e-3', '2.5e-3'],
	['-0',     's', '-0',     '-0'],		# a minus sign on zero
	['-0.0',   's', '-0.0',   '-0.0'],
	['0.0',    's', '0.0',    '0.0'],
	# what was text, and stays text
	['007',    's', '007',    '007'],
	['1e',     's', '1e',     '1e'],
	['-.',     's', '-.',     '-.'],
	# what is a number cell, and shows as it was written
	['0',      'n', 0,        '0'],
	['6.12',   'n', 6.12,     '6.12'],
	['0.5',    'n', 0.5,      '0.5'],
	['-0.5',   'n', -0.5,     '-0.5'],
	['100.5',  'n', 100.5,    '100.5'],
	['12.25',  'n', 12.25,    '12.25'],
	['42',     'n', 42,       '42'],
	['-7',     'n', -7,       '-7'],
	['10',     'n', 10,       '10'],
	['100',    'n', 100,      '100'],
	['1.5',    'n', 1.5,      '1.5'],
);

my $f = xlsx_path();
write_table([['v'], map { [ $_->[0] ] } @case], $f, quiet => 1);
my $x = sheet($f);
for my $i (0 .. $#case) {
	my ($text, $kind, $opx, $lo) = @{ $case[$i] };
	my $r = $i + 2;
	my $want = $kind eq 's'
		? qq{<c r="A$r" t="inlineStr"><is><t xml:space="preserve">$text</t></is></c>}
		: qq{<c r="A$r"><v>$text</v></c>};
	is(cell_a($x, $r), $want, "'$text' is " . ($kind eq 's' ? 'a string cell' : 'a number cell'));
	if ($kind eq 'n') {
		cmp_ok($opx, '==', $text, "... which openpyxl reads as the number $opx");
	} else {
		is($opx, $text, '... whose string openpyxl returns as written');
	}
	is($lo, $text, '... and LibreOffice shows as written');
}

# A number the caller holds as a number keeps the handling it had: it is a
# number cell whatever its text, as in pandas.
{
	my $g = xlsx_path();
	write_table([['v'], [100000], [0.0025], [0.5], [-7]], $g, quiet => 1);
	my $y = sheet($g);
	is(cell_a($y, 2), '<c r="A2"><v>100000</v></c>', 'the number 100000 is a number cell');
	is(cell_a($y, 3), '<c r="A3"><v>0.0025</v></c>', '... and 0.0025');
	is(cell_a($y, 4), '<c r="A4"><v>0.5</v></c>', '... and 0.5');
	is(cell_a($y, 5), '<c r="A5"><v>-7</v></c>', '... and -7');
}

# The writer does not leak, whichever way a cell goes.
{
	my $g = xlsx_path();
	my @rows = (['v'], ['6.10'], ['6.12'], ['1e5'], [42]);
	write_table(\@rows, $g, quiet => 1);	# warm up
	no_leaks_ok { write_table(\@rows, $g, quiet => 1) } 'writing string and number cells does not leak';
}

done_testing;
