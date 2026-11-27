#!/usr/bin/env perl

# read_table() of an OpenDocument spreadsheet (.ods): what pandas' tests of its
# odf reader (t/read_table.ods.pandas.t) do not reach -- the format's repeated
# rows and cells, covered cells, paragraphs and their markup, value types, the
# namespace prefixes, the bounds on rows and columns, the sheet list, every
# read_table option on an .ods, the error paths, and leaks.
#
# The format is OASIS OpenDocument 1.2 part 1: section 9.1 for tables, rows and
# cells (table:number-rows-repeated, table:number-columns-repeated,
# table:covered-table-cell), section 6.1 for paragraph text (<text:s>,
# <text:tab>, <text:line-break>, and the white-space rule of 6.1.2), and section
# 19.385 for office:value-type.  calcext:value-type is LibreOffice's extension
# (namespace urn:org:documentfoundation:names:experimental:calc:xmlns:calcext:1.0),
# which marks a formula's error.  Each workbook here is written by mk() from
# the XML its case gives.

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use Test::More;
use Stats::LikeR 'read_table';

no warnings 'once';	# $IO::Compress::Zip::ZipError is read, never assigned
plan skip_all => 'IO::Compress::Zip (core) is not installed'
	unless eval { require IO::Compress::Zip; 1 };
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval { require Test::LeakTrace; Test::LeakTrace->import('no_leaks_ok'); 1 } ? 1 : 0;
}
my $dir = tempdir(CLEANUP => 1);

