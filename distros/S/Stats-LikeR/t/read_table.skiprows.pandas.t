#!/usr/bin/env perl

# read_table(skiprows => ...), from pandas' own skiprows tests: rows left out
# by 0-based index, as a count of leading rows, a list of indices or a sub.
#
# Provenance: pandas 3.0.4, installed at
# /home/con/.pyenv/versions/3.14.2/lib/python3.14/site-packages/pandas.
#
#   tests/io/excel/test_readers.py
#     test_read_excel_skiprows (GH 4903, GH 36435): testskiprows, sheet
#       skiprows_list, read with skiprows=[0, 2], np.array([0, 2]),
#       lambda x: x in [0, 2], and 3 with names=[a, b, c, d]
#     test_read_excel_skiprows_callable_not_in (GH 4903):
#       lambda x: x not in [1, 3, 5]
#     test_excel_table: test1, sheet Sheet2 with skiprows=[1] is sheet Sheet1,
#       and both are tests/io/data/csv/test1.csv (df_ref)
#     test_euro_decimal_format: test_decimal with skiprows=1
#     test_read_excel_nrows_params cases with skiprows ([0, 2] and the
#       lambda) are test_read_excel_skiprows's: nrows does not bind there
#   tests/io/parser/test_skiprows.py, every test, for a delimited file
#
# The workbooks are pandas' own (pandas/tests/io/data/excel/ at the git tag
# v3.0.4), which pandas' wheel does not ship.  The parts read_table reads are
# in __DATA__, byte for byte, written by t/read_table.pandas.fixtures.pl, which
# says how to re-run it; this test never runs it.  Its file list for this test:
#   testskiprows.ods testskiprows.xlsx test1.ods test1.xlsx test_decimal.ods
#
# What pandas returns as a Timestamp, a bool or a float is compared as what
# read_table returns: an .ods date is its office:date-value text, an .xlsx date
# its serial number (42005 is 2015-01-01: Excel's 1900 date system, which
# counts the fictitious 1900-02-29), a boolean 1 or 0, and a number the text the
# file holds.  The numbers of test1 are compared with test1.csv's numerically:
# the workbooks hold LibreOffice's and Excel's 17-digit renderings of the same
# doubles the CSV's 12 digits name, which differ by less than half an ulp of a
# double, so 2**-52 relative is the bound, on any NV width (a long-double or
# quadmath perl reads the two texts as different numbers).
#
# Where read_table() is not pandas, on purpose, and so not tested as pandas has it:
#   - test_skip_rows_skip_all: every row skipped raises EmptyDataError in
#     pandas; read_table returns an empty table, as it does for an empty file;
#   - test_euro_decimal_format passes decimal=",", which read_table does not
#     have, so its numbers stay the text the cells hold ("1521,1541");
#   - quotechar="~" in test_skip_row_with_newline has no read_table
#     equivalent ('quote' takes '"' only), so those two cases are run with
#     each "~" written as '"', which is the same file to a CSV reader;
#   - parse_dates, index_col, nrows and chunksize are not read_table's: the
#     dates are compared as their text, the index as the first column, and
#     the chunked read as one read (its chunks concatenated);
#   - header=None is header => 0, and names= is col_names (renaming a header
#     when header => 1, as R's col.names and pandas' names with header=0 do).
#
# R's read.table(skip = n) counts lines, not rows, and R's own suite has no
# read.table(skip=) case: its only skip= cases are scan() and read.fwf() in
# tests/reg-tests-1a.R and tests/reg-tests-2.R, whose rows read_table would
# refuse as ragged.

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use Test::More;
use Stats::LikeR 'read_table';

no warnings 'once';	# $IO::Compress::Zip::ZipError is read, never assigned
my $have_zip = eval { require IO::Compress::Zip; 1 };
my $have_gz  = eval { require IO::Compress::Gzip; 1 };
my $dir = tempdir(CLEANUP => 1);

# The fixtures: file => [part, bytes, part, bytes, ...] in the order written.
my %fixture;
{
	local $/;
	binmode DATA;
	my @chunk = split /^=== (\S+) ([^\n]*)\n/m, <DATA>;
	shift @chunk;	# what comes before the first part: nothing
	while (my ($file, $part, $bytes) = splice @chunk, 0, 3) {
		$bytes =~ s/\n\z//;
		push @{ $fixture{$file} }, $part, $bytes;
	}
}

