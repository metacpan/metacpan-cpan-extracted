#!/usr/bin/env perl

# read_table() of an .xlsx: a row with no value, between the header and the
# last row with a value, is a row of undef.  Up to 0.3425 every such row was
# dropped, so a table write_table() wrote with a row of undef in it lost that
# row on the way back (t/read_write_table.roundtrip.t).
#
# The rule is pandas' (pandas/io/excel/_openpyxl.py, get_sheet_data(), which
# keeps every row up to the last one with data, and _base.py's TextParser
# call with skip_blank_lines=False, GH 39808).  Provenance of the cases, all
# in pandas 3.0.4's tests/io/excel/ under
# /home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages/pandas:
#   test_readers.py, test_one_col_noskip_blank_line (GH 39808):
#     one_col_blank_line.xlsx reads as numbers = [0.5, NaN, 1, 2]
#   test_openpyxl.py, test_read_with_empty_trailing_rows (GH 39181):
#     empty_trailing_rows.xlsx reads as Title / Unnamed: 1 / Unnamed: 2 =
#     [NaN, A, 1, 2, 3], [NaN, B, 4, 5, 6], [NaN, C, 7, 8, 9]
#   test_openpyxl.py, test_read_empty_with_blank_row (GH 39547):
#     empty_with_blank_row.xlsx, a sheet of one blank row, reads as an empty
#     DataFrame
#   test_readers.py, test_multiheader_two_blank_lines (GH 40442):
#     testmultiindex.xlsx's mi_column_empty_rows reads as [NaN, NaN] twice,
#     then [1, 3] and [2, 4]; read_table has one header row, so the case is
#     taken with one
# pandas' wheel does not ship those workbooks, so each is rebuilt here from
# the frame its test expects, in every way a writer records a blank row: left
# out of the XML (as Excel does), <row r="3"/>, <row r="3"></row> (as
# write_table() does), a row of formatted empty cells, and rows with no r= at
# all.  On 2026-11-20 pandas 3.0.4's read_excel() (openpyxl 3.1.5) read every
# rebuilt workbook as its test expects; t/read_table.xlsx.blank_rows.pandas.py
# repeats that check, and says how to run it.  This test never runs it.
#
# Where read_table() is not pandas, on purpose:
#   - the header is the first row with a value, as it always was: pandas makes
#     the sheet's first row the header even when it is blank, so a blank row 1
#     above "h" in row 3 reads there as a column "Unnamed: 0" holding NaN, "h"
#     and the data (checked with pandas 3.0.4 on the 'leading blank rows' case);
#   - output_type => 'hoh' still leaves a blank row out: it has no row name,
#     and read_table() refuses an undefined one, which would make every sheet
#     with a spacer row unreadable as a hash of hashes;
#   - rows are read in the order the XML gives them, and r= only says how many
#     blank rows lie before a row; a row whose r= is not past the row before
#     (malformed XML) is the next row, where openpyxl would move it.
# A blank row reads as a CSV record of empty fields reads, on every path.
#
# Run as
#   perl -Iblib/lib -Iblib/arch t/read_table.xlsx.blank_rows.pandas.t --write-fixtures DIR
# it writes each pandas case's workbook to DIR instead of testing; prove never
# passes arguments.

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use Stats::LikeR 'read_table';

no warnings 'once';	# $IO::Compress::Zip::ZipError is read, never assigned
my $have_zip = eval { require IO::Compress::Zip; 1 };

sub mk {
	my ($path, $body) = @_;
	my $ns  = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
	my $rns = 'http://schemas.openxmlformats.org/package/2006/relationships';
	my $ons = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
	my @part = (
		'[Content_Types].xml' => '<?xml version="1.0"?>'
			. '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
			. '<Default Extension="xml" ContentType="application/xml"/>'
			. '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
			. '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
			. '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
			. '</Types>',
		'_rels/.rels' => qq{<?xml version="1.0"?><Relationships xmlns="$rns">}
			. qq{<Relationship Id="rId1" Type="$ons/officeDocument" Target="xl/workbook.xml"/></Relationships>},
		'xl/workbook.xml' => qq{<?xml version="1.0"?><workbook xmlns="$ns" xmlns:r="$ons">}
			. qq{<sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets></workbook>},
		'xl/_rels/workbook.xml.rels' => qq{<?xml version="1.0"?><Relationships xmlns="$rns">}
			. qq{<Relationship Id="rId1" Type="$ons/worksheet" Target="worksheets/sheet1.xml"/></Relationships>},
		'xl/worksheets/sheet1.xml' => qq{<?xml version="1.0"?><worksheet xmlns="$ns"><sheetData>$body</sheetData></worksheet>},
	);
	my $z = IO::Compress::Zip->new($path, Name => $part[0])
		or die "cannot create $path: $IO::Compress::Zip::ZipError";
	$z->print($part[1]);
	for (my $i = 2; $i < @part; $i += 2) {
		$z->newStream(Name => $part[$i]) or die "newStream failed: $IO::Compress::Zip::ZipError";
		$z->print($part[$i + 1]);
	}
	$z->close;
	return $path;
}
sub str { qq{<c r="$_[0]" t="inlineStr"><is><t>$_[1]</t></is></c>} }
sub num { qq{<c r="$_[0]"><v>$_[1]</v></c>} }
sub row { my $r = shift; return qq{<row r="$r">} . join('', @_) . '</row>' }

