#!/usr/bin/env perl
# Provenance: no R or SciPy counterpart; the cases are this reader's own and
# follow t/read_table.xlsx.xml.t (same fixture builder, same rule: what an XML
# processor makes of an entity, with a bare '&' and an unknown entity left in
# the text verbatim as that file records).  The expected strings were taken
# from the 0.3418 build, whose decoding this test pins unchanged.
#
# The fix under test: xlsx_xml_uncat() looked for the ';' that ends a reference
# with a memchr() over the whole rest of the text node for every '&', so a node
# of n '&' and no ';' scanned n * len / 2 bytes.  Measured on 2026-11-09 through
# read_table() of a one-cell workbook, one process per size: 0.053 s at
# n = 1e5 and 0.836 s at n = 4e5 with 0.3418 (quadratic), 0.002 s and 0.007 s
# now.  The search now stops at the next '&', which cannot lie inside a
# reference.  The timing check is gated behind EXTENDED_TESTING because a bound
# on wall time is the one assertion here that can fail on a loaded machine.
require 5.010;
use strict; use warnings FATAL => 'all';
use Test::More;
use File::Temp 'tempdir';
use Time::HiRes 'time';
use Stats::LikeR 'read_table';

no warnings 'once';	# $IO::Compress::Zip::ZipError is read, never assigned
plan skip_all => 'IO::Compress::Zip (core) not available' unless eval { require IO::Compress::Zip; 1 };

my $dir = tempdir(CLEANUP => 1);
my $seq = 0;
my $NS  = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
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

# A one-sheet workbook whose only data cell is the inline string $text, which
# is raw XML (nothing is escaped here).
sub cell_file {
	my ($text) = @_;
	return zip_parts({
		'xl/workbook.xml' => qq{<?xml version="1.0"?><workbook xmlns="$NS" xmlns:r="$ONS">}
			. q{<sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets></workbook>},
		'xl/_rels/workbook.xml.rels' => q{<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">}
			. qq{<Relationship Id="rId1" Type="$ONS/worksheet" Target="worksheets/sheet1.xml"/></Relationships>},
		'xl/worksheets/sheet1.xml' => qq{<?xml version="1.0"?><worksheet xmlns="$NS"><sheetData>}
			. q{<row r="1"><c r="A1" t="inlineStr"><is><t>h</t></is></c></row>}
			. qq{<row r="2"><c r="A2" t="inlineStr"><is><t>$text</t></is></c></row>}
			. q{</sheetData></worksheet>},
	});
}
sub cell { read_table(cell_file($_[0]), 'output_type' => 'aoa')->[1][0] }

my @cases = (
	['bare ampersands, no semicolon anywhere',       '&&&&',               '&&&&'],
	['a bare & before a real reference',             '&&amp;',             '&&'],
	['a bare & then an unknown entity',              '&&nbsp;x',           '&&nbsp;x'],
	['unknown entity, then reference',               '&a;&amp;',           '&a;&'],
	['a ; after a bare &, with a space inside',      'a & b; c',           'a & b; c'],
	['the far ; belongs to a later reference',       '&&&lt;&gt;',         '&&<>'],
	['numeric references among bare &s',             '&&#65;&#x42;&',      '&AB&'],
	['trailing bare &',                              'x&',                 'x&'],
	['a reference cut off by a following &',         '&am&amp;',           '&am&'],
	['no ampersand at all',                          'plain',              'plain'],
);
for my $c (@cases) {
	is(cell($c->[1]), $c->[2], $c->[0]);
}

# many bare '&' and a ';' only at the very end: the case that was quadratic
{
	my $n = 5000;
	is(cell(('&' x $n) . ';'), ('&' x $n) . ';', "$n bare & then a ';'");
	is(cell(('&' x $n) . 'amp;'), ('&' x ($n - 1)) . '&', "$n & whose last starts &amp;");
}

SKIP: {
	skip 'timing check: set EXTENDED_TESTING=1', 1 unless $ENV{EXTENDED_TESTING};
	# 1e6 '&' took about 5 s when quadratic (0.836 s at 4e5, scaling as n^2)
	# against ~0.02 s linear; 1 s leaves 50x headroom over the fix.
	my $n = 1_000_000;
	my $f = cell_file('&' x $n);
	my $t = time;
	my $v = read_table($f, 'output_type' => 'aoa')->[1][0];
	my $dt = time - $t;
	is(length($v), $n, 'a million bare & read back whole');
	cmp_ok($dt, '<', 1.0, "and in linear time (took ${dt}s)");
}

done_testing;
