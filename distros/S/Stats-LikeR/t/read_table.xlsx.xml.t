#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use File::Temp 'tempdir';
use Stats::LikeR 'read_table';

# How read_table's .xlsx reader takes the XML of a workbook's parts: the things
# an XML processor does that a tag-by-tag scanner has to do for itself, and the
# parts of the package it has to find. Each case was a wrong answer up to
# 0.3213, found by reading the reader and confirmed against 0.3213's build:
#
#   * a phonetic run, <rPh>, in a shared string or an inline string: its <t> is
#     the furigana Japanese Excel records for text typed through the IME, and
#     was concatenated into the cell (漢字 read as 漢字カンジ)
#   * the shared-string part found through workbook.xml.rels by its
#     relationship Type, not by the name Excel happens to give it: a workbook
#     storing it as xl/SharedStrings.xml read every string cell as empty
#   * single-quoted attributes in workbook.xml and its rels, which XML allows
#     and which lost every sheet name; a '>' inside an attribute value; and a
#     commented-out <sheet>
#   * .xlsm, .xltx and .xltm, read as text before (an "Alignment error")
#   * the "SheetN" key an unnamed sheet gets, which could replace a sheet
#     really named that in the hash a whole workbook is read into
#   * a numeric character reference to something that is not an XML Char:
#     NUL, a surrogate, U+FFFE/U+FFFF, or past U+10FFFF (which came back as
#     four to six bytes of perl's extended UTF-8)
#   * comments, read as data when they held a <row>; CDATA sections, returned
#     with "<![CDATA[" still on; and line ends, where CR LF in a cell came back
#     as both bytes
#   * Excel's _xHHHH_ escape for characters XML cannot hold, returned as
#     written, so a cell with a control character in it never read back
#
# What each case should read as is what an XML processor makes of the part,
# and what openpyxl 3.1.5 (through expat) returns for the same workbook. That
# was checked on 2026-10-05 by keeping the workbooks these tests build, adding
# the [Content_Types].xml openpyxl insists on, and reading each with
# openpyxl.load_workbook(): every value below agrees with it, with three kinds
# of exception, each this reader's own answer and marked where it is tested,
# and one section, 9, checked against LibreOffice instead (it says why) --
#   - openpyxl refuses outright what XML does not allow: a reference to a
#     non-Char, an unclosed CDATA section, a <sheet> with no name, an <rPh>
#     without its sb= and eb=. This reader leaves the reference in the text,
#     reads on to the end of the part, and names the sheet "SheetN".
#   - openpyxl places rows by their r= and pads a gap with an empty row, and
#     keeps a trailing column that holds only empty cells; this reader drops
#     both, as it always has (README.md, "Excel (.xlsx) files").
# Where openpyxl's rules are written down:
#   - openpyxl/cell/text.py, Text.content: a string's text is its <t> and its
#     <r><t> runs; <rPh> is parsed into Text.rPh and is not part of it
#   - openpyxl/reader/excel.py, SUPPORTED_FORMATS = ('.xlsx', '.xlsm', '.xltx',
#     '.xltm'); and ExcelReader.read_strings(), which finds the shared-string
#     part by its content type rather than its name (this reader goes by the
#     relationship, the other half of the same package bookkeeping)
#   - expat does XML 1.0 (5th edition) section 2.11's end-of-line handling and
#     section 2.2's Char production, unwraps CDATA and drops comments
# The cases themselves are this reader's own: neither openpyxl's nor pandas'
# test suites are shipped in their wheels, and pandas' read_excel tests go by
# binary fixtures (test1.xlsm and the rest) that are not available here.
#
# Fixtures are built here with core IO::Compress::Zip, as the sibling .xlsx
# tests build theirs, so the test needs no binary fixture and no CPAN reader.

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