# [label, <sheetData>, the aoa read_table gives, the rows pandas gives (header
# row left out, NaN as undef) or undef where pandas differs (see above)]
my $hdr  = row(1, str('A1', 'numbers'));
my $tail = row(4, num('A4', 1)) . row(5, num('A5', 2));
my @u3   = (undef) x 3;
my @case = (
	['GH 39808, the blank row left out', $hdr . row(2, num('A2', 0.5)) . $tail,
		[['numbers'], [0.5], [undef], [1], [2]], [[0.5], [undef], [1], [2]]],
	['GH 39808, <row r="3"/>', $hdr . row(2, num('A2', 0.5)) . '<row r="3"/>' . $tail,
		[['numbers'], [0.5], [undef], [1], [2]], [[0.5], [undef], [1], [2]]],
	['GH 39808, <row r="3"></row>', $hdr . row(2, num('A2', 0.5)) . row(3) . $tail,
		[['numbers'], [0.5], [undef], [1], [2]], [[0.5], [undef], [1], [2]]],
	['GH 39808, a row of formatted empty cells', $hdr . row(2, num('A2', 0.5)) . row(3, '<c r="A3" s="1"/>') . $tail,
		[['numbers'], [0.5], [undef], [1], [2]], [[0.5], [undef], [1], [2]]],
	['GH 39808, no r= anywhere',
		'<row><c t="inlineStr"><is><t>numbers</t></is></c></row><row><c><v>0.5</v></c></row>'
		. '<row></row><row><c><v>1</v></c></row><row><c><v>2</v></c></row>',
		[['numbers'], [0.5], [undef], [1], [2]], [[0.5], [undef], [1], [2]]],
	['GH 39181, a blank row under the title and formatted rows at the end',
		row(1, str('A1', 'Title')) . row(3, str('A3', 'A'), str('B3', 'B'), str('C3', 'C'))
		. join('', map { my $r = $_ + 3; row($r, num("A$r", $_), num("B$r", $_ + 3), num("C$r", $_ + 6)) } 1 .. 3)
		. join('', map { row($_, map { qq{<c r="$_" s="1"/>} } "A$_", "B$_", "C$_") } 7 .. 10),
		[['Title', '', ''], [@u3], ['A', 'B', 'C'], [1, 4, 7], [2, 5, 8], [3, 6, 9]],
		[[@u3], ['A', 'B', 'C'], [1, 4, 7], [2, 5, 8], [3, 6, 9]]],
	['GH 39547, a sheet of one blank row', '<row r="1"/>', [], []],
	['GH 39547, a sheet of one formatted empty cell', row(1, '<c r="A1" s="1"/>'), [], []],
	['GH 40442, two blank rows under the header',
		row(1, str('A1', 'a'), str('B1', 'b')) . row(4, num('A4', 1), num('B4', 3)) . row(5, num('A5', 2), num('B5', 4)),
		[['a', 'b'], [undef, undef], [undef, undef], [1, 3], [2, 4]],
		[[undef, undef], [undef, undef], [1, 3], [2, 4]]],
	['leading blank rows', '<row r="1"/>' . row(3, str('A3', 'h')) . row(4, num('A4', 1)),
		[['h'], [1]], undef],
);

if (@ARGV == 2 and $ARGV[0] eq '--write-fixtures') {
	die "IO::Compress::Zip (core) is needed\n" unless $have_zip;
	for my $i (0 .. $#case) {
		mk("$ARGV[1]/$i.xlsx", $case[$i][1]);
		open my $fh, '>', "$ARGV[1]/$i.label" or die "cannot write: $!";
		print {$fh} $case[$i][0];
		close $fh or die "cannot write: $!";
	}
	exit 0;
}

require Test::More;
Test::More->import;
plan(skip_all => 'IO::Compress::Zip (core) not available') unless $have_zip;

my $HAVE_LEAKTRACE = eval { require Test::LeakTrace; 1 } ? 1 : 0;

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;
sub xlsx { return mk("$dir/x" . $seq++ . '.xlsx', $_[0]) }