# A workbook from its parts: an .ods's mimetype goes first, as the format asks
# (OpenDocument 1.2 part 3, section 3.3), though read_table does not read it.
sub book {
	my ($name) = @_;
	my $path = "$dir/$name";
	return $path if -e $path;
	my @part = @{ $fixture{$name} or die "no fixture $name" };
	unshift @part, mimetype => 'application/vnd.oasis.opendocument.spreadsheet'
		if $name =~ /\.ods\z/;
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

my $n = 0;
sub csv {	# a delimited file holding exactly these bytes
	my ($text, $ext) = @_;
	my $path = "$dir/c" . $n++ . ($ext // '.csv');
	open my $fh, '>:raw', $path or die "cannot write $path: $!";
	print {$fh} $text;
	close $fh or die "cannot write $path: $!";
	return $path;
}
sub aoa { read_table(shift, output_type => 'aoa', @_) }

SKIP: {
	skip 'IO::Compress::Zip (core) is not installed', 30 unless $have_zip;

	# test_read_excel_skiprows and test_read_excel_skiprows_callable_not_in.
	# Row 0 of skiprows_list is blank, row 1 the header a b c d, row 2 blank,
	# and rows 3 to 6 the data.
	for my $ext ('ods', 'xlsx') {
		my $f = book("testskiprows.$ext");
		my @day = $ext eq 'ods'
			? map { "2015-01-0${_}T00:00:00" } 1 .. 4
			: (42005 .. 42008);
		my @row = ([1, '2.5', $day[0], 1], [2, '3.5', $day[1], 0],
		           [3, '4.5', $day[2], 0], [4, '5.5', $day[3], 1]);
		my $all = [[qw(a b c d)], @row];
		is_deeply(aoa($f, sheet => 'skiprows_list', skiprows => [0, 2]), $all,
			"$ext: skiprows => [0, 2]");
		is_deeply(aoa($f, sheet => 'skiprows_list', skiprows => [2, 0, 2]), $all,
			"$ext: the same list, out of order and repeated (np.array([0, 2]) in pandas)");
		my @asked;
		is_deeply(aoa($f, sheet => 'skiprows_list',
				skiprows => sub { push @asked, $_[0]; $_[0] == 0 || $_[0] == 2 }),
			$all, "$ext: skiprows => sub { x in [0, 2] }");
		is_deeply(\@asked, [0 .. 6], "$ext: ... the sub is asked once per row, in order, to the last row");
		is_deeply(aoa($f, sheet => 'skiprows_list', skiprows => 3, col_names => [qw(a b c d)]),
			[[qw(a b c d)], @row[1 .. 3]], "$ext: skiprows => 3, names => [a, b, c, d]");
		is_deeply(aoa($f, sheet => 'skiprows_list',
				skiprows => sub { my $x = shift; !grep { $_ == $x } 1, 3, 5 }),
			[[qw(a b c d)], @row[0, 2]], "$ext: skiprows => sub { x not in [1, 3, 5] }");
		# Without skiprows the blank row 2 is a row of undef (pandas'
		# skip_blank_lines=False reading, t/read_table.xlsx.blank_rows.pandas.t).
		is_deeply(aoa($f), [[qw(a b c d)], [(undef) x 4], @row], "$ext: and without skiprows");
		# every output type: the list and the sub agree
		for my $otype (qw(aoh hoa hoh)) {
			is_deeply(read_table($f, output_type => $otype, skiprows => [0, 2]),
				read_table($f, output_type => $otype, skiprows => sub { $_[0] == 0 || $_[0] == 2 }),
				"$ext: $otype, the list and the sub agree");
		}
	}

	# test_excel_table: Sheet2 is Sheet1 with a row under the header that
	# skiprows => [1] leaves out ("col we should ignore"), and both are
	# test1.csv, whose index column has no name in the header (row_name here).
	my @csv = (	# pandas tests/io/data/csv/test1.csv, v3.0.4
		['2000-01-03 00:00:00', 0.980268513777, 3.68573087906, -0.364216805298, -1.15973806169],
		['2000-01-04 00:00:00', 1.04791624281, -0.0412318367011, -0.16181208307, 0.212549316967],
		['2000-01-05 00:00:00', 0.498580885705, 0.731167677815, -0.537677223318, 1.34627041952],
		['2000-01-06 00:00:00', 1.12020151869, 1.56762092543, 0.00364077397681, 0.67525259227],
		['2000-01-07 00:00:00', -0.487094399463, 0.571454623474, -1.6116394093, 0.103468562917],
		['2000-01-10 00:00:00', 0.836648671666, 0.246461918642, 0.588542635376, 1.0627820613],
		['2000-01-11 00:00:00', -0.157160753327, 1.34030689438, 1.19577795622, -1.09700699751],
	);
	for my $ext ('ods', 'xlsx') {
		my $f  = book("test1.$ext");
		my $s1 = aoa($f, sheet => 'Sheet1');
		is_deeply(aoa($f, sheet => 'Sheet2', skiprows => [1]), $s1,
			"$ext: Sheet2 with skiprows => [1] is Sheet1");
		is_deeply($s1->[0], [qw(row_name A B C D)], "$ext: test1's header");
		is(scalar @$s1 - 1, scalar @csv, "$ext: test1 has test1.csv's rows");
		my @bad;
		for my $i (0 .. $#csv) {
			my $got = $s1->[ $i + 1 ];
			my $day = $got->[0];
			$day =~ tr/T/ / if $ext eq q(ods);
			# 36528 is 2000-01-03; the CSV skips the weekend after 01-07
			my $want_day = $ext eq 'ods' ? $csv[$i][0]
				: (36528, 36529, 36530, 36531, 36532, 36535, 36536)[$i];
			push @bad, "row $i date $day" unless $day eq $want_day;
			for my $j (1 .. 4) {
				my ($g, $w) = ($got->[$j], $csv[$i][$j]);
				push @bad, "row $i col $j: $g vs $w" unless abs($g - $w) <= 2**-52 * abs($w);
			}
		}
		is("@bad", '', "$ext: test1's values are test1.csv's");
	}
	ok(!eval { aoa(book('test1.ods'), sheet => 'Sheet2', skiprows => [1, 99]); 0 } && !$@,
		'an index past the last row is no error') or diag $@;

	# test_euro_decimal_format: the header is in row 1, under a row of
	# Column1..Column6 that skiprows => 1 leaves out.
	is_deeply(aoa(book('test_decimal.ods'), skiprows => 1),
		[[qw(Id Number1 Number2 Text1 Text2 Number3)],
		 [1, '1521,1541', '187101,9543', 'ABC', 'poi', '4,738797819'],
		 [2, '121,12', '14897,76', 'DEF', 'uyt', '0,377320872'],
		 [3, '878,158', '108013,434', 'GHI', 'rez', '2,735694704']],
		'test_euro_decimal_format: skiprows => 1');
}

# tests/io/parser/test_skiprows.py
{
	my $bug = join('', ("#foo,a,b,c\n") x 6) . "1/1/2000,1.,2.,3.\n1/2/2000,4,5,6\n1/3/2000,7,8,9\n";
	my $want = [[qw(V1 V2 V3 V4)], ['1/1/2000', '1.', '2.', '3.'], ['1/2/2000', 4, 5, 6], ['1/3/2000', 7, 8, 9]];
	for my $s ([0 .. 5], 6) {
		my $got = aoa(csv($bug), skiprows => $s, header => 0);
		is_deeply($got, $want, 'test_skip_rows_bug (gh-505), skiprows => ' . (ref $s ? '[0..5]' : $s));
		is_deeply([ map { [ map { $_ + 0 } @$_[1 .. 3] ] } @$got[1 .. 3] ],
			[[1, 2, 3], [4, 5, 6], [7, 8, 9]], '... the values are 1.0 to 9.0');
	}

	my $deep = "a,b,c\n" . join("\n", map { join ',', $_, $_ + 1, $_ + 2 } 0 .. 9);
	my $cond = "a,b,c\n" . join("\n", map { join ',', $_, $_ + 1, $_ + 2 } 0 .. 4, 6, 8, 9);
	for my $otype (qw(aoa aoh hoa hoh)) {
		is_deeply(read_table(csv($deep), output_type => $otype, skiprows => [6, 8]),
			read_table(csv($cond), output_type => $otype),
			"test_deep_skip_rows (gh-4382), $otype: as the file without those rows");
	}
	SKIP: {
		skip 'IO::Compress::Gzip (core) is not installed', 1 unless $have_gz;
		my $gz = "$dir/deep.csv.gz";
		IO::Compress::Gzip::gzip(\$deep => $gz) or die "gzip failed";
		is_deeply(aoa($gz, skiprows => [6, 8]), aoa(csv($cond)),
			'test_deep_skip_rows, read through gzip');
	}

	is_deeply(aoa(csv("#foo,a,b,c\n#foo,a,b,c\n\n#foo,a,b,c\n#foo,a,b,c\n\n"
			. "1/1/2000,1.,2.,3.\n1/2/2000,4,5,6\n1/3/2000,7,8,9\n"), skiprows => 6, header => 0),
		$want, 'test_skip_rows_blank (gh-9832): blank lines are rows');

	# test_skip_row_with_newline (gh-12775, gh-10911): a row whose quoted
	# field runs across lines is one index, kept or left out whole
	is_deeply(aoa(csv(qq{id,text,num_lines\n1,"line 11\nline 12",2\n2,"line 21\nline 22",2\n3,"line 31",1}),
			skiprows => [1]),
		[[qw(id text num_lines)], [2, "line 21\nline 22", 2], [3, 'line 31', 1]],
		'test_skip_row_with_newline, case 1');
	is_deeply(aoa(csv(qq{a,b,c\n"a\n b","e\n d","f\n f"\n1,2,"12\n 13\n 14"}), skiprows => [2]),
		[[qw(a b c)], ["a\n b", "e\n d", "f\n f"]],
		'test_skip_row_with_newline, case 2 (quotechar "~" as \'"\')');
	is_deeply(aoa(csv(qq{Text,url\n"example\n sentence\n one",url1\n"example\n sentence\n two",url2\n}
			. qq{"example\n sentence\n three",url3}), skiprows => [1, 3]),
		[[qw(Text url)], ["example\n sentence\n two", 'url2']],
		'test_skip_row_with_newline, case 3 (quotechar "~" as \'"\')');

	is_deeply(aoa(csv(qq{id,text,num_lines\n1,"line '11' line 12",2\n2,"line '21' line 22",2\n3,"line '31' line 32",1}),
			skiprows => [1]),
		[[qw(id text num_lines)], [2, "line '21' line 22", 2], [3, "line '31' line 32", 1]],
		'test_skip_row_with_quote');

	my @nq = (
		[qq{line \n'%d1' line %d2}],
		[qq{line '%d1\n' line %d2}],
		[qq{line '%d1\n' \r\tline %d2}],
	);
	for my $k (0 .. $#nq) {
		my $fmt = $nq[$k][0];
		my $text = "id,text,num_lines\n" . join("\n", map {
			qq{$_,"} . sprintf($fmt, $_, $_) . qq{",} . ($_ == 3 ? 1 : 2) } 1 .. 3);
		is_deeply(aoa(csv($text), skiprows => [1]),
			[[qw(id text num_lines)], [2, sprintf($fmt, 2, 2), 2], [3, sprintf($fmt, 3, 3), 1]],
			'test_skip_row_with_newline_and_quote, case ' . ($k + 1));
	}

	# test_skiprows_lineterminator (gh-9079), LF, CRLF and CR
	for my $lt ("\n", "\r\n", "\r") {
		my $text = join $lt, 'SMOSMANIA ThetaProbe-ML2X ', '2007/01/01 01:00   0.2140 U M ',
			'2007/01/01 02:00   0.2141 M O ', '2007/01/01 04:00   0.2142 D M ';
		is_deeply(aoa(csv($text), skiprows => 1, sep => qr/\s+/, header => 0,
				col_names => [qw(date time var flag oflag)]),
			[[qw(date time var flag oflag)],
			 ['2007/01/01', '01:00', '0.2140', 'U', 'M'],
			 ['2007/01/01', '02:00', '0.2141', 'M', 'O'],
			 ['2007/01/01', '04:00', '0.2142', 'D', 'M']],
			'test_skiprows_lineterminator, ' . join('', map { sprintf '\\x%02x', ord } split //, $lt));
	}

	is_deeply(aoa(csv(qq{a"\nb"\na\n1}), skiprows => 2), [['a'], [1]],
		'test_skiprows_infield_quote (gh-14459): a \'"\' inside a skipped field opens nothing');

	is_deeply(aoa(csv("a\n1\n2\n3\n4\n5"), skiprows => sub { $_[0] % 2 == 0 }),
		[[1], [3], [5]], 'test_skip_rows_callable, {}');
	is_deeply(aoa(csv("a\n1\n2\n3\n4\n5"), skiprows => sub { $_[0] % 2 == 0 }, col_names => ['foo']),
		[['foo'], [3], [5]], 'test_skip_rows_callable, header 0 and names [foo]');
	is_deeply(aoa(csv("0,a\n1,b\n2,c\n3,d\n4,e"), header => 0,
			skiprows => sub { my $x = shift; !grep { $_ == $x } 1, 3 }),
		[[qw(V1 V2)], [1, 'b'], [3, 'd']], 'test_skip_rows_callable_not_in');
	is_deeply(aoa(csv("a\n1\n2\n3\n4\n5"), skiprows => sub { 1 }), [],
		'test_skip_rows_skip_all: an empty table (pandas: EmptyDataError)');
	ok(!eval { aoa(csv("a\n1\n2\n3\n4\n5"), skiprows => sub { 1 / 0 }); 1 }
		&& $@ =~ /division by zero/, 'test_skip_rows_bad_callable: the sub\'s die is the read\'s');
	is_deeply(aoa(csv("a,b\n1,a\n2,b\n3,c\n4,d\n5,e\n6,f\n7,g\n8,h\n"), skiprows => [2, 4, 6]),
		[[qw(a b)], [1, 'a'], [3, 'c'], [5, 'e'], [7, 'g'], [8, 'h']],
		'test_skip_rows_and_n_rows (GH#44021), nrows=5 not binding');
	is_deeply(aoa(csv(join '', map { "$_\n" } 'col_a', map { $_ * 10 } 1 .. 10),
			skiprows => sub { my $x = shift; grep { $_ == $x } 1, 4, 5 }),
		[['col_a'], [20], [30], [60], [70], [80], [90], [100]],
		'test_skip_rows_with_chunks (GH 55677), its two chunks as one');
}

done_testing;

__DATA__
=== testskiprows.ods content.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<office:document-content xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" office:version="1.2"><office:body><office:spreadsheet><table:calculation-settings table:case-sensitive="false" table:search-criteria-must-apply-to-whole-cell="true" table:use-wildcards="true" table:use-regular-expressions="false" table:automatic-find-labels="false"/><table:table table:name="skiprows_list" table:style-name="ta1"><table:table-column table:style-name="co1" table:number-columns-repeated="2" table:default-cell-style-name="ce1"/><table:table-column table:style-name="co2" table:default-cell-style-name="ce1"/><table:table-column table:style-name="co1" table:number-columns-repeated="16381" table:default-cell-style-name="ce1"/><table:table-row table:style-name="ro1"><table:table-cell table:number-columns-repeated="16384"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>a</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>b</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>c</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>d</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16380"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell table:number-columns-repeated="16384"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="float" office:value="1" table:style-name="ce1"><text:p>1</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="2.5" table:style-name="ce1"><text:p>2.5</text:p></table:table-cell><table:table-cell office:value-type="date" office:date-value="2015-01-01T00:00:00" table:style-name="ce2"><text:p>2015-01-01 00:00:00</text:p></table:table-cell><table:table-cell office:value-type="boolean" office:boolean-value="true" table:style-name="ce1"><text:p>TRUE</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16380"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="float" office:value="2" table:style-name="ce1"><text:p>2</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="3.5" table:style-name="ce1"><text:p>3.5</text:p></table:table-cell><table:table-cell office:value-type="date" office:date-value="2015-01-02T00:00:00" table:style-name="ce2"><text:p>2015-01-02 00:00:00</text:p></table:table-cell><table:table-cell office:value-type="boolean" office:boolean-value="false" table:style-name="ce1"><text:p>FALSE</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16380"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="float" office:value="3" table:style-name="ce1"><text:p>3</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="4.5" table:style-name="ce1"><text:p>4.5</text:p></table:table-cell><table:table-cell office:value-type="date" office:date-value="2015-01-03T00:00:00" table:style-name="ce2"><text:p>2015-01-03 00:00:00</text:p></table:table-cell><table:table-cell office:value-type="boolean" office:boolean-value="false" table:style-name="ce1"><text:p>FALSE</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16380"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="float" office:value="4" table:style-name="ce1"><text:p>4</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="5.5" table:style-name="ce1"><text:p>5.5</text:p></table:table-cell><table:table-cell office:value-type="date" office:date-value="2015-01-04T00:00:00" table:style-name="ce2"><text:p>2015-01-04 00:00:00</text:p></table:table-cell><table:table-cell office:value-type="boolean" office:boolean-value="true" table:style-name="ce1"><text:p>TRUE</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16380"/></table:table-row><table:table-row table:number-rows-repeated="1048569" table:style-name="ro1"><table:table-cell table:number-columns-repeated="16384"/></table:table-row></table:table></office:spreadsheet></office:body></office:document-content>
=== testskiprows.xlsx [Content_Types].xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/><Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/><Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/></Types>
=== testskiprows.xlsx _rels/.rels
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>
=== testskiprows.xlsx xl/_rels/workbook.xml.rels
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/></Relationships>
=== testskiprows.xlsx xl/sharedStrings.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="4" uniqueCount="4"><si><t>a</t></si><si><t>b</t></si><si><t>c</t></si><si><t>d</t></si></sst>
=== testskiprows.xlsx xl/workbook.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x15" xmlns:x15="http://schemas.microsoft.com/office/spreadsheetml/2010/11/main"><fileVersion appName="xl" lastEdited="6" lowestEdited="4" rupBuild="14420"/><workbookPr defaultThemeVersion="124226"/><mc:AlternateContent xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"><mc:Choice Requires="x15"><x15ac:absPath url="C:\Users\Chris\Documents\python-dev\pandas\pandas\io\tests\data\" xmlns:x15ac="http://schemas.microsoft.com/office/spreadsheetml/2010/11/ac"/></mc:Choice></mc:AlternateContent><bookViews><workbookView xWindow="240" yWindow="15" windowWidth="16095" windowHeight="9660"/></bookViews><sheets><sheet name="skiprows_list" sheetId="11" r:id="rId1"/></sheets><calcPr calcId="124519" calcMode="manual" calcCompleted="0" calcOnSave="0"/></workbook>
=== testskiprows.xlsx xl/worksheets/sheet1.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac" xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac"><dimension ref="A2:D7"/><sheetViews><sheetView tabSelected="1" workbookViewId="0"><selection activeCell="C18" sqref="C18"/></sheetView></sheetViews><sheetFormatPr defaultRowHeight="15" x14ac:dyDescent="0.25"/><cols><col min="3" max="3" width="18.28515625" bestFit="1" customWidth="1"/></cols><sheetData><row r="2" spans="1:4" x14ac:dyDescent="0.25"><c r="A2" t="s"><v>0</v></c><c r="B2" t="s"><v>1</v></c><c r="C2" t="s"><v>2</v></c><c r="D2" t="s"><v>3</v></c></row><row r="4" spans="1:4" x14ac:dyDescent="0.25"><c r="A4"><v>1</v></c><c r="B4"><v>2.5</v></c><c r="C4" s="1"><v>42005</v></c><c r="D4" t="b"><v>1</v></c></row><row r="5" spans="1:4" x14ac:dyDescent="0.25"><c r="A5"><v>2</v></c><c r="B5"><v>3.5</v></c><c r="C5" s="1"><v>42006</v></c><c r="D5" t="b"><v>0</v></c></row><row r="6" spans="1:4" x14ac:dyDescent="0.25"><c r="A6"><v>3</v></c><c r="B6"><v>4.5</v></c><c r="C6" s="1"><v>42007</v></c><c r="D6" t="b"><v>0</v></c></row><row r="7" spans="1:4" x14ac:dyDescent="0.25"><c r="A7"><v>4</v></c><c r="B7"><v>5.5</v></c><c r="C7" s="1"><v>42008</v></c><c r="D7" t="b"><v>1</v></c></row></sheetData><pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/></worksheet>
=== test1.ods content.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<office:document-content xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" office:version="1.2"><office:body><office:spreadsheet><table:calculation-settings table:case-sensitive="false" table:search-criteria-must-apply-to-whole-cell="true" table:use-wildcards="true" table:use-regular-expressions="false" table:automatic-find-labels="false"/><table:table table:name="Sheet1" table:style-name="ta1"><table:table-column table:style-name="co1" table:default-cell-style-name="ce1"/><table:table-column table:style-name="co2" table:number-columns-repeated="16383" table:default-cell-style-name="ce1"/><table:table-row table:style-name="ro1"><table:table-cell table:style-name="ce1"/><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>A</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>B</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>C</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>D</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-03T00:00:00" table:style-name="ce2"><text:p>1/3/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.98026851377699997" table:style-name="ce1"><text:p>0.980268514</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="3.6857308790599999" table:style-name="ce1"><text:p>3.685730879</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-0.36421680529799999" table:style-name="ce1"><text:p>-0.364216805</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-1.1597380616899999" table:style-name="ce1"><text:p>-1.159738062</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-04T00:00:00" table:style-name="ce2"><text:p>1/4/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.04791624281" table:style-name="ce1"><text:p>1.047916243</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-4.1231836701099998E-2" table:style-name="ce1"><text:p>-0.041231837</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-0.16181208307" table:style-name="ce1"><text:p>-0.161812083</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.212549316967" table:style-name="ce1"><text:p>0.212549317</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-05T00:00:00" table:style-name="ce2"><text:p>1/5/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.49858088570499998" table:style-name="ce1"><text:p>0.498580886</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.73116767781500003" table:style-name="ce1"><text:p>0.731167678</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-0.53767722331800005" table:style-name="ce1"><text:p>-0.537677223</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.3462704195199999" table:style-name="ce1"><text:p>1.34627042</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-06T00:00:00" table:style-name="ce2"><text:p>1/6/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.1202015186900001" table:style-name="ce1"><text:p>1.120201519</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.56762092543" table:style-name="ce1"><text:p>1.567620925</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="3.64077397681E-3" table:style-name="ce1"><text:p>0.003640774</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.67525259227000001" table:style-name="ce1"><text:p>0.675252592</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-07T00:00:00" table:style-name="ce2"><text:p>1/7/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-0.48709439946299998" table:style-name="ce1"><text:p>-0.487094399</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.571454623474" table:style-name="ce1"><text:p>0.571454623</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-1.6116394092999999" table:style-name="ce1"><text:p>-1.611639409</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.103468562917" table:style-name="ce1"><text:p>0.103468563</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-10T00:00:00" table:style-name="ce2"><text:p>1/10/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.83664867166599999" table:style-name="ce1"><text:p>0.836648672</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.24646191864200001" table:style-name="ce1"><text:p>0.246461919</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.58854263537600005" table:style-name="ce1"><text:p>0.588542635</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.0627820613000001" table:style-name="ce1"><text:p>1.062782061</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-11T00:00:00" table:style-name="ce2"><text:p>1/11/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-0.157160753327" table:style-name="ce1"><text:p>-0.157160753</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.3403068943800001" table:style-name="ce1"><text:p>1.340306894</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.1957779562199999" table:style-name="ce1"><text:p>1.195777956</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-1.0970069975100001" table:style-name="ce1"><text:p>-1.097006998</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:number-rows-repeated="1048568" table:style-name="ro1"><table:table-cell table:number-columns-repeated="16384"/></table:table-row></table:table><table:table table:name="Sheet2" table:style-name="ta1"><table:table-column table:style-name="co2" table:number-columns-repeated="16384" table:default-cell-style-name="ce1"/><table:table-row table:style-name="ro1"><table:table-cell table:style-name="ce1"/><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>A</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>B</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>C</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>D</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell table:style-name="ce1"/><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>col</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>we</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>should</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>ignore</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-03T00:00:00" table:style-name="ce2"><text:p>1/3/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.98026851377699997" table:style-name="ce1"><text:p>0.980268514</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="3.6857308790599999" table:style-name="ce1"><text:p>3.685730879</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-0.36421680529799999" table:style-name="ce1"><text:p>-0.364216805</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-1.1597380616899999" table:style-name="ce1"><text:p>-1.159738062</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-04T00:00:00" table:style-name="ce2"><text:p>1/4/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.04791624281" table:style-name="ce1"><text:p>1.047916243</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-4.1231836701099998E-2" table:style-name="ce1"><text:p>-0.041231837</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-0.16181208307" table:style-name="ce1"><text:p>-0.161812083</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.212549316967" table:style-name="ce1"><text:p>0.212549317</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-05T00:00:00" table:style-name="ce2"><text:p>1/5/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.49858088570499998" table:style-name="ce1"><text:p>0.498580886</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.73116767781500003" table:style-name="ce1"><text:p>0.731167678</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-0.53767722331800005" table:style-name="ce1"><text:p>-0.537677223</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.3462704195199999" table:style-name="ce1"><text:p>1.34627042</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-06T00:00:00" table:style-name="ce2"><text:p>1/6/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.1202015186900001" table:style-name="ce1"><text:p>1.120201519</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.56762092543" table:style-name="ce1"><text:p>1.567620925</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="3.64077397681E-3" table:style-name="ce1"><text:p>0.003640774</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.67525259227000001" table:style-name="ce1"><text:p>0.675252592</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-07T00:00:00" table:style-name="ce2"><text:p>1/7/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-0.48709439946299998" table:style-name="ce1"><text:p>-0.487094399</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.571454623474" table:style-name="ce1"><text:p>0.571454623</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-1.6116394092999999" table:style-name="ce1"><text:p>-1.611639409</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.103468562917" table:style-name="ce1"><text:p>0.103468563</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-10T00:00:00" table:style-name="ce2"><text:p>1/10/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.83664867166599999" table:style-name="ce1"><text:p>0.836648672</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.24646191864200001" table:style-name="ce1"><text:p>0.246461919</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="0.58854263537600005" table:style-name="ce1"><text:p>0.588542635</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.0627820613000001" table:style-name="ce1"><text:p>1.062782061</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="date" office:date-value="2000-01-11T00:00:00" table:style-name="ce2"><text:p>1/11/00 0:00</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-0.157160753327" table:style-name="ce1"><text:p>-0.157160753</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.3403068943800001" table:style-name="ce1"><text:p>1.340306894</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="1.1957779562199999" table:style-name="ce1"><text:p>1.195777956</text:p></table:table-cell><table:table-cell office:value-type="float" office:value="-1.0970069975100001" table:style-name="ce1"><text:p>-1.097006998</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16379"/></table:table-row><table:table-row table:number-rows-repeated="1048567" table:style-name="ro1"><table:table-cell table:number-columns-repeated="16384"/></table:table-row></table:table><table:table table:name="Sheet3" table:style-name="ta1"><table:table-column table:style-name="co2" table:number-columns-repeated="16384" table:default-cell-style-name="ce1"/><table:table-row table:style-name="ro1"><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>A</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>B</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>C</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>D</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>E</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>F</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16378"/></table:table-row><table:table-row table:number-rows-repeated="1048575" table:style-name="ro1"><table:table-cell table:number-columns-repeated="16384"/></table:table-row></table:table><table:table table:name="Sheet4" table:style-name="ta1"><table:table-column table:style-name="co2" table:number-columns-repeated="16384" table:default-cell-style-name="ce1"/><table:table-row table:style-name="ro1"><table:table-cell table:style-name="ce1"/><table:table-cell office:value-type="string" table:style-name="ce3"><text:p>col1</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce3"><text:p>col2</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16381"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="string" table:style-name="ce3"><text:p>i1</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>a</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>x</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16381"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="string" table:style-name="ce3"><text:p>i2</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>b</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>y</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16381"/></table:table-row><table:table-row table:number-rows-repeated="1048573" table:style-name="ro1"><table:table-cell table:number-columns-repeated="16384"/></table:table-row></table:table></office:spreadsheet></office:body></office:document-content>
=== test1.xlsx [Content_Types].xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/worksheets/sheet3.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/worksheets/sheet4.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/><Override PartName="/xl/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/><Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/><Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/><Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/></Types>
=== test1.xlsx _rels/.rels
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>
=== test1.xlsx xl/_rels/workbook.xml.rels
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet3.xml"/><Relationship Id="rId7" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/><Relationship Id="rId6" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/><Relationship Id="rId5" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="theme/theme1.xml"/><Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet4.xml"/></Relationships>
=== test1.xlsx xl/sharedStrings.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="26" uniqueCount="18"><si><t>A</t></si><si><t>B</t></si><si><t>C</t></si><si><t>D</t></si><si><t>col</t><phoneticPr fontId="0" type="noConversion"/></si><si><t>we</t><phoneticPr fontId="0" type="noConversion"/></si><si><t>should</t><phoneticPr fontId="0" type="noConversion"/></si><si><t>ignore</t><phoneticPr fontId="0" type="noConversion"/></si><si><t>E</t></si><si><t>F</t></si><si><t>col1</t></si><si><t>col2</t></si><si><t>i1</t></si><si><t>a</t></si><si><t>x</t></si><si><t>i2</t></si><si><t>b</t></si><si><t>y</t></si></sst>
=== test1.xlsx xl/workbook.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x15 xr xr6 xr10 xr2" xmlns:x15="http://schemas.microsoft.com/office/spreadsheetml/2010/11/main" xmlns:xr="http://schemas.microsoft.com/office/spreadsheetml/2014/revision" xmlns:xr6="http://schemas.microsoft.com/office/spreadsheetml/2016/revision6" xmlns:xr10="http://schemas.microsoft.com/office/spreadsheetml/2016/revision10" xmlns:xr2="http://schemas.microsoft.com/office/spreadsheetml/2015/revision2"><fileVersion appName="xl" lastEdited="7" lowestEdited="7" rupBuild="10609"/><workbookPr defaultThemeVersion="166925"/><mc:AlternateContent xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"><mc:Choice Requires="x15"><x15ac:absPath url="/Users/williamayd/clones/pandas/pandas/tests/io/data/" xmlns:x15ac="http://schemas.microsoft.com/office/spreadsheetml/2010/11/ac"/></mc:Choice></mc:AlternateContent><xr:revisionPtr revIDLastSave="0" documentId="8_{531BDF74-4C20-AC4F-B21A-F90470D62DAB}" xr6:coauthVersionLast="43" xr6:coauthVersionMax="43" xr10:uidLastSave="{00000000-0000-0000-0000-000000000000}"/><bookViews><workbookView xWindow="1760" yWindow="760" windowWidth="27640" windowHeight="16060" xr2:uid="{83D80846-740D-F245-84E4-070D53ACA2AD}"/></bookViews><sheets><sheet name="Sheet1" sheetId="1" r:id="rId1"/><sheet name="Sheet2" sheetId="2" r:id="rId2"/><sheet name="Sheet3" sheetId="3" r:id="rId3"/><sheet name="Sheet4" sheetId="4" r:id="rId4"/></sheets><calcPr calcId="181029" concurrentCalc="0"/><extLst><ext uri="{140A7094-0E35-4892-8432-C4D2E57EDEB5}" xmlns:x15="http://schemas.microsoft.com/office/spreadsheetml/2010/11/main"><x15:workbookPr chartTrackingRefBase="1"/></ext><ext uri="{B58B0392-4F1F-4190-BB64-5DF3571DCE5F}" xmlns:xcalcf="http://schemas.microsoft.com/office/spreadsheetml/2018/calcfeatures"><xcalcf:calcFeatures><xcalcf:feature name="microsoft.com:RD"/><xcalcf:feature name="microsoft.com:FV"/></xcalcf:calcFeatures></ext></extLst></workbook>
=== test1.xlsx xl/worksheets/sheet1.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac xr xr2 xr3" xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac" xmlns:xr="http://schemas.microsoft.com/office/spreadsheetml/2014/revision" xmlns:xr2="http://schemas.microsoft.com/office/spreadsheetml/2015/revision2" xmlns:xr3="http://schemas.microsoft.com/office/spreadsheetml/2016/revision3" xr:uid="{CCFCA61B-52C3-834A-BF4F-09112C347348}"><dimension ref="A1:E8"/><sheetViews><sheetView tabSelected="1" workbookViewId="0"><selection activeCell="B10" sqref="B10"/></sheetView></sheetViews><sheetFormatPr baseColWidth="10" defaultRowHeight="16" x14ac:dyDescent="0.2"/><cols><col min="1" max="1" width="11.83203125" bestFit="1" customWidth="1"/></cols><sheetData><row r="1" spans="1:5" x14ac:dyDescent="0.2"><c r="B1" t="s"><v>0</v></c><c r="C1" t="s"><v>1</v></c><c r="D1" t="s"><v>2</v></c><c r="E1" t="s"><v>3</v></c></row><row r="2" spans="1:5" x14ac:dyDescent="0.2"><c r="A2" s="1"><v>36528</v></c><c r="B2"><v>0.98026851377699997</v></c><c r="C2"><v>3.6857308790599999</v></c><c r="D2"><v>-0.36421680529799999</v></c><c r="E2"><v>-1.1597380616899999</v></c></row><row r="3" spans="1:5" x14ac:dyDescent="0.2"><c r="A3" s="1"><v>36529</v></c><c r="B3"><v>1.04791624281</v></c><c r="C3"><v>-4.1231836701099998E-2</v></c><c r="D3"><v>-0.16181208307</v></c><c r="E3"><v>0.212549316967</v></c></row><row r="4" spans="1:5" x14ac:dyDescent="0.2"><c r="A4" s="1"><v>36530</v></c><c r="B4"><v>0.49858088570499998</v></c><c r="C4"><v>0.73116767781500003</v></c><c r="D4"><v>-0.53767722331800005</v></c><c r="E4"><v>1.3462704195199999</v></c></row><row r="5" spans="1:5" x14ac:dyDescent="0.2"><c r="A5" s="1"><v>36531</v></c><c r="B5"><v>1.1202015186900001</v></c><c r="C5"><v>1.56762092543</v></c><c r="D5"><v>3.64077397681E-3</v></c><c r="E5"><v>0.67525259227000001</v></c></row><row r="6" spans="1:5" x14ac:dyDescent="0.2"><c r="A6" s="1"><v>36532</v></c><c r="B6"><v>-0.48709439946299998</v></c><c r="C6"><v>0.571454623474</v></c><c r="D6"><v>-1.6116394092999999</v></c><c r="E6"><v>0.103468562917</v></c></row><row r="7" spans="1:5" x14ac:dyDescent="0.2"><c r="A7" s="1"><v>36535</v></c><c r="B7"><v>0.83664867166599999</v></c><c r="C7"><v>0.24646191864200001</v></c><c r="D7"><v>0.58854263537600005</v></c><c r="E7"><v>1.0627820613000001</v></c></row><row r="8" spans="1:5" x14ac:dyDescent="0.2"><c r="A8" s="1"><v>36536</v></c><c r="B8"><v>-0.157160753327</v></c><c r="C8"><v>1.3403068943800001</v></c><c r="D8"><v>1.1957779562199999</v></c><c r="E8"><v>-1.0970069975100001</v></c></row></sheetData><pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/></worksheet>
=== test1.xlsx xl/worksheets/sheet2.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac xr xr2 xr3" xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac" xmlns:xr="http://schemas.microsoft.com/office/spreadsheetml/2014/revision" xmlns:xr2="http://schemas.microsoft.com/office/spreadsheetml/2015/revision2" xmlns:xr3="http://schemas.microsoft.com/office/spreadsheetml/2016/revision3" xr:uid="{B48E2057-3592-C44A-86EF-7E23838A9FFC}"><dimension ref="A1:E9"/><sheetViews><sheetView workbookViewId="0"><selection sqref="A1:E9"/></sheetView></sheetViews><sheetFormatPr baseColWidth="10" defaultRowHeight="16" x14ac:dyDescent="0.2"/><sheetData><row r="1" spans="1:5" x14ac:dyDescent="0.2"><c r="B1" t="s"><v>0</v></c><c r="C1" t="s"><v>1</v></c><c r="D1" t="s"><v>2</v></c><c r="E1" t="s"><v>3</v></c></row><row r="2" spans="1:5" x14ac:dyDescent="0.2"><c r="B2" t="s"><v>4</v></c><c r="C2" t="s"><v>5</v></c><c r="D2" t="s"><v>6</v></c><c r="E2" t="s"><v>7</v></c></row><row r="3" spans="1:5" x14ac:dyDescent="0.2"><c r="A3" s="1"><v>36528</v></c><c r="B3"><v>0.98026851377699997</v></c><c r="C3"><v>3.6857308790599999</v></c><c r="D3"><v>-0.36421680529799999</v></c><c r="E3"><v>-1.1597380616899999</v></c></row><row r="4" spans="1:5" x14ac:dyDescent="0.2"><c r="A4" s="1"><v>36529</v></c><c r="B4"><v>1.04791624281</v></c><c r="C4"><v>-4.1231836701099998E-2</v></c><c r="D4"><v>-0.16181208307</v></c><c r="E4"><v>0.212549316967</v></c></row><row r="5" spans="1:5" x14ac:dyDescent="0.2"><c r="A5" s="1"><v>36530</v></c><c r="B5"><v>0.49858088570499998</v></c><c r="C5"><v>0.73116767781500003</v></c><c r="D5"><v>-0.53767722331800005</v></c><c r="E5"><v>1.3462704195199999</v></c></row><row r="6" spans="1:5" x14ac:dyDescent="0.2"><c r="A6" s="1"><v>36531</v></c><c r="B6"><v>1.1202015186900001</v></c><c r="C6"><v>1.56762092543</v></c><c r="D6"><v>3.64077397681E-3</v></c><c r="E6"><v>0.67525259227000001</v></c></row><row r="7" spans="1:5" x14ac:dyDescent="0.2"><c r="A7" s="1"><v>36532</v></c><c r="B7"><v>-0.48709439946299998</v></c><c r="C7"><v>0.571454623474</v></c><c r="D7"><v>-1.6116394092999999</v></c><c r="E7"><v>0.103468562917</v></c></row><row r="8" spans="1:5" x14ac:dyDescent="0.2"><c r="A8" s="1"><v>36535</v></c><c r="B8"><v>0.83664867166599999</v></c><c r="C8"><v>0.24646191864200001</v></c><c r="D8"><v>0.58854263537600005</v></c><c r="E8"><v>1.0627820613000001</v></c></row><row r="9" spans="1:5" x14ac:dyDescent="0.2"><c r="A9" s="1"><v>36536</v></c><c r="B9"><v>-0.157160753327</v></c><c r="C9"><v>1.3403068943800001</v></c><c r="D9"><v>1.1957779562199999</v></c><c r="E9"><v>-1.0970069975100001</v></c></row></sheetData><pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/></worksheet>
=== test1.xlsx xl/worksheets/sheet3.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac xr xr2 xr3" xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac" xmlns:xr="http://schemas.microsoft.com/office/spreadsheetml/2014/revision" xmlns:xr2="http://schemas.microsoft.com/office/spreadsheetml/2015/revision2" xmlns:xr3="http://schemas.microsoft.com/office/spreadsheetml/2016/revision3" xr:uid="{0B151EF2-7DAF-3542-B021-F4540923EAFF}"><dimension ref="A1:F1"/><sheetViews><sheetView workbookViewId="0"><selection sqref="A1:F1"/></sheetView></sheetViews><sheetFormatPr baseColWidth="10" defaultRowHeight="16" x14ac:dyDescent="0.2"/><sheetData><row r="1" spans="1:6" x14ac:dyDescent="0.2"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c><c r="C1" t="s"><v>2</v></c><c r="D1" t="s"><v>3</v></c><c r="E1" t="s"><v>8</v></c><c r="F1" t="s"><v>9</v></c></row></sheetData><pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/></worksheet>
=== test1.xlsx xl/worksheets/sheet4.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" mc:Ignorable="x14ac xr xr2 xr3" xmlns:x14ac="http://schemas.microsoft.com/office/spreadsheetml/2009/9/ac" xmlns:xr="http://schemas.microsoft.com/office/spreadsheetml/2014/revision" xmlns:xr2="http://schemas.microsoft.com/office/spreadsheetml/2015/revision2" xmlns:xr3="http://schemas.microsoft.com/office/spreadsheetml/2016/revision3" xr:uid="{5B305A25-F2CC-5E4E-B3AD-49DEDB1C3E16}"><dimension ref="A1:C3"/><sheetViews><sheetView workbookViewId="0"><selection activeCell="C14" sqref="C14"/></sheetView></sheetViews><sheetFormatPr baseColWidth="10" defaultRowHeight="16" x14ac:dyDescent="0.2"/><sheetData><row r="1" spans="1:3" x14ac:dyDescent="0.2"><c r="B1" s="2" t="s"><v>10</v></c><c r="C1" s="2" t="s"><v>11</v></c></row><row r="2" spans="1:3" x14ac:dyDescent="0.2"><c r="A2" s="2" t="s"><v>12</v></c><c r="B2" t="s"><v>13</v></c><c r="C2" t="s"><v>14</v></c></row><row r="3" spans="1:3" x14ac:dyDescent="0.2"><c r="A3" s="2" t="s"><v>15</v></c><c r="B3" t="s"><v>16</v></c><c r="C3" t="s"><v>17</v></c></row></sheetData><pageMargins left="0.7" right="0.7" top="0.75" bottom="0.75" header="0.3" footer="0.3"/></worksheet>
=== test_decimal.ods content.xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<office:document-content xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:of="urn:oasis:names:tc:opendocument:xmlns:of:1.2" office:version="1.3"><office:body><office:spreadsheet><table:calculation-settings table:case-sensitive="false" table:search-criteria-must-apply-to-whole-cell="true" table:use-wildcards="true" table:use-regular-expressions="false" table:automatic-find-labels="false"/><table:table table:name="test_decimal" table:style-name="ta1"><table:table-column table:style-name="co1" table:number-columns-repeated="2" table:default-cell-style-name="ce1"/><table:table-column table:style-name="co2" table:default-cell-style-name="ce1"/><table:table-column table:style-name="co1" table:number-columns-repeated="2" table:default-cell-style-name="ce1"/><table:table-column table:style-name="co2" table:default-cell-style-name="ce1"/><table:table-column table:style-name="co3" table:number-columns-repeated="16378" table:default-cell-style-name="ce1"/><table:table-row table:style-name="ro1"><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>Column1</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>Column2</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>Column3</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>Column4</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>Column5</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce1"><text:p>Column6</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16378"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>Id</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>Number1</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>Number2</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>Text1</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>Text2</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>Number3</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16378"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>1</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>1521,1541</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>187101,9543</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>ABC</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>poi</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>4,738797819</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16378"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>2</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>121,12</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>14897,76</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>DEF</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>uyt</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>0,377320872</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16378"/></table:table-row><table:table-row table:style-name="ro1"><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>3</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>878,158</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>108013,434</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>GHI</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>rez</text:p></table:table-cell><table:table-cell office:value-type="string" table:style-name="ce2"><text:p>2,735694704</text:p></table:table-cell><table:table-cell table:number-columns-repeated="16378"/></table:table-row><table:table-row table:number-rows-repeated="1048571" table:style-name="ro1"><table:table-cell table:number-columns-repeated="16384"/></table:table-row></table:table><table:database-ranges><table:database-range table:target-range-address="test_decimal.A1:test_decimal.F5" table:name="test_decimal" table:display-filter-buttons="true" table:on-update-keep-size="false" table:on-update-keep-styles="true" table:refresh-delay="false"><table:database-source-sql table:database-name="Provider=Microsoft.Mashup.OleDb.1;Data Source=$Workbook$;Location=test_decimal;Extended Properties=&quot;&quot;" table:sql-statement="SELECT * FROM [test_decimal]"/></table:database-range></table:database-ranges></office:spreadsheet></office:body></office:document-content>
