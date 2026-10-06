#!/usr/bin/env perl

# write_table's .xlsx output: characters XML cannot hold, Excel's sheet
# limits, which cells are numbers, the freeze-pane bounds and the ZIP CRCs.
#
# Provenance:
#
# - Escaping follows XlsxWriter 1.3.9, xlsxwriter/sharedstrings.py,
#   _write_si(): a literal _xHHHH_ is escaped as _x005F_xHHHH_ ("escape the
#   escape"), the controls [\x00-\x08\x0B-\x1F] become "_x%04X_", and U+FFFE
#   and U+FFFF become _xFFFE_ and _xFFFF_.  The surrogates U+D800-U+DFFF, which
#   a Python str bound for XML cannot hold but a perl string can, are escaped
#   in the same _xHHHH_ form (ECMA-376 Part 1, 22.9.2.19 ST_Xstring).  Up to
#   0.3213 the controls were dropped and the rest written raw, and openpyxl
#   3.1.5 refused such a workbook as "not well-formed".
# - The literal-escape rule departs from XlsxWriter's on purpose: its
#   non-overlapping s/(_x[0-9a-fA-F]{4}_)/_x005F$1/g writes a literal
#   "_x005F_x0041_" as "_x005F_x005F_x0041_", which a left-to-right decoder
#   (Excel, LibreOffice 24.2, read_table) reads back as "_x005FA".  Every '_'
#   that would open an escape is escaped instead.  The expected bytes for
#   those cases are frozen below, and every written cell is also put through
#   decode(), a left-to-right decoder written the way read_table's
#   xlsx_xstring_unescape() and LibreOffice decode (lower-case x, hex digits
#   of either case, a high surrogate escaped straight before a low one taken
#   as the pair), to check that it reads back as the string written.
# - The limits are Excel's (Microsoft, "Excel specifications and limits"):
#   1048576 rows, 16384 columns, 32767 characters in a cell.  XlsxWriter 1.3.9
#   worksheet.py sets xls_rowmax, xls_colmax and xls_strmax to those, and
#   pandas 3.0.4 tests/io/excel/test_writers.py, test_excel_sheet_size, refuses
#   2**20 + 1 rows and 2**14 + 1 columns ("sheet is too large").  The cases
#   here are that test's, counted as Excel counts: header row included.
# - Number typing: pandas' to_excel() writes a str as a string cell (openpyxl
#   3.1.5 cell/cell.py, Cell._bind_value()), so "007" and a 20-digit ID stay
#   text there; Excel keeps 15 significant digits and holds magnitudes up to
#   9.99999999999999E+307.
# - The CRC-32 check value, 0xCBF43926 for "123456789", is the one every
#   CRC-32/IEEE implementation is checked against (zlib's crc32()).
#
# The remaining cases are regression tests from the reproducers that found
# them: a 16385th column written as XFE, a 40000-character cell written
# whole, xlsx_freeze_rows => 2**32 + 1 freezing one row.

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp;
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use Stats::LikeR qw(write_table);

my $have_unzip = eval { require IO::Uncompress::Unzip; require Compress::Raw::Zlib; 1 };
plan skip_all => 'IO::Uncompress::Unzip and Compress::Raw::Zlib (core) are needed' unless $have_unzip;