for my $c (@case) {
	my ($label, $body, $aoa, $pandas) = @$c;
	my $f = xlsx($body);
	my @warn;
	my $got = do { local $SIG{__WARN__} = sub { push @warn, $_[0] }; read_table($f, output_type => 'aoa') };
	is_deeply($got, $aoa, "$label: read as the table pandas reads") or diag(explain($got));
	is_deeply([ @$got[1 .. $#$got] ], $pandas, "$label: ... row for row") if $pandas && @$got;
	# GH 39181's two unnamed columns (pandas' "Unnamed: 1" and "Unnamed: 2")
	# are not warned of in an aoa, whose columns are positional
	is(scalar @warn, 0, "$label: no warning") or diag(@warn);
}

# A blank row reads as the CSV record of empty fields reads, on every path:
# each output type, a filter that keeps it and one that drops it, and with a
# column left out.  'hoh' is the exception (see above).
{
	my $f = xlsx(row(1, str('A1', 'id'), str('B1', 'v')) . row(2, str('A2', 'a'), num('B2', 1))
	           . row(4, str('A4', 'c'), num('B4', 3)));
	my $csv = "$dir/same.csv";
	open my $fh, '>', $csv or die "cannot write $csv: $!";
	print {$fh} "id,v\na,1\n,\nc,3\n";
	close $fh or die "cannot write $csv: $!";
	my @opt = (
		['aoh', output_type => 'aoh'], ['hoa', output_type => 'hoa'], ['aoa', output_type => 'aoa'],
		['a filter that keeps every row', filter => { v => sub { 1 } }],
		['a filter that drops empty rows', filter => { v => sub { defined $_ && length } }],
		['keep_cols', keep_cols => ['v']], ['drop_cols', drop_cols => ['id']],
	);
	for my $o (@opt) {
		my ($what, @args) = @$o;
		is_deeply(read_table($f, @args), read_table($csv, @args), "$what: the blank row reads as the CSV record ',' does");
	}
	is_deeply(read_table($f, output_type => 'aoh'),
		[ { id => 'a', v => 1 }, { id => undef, v => undef }, { id => 'c', v => 3 } ],
		'... which is a row of undef');
	is_deeply(read_table($f, output_type => 'hoh'), { a => { v => 1 }, c => { v => 3 } },
		"hoh: the blank row is left out, having no row name");
	is_deeply(read_table($f, output_type => 'hoh', filter => { v => sub { 1 } }),
		{ a => { v => 1 }, c => { v => 3 } }, '... through the filter path too');
	my $err = eval { read_table($csv, output_type => 'hoh'); 1 } ? '' : $@;
	like($err, qr/undefined row name/, "... where the CSV record ',' is refused");
}

# Malformed and missing r=: rows go in the order the XML gives them.
{
	my $f = xlsx(row(1, str('A1', 'h')) . row(3, num('A3', 1)) . row(2, num('A2', 2))
	           . row(9999999, num('A9', 3)) . row('x', num('A10', 4)));
	is_deeply(read_table($f, output_type => 'aoa'), [ ['h'], [undef], [1], [2], [3], [4] ],
		'an r= that is not past the row before, past row 1048576 or not a number is the next row');
	my $g = xlsx(row(1, str('A1', 'h')) . row(2, num('A2', 1)) . row(5, num('A5', 2)));
	is_deeply(read_table($g, output_type => 'aoa'), [ ['h'], [1], [undef], [undef], [2] ],
		'rows left out of the XML are rows of undef, one for each number skipped');
}

# Leaks, on the path that emits blank rows and when a filter dies on one,
# which leaves the row being read set aside (xlsx_ws_blank_rows() in LikeR.xs).
SKIP: {
	skip('Test::LeakTrace not installed', 3) unless $HAVE_LEAKTRACE;
	my $f = xlsx(row(1, str('A1', 'id'), str('B1', 'v')) . row(2, str('A2', 'a'), num('B2', 1))
	           . row(5, str('A5', 'c'), num('B5', 3)));
	# as in t/read_table.xlsx.xml.t: IO::Uncompress::Unzip leaks on some
	# perls, and a leak check around read_table would measure it
	Stats::LikeR::_unzip_member($f, 'xl/worksheets/sheet1.xml');
	my $unzip_leaks = Test::LeakTrace::leaked_count(
		sub { Stats::LikeR::_unzip_member($f, 'xl/worksheets/sheet1.xml') });
	skip("IO::Uncompress::Unzip leaks $unzip_leaks SV(s) per member on this perl", 3) if $unzip_leaks;
	my $dies = { v => sub { die "blank\n" unless defined $_ && length; 1 } };
	read_table($f) for 1 .. 2;	# warm: the first read loads modules and caches patterns
	eval { read_table($f, filter => $dies) } for 1 .. 2;
	Test::LeakTrace::no_leaks_ok(sub { read_table($f) }, 'no leaks: blank rows emitted');
	Test::LeakTrace::no_leaks_ok(sub { read_table($f, output_type => 'hoh') }, 'no leaks: blank rows left out of a hoh');
	Test::LeakTrace::no_leaks_ok(sub { eval { read_table($f, filter => $dies) } }, 'no leaks: a filter dies on a blank row');
}
{
	my $f = xlsx(row(1, str('A1', 'v')) . row(2, num('A2', 1)) . row(4, num('A4', 3)));
	my $err = eval { read_table($f, filter => { v => sub { die "blank\n" unless defined $_ && length; 1 } }); 1 } ? '' : $@;
	is($err, "blank\n", "a filter's die on a blank row reaches the caller");
}

done_testing();
