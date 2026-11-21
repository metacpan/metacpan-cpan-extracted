#!/usr/bin/env perl

# read_table() of an .xlsx returns its text as characters: sheet names (the
# keys of the hash a workbook is read into), header names, and string cells,
# shared and inline alike.  Up to 0.3425 all of it was the raw UTF-8 bytes of
# the XML, so a workbook write_table() wrote from the keys "café" and
# "αβ" read back with keys of 5 and 4 bytes, and $book->{"\x{3b1}\x{3b2}"}
# found nothing.
#
# Provenance: the workbook of section 1 was written by write_table() and read
# with openpyxl 3.1.5 on 2026-11-19, which returns sheetnames ['café', 'αβ'],
# the cells [['n', 'α'], [1, 'α']] of the first and [['k'], ['naïve 漢字']] of
# the second, so those are the characters a reader should get; the other
# sections are this reader's own handling of the format, with no counterpart in
# openpyxl's or pandas' test suites (neither ships its tests in its wheel).
# Text that is not valid UTF-8, which Excel and LibreOffice never write, is
# returned as the bytes it holds, with no UTF-8 flag (section 5): that is a
# decision of this reader, since there are no characters to give.
#
# Fixtures are built here with core IO::Compress::Zip, as the sibling .xlsx
# tests build theirs.

require 5.010;
use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More;
use Test::Exception;
use File::Temp 'tempdir';
use Stats::LikeR qw(read_table write_table);

no warnings 'once';	# $IO::Compress::Zip::ZipError is read, never assigned
my $have_zip = eval { require IO::Compress::Zip; 1 };
plan skip_all => 'IO::Compress::Zip (core) not available' unless $have_zip;

my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	} ? 1 : 0;
}

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;
my $NS  = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
my $RNS = 'http://schemas.openxmlformats.org/package/2006/relationships';
my $ONS = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