my $dir = File::Temp->newdir;
my $seq = 0;
sub xlsx_path { $seq++; return "$dir/t$seq.xlsx" }
sub member {
	my ($file, $name) = @_;
	my $z = IO::Uncompress::Unzip->new($file, Name => $name) or return undef;
	my ($out, $buf) = ('', '');
	$out .= $buf while $z->read($buf) > 0;
	$z->close;
	return $out;
}
sub sheet { member($_[0], 'xl/worksheets/sheet1.xml') }
# the text of a cell decoded left to right, as a reader of the workbook does
sub decode {
	my $t = shift;
	my %ent = (amp => '&', lt => '<', gt => '>', quot => '"', apos => "'");
	$t =~ s/&(amp|lt|gt|quot|apos);/$ent{$1}/g;
	utf8::decode($t);
	my $out = '';
	while ($t =~ /\G(.*?)_x([0-9A-Fa-f]{4})_/gcs) {
		$out .= $1;
		my $cp = hex $2;
		if ($cp >= 0xD800 && $cp <= 0xDBFF && $t =~ /\G_x(D[C-Fc-f][0-9A-Fa-f]{2})_/gc) {
			$cp = 0x10000 + (($cp - 0xD800) << 10) + (hex($1) - 0xDC00);
		}
		no warnings;
		$out .= chr $cp;
	}
	$out .= substr($t, pos($t) // 0);
	return $out;
}
# the <c> element of cell A<row>, as written
sub cell_a {
	my ($xml, $row) = @_;
	return $xml =~ m{(<c r="A$row"[^>]*>.*?</c>)}s ? $1 : undef;
}

# ---- characters XML 1.0 cannot hold (XlsxWriter's _write_si) ----------
{
	my $f = xlsx_path();
	my (@cells, $sheet, $comment);
	{
		no warnings;    # noncharacters and surrogates are warned about, and 5.10 makes it fatal
		$sheet   = "S\x{FFFF}h";
		$comment = "c\x01d\x{FFFE}e";
		@cells = (
			"x\x{FFFF}y\x{FFFE}z",
			"s" . chr(0xD800) . "t" . chr(0xDFFF),
			"a\x00b\x01c\x08d\x0Be\x1Ff",
			"r\rn\ns\tt",
			'_x0041_ and _x00ff_ and _X0041_ and _x00G1_ and _x0041',
		);
	}
	write_table([['t'], map { [$_] } @cells], $f, quiet => 1,
		xlsx_sheet => $sheet, xlsx_comment => $comment);
	my $x = sheet($f);
	my @want = (
		'x_xFFFF_y_xFFFE_z',
		's_xD800_t_xDFFF_',
		'a_x0000_b_x0001_c_x0008_d_x000B_e_x001F_f',
		"r_x000D_n\ns\tt",
		'_x005F_x0041_ and _x005F_x00ff_ and _X0041_ and _x00G1_ and _x0041',
	);
	for my $i (0 .. $#want) {
		is(cell_a($x, $i + 2), qq{<c r="A@{[$i + 2]}" t="inlineStr"><is><t xml:space="preserve">$want[$i]</t></is></c>},
			"escaped as XlsxWriter does: row " . ($i + 2));
		is(decode($want[$i]), $cells[$i], '... and decodes back to the cell: row ' . ($i + 2));
	}
	like(member($f, 'xl/workbook.xml'), qr{<sheet name="Sh"}, 'the sheet name loses U+FFFF (no reader decodes _xHHHH_ there)');
	like(member($f, 'docProps/core.xml'), qr{\ncde</dc:description>}, 'the description loses the control and U+FFFE');
	unlike($x, qr/[\x00-\x08\x0B\x0C\x0E-\x1F]|\xEF\xBF[\xBE\xBF]|\xED[\xA0-\xBF]/,
		'no byte sequence XML 1.0 forbids is left in the worksheet');
}

# ---- escapes that overlap: every '_' that would open one is escaped ----
{
	my @cases;
	{
		no warnings;    # a NUL and a surrogate beside literal escapes
		@cases = (
			['_x005F_x0041_',  '_x005F_x005F_x005F_x0041_', 'an escaped escape, written literally'],
			['__x0041_',       '__x005F_x0041_',            'a doubled underscore: only the second opens one'],
			['_x0041__x0042_', '_x005F_x0041__x005F_x0042_', 'two escapes sharing no underscore'],
			['_x005f_',        '_x005F_x005f_',             'lower-case hex is an escape too'],
			['_x0041_x0042_',  '_x005F_x0041_x005F_x0042_', 'escapes sharing an underscore: each is escaped'],
			['_X0041_',        '_X0041_',                   'an upper-case X is no escape to any reader'],
			["_x0041\x00",     '_x005F_x0041_x0000_',       'a NUL after "_x0041" closes it as an escape would'],
			["_x0041\x{FFFF}", '_x005F_x0041_xFFFF_',       'so does U+FFFF'],
			["_x0041\t",       "_x0041\t",                  'a tab is written as it is, and closes nothing'],
			["\x01x0041_",     '_x0001_x0041_',             'the escape of a control does not open one with the text after it'],
			['_x004_',         '_x004_',                    'three hex digits are no escape'],
			['_xD83D_',        '_x005F_xD83D_',             'a literal surrogate escape'],
			[chr(0xD83D) . '_xDE00_', '_xD83D__x005F_xDE00_', 'a surrogate, then a literal low-surrogate escape'],
		);
	}
	my $f = xlsx_path();
	write_table([['t'], map { [$_->[0]] } @cases], $f, quiet => 1);
	my $x = sheet($f);
	for my $i (0 .. $#cases) {
		my ($in, $want, $name) = @{ $cases[$i] };
		my $r = $i + 2;
		is(cell_a($x, $r), qq{<c r="A$r" t="inlineStr"><is><t xml:space="preserve">$want</t></is></c>}, $name);
		is(decode($want), $in, "... and it decodes back: $name");
	}
}
{
	no warnings;
	my $big = chr(0x110000);
	throws_ok { write_table([['t'], ["a$big"]], xlsx_path(), quiet => 1) }
		qr/^write_table: a cell holds a code point above U\+10FFFF/, 'a code point above U+10FFFF dies';
}

# ---- Excel's limits (pandas' test_excel_sheet_size) -------------------
{
	throws_ok { write_table([[map { "c$_" } 1 .. 2**14 + 1], [1]], xlsx_path(), quiet => 1) }
		qr/^write_table: '.*' would have 16385 columns, more than the 16384 an Excel worksheet holds/,
		'2**14 + 1 columns die';
	my $f = xlsx_path();
	lives_ok { write_table([[map { "c$_" } 1 .. 2**14], [1]], $f, quiet => 1) } '2**14 columns are written';
	like(sheet($f), qr{<c r="XFD1" t="inlineStr">}, '... the last of them in column XFD');
	throws_ok { write_table({ a => [1] }, xlsx_path(), quiet => 1, col_names => [('a') x 2**14], row_names => 1) }
		qr/would have 16385 columns/, 'the label column counts as a column';

	my $one = [0];    # one row shared 2**20 times keeps the table small
	my $kept = xlsx_path();
	write_table([['old']], $kept, quiet => 1);
	my $before = -s $kept;
	throws_ok { write_table([['a'], ($one) x 2**20], $kept, quiet => 1) }
		qr/^write_table: '.*' would have more than the 1048576 rows an Excel worksheet holds, header included/,
		'AoA: a header and 2**20 rows die';
	is(-s $kept, $before, '... before the file is opened');
	throws_ok { write_table([($one) x 2**20], xlsx_path(), quiet => 1, col_names => ['a']) }
		qr/would have more than the 1048576 rows/, 'AoA with col_names: likewise';
	my $h = { a => 0 };
	throws_ok { write_table([($h) x 2**20], xlsx_path(), quiet => 1) }
		qr/would have more than the 1048576 rows/, 'AoH: likewise';
	throws_ok { write_table({ map { ("r$_" => $h) } 1 .. 2**20 }, xlsx_path(), quiet => 1) }
		qr/would have more than the 1048576 rows/, 'HoH: likewise';
  SKIP: {
		skip 'writes two 1048576-row workbooks; set EXTENDED_TESTING', 3
			unless $ENV{EXTENDED_TESTING} || $ENV{AUTHOR_TESTING};
		# a HoA's row count is found as the rows go out
		throws_ok { write_table({ a => [(0) x 2**20] }, xlsx_path(), quiet => 1) }
			qr/would have more than the 1048576 rows/, 'HoA: a header and 2**20 rows die';
		my $full = xlsx_path();
		lives_ok { write_table([['a'], ($one) x (2**20 - 1)], $full, quiet => 1) }
			'a header and 2**20 - 1 rows are written';
		like(sheet($full), qr{<row r="1048576"><c r="A1048576"><v>0</v></c></row></sheetData>}, '... ending at row 1048576');
	}

	my $e = "\x{e9}";
	lives_ok { write_table([['t'], ['x' x 32767]], xlsx_path(), quiet => 1) } 'a cell of 32767 characters is written';
	throws_ok { write_table([['t'], ['x' x 32768]], xlsx_path(), quiet => 1) }
		qr/^write_table: a cell in row 2 of '.*' has more than the 32767 characters an Excel cell holds/,
		'a cell of 32768 characters dies';
	my $u = $e x 32767;
	utf8::upgrade($u);    # 65534 bytes, 32767 characters
	lives_ok { write_table([['t'], [$u]], xlsx_path(), quiet => 1) } 'the limit counts characters, not UTF-8 bytes';
}

# ---- freeze-pane bounds ------------------------------------------------
{
	my $f = xlsx_path();
	lives_ok { write_table([['a'], [1]], $f, quiet => 1, xlsx_freeze_rows => 2**20 - 1, xlsx_freeze_cols => 2**14 - 1) }
		'freezing 1048575 rows and 16383 columns is allowed';
	like(sheet($f), qr{<pane xSplit="16383" ySplit="1048575" topLeftCell="XFD1048576"}, '... and anchored at XFD1048576');
	throws_ok { write_table([['a']], xlsx_path(), quiet => 1, xlsx_freeze_rows => 2**20) }
		qr/^write_table: 'xlsx_freeze_rows' must be a non-negative integer no larger than 1048575/, '2**20 frozen rows die';
	throws_ok { write_table([['a']], xlsx_path(), quiet => 1, xlsx_freeze_cols => 2**14) }
		qr/^write_table: 'xlsx_freeze_cols' must be a non-negative integer no larger than 16383/, '2**14 frozen columns die';
	throws_ok { write_table([['a']], xlsx_path(), quiet => 1, xlsx_freeze_rows => 2**32 + 1) }
		qr/'xlsx_freeze_rows' must be a non-negative integer no larger than 1048575/,
		'2**32 + 1 dies, rather than wrapping to 1';
	throws_ok { write_table([['a']], xlsx_path(), quiet => 1, xlsx_freeze_cols => 1e300) }
		qr/'xlsx_freeze_cols' must be a non-negative integer no larger than 16383/, '1e300 dies';
}

# ---- which cells are numbers -------------------------------------------
{
	# [text, 1 = a <v> number, 0 = an inline string]
	my @strings = (
		['0', 1], ['-0', 1], ['42', 1], ['-42', 1], ['0.5', 1], ['-0.5', 1], ['0.', 1],
		['5.', 1], ['.5', 1], ['1e3', 1], ['1E-3', 1], ['2.5e+10', 1],
		['123456789012345', 1], ['1234567890.12345', 1], ['0.000123456789012345', 1],
		['9.99999999999999e307', 1], ['1e-307', 1], ['0e999', 1],
		['007', 0], ['00', 0], ['-007', 0], ['00.5', 0], ['+5', 0], ['1234567890123456', 0],
		['12345678901234567890', 0], ['1.234567890123456', 0], ['1e308', 0], ['1e400', 0],
		['1e-308', 0], ['1e-400', 0], ['Inf', 0], ['-Inf', 0], ['NaN', 0], ['inf', 0],
		['0x1A', 0], [' 5', 0], ['5 ', 0], ['1_000', 0], ['.', 0], ['-', 0], ['e5', 0],
		['1e', 0], ['1e+', 0], ['1.2.3', 0], ['--1', 0],
	);
	my $f = xlsx_path();
	write_table([['v'], map { [$_->[0]] } @strings], $f, quiet => 1);
	my $x = sheet($f);
	for my $i (0 .. $#strings) {
		my ($text, $num) = @{ $strings[$i] };
		my $r = $i + 2;
		is(cell_a($x, $r), $num ? qq{<c r="A$r"><v>$text</v></c>}
		                        : qq{<c r="A$r" t="inlineStr"><is><t xml:space="preserve">$text</t></is></c>},
			"string '$text' is " . ($num ? 'a number' : 'text'));
	}

	# numbers held as numbers are numbers whatever their digits; Inf and NaN
	# format as text that is not a decimal, and stay text
	my $inf = 9**9**9;
	my $nan = $inf - $inf;
	my @held = (
		[12345678901234567890, 1, 'a 20-digit number held as a number'],
		[2**60, 1, '2**60'],
		[-1e-300, 1, '-1e-300'],
		[0.1 + 0.2, 1, '0.1 + 0.2'],
		[7, 1, '7'],
		[$inf, 0, 'Inf'],
		[-$inf, 0, '-Inf'],
		[$nan, 0, 'NaN'],
	);
	$f = xlsx_path();
	write_table([['v'], map { [$_->[0]] } @held], $f, quiet => 1);
	$x = sheet($f);
	for my $i (0 .. $#held) {
		my $r = $i + 2;
		my $c = cell_a($x, $r);
		if ($held[$i][1]) { like($c, qr{^<c r="A$r"><v>[-0-9.e+]+</v></c>$}, "$held[$i][2] is a number") }
		else              { like($c, qr{^<c r="A$r" t="inlineStr">}, "$held[$i][2] is text") }
	}
	# a number that has been printed is a string to perls before 5.36, which
	# cannot tell it from one; the digits then decide
	my $printed = 7;
	my $s = "$printed";
	$f = xlsx_path();
	write_table([['v'], [$printed]], $f, quiet => 1);
	is(cell_a(sheet($f), 2), '<c r="A2"><v>7</v></c>', 'a printed small number is a number either way');
}

# ---- every member's CRC-32 is right -----------------------------------
{
	is(sprintf('%08X', Compress::Raw::Zlib::crc32('123456789')), 'CBF43926', 'the reference CRC-32 check value');
	my $f = xlsx_path();
	# three 30000-byte cells: the worksheet goes out in more than one 64 KB chunk
	write_table([['a', 'b'], ["x\x{e9}", 1], map { [('y' x 30000), $_] } 1 .. 3], $f, quiet => 1);
	open my $fh, '<:raw', $f or die "cannot read $f: $!";
	my $zip = do { local $/; <$fh> };
	my $checked = 0;
	# each central-directory record: signature, ..., CRC at +16, name length at +28, name at +46
	while ($zip =~ /PK\x01\x02/g) {
		my $at = pos($zip) - 4;
		my $crc = unpack 'V', substr($zip, $at + 16, 4);
		my $nlen = unpack 'v', substr($zip, $at + 28, 2);
		my $name = substr($zip, $at + 46, $nlen);
		is(sprintf('%08X', $crc), sprintf('%08X', Compress::Raw::Zlib::crc32(member($f, $name))),
			"the CRC recorded for $name is the CRC of its bytes");
		$checked++;
	}
	is($checked, 6, 'all six members were checked');
}

# ---- leaks -------------------------------------------------------------
my @leak_rows = (['t'], ["a\x01_x0041_"], ['007'], [42]);
no_leaks_ok {
	my $f = xlsx_path();
	eval { write_table(\@leak_rows, $f, quiet => 1) };
} 'no leaks: escapes and number typing' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { write_table([[map { "c$_" } 1 .. 2**14 + 1]], xlsx_path(), quiet => 1) };
	eval { write_table([['t'], ['x' x 32768]], xlsx_path(), quiet => 1) };
	eval { write_table([['a']], xlsx_path(), quiet => 1, xlsx_freeze_rows => 2**20) };
} 'no leaks: the limit croaks' unless $INC{'Devel/Cover.pm'};

done_testing();