my %NS = (
	office  => 'urn:oasis:names:tc:opendocument:xmlns:office:1.0',
	table   => 'urn:oasis:names:tc:opendocument:xmlns:table:1.0',
	text    => 'urn:oasis:names:tc:opendocument:xmlns:text:1.0',
	calcext => 'urn:org:documentfoundation:names:experimental:calc:xmlns:calcext:1.0',
);
my $n = 0;
# An .ods whose content.xml holds $tables inside <office:spreadsheet>, with the
# conventional prefixes; or, with %opt{xml}, exactly that content.xml; or, with
# %opt{members}, those archive members and nothing else.
sub mk {
	my ($tables, %opt) = @_;
	my $path = "$dir/w" . $n++ . ($opt{ext} // '.ods');
	my $root = join ' ', map { qq{xmlns:$_="$NS{$_}"} } sort keys %NS;
	my @m = $opt{members} ? @{ $opt{members} } : (
		mimetype => 'application/vnd.oasis.opendocument.spreadsheet',
		'content.xml' => $opt{xml} // qq{<?xml version="1.0" encoding="UTF-8"?><office:document-content $root>}
			. qq{<office:body><office:spreadsheet>$tables</office:spreadsheet></office:body></office:document-content>},
	);
	my $z = IO::Compress::Zip->new($path, Name => $m[0])
		or die "cannot create $path: $IO::Compress::Zip::ZipError";
	$z->print($m[1]);
	for (my $i = 2; $i < @m; $i += 2) {
		$z->newStream(Name => $m[$i]) or die "newStream failed: $IO::Compress::Zip::ZipError";
		$z->print($m[$i + 1]);
	}
	$z->close;
	return $path;
}
sub tbl { my $name = shift; qq{<table:table table:name="$name">} . join('', @_) . '</table:table>' }
sub row { my $at = ref $_[0] ? ${ shift() } : ''; "<table:table-row$at>" . join('', @_) . '</table:table-row>' }
sub st { qq{<table:table-cell office:value-type="string"><text:p>$_[0]</text:p></table:table-cell>} }
sub nu { qq{<table:table-cell office:value-type="float" office:value="$_[0]"><text:p>$_[0]</text:p></table:table-cell>} }
sub em { '<table:table-cell/>' }
sub aoa { read_table(shift, output_type => 'aoa', @_) }
sub dies_like {
	my ($code, $re, $name) = @_;
	my $ok = !eval { $code->(); 1 };
	ok($ok && $@ =~ $re, $name) or diag $ok ? "died: $@" : 'lived';
}

my $hdr = row(st('a'), st('b'));

# repeated rows and cells
{
	my $f = mk(tbl('S', $hdr, row(\' table:number-rows-repeated="3"', nu(7), st('x')), row(nu(8), em())));
	is_deeply(aoa($f), [[qw(a b)], [7, 'x'], [7, 'x'], [7, 'x'], [8, undef]],
		'a row repeated three times is three rows');
	is_deeply(aoa($f, skiprows => [2]), [[qw(a b)], [7, 'x'], [7, 'x'], [8, undef]],
		'... each of which skiprows numbers on its own');
	is_deeply(read_table($f, output_type => 'hoa'), { a => [7, 7, 7, 8], b => [qw(x x x), undef] },
		'... as a hoa');
	is_deeply(aoa(mk(tbl('S', $hdr, row(qq{<table:table-cell table:number-columns-repeated="2" office:value-type="string"><text:p>y</text:p></table:table-cell>})))),
		[[qw(a b)], [qw(y y)]], 'a cell repeated across two columns fills both');
	is_deeply(aoa(mk(tbl('S', row(st('a'), qq{<table:table-cell table:number-columns-repeated="16383"/>}),
			row(\' table:number-rows-repeated="1048575"', '<table:table-cell table:number-columns-repeated="16384"/>')))),
		[['a']], 'LibreOffice\'s runs of empty cells and rows are not read');
	is_deeply(aoa(mk(tbl('S', $hdr, row(\' table:number-rows-repeated="2"', em()), row(nu(1), nu(2))))),
		[[qw(a b)], [undef, undef], [undef, undef], [1, 2]],
		'repeated empty rows between rows of values are rows of undef');
	is_deeply(aoa(mk(tbl('S', $hdr, row(nu(1), nu(2)), row(\' table:number-rows-repeated="2"', em())))),
		[[qw(a b)], [1, 2]], '... and after the last row with a value, nothing');
}

# covered cells, and what a cell's text is
{
	my $merged = row(qq{<table:table-cell office:value-type="string" table:number-columns-spanned="2"><text:p>m</text:p></table:table-cell>},
		'<table:covered-table-cell office:value-type="string"><text:p>hidden</text:p></table:covered-table-cell>');
	is_deeply(aoa(mk(tbl('S', $hdr, $merged))), [[qw(a b)], ['m', undef]],
		'a merged cell is in its first column, and a covered cell is empty');
	my %text = (
		'two paragraphs'       => ['<text:p>one</text:p><text:p>two</text:p>', "one\ntwo"],
		'an empty paragraph'   => ['<text:p>one</text:p><text:p/><text:p>three</text:p>', "one\n\nthree"],
		'a heading'            => ['<text:h>head</text:h>', 'head'],
		'tab and line break'   => ['<text:p>a<text:tab/>b<text:line-break/>c</text:p>', "a\tb\nc"],
		'text:s with c'        => ['<text:p>a<text:s text:c="3"/>b</text:p>', 'a   b'],
		'a huge text:c'        => ['<text:p><text:s text:c="99999999999"/></text:p>', ' ' x 32767],
		'collapsed white space' => [qq{<text:p>\n  a \t\n b  </text:p>}, 'a b '],
		'references'           => ['<text:p>&lt;&amp;&gt; &#233;&#x4E2D;&quot;</text:p>', "<&> \x{e9}\x{4e2d}\""],
		'a CDATA section'      => ['<text:p><![CDATA[<b> & ]]>x</text:p>', '<b> & x'],
		'a comment'            => ['<text:p>a<!-- <text:p>no</text:p> -->b</text:p>', 'ab'],
		'spans and links'      => ['<text:p><text:span>sp</text:span><text:a xlink:href="u">an</text:a></text:p>', 'span'],
		'an annotation'        => ['<office:annotation><text:p>note</text:p></office:annotation><text:p>v</text:p>', 'v'],
		'UTF-8 text'           => ["<text:p>\xc3\xa9t\xc3\xa9</text:p>", "\x{e9}t\x{e9}"],
	);
	for my $k (sort keys %text) {
		my ($xml, $want) = @{ $text{$k} };
		my $got = aoa(mk(tbl('S', row(st('h')), row(qq{<table:table-cell office:value-type="string">$xml</table:table-cell>}))));
		is_deeply($got, [['h'], [$want]], "text: $k");
	}
}

# value types
{
	my %v = (
		'percentage'           => ['office:value-type="percentage" office:value="0.25"', '<text:p>25%</text:p>', '0.25'],
		'currency'             => ['office:value-type="currency" office:currency="USD" office:value="-1.5"', '<text:p>-$1.50</text:p>', '-1.5'],
		'float without value'  => ['office:value-type="float"', '<text:p>3.5</text:p>', '3.5'],
		'boolean false'        => ['office:value-type="boolean" office:boolean-value="false"', '<text:p>FALSE</text:p>', 0],
		'boolean 1'            => ['office:value-type="boolean" office:boolean-value="1"', '<text:p>WAHR</text:p>', 1],
		'boolean, no value'    => ['office:value-type="boolean"', '<text:p>WAHR</text:p>', 'WAHR'],
		'date'                 => ['office:value-type="date" office:date-value="1999-12-31"', '<text:p>12/31/99</text:p>', '1999-12-31'],
		'time with no text'    => ['office:value-type="time" office:time-value="PT01H02M03S"', '', 'PT01H02M03S'],
		'string-value'         => ['office:value-type="string" office:string-value="a&amp;b"', '<text:p>shown</text:p>', 'a&b'],
		'void'                 => ['office:value-type="void"', '<text:p>x</text:p>', undef],
		'no value-type'        => ['', '<text:p>plain</text:p>', 'plain'],
		'an error (calcext)'   => ['office:value-type="string" office:string-value="" calcext:value-type="error" table:formula="of:=1/0"', '<text:p>#DIV/0!</text:p>', '#DIV/0!'],
		'an error (no calcext)' => ['office:value-type="float" office:value="0" table:formula="of:=1/0"', '<text:p>#DIV/0!</text:p>', '#DIV/0!'],
		'a formula, no error'  => ['office:value-type="float" office:value="3" table:formula="of:=1+2" calcext:value-type="float"', '<text:p>3</text:p>', 3],
		'"#N/A" typed, no formula' => ['office:value-type="string"', '<text:p>#N/A</text:p>', '#N/A'],
	);
	for my $k (sort keys %v) {
		my ($attr, $body, $want) = @{ $v{$k} };
		my $got = aoa(mk(tbl('S', row(st('h'), st('z')), row("<table:table-cell $attr>$body</table:table-cell>", st('z')))));
		is_deeply($got, [[qw(h z)], [$want, 'z']], "value: $k");
	}
	dies_like(sub { aoa(mk(tbl('S', row('<table:table-cell office:value-type="bogus"/>')))) },
		qr/^read_table: a cell of sheet 'S' in \S+ has the value-type 'bogus', which is not an OpenDocument one$/,
		'an unknown value-type dies, naming the sheet and the file');
}

# namespace prefixes are the file's, not the conventional ones
{
	my $xml = qq{<?xml version="1.0"?><o:document-content xmlns:o="$NS{office}" xmlns:t="$NS{table}" xmlns:x="$NS{text}" xmlns:table="urn:not-it">}
		. '<o:body><o:spreadsheet><t:table t:name="P"><t:table-row><t:table-cell o:value-type="string"><x:p>k</x:p></t:table-cell></t:table-row>'
		. '<t:table-row t:number-rows-repeated="2"><t:table-cell o:value-type="float" o:value="4"/></t:table-row>'
		. '<table:table-row><table:table-cell o:value-type="string"><x:p>not a row</x:p></table:table-cell></table:table-row>'
		. '</t:table></o:spreadsheet></o:body></o:document-content>';
	is_deeply(aoa(mk(undef, xml => $xml), sheet => 'P'), [['k'], [4], [4]],
		'prefixes bound on the root are read; "table:" bound to another namespace is not the table one');
}

# every read_table option on an .ods
{
	my $f = mk(tbl('S', row(st('id'), st('x'), st('y')), row(st('r1'), nu(1), nu('1.5')), row(st('r2'), nu(2), nu('2.5')),
		row(st('r3'), nu(3), st('NA'))));
	is_deeply(read_table($f, output_type => 'hoh'), { r1 => { x => 1, y => '1.5' }, r2 => { x => 2, y => '2.5' },
		r3 => { x => 3, y => 'NA' } }, 'hoh, keyed by the first column');
	is_deeply(read_table($f, na_strings => 'NA', drop_cols => 'x'),
		[{ id => 'r1', y => '1.5' }, { id => 'r2', y => '2.5' }, { id => 'r3', y => undef }], 'drop_cols and na_strings');
	is_deeply(read_table($f, keep_cols => qr/^[xy]$/, output_type => 'aoa'), [[qw(x y)], [1, '1.5'], [2, '2.5'], [3, 'NA']],
		'keep_cols, a regex');
	is_deeply(read_table($f, filter => { x => sub { $_ > 1 } }, output_type => 'aoa', skiprows => [3]),
		[[qw(id x y)], ['r2', 2, '2.5']], 'a filter with skiprows: r3, index 3, is left out before it is filtered');
	is_deeply(read_table($f, header => 0, col_names => [qw(p q r)], output_type => 'aoa', skiprows => 1),
		[[qw(p q r)], ['r1', 1, '1.5'], ['r2', 2, '2.5'], ['r3', 3, 'NA']], 'header => 0 and col_names');
	dies_like(sub { read_table($f, colClasses => { y => 'numeric' }) }, qr/NA/, 'colClasses numeric on text dies');
	my $c = read_table($f, colClasses => { y => 'character' }, output_type => 'aoa');
	is($c->[1][2], '1.5', 'colClasses character');
}

# sheets
{
	my $book = mk('<table:table><table:table-row>' . st('u1') . '</table:table-row></table:table>'
		. tbl('Sheet1', row(st('named'))) . '<table:table table:name="E"/>');
	is_deeply(read_table($book, output_type => 'aoa'),
		{ Sheet1 => [['named']], Sheet2 => [['u1']], E => [] },
		'a sheet with no name is keyed by the next free SheetN, and an empty table is []');
	dies_like(sub { read_table(mk(tbl('D', row(st('a'))) . tbl('D', row(st('b'))))) },
		qr/worksheet name 'D' is used by more than one sheet/, 'two sheets of one name die');
	my $nested = mk(tbl('Outer', row(st('h')), row('<table:table-cell office:value-type="string"><table:table table:name="Inner">'
		. row(st('in')) . '</table:table><text:p>out</text:p></table:table-cell>'), row(st('last'))));
	is_deeply(read_table($nested, output_type => 'aoa'), [['h'], ["in\nout"], ['last']],
		'a table nested in a cell is part of the cell, not a sheet, and does not end the row');
	is_deeply(aoa(mk(tbl('T', row(st('t'))), ext => '.ots')), [['t']], 'an .ots template is read as an .ods');
	is_deeply(read_table(mk(tbl('A', row(st('a')), row(st('skip')), row(nu(1))) . tbl('B', row(st('b')), row(st('skip')), row(nu(2)))),
			skiprows => [1], output_type => 'aoa'),
		{ A => [['a'], [1]], B => [['b'], [2]] }, 'skiprows applies to each sheet of a workbook read whole');
}

# bounds and damaged files
{
	dies_like(sub { aoa(mk(tbl('Big', row(\' table:number-rows-repeated="16777216"', em()), row(st('late'))))) },
		qr/^read_table: sheet 'Big' in \S+ has a value in row 16777217, past the 16777216 rows read_table reads$/,
		'a value past row 16,777,216 dies');
	dies_like(sub { aoa(mk(tbl('Big', row(st('h')), row(\' table:number-rows-repeated="16777216"', st('x'))))) },
		qr/has a value in row 16777217, past the 16777216 rows/, '... as does a repeated row that runs past it');
	is_deeply(aoa(mk(tbl('Big', row(st('h')), row(\' table:number-rows-repeated="4294967296"', em())))), [['h']],
		'... while empty rows past it are only counted, however many');
	dies_like(sub { aoa(mk(tbl('Wide', row('<table:table-cell table:number-columns-repeated="16384"/>', st('x'))))) },
		qr/^read_table: sheet 'Wide' in \S+ has a value past column 16384, the last read_table reads$/,
		'a value past column 16,384 dies');
	dies_like(sub { read_table(mk(undef, members => [mimetype => 'application/vnd.oasis.opendocument.spreadsheet'])) },
		qr/^read_table: '\S+' is not a readable \.ods spreadsheet: it has no content\.xml$/, 'no content.xml dies');
	dies_like(sub { read_table(mk('')) }, qr/has no sheet: its content\.xml holds no table:table/, 'no table dies');
	my $txt = "$dir/plain.ods";
	open my $fh, '>', $txt or die $!;
	print {$fh} "a,b\n1,2\n";
	close $fh or die $!;
	dies_like(sub { read_table($txt) }, qr/^read_table: '\Q$txt\E' is not a readable \.ods spreadsheet: /,
		'a text file named .ods is not read as text');
	dies_like(sub { read_table($txt, sheet => 'x', sep => ',') }, qr/not a readable \.ods/,
		'... and sheet is not refused on it');
}

SKIP: {
	skip 'Test::LeakTrace not installed', 5 unless $HAVE_LEAKTRACE;
	skip 'running under Devel::Cover', 5 if $INC{'Devel/Cover.pm'};
	my $f = mk(tbl('S', $hdr, row(\' table:number-rows-repeated="3"', nu(7), st('x')), row(nu(8), em())));
	my $bad = mk(tbl('S', $hdr, row('<table:table-cell office:value-type="bogus"/>')));
	my $big = mk(tbl('S', $hdr, row(\' table:number-rows-repeated="16777216"', nu(1))));
	local $SIG{__WARN__} = sub { };	# a hoh of repeated rows repeats row names
	for my $otype (qw(aoa hoh)) {
		no_leaks_ok { read_table($f, output_type => $otype) } "no leaks: repeated rows, $otype";
	}
	no_leaks_ok { read_table($f, skiprows => sub { $_[0] == 2 }) } 'no leaks: a skiprows sub on an .ods';
	no_leaks_ok { eval { read_table($bad) } } 'no leaks: an unknown value-type';
	no_leaks_ok { eval { read_table($big) } } 'no leaks: a repeated row past the last';
}

done_testing;