# Zip %$parts (member name => content) into a new file with suffix $ext, as one
# archive with one central directory -- the layout every writer produces, and
# the one _unzip_member_fast() reads rather than handing on to
# IO::Uncompress::Unzip.
sub zip_parts {
	my ($parts, $ext) = @_;
	my $path  = "$dir/w" . $seq++ . ($ext // '.xlsx');
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

# A worksheet part holding $rows, the inside of its <sheetData>.
sub ws { qq{<?xml version="1.0"?><worksheet xmlns="$NS"><sheetData>$_[0]</sheetData></worksheet>} }

# A shared-string part holding the <si> elements in $si.
sub sst { qq{<?xml version="1.0"?><sst xmlns="$NS">$_[0]</sst>} }

# A one-sheet workbook: the worksheet's <sheetData> body, and optionally the
# <si> elements of its shared strings, stored at xl/sharedStrings.xml with the
# relationship Excel writes for it. %o overrides: 'ext' the file suffix,
# 'sst_member' and 'sst_target' where the shared strings live and how the rels
# point there (sst_target undef for no relationship at all).
sub mk {
	my ($rows, $si, %o) = @_;
	my $member = $o{sst_member} // 'xl/sharedStrings.xml';
	my $target = exists $o{sst_target} ? $o{sst_target} : 'sharedStrings.xml';
	my %p = (
		'xl/workbook.xml' => qq{<?xml version="1.0"?><workbook xmlns="$NS" xmlns:r="$ONS">}
			. q{<sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets></workbook>},
		'xl/_rels/workbook.xml.rels' => qq{<?xml version="1.0"?><Relationships xmlns="$RNS">}
			. qq{<Relationship Id="rId1" Type="$ONS/worksheet" Target="worksheets/sheet1.xml"/>}
			. (defined $si && defined $target
				? qq{<Relationship Id="rId2" Type="$ONS/sharedStrings" Target="$target"/>} : '')
			. '</Relationships>',
		'xl/worksheets/sheet1.xml' => ws($rows),
	);
	$p{$member} = sst($si) if defined $si;
	return zip_parts(\%p, $o{ext});
}

# A workbook from its workbook.xml and rels as written, with a worksheet per
# entry of $sheets (sheetN.xml, N from 1) holding a single cell A1 = its value.
sub mk_book {
	my ($wb, $rels, @vals) = @_;
	my %p = (
		'xl/workbook.xml'            => $wb,
		'xl/_rels/workbook.xml.rels' => $rels,
	);
	$p{'xl/worksheets/sheet' . ($_ + 1) . '.xml'} = ws(qq{<row r="1"><c r="A1"><v>$vals[$_]</v></c></row>})
		for 0 .. $#vals;
	return zip_parts(\%p);
}

my $h = '<row r="1"><c r="A1" t="inlineStr"><is><t>h</t></is></c></row>';	# a header "h"

# 1. Phonetic runs. Japanese Excel writes one for every string typed through
# the IME; it annotates the text and is no part of it.
{
	my $f = mk('<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c></row>'
	         . '<row r="2"><c r="A2" t="s"><v>2</v></c>'
	         .            '<c r="B2" t="inlineStr"><is><t>a</t><rPh sb="0" eb="1"><t>X</t></rPh>'
	         .            '<r><t>b</t></r><phoneticPr fontId="1"/></is></c></row>',
		'<si><t>k</t></si><si><t>i</t></si>'
		. "<si><t>\xe6\xbc\xa2\xe5\xad\x97</t><rPh sb=\"0\" eb=\"2\"><t>\xe3\x82\xab\xe3\x83\xb3\xe3\x82\xb8</t></rPh>"
		. '<phoneticPr fontId="1" type="noConversion"/></si>');
	is_deeply( read_table($f), [ { k => "\xe6\xbc\xa2\xe5\xad\x97", i => 'ab' } ],
		'<rPh> is left out of a shared string and of an inline string' );
	is_deeply( read_table($f, filter => { 0 => sub { 1 } }),
		[ { k => "\xe6\xbc\xa2\xe5\xad\x97", i => 'ab' } ], '... and through the callback path' );

	# A cell whose only text is phonetic is empty, so it does not widen the
	# table -- pass 1 and pass 2 have to read it alike, or a row comes out
	# the wrong width.
	my $g = mk($h . '<row r="2"><c r="A2"><v>1</v></c>'
	         . '<c r="B2" t="inlineStr"><is><rPh sb="0" eb="1"><t>X</t></rPh></is></c>'
	         . '<c r="C2" t="s"><v>0</v></c></row>',
		'<si><rPh sb="0" eb="1"><t>Y</t></rPh></si>');
	is_deeply( read_table($g, 'output_type' => 'aoa'), [ ['h'], [1] ],
		'a cell with nothing but a phonetic run is empty, and adds no column' );
	# a self-closing <rPh/> and an unclosed one at the end of the string
	my $u = mk($h . '<row r="2"><c r="A2" t="inlineStr"><is><t>p</t><rPh/><t>q</t></is></c></row>'
	          . '<row r="3"><c r="A3" t="inlineStr"><is><t>r</t><rPh><t>s</t></is></c></row>');
	is_deeply( read_table($u, 'output_type' => 'aoa'), [ ['h'], ['pq'], ['r'] ],
		'a self-closing <rPh/>, and an unclosed <rPh> that runs to the end of the string' );
}

# 2. The shared-string part, wherever the relationships put it.
{
	my $rows = '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c></row>'
	         . '<row r="2"><c r="A2" t="s"><v>2</v></c><c r="B2"><v>5</v></c></row>';
	my $si   = '<si><t>a</t></si><si><t>b</t></si><si><t>val</t></si>';
	my $want = [ { a => 'val', b => 5 } ];
	is_deeply( read_table(mk($rows, $si)), $want, 'the shared strings where Excel puts them' );
	is_deeply( read_table(mk($rows, $si, sst_member => 'xl/SharedStrings.xml',
		sst_target => 'SharedStrings.xml')), $want,
		'... at xl/SharedStrings.xml, named by the relationship' );
	is_deeply( read_table(mk($rows, $si, sst_member => 'xl/strings/s1.xml',
		sst_target => '/xl/strings/s1.xml')), $want,
		'... at an absolute target, from the package root' );
	is_deeply( read_table(mk($rows, $si, sst_member => 'xl/strings/s1.xml',
		sst_target => './strings/../strings/s1.xml')), $want,
		'... at a target with "." and ".." segments' );
	is_deeply( read_table(mk($rows, $si, sst_target => undef)), $want,
		'... and at xl/sharedStrings.xml when no relationship names the part' );
	# A multi-sheet workbook reads the part once for every sheet, by the same rule
	my %p = (
		'xl/workbook.xml' => qq{<workbook xmlns="$NS" xmlns:r="$ONS"><sheets>}
			. '<sheet name="One" sheetId="1" r:id="rId1"/><sheet name="Two" sheetId="2" r:id="rId2"/>'
			. '</sheets></workbook>',
		'xl/_rels/workbook.xml.rels' => qq{<Relationships xmlns="$RNS">}
			. qq{<Relationship Id="rId1" Type="$ONS/worksheet" Target="worksheets/sheet1.xml"/>}
			. qq{<Relationship Id="rId2" Type="$ONS/worksheet" Target="worksheets/sheet2.xml"/>}
			. qq{<Relationship Id="rId3" Type="$ONS/sharedStrings" Target="SST.xml"/>}
			. '</Relationships>',
		'xl/worksheets/sheet1.xml' => ws($rows),
		'xl/worksheets/sheet2.xml' => ws($rows),
		'xl/SST.xml'               => sst($si),
	);
	is_deeply( read_table(zip_parts(\%p)), { One => $want, Two => $want },
		'... and for every sheet of a workbook read whole' );
	is_deeply( Stats::LikeR::_xlsx_rels(zip_parts(\%p))->{sst}, 'xl/SST.xml',
		'_xlsx_rels names the shared-string part by its relationship Type' );
	is( Stats::LikeR::_xlsx_part_path($_->[0]), $_->[1], "_xlsx_part_path('$_->[0]')" ) for
		[ 'worksheets/sheet1.xml', 'xl/worksheets/sheet1.xml' ],
		[ '/xl/worksheets/sheet1.xml', 'xl/worksheets/sheet1.xml' ],
		[ 'xl/worksheets/sheet1.xml', 'xl/worksheets/sheet1.xml' ],
		[ '../xl/worksheets/sheet1.xml', 'xl/worksheets/sheet1.xml' ],
		[ './worksheets//./sheet1.xml', 'xl/worksheets/sheet1.xml' ];
}

# 3. Attributes as XML allows them to be written.
{
	my $wb = qq{<workbook xmlns="$NS" xmlns:r="$ONS"><sheets>}
	       . q{<sheet name='Second' sheetId='2' r:id='rId2'/>}
	       . q{<sheet name = 'First' sheetId = '1' r:id = 'rId1' />}
	       . '</sheets></workbook>';
	my $rels = qq{<Relationships xmlns='$RNS'>}
	         . qq{<Relationship Id='rId1' Type='$ONS/worksheet' Target='worksheets/sheet1.xml'/>}
	         . qq{<Relationship Target='worksheets/sheet2.xml' Type='$ONS/worksheet' Id='rId2'/>}
	         . '</Relationships>';
	is_deeply( read_table(mk_book($wb, $rels, 1, 2), 'output_type' => 'aoa'),
		{ First => [ [1] ], Second => [ [2] ] },
		'single-quoted attributes, blanks around "=", and any attribute order' );

	# '>' is legal unescaped in an attribute value, and a comment is not a sheet
	my $wb2 = qq{<workbook xmlns="$NS" xmlns:r="$ONS"><sheets>}
	        . '<!-- <sheet name="Old" sheetId="9" r:id="rId9"/> -->'
	        . '<sheet name="a>b" sheetId="1" r:id="rId1"/>'
	        . q{<sheet name="it's" sheetId="2" r:id="rId2"/>}
	        . '</sheets></workbook>';
	my $rels2 = qq{<Relationships xmlns="$RNS">}
	          . qq{<Relationship Id="rId1" Type="$ONS/worksheet" Target="worksheets/sheet1.xml"/>}
	          . qq{<Relationship Id="rId2" Type="$ONS/worksheet" Target="worksheets/sheet2.xml"/>}
	          . qq{<!-- <Relationship Id="rId9" Type="$ONS/worksheet" Target="worksheets/sheet3.xml"/> -->}
	          . '</Relationships>';
	is_deeply( read_table(mk_book($wb2, $rels2, 1, 2, 3), 'output_type' => 'aoa'),
		{ 'a>b' => [ [1] ], "it's" => [ [2] ] },
		"a '>' and a \"'\" inside a value, and a commented-out <sheet> and <Relationship>" );
}

# 4. The other three Excel workbook suffixes, as openpyxl's SUPPORTED_FORMATS
# lists them, in either case.
{
	my $rows = '<row r="1"><c r="A1" t="inlineStr"><is><t>a</t></is></c></row>'
	         . '<row r="2"><c r="A2"><v>1</v></c></row>';
	for my $ext (qw(.xlsm .xltx .xltm .XLSM .Xltx)) {
		my $f = mk($rows, undef, ext => $ext);
		is_deeply( read_table($f), [ { a => 1 } ], "a workbook named *$ext" );
		is_deeply( read_table($f, sheet => 'Data'), [ { a => 1 } ], "... and 'sheet' on it" );
	}
}

# 5. A sheet with no name is keyed "SheetN", N its position or the next N that
# no sheet is named.
{
	my $wb = qq{<workbook xmlns="$NS" xmlns:r="$ONS"><sheets>}
	       . '<sheet sheetId="1" r:id="rId1"/>'
	       . '<sheet name="Sheet1" sheetId="2" r:id="rId2"/>'
	       . '<sheet sheetId="3" r:id="rId3"/>'
	       . '<sheet name="Sheet4" sheetId="4" r:id="rId4"/>'
	       . '</sheets></workbook>';
	my $rels = qq{<Relationships xmlns="$RNS">}
	         . join('', map { qq{<Relationship Id="rId$_" Type="$ONS/worksheet" Target="worksheets/sheet$_.xml"/>} } 1 .. 4)
	         . '</Relationships>';
	is_deeply( read_table(mk_book($wb, $rels, 1 .. 4), 'output_type' => 'aoa'),
		{ Sheet1 => [ [2] ], Sheet2 => [ [1] ], Sheet3 => [ [3] ], Sheet4 => [ [4] ] },
		'an unnamed sheet never takes the key of a sheet that has the name' );
}

# 6. Numeric character references: a Char is decoded to UTF-8 bytes, and
# anything else is left in the text as it was written.
{
	my @ok = (
		[ '&#x9;', "\t" ], [ '&#xA;', "\n" ], [ '&#xD;', "\r" ], [ '&#x20;', ' ' ],
		[ '&#xD7FF;', "\xed\x9f\xbf" ], [ '&#xE000;', "\xee\x80\x80" ],
		[ '&#xFFFD;', "\xef\xbf\xbd" ], [ '&#x10000;', "\xf0\x90\x80\x80" ],
		[ '&#x10FFFF;', "\xf4\x8f\xbf\xbf" ], [ '&#1114111;', "\xf4\x8f\xbf\xbf" ],
	);
	my @bad = ('&#0;', '&#x0;', '&#x1F;', '&#8;', '&#xD800;', '&#xDFFF;', '&#xFFFE;',
		'&#xFFFF;', '&#x110000;', '&#1114112;', '&#x7FFFFFFF;', '&#xFFFFFFFFFFFFFFFFFF;');
	my $rows_of = sub {
		my $r = 1;
		return $h . join '', map {
			$r++;
			qq{<row r="$r"><c r="A$r" t="inlineStr"><is><t>[$_]</t></is></c></row>}
		} @_;
	};
	is_deeply( read_table(mk($rows_of->(map { $_->[0] } @ok))),
		[ map { { h => "[$_->[1]]" } } @ok ], 'each reference to an XML Char is decoded' );
	is_deeply( read_table(mk($rows_of->(@bad))), [ map { { h => "[$_]" } } @bad ],
		'... and every reference to anything else is left in the text verbatim' );
	is( Stats::LikeR::_xml_unescape('a&#0;b&#x10FFFF;c&#x110000;'),
		"a&#0;b\xf4\x8f\xbf\xbfc&#x110000;", '... and in a sheet name, through the same decoder' );
}

# 7. Comments, CDATA and line ends.
{
	my $f = mk($h
	         . '<!-- <row r="2"><c r="A2"><v>99</v></c></row> -->'
	         . '<row r="3"><c r="A3"><v>1<!-- 2 -->3</v></c></row>'
	         . '<row r="4"><c r="A4" t="inlineStr"><is><t><![CDATA[a&amp;b<c></t>]]></t></is></c></row>'
	         . '<row r="5"><c r="A5"><v><![CDATA[4]]><!--x-->5</v></c></row>'
	         . '<row r="6"><c r="A6" t="s"><v>1</v></c></row>'
	         . '<row r="7"><c r="A7" t="inlineStr"><is><t><![CDATA[]]>x<![CDATA[y]]></t></is></c></row>',
		'<si><t>s0</t></si><!-- <si><t>gone</t></si> --><si><t><![CDATA[s&1]]></t></si>');
	is_deeply( read_table($f, 'output_type' => 'aoa'),
		[ ['h'], [13], ['a&amp;b<c></t>'], [45], ['s&1'], ['xy'] ],
		'comments are dropped, a commented-out <row> or <si> included, and CDATA is its literal text' );
	# An unclosed CDATA section runs to the end of the part, as an unclosed
	# element does, and its text is all there is left. Not XML, so this is
	# this reader's answer alone: expat refuses the part.
	my $u = mk($h . '<row r="2"><c r="A2" t="inlineStr"><is><t><![CDATA[open</t></is></c></row>'
	         . '<row r="3"><c r="A3"><v>1</v></c></row>');
	is_deeply( read_table($u, 'output_type' => 'aoa'),
		[ ['h'], ['open</t></is></c></row><row r="3"><c r="A3"><v>1</v></c></row></sheetData></worksheet>'] ],
		'an unclosed CDATA section runs to the end of the part' );

	# An empty CDATA section, or a comment, is no value, and a CDATA section
	# that holds one is: each widens the table, or not, as its value says
	my $w = mk($h . '<row r="2"><c r="A2"><v>1</v></c><c r="B2"><v><![CDATA[]]></v></c>'
	         . '<c r="C2"><v><!-- x --></v></c></row>');
	is_deeply( read_table($w, 'output_type' => 'aoa'), [ ['h'], [1] ],
		'an empty CDATA section or a lone comment adds no column' );
	my $c = mk($h . '<row r="2"><c r="A2"><v>1</v></c><c r="B2"><v><![CDATA[7]]></v></c></row>');
	is_deeply( read_table($c, 'output_type' => 'aoa'), [ ['h', ''], [1, 7] ],
		'a cell whose value is a CDATA section widens the table to hold it' );

	my $e = mk($h
	         . qq{<row r="2"><c r="A2" t="inlineStr"><is><t>a\r\nb\rc\nd</t></is></c></row>}
	         . qq{<row r="3"><c r="A3" t="inlineStr"><is><t>e&#13;&#10;f&#xD;g</t></is></c></row>}
	         . qq{<row r="4"><c r="A4" t="inlineStr"><is><t><![CDATA[h\r\ni\rj]]></t></is></c></row>}
	         . qq{<row r="5"><c r="A5" t="s"><v>0</v></c></row>}
	         . qq{<row r="6"><c r="A6" t="inlineStr"><is><t>k\r&amp;\r\n&#13;\r</t></is></c></row>},
		qq{<si><t>l\r\nm</t></si>});
	is_deeply( read_table($e, 'output_type' => 'aoa'),
		[ ['h'], ["a\nb\nc\nd"], ["e\r\nf\rg"], ["h\ni\nj"], ["l\nm"], ["k\n&\n\r\n"] ],
		'a literal CR LF or CR is LF, in text and in CDATA, and &#13; is still a CR' );
}

# 8. A shared-string cell carries the same bytes and the same flag as before
# the strings were stored as shared hash keys, and each cell is its own value.
{
	my $f = mk('<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c></row>'
	         . '<row r="2"><c r="A2" t="s"><v>2</v></c><c r="B2" t="s"><v>3</v></c></row>'
	         . '<row r="3"><c r="A3" t="s"><v>2</v></c><c r="B3" t="s"><v>3</v></c></row>',
		"<si><t>k</t></si><si><t>v</t></si><si><t>caf\xc3\xa9</t></si><si><t>&#xe9;x</t></si>");
	my $aoa = read_table($f, 'output_type' => 'aoa');
	is_deeply( $aoa, [ ['k', 'v'], ["caf\xc3\xa9", "\xc3\xa9x"], ["caf\xc3\xa9", "\xc3\xa9x"] ],
		'shared strings come back as their UTF-8 bytes' );
	ok( !grep({ utf8::is_utf8($_) } map { @$_ } @$aoa), '... with no UTF-8 flag on any of them' );
	$aoa->[1][0] .= '!';
	substr($aoa->[1][1], 0, 1) = 'Z';
	is_deeply( [ $aoa->[1][0], $aoa->[1][1], $aoa->[2][0], $aoa->[2][1] ],
		[ "caf\xc3\xa9!", "Z\xa9x", "caf\xc3\xa9", "\xc3\xa9x" ],
		'... and changing one cell changes no other cell sharing its string' );
	my @warned;
	my $hoh = do {
		local $SIG{__WARN__} = sub { push @warned, $_[0] };
		read_table($f, 'output_type' => 'hoh');
	};
	is_deeply( $hoh, { "caf\xc3\xa9" => { v => "\xc3\xa9x" } }, '... and keys a hoh by them' );
	is( scalar @warned, 1, '... warning once that the two rows share a name' );
	is_deeply( Stats::LikeR::_xlsx_shared_strings($f),
		[ 'k', 'v', "caf\xc3\xa9", "\xc3\xa9x" ], '_xlsx_shared_strings, as bytes' );
}

# 9. Excel's own escape, ST_Xstring's _xHHHH_, in a <t>: a character XML
# cannot hold, written as _x, four hex digits and _, and a literal "_xHHHH_"
# written with its underscore escaped as _x005F_. Decoded after references and
# CDATA, one <t> at a time, left to right, into UTF-8 bytes. The writers'
# side is Excel::Writer::XLSX 1.15, Package/XMLwriter.pm,
# _escape_control_characters(), and XlsxWriter 1.3.9's sharedstrings.py
# _write_si(). Every expected value here is what LibreOffice 24.2.7.2 reads the
# same workbook as (soffice --convert-to csv, 2026-10-05), but for the lone
# surrogates, which its UTF-8 export cannot write. This is the one section that
# openpyxl 3.1.5 does not agree with: reader/strings.py strips "x005F_" from a
# shared string and decodes nothing else, and it leaves an inline string as
# written.
{
	my @cases = (
		[ 'a_x0000_b',            "a\0b" ],
		[ '_x000D__x000a_',       "\r\n" ],
		[ '_x0041_',              'A' ],
		[ '_x005F_x0041_',        '_x0041_' ],	# a literal "_x0041_", escaped
		# "_x005F_x0041_" written with each underscore that starts an escape
		# escaped, and the same string as XlsxWriter's and Excel::Writer::XLSX's
		# non-overlapping s/(_x[0-9a-fA-F]{4}_)/_x005F$1/g writes it, which a
		# left-to-right reading -- openpyxl's regex included -- cannot invert
		[ '_x005F_x005F_x005F_x0041_', '_x005F_x0041_' ],
		[ '_x005F_x005F_x0041_',  '_x005FA' ],
		[ '_x00e9_',              "\xc3\xa9" ],
		[ '_xFFFF__xD800_',       "\xef\xbf\xbf\xed\xa0\x80" ],	# a nonchar and a lone surrogate
		[ '_xD83D__xDE00_',       "\xf0\x9f\x98\x80" ],	# a pair: U+1F600, as LibreOffice reads it
		[ '_xDE00__xD83D_',       "\xed\xb8\x80\xed\xa0\xbd" ],	# low then high: two lone ones
		[ '__x0041__',            '_A_' ],
		[ 'tail_x0041_',          'tailA' ],
		[ '_x004_ _x00G1_ x0041_ _X0041_ _x0041', '_x004_ _x00G1_ x0041_ _X0041_ _x0041' ],
		[ '&#95;x0042_',          'B' ],	# the escape is read after references
		[ '<![CDATA[_x0043_]]>',  'C' ],	# ... and after CDATA
	);
	my $r = 1;
	my $rows = $h . join '', map {
		$r++;
		qq{<row r="$r"><c r="A$r" t="inlineStr"><is><t>$_->[0]</t></is></c></row>}
	} @cases;
	is_deeply( read_table(mk($rows), 'output_type' => 'aoa'),
		[ ['h'], map { [ $_->[1] ] } @cases ], '_xHHHH_ decoded in an inline string' );
	my $si = join '', map { "<si><t>$_->[0]</t></si>" } @cases;
	$r = 1;
	my $srows = $h . join '', map {
		$r++;
		qq{<row r="$r"><c r="A$r" t="s"><v>} . ($r - 2) . '</v></c></row>'
	} @cases;
	is_deeply( read_table(mk($srows, $si), 'output_type' => 'aoa'),
		[ ['h'], map { [ $_->[1] ] } @cases ], '... and in a shared string' );

	# One <t> at a time: an escape is not put together from two runs
	my $runs = mk($h . '<row r="2"><c r="A2" t="inlineStr"><is><r><t>_x00</t></r>'
	            . '<r><t>41_</t></r><r><t>_x0042_</t></r></is></c></row>',
	              '<si><r><t>_x00</t></r><r><t>43_</t></r></si>');
	is_deeply( read_table($runs, 'output_type' => 'aoa'), [ ['h'], ['_x0041_B'] ],
		'an escape split across two runs is not one' );
	is_deeply( Stats::LikeR::_xlsx_shared_strings($runs), ['_x0043_'],
		'... in a shared string either' );

	# A cell whose only text is an escape has a value, so it widens the table
	# -- pass 1 and pass 2 have to agree -- and it is not dropped as blank
	my $w = mk($h . '<row r="2"><c r="A2"><v>1</v></c>'
	         . '<c r="B2" t="inlineStr"><is><t>_x0000_</t></is></c>'
	         . '<c r="C2" t="s"><v>0</v></c></row>'
	         . '<row r="3"><c r="A3" t="inlineStr"><is><t>_x0009_</t></is></c></row>',
	           '<si><t>_x0000_</t></si>');
	is_deeply( read_table($w, 'output_type' => 'aoa'),
		[ ['h', '', ''], [1, "\0", "\0"], ["\t", undef, undef] ],
		'a cell that is only an escape is a value, and widens the table' );

	# A formula's string result, <v> under t="str", is not decoded: ECMA-376
	# types <v> as ST_Xstring as well, but LibreOffice shows this cached result
	# as written, openpyxl decodes it nowhere, and Excel::Writer::XLSX writes a
	# formula's result without the escape
	my $f = mk($h . '<row r="2"><c r="A2" t="str"><f>"_x0041_"</f><v>_x0041_</v></c></row>');
	is_deeply( read_table($f, 'output_type' => 'aoa'), [ ['h'], ['_x0041_'] ],
		'a formula result in <v> is left as it is' );
}

SKIP: {
	skip 'Test::LeakTrace not installed', 4 unless $HAVE_LEAKTRACE;
	# The same caveat as t/read_table.xlsx.parser.t's: IO::Uncompress::Unzip
	# leaks on some perls, and a leak check around read_table would measure it.
	my $f = mk($h . '<!-- c --><row r="2"><c r="A2" t="s"><v>0</v></c></row>'
	         . '<row r="3"><c r="A3" t="inlineStr"><is><t><![CDATA[x]]>&#0;_x0041_</t><rPh><t>y</t></rPh></is></c></row>',
		'<si><t>a</t><rPh><t>b</t></rPh></si>', sst_member => 'xl/S.xml', sst_target => 'S.xml');
	Stats::LikeR::_unzip_member($f, 'xl/worksheets/sheet1.xml');
	my $unzip_leaks = Test::LeakTrace::leaked_count(
		sub { Stats::LikeR::_unzip_member($f, 'xl/worksheets/sheet1.xml') });
	skip "IO::Uncompress::Unzip leaks $unzip_leaks SV(s) per member on this perl",
		4 if $unzip_leaks;
	read_table($f) for 1 .. 2;	# warm: the first read loads modules and caches patterns
	no_leaks_ok { read_table($f) }                               'no leaks: aoh';
	no_leaks_ok { read_table($f, 'output_type' => 'aoa') }       'no leaks: aoa';
	no_leaks_ok { read_table($f, filter => { 0 => sub { 1 } }) } 'no leaks: callback path';
	no_leaks_ok { Stats::LikeR::_xlsx_shared_strings($f) }       'no leaks: shared strings';
}

done_testing;