sub zip_parts {
	my ($parts) = @_;
	my $path  = "$dir/w" . $seq++ . '.xlsx';
	my @names = sort keys %$parts;
	my $z = IO::Compress::Zip->new($path, Name => $names[0],
		Method => IO::Compress::Zip::ZIP_CM_DEFLATE())
		or die "Cannot create $path: $IO::Compress::Zip::ZipError";
	$z->print($parts->{$names[0]});
	for my $name (@names[1 .. $#names]) {
		$z->newStream(Name => $name, Method => IO::Compress::Zip::ZIP_CM_DEFLATE())
			or die "newStream failed: $IO::Compress::Zip::ZipError";
		$z->print($parts->{$name});
	}
	$z->close;
	return $path;
}

# A one-sheet workbook named $name (given as the bytes the XML holds), whose
# <sheetData> is $rows and whose shared strings are the <si> elements in $si.
# Everything is bytes: the XML is built from byte strings, as a file holds it.
sub mk {
	my ($rows, $si, $name) = @_;
	$name //= 'Data';
	my %p = (
		'xl/workbook.xml' => qq{<?xml version="1.0"?><workbook xmlns="$NS" xmlns:r="$ONS">}
			. qq{<sheets><sheet name="$name" sheetId="1" r:id="rId1"/></sheets></workbook>},
		'xl/_rels/workbook.xml.rels' => qq{<?xml version="1.0"?><Relationships xmlns="$RNS">}
			. qq{<Relationship Id="rId1" Type="$ONS/worksheet" Target="worksheets/sheet1.xml"/>}
			. (defined $si ? qq{<Relationship Id="rId2" Type="$ONS/sharedStrings" Target="sharedStrings.xml"/>} : '')
			. '</Relationships>',
		'xl/worksheets/sheet1.xml' => qq{<?xml version="1.0"?><worksheet xmlns="$NS"><sheetData>$rows</sheetData></worksheet>},
	);
	$p{'xl/sharedStrings.xml'} = qq{<?xml version="1.0"?><sst xmlns="$NS">$si</sst>} if defined $si;
	return zip_parts(\%p);
}
sub bytes { my ($s) = @_; utf8::encode($s); return $s }
sub is_chars { my ($s) = @_; return utf8::is_utf8($s) ? 1 : 0 }

# ---- 1. write_table's workbook reads back as the keys and cells it was given
{
	my $f = "$dir/book.xlsx";
	my %book = ("café" => [ { "α" => "α", n => 1 } ], "αβ" => [ { k => "naïve 漢字" } ]);
	write_table(\%book, $f, quiet => 1);
	my $back = read_table($f);
	is_deeply([ sort keys %$back ], [ sort keys %book ], 'a workbook of non-ASCII sheet names round-trips its keys');
	is(length((grep { /^caf/ } keys %$back)[0]), 4, '... "café" is 4 characters, not 5 bytes');
	is(length((grep { /^\x{3b1}/ } keys %$back)[0]), 2, '... and "αβ" 2, not 4');
	ok(exists $back->{"\x{3b1}\x{3b2}"}, '... so $book->{"\x{3b1}\x{3b2}"} finds its sheet');
	is_deeply($back, \%book, '... and every cell and column name is the characters written');
	is_deeply(read_table($f, sheet => 'αβ'), $book{'αβ'}, 'a sheet is asked for by its name as characters');
	is_deeply(read_table($f, sheet => bytes('αβ')), $book{'αβ'}, '... or as the UTF-8 bytes of it, as it had to be');
	is_deeply(read_table($f, sheet => 'café', output_type => 'aoa'), [ ['n', 'α'], [1, 'α'] ], '... in every output type');
	throws_ok { read_table($f, sheet => 'ω') } qr/^read_table: sheet 'ω' not found in .*\(have: 'café', 'αβ'\)$/, 'an unknown name is reported as characters';
}

# ---- 2. shared strings, inline strings and entities, in every output type
{
	my $rows = '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="inlineStr"><is><t>' . bytes('ключ') . '</t></is></c></row>'
	         . '<row r="2"><c r="A2" t="s"><v>1</v></c><c r="B2" t="inlineStr"><is><t>' . bytes('é') . '&#x4E2D;&#233;</t></is></c></row>'
	         . '<row r="3"><c r="A3" t="s"><v>2</v></c><c r="B3" t="str"><v>' . bytes('ü') . '</v></c></row>';
	my $si = '<si><t>' . bytes('名前') . '</t></si><si><t>' . bytes('naïve') . '</t></si>'
	       . '<si><r><t>' . bytes('Gr') . '</t></r><r><t>' . bytes('öße') . '</t></r></si>';
	my $f = mk($rows, $si);
	my @aoa = (["名前", "ключ"], ["naïve", "é中é"], ["Größe", "ü"]);
	is_deeply(read_table($f, output_type => 'aoa'), \@aoa, 'shared, inline and formula-string cells are characters (aoa)');
	is_deeply(read_table($f), [ { "名前" => "naïve", "ключ" => "é中é" }, { "名前" => "Größe", "ключ" => "ü" } ], '... and so are the keys of an aoh');
	is_deeply(read_table($f, output_type => 'hoa'), { "名前" => ["naïve", "Größe"], "ключ" => ["é中é", "ü"] }, '... of a hoa');
	is_deeply(read_table($f, output_type => 'hoh', row_names => 'ключ'),
		{ "é中é" => { "名前" => "naïve" }, "ü" => { "名前" => "Größe" } }, '... and the row names of a hoh, named by characters');
	is_deeply(read_table($f, output_type => 'hoh', row_names => bytes('ключ')),
		{ "é中é" => { "名前" => "naïve" }, "ü" => { "名前" => "Größe" } }, '... or by the bytes of the name');
	is_deeply(read_table($f, filter => { 0 => sub { 1 } }), read_table($f), 'the callback path (a filter) agrees with the fast path');
	is_deeply(read_table($f, filter => { "名前" => sub { $_ eq 'Größe' } }), [ { "名前" => "Größe", "ключ" => "ü" } ],
		'a filter on a column named by characters sees characters');
	is_deeply(read_table($f, output_type => 'aoa', keep_cols => ['名前']), [ ['名前'], ['naïve'], ['Größe'] ], 'keep_cols by characters');
	is_deeply(read_table($f, output_type => 'aoa', keep_cols => [bytes('名前')]), [ ['名前'], ['naïve'], ['Größe'] ], '... and by bytes');
	is_deeply(read_table($f, output_type => 'aoa', drop_cols => [qr/^名/]), [ ['ключ'], ['é中é'], ['ü'] ], 'drop_cols by a pattern');
	is_deeply(read_table($f, colClasses => { "名前" => 'character' }), read_table($f), 'colClasses names a column by characters');

	# keep_cols by a name that is a copy of a key: on perl 5.32 utf8::encode()
	# of such a copy kept it looking up as the key, so the name was never
	# marked found, and the warning below then died (0.3426 before release)
	my %by_key = ("名前" => 1);
	is_deeply(read_table($f, output_type => 'aoa', keep_cols => [ keys %by_key ]), [ ['名前'], ['naïve'], ['Größe'] ],
		'keep_cols by a hash key of characters');

	# A warning that names a column of characters is a warning, not a die:
	# perl 5.18 and later warn "Wide character in warn" of such a message, which
	# the module's FATAL warnings made fatal. It comes as the UTF-8 bytes perl
	# would have printed.
	{
		my @w;
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		my $got = read_table($f, output_type => 'aoa', keep_cols => ['名前', 'ωμέγα']);
		is_deeply($got, [ ['名前'], ['naïve'], ['Größe'] ], 'a keep_cols name that is no column warns and keeps the rest');
		is(scalar(@w), 1, '... with one warning');
		like($w[0] // '', qr/^read_table: not all columns named in 'keep_cols' exist in .*: '\Q@{[ bytes('ωμέγα') ]}\E'$/,
			'... that names it in UTF-8 bytes');
		ok(!is_chars($w[0] // ''), '... and is a byte string');
		@w = ();
		my $dup = mk('<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>0</v></c></row>'
		           . '<row r="2"><c r="A2"><v>1</v></c><c r="B2"><v>2</v></c></row>', '<si><t>' . bytes('名前') . '</t></si>');
		is_deeply(read_table($dup), [ { "名前" => 2 } ], 'a repeated column name of characters: the later value wins');
		like($w[0] // '', qr/^read_table: duplicate column name\(s\) in .*\Q@{[ bytes('名前') ]}\E/,
			'... and the warning names it in UTF-8 bytes');
	}

	# the strings are plain characters: ASCII ones carry no flag, and the
	# length is of characters
	my $aoa = read_table($f, output_type => 'aoa');
	is(length($aoa->[2][0]), 5, '"Größe" is 5 characters');
	ok(!is_chars(read_table(mk('<row r="1"><c r="A1" t="inlineStr"><is><t>abc</t></is></c></row>'), output_type => 'aoa')->[0][0]),
		'an ASCII cell is not flagged');
}

# ---- 3. na_strings, with a token of characters or of bytes
{
	my $rows = '<row r="1"><c r="A1" t="inlineStr"><is><t>a</t></is></c><c r="B1" t="inlineStr"><is><t>b</t></is></c></row>'
	         . '<row r="2"><c r="A2" t="s"><v>0</v></c><c r="B2" t="inlineStr"><is><t>' . bytes('—') . '</t></is></c></row>'
	         . '<row r="3"><c r="A3" t="s"><v>1</v></c><c r="B3" t="s"><v>0</v></c></row>';
	my $f = mk($rows, '<si><t>' . bytes('—') . '</t></si><si><t>' . bytes('é') . '</t></si>');
	my $want = [ { a => undef, b => undef }, { a => 'é', b => undef } ];
	is_deeply(read_table($f, na_strings => '—'), [ { a => undef, b => undef }, { a => 'é', b => undef } ], 'na_strings given as characters');
	is_deeply(read_table($f, na_strings => bytes('—')), $want, '... and as bytes');
	is_deeply(read_table($f, na_strings => ['—', 'x']), $want, '... in a list');
	is_deeply(read_table($f, na_strings => 'é'), [ { a => '—', b => '—' }, { a => undef, b => '—' } ], 'a Latin-1 token matches a cell, shared or not');
	is_deeply(read_table($f, na_strings => '—', filter => { a => sub { 1 } }), $want, '... also through a filter');
}

# ---- 4. the names of a worksheet
{
	my $f = mk('<row r="1"><c r="A1" t="inlineStr"><is><t>x</t></is></c></row><row r="2"><c r="A2"><v>1</v></c></row>', undef,
		bytes('Données') . '&amp;&#x4E2D;');
	is_deeply([ Stats::LikeR::_xlsx_sheets($f)->[0]{name} ], ["Données&中"], 'a sheet name has its references decoded, and is characters');
	is_deeply(read_table($f, sheet => "Données&中"), [ { x => 1 } ], '... and is found by it');
}

# ---- 5. text that is not valid UTF-8 is returned as the bytes it holds
{
	my $bad = "caf\xe9";	# Latin-1, not UTF-8
	my $rows = '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="inlineStr"><is><t>' . $bad . '</t></is></c></row>'
	         . '<row r="2"><c r="A2" t="s"><v>1</v></c><c r="B2" t="inlineStr"><is><t>' . "\xc3" . '</t></is></c></row>'
	         . '<row r="3"><c r="A3" t="s"><v>2</v></c><c r="B3" t="inlineStr"><is><t>' . bytes('ok é') . '</t></is></c></row>';
	my $f = mk($rows, '<si><t>' . "\xff\xfe" . '</t></si><si><t>' . bytes('é') . "\x80" . '</t></si><si><t>' . bytes('good é') . '</t></si>');
	my $aoa;
	lives_ok { $aoa = read_table($f, output_type => 'aoa') } 'invalid UTF-8 does not die';
	is_deeply($aoa, [ ["\xff\xfe", $bad], [bytes('é') . "\x80", "\xc3"], ['good é', 'ok é'] ], '... and comes back as bytes');
	ok(!is_chars($aoa->[0][0]) && !is_chars($aoa->[0][1]) && !is_chars($aoa->[1][1]), '... with no UTF-8 flag');
	is(length($aoa->[2][0]) . length($aoa->[2][1]), '64', '... while valid text beside it is still characters');
	is(length($aoa->[1][0]), 3, 'a shared string with a stray byte is 3 bytes');
	lives_ok { read_table($f) } '... in every output type';
	lives_ok { read_table($f, output_type => 'hoh') } '... even as a hoh';
	my $g = mk('<row r="1"><c r="A1" t="inlineStr"><is><t>x</t></is></c></row><row r="2"><c r="A2"><v>1</v></c></row>', undef, "caf\xe9");
	is_deeply([ Stats::LikeR::_xlsx_sheets($g)->[0]{name} ], ["caf\xe9"], 'a sheet name that is not UTF-8 is its bytes');
	is(length(Stats::LikeR::_xlsx_sheets($g)->[0]{name}), 4, '... 4 of them');
}

# ---- 6. a delimited file is untouched: its fields are still the bytes it holds
{
	my $f = "$dir/t.csv";
	open my $fh, '>:raw', $f or die $!;
	print $fh bytes("é,b\nαβ,x\n");
	close $fh;
	my $aoa = read_table($f, output_type => 'aoa');
	is_deeply($aoa, [ [bytes('é'), 'b'], [bytes('αβ'), 'x'] ], 'a CSV is still read as UTF-8 bytes');
	ok(!is_chars($aoa->[1][0]), '... with no UTF-8 flag');
	is_deeply(read_table($f, na_strings => 'αβ'), [ { bytes('é') => undef, b => 'x' } ], '... and an na_strings token is still compared as bytes');
}

# ---- 7. no leaks
SKIP: {
	skip 'Test::LeakTrace not available', 4 unless $HAVE_LEAKTRACE;
	my $f = mk('<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="inlineStr"><is><t>' . bytes('é') . '</t></is></c></row>'
	         . '<row r="2"><c r="A2" t="s"><v>1</v></c><c r="B2" t="inlineStr"><is><t>' . "\xff" . '</t></is></c></row>',
		'<si><t>' . bytes('名') . '</t></si><si><t>' . bytes('ü') . '</t></si>', bytes('Données'));
	my $w = "$dir/leak.xlsx";
	write_table({ "café" => [ { "α" => "β" } ], "αβ" => [ { k => 'v' } ] }, $w, quiet => 1);
	my $na = '—';
	read_table($f); read_table($w); read_table($f, na_strings => $na);	# warm up
	no_leaks_ok { my $x = read_table($f) } 'reading non-ASCII and invalid text does not leak';
	no_leaks_ok { my $x = read_table($f, output_type => 'hoh') } '... as a hoh';
	no_leaks_ok { my $x = read_table($w) } '... nor does a workbook of non-ASCII sheet names';
	no_leaks_ok { my $x = read_table($f, na_strings => $na) } '... nor does na_strings with a non-ASCII token';
}

done_testing;
