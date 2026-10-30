#!/usr/bin/env perl

# write_table() of a hash of data frames: an .xlsx workbook of one worksheet
# per key, the keys sorted as a HoH's rows are.
#
# Provenance of the cases taken from elsewhere:
#
# - pandas 3.0.4, pandas/tests/io/excel/test_writers.py:
#   test_creating_and_reading_multiple_sheets (gh-9450) writes sheets "AAA",
#   "BBB" and "CCC", each a frame of one column named for its sheet, holding
#   11, 22 and 33 over the index 1, 2, 3, and reads every sheet back equal; and
#   test_sheets writes "test1" and "test2" and asserts that the workbook holds
#   two sheets, in that order.
# - Excel::Writer::XLSX 1.15, t/workbook/workbook_check_sheetname.t: after a
#   first worksheet "Sheet1", the names 'Sheet1' and 'sheet1' (a duplicate with
#   case ignored), 'Sheet[', 'Sheet]', 'Sheet:', 'Sheet*', 'Sheet/', 'Sheet\'
#   (each holding a character Excel refuses),
#   'name_that_is_longer_than_thirty_one_characters', and "Sheet'", "'Sheet"
#   and "'Sheet'" (an apostrophe at either end) are all refused.  Here the
#   long name is warned about rather than refused, as openpyxl 3.1.5 does
#   (see t/write_table.xlsx.t), and every other one dies.  '?' is in that
#   module's _check_sheetname() pattern though not in its test, and is
#   checked here too.
#
# Everything else -- every shape as a worksheet, the options a workbook shares,
# and the messages -- is this module's own behaviour.

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp qw(tempdir);
use Test::More;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';
use Tie::Hash;
use Stats::LikeR qw(write_table read_table);

my $have_unzip = eval { require IO::Uncompress::Unzip; 1 };
my $dir = tempdir(CLEANUP => 1);
my $seq = 0;
sub path { $seq++; return "$dir/b$seq." . (shift // 'xlsx') }

# A named member of a .xlsx, as bytes (core IO::Uncompress::Unzip).
sub member {
	my ($file, $name) = @_;
	my $z = IO::Uncompress::Unzip->new($file, Name => $name) or return undef;
	my ($out, $buf) = ('', '');
	$out .= $buf while $z->read($buf) > 0;
	$z->close;
	return $out;
}

# The worksheet names, in the order workbook.xml lists them.
sub sheet_names {
	my $wb = member(shift, 'xl/workbook.xml');
	return [ $wb =~ /<sheet name="([^"]*)"/g ];
}

# pandas test_creating_and_reading_multiple_sheets (gh-9450)
{
	my %book = map {
		my $s = $_;
		($s => { 1 => { $s => 11 }, 2 => { $s => 22 }, 3 => { $s => 33 } })
	} qw(AAA BBB CCC);
	my $f = path();
	lives_ok { write_table(\%book, $f, row_names => 'index', quiet => 1) }
		'a hash of three HoH frames is written as a workbook';
	my $back = read_table($f);
	is_deeply( [ sort keys %$back ], [qw(AAA BBB CCC)], 'every sheet reads back, under its name' );
	for my $s (qw(AAA BBB CCC)) {
		is_deeply( $back->{$s},
			[ { index => 1, $s => 11 }, { index => 2, $s => 22 }, { index => 3, $s => 33 } ],
			"sheet $s reads back equal" );
	}
}

# pandas test_sheets: two sheets, in order
SKIP: {
	skip 'IO::Uncompress::Unzip (core) not available', 2 unless $have_unzip;
	my $f = path();
	write_table({ test2 => [ { A => 1 } ], test1 => [ { A => 2 } ] }, $f, quiet => 1);
	is_deeply( sheet_names($f), [qw(test1 test2)], 'the workbook holds two sheets, sorted by name' );
	like( member($f, 'xl/_rels/workbook.xml.rels'),
		qr{Id="rId1"[^>]*Target="worksheets/sheet1\.xml".*Id="rId2"[^>]*Target="worksheets/sheet2\.xml"},
		'each sheet has its own part and relationship' );
}

# Every shape as a worksheet, and an empty one
{
	my %book = (
		aoh   => [ { x => 1, y => 'p' }, { x => 2, y => 'q' } ],
		aoa   => [ [qw(x y)], [3, 'r'] ],
		hoa   => { x => [4, 5], y => [qw(s t)] },
		hoh   => { r1 => { x => 6 }, r2 => { x => 7, y => 'u' } },
		none  => [],
		nada  => {},
	);
	my $f = path();
	my @w;
	{
		local $SIG{__WARN__} = sub { push @w, @_ };
		write_table(\%book, $f, quiet => 1);
	}
	my $back = read_table($f);
	is_deeply( $back->{aoh}, [ { x => 1, y => 'p' }, { x => 2, y => 'q' } ], 'an AoH sheet' );
	is_deeply( $back->{aoa}, [ { x => 3, y => 'r' } ], 'an AoA sheet' );
	is_deeply( $back->{hoa}, [ { x => 4, y => 's' }, { x => 5, y => 't' } ], 'a HoA sheet' );
	is_deeply( $back->{hoh}, [ { row_name => 'r1', x => 6, y => undef }, { row_name => 'r2', x => 7, y => 'u' } ],
		'a HoH sheet keeps its keys, as a HoH file does' );
	is_deeply( $back->{none}, [], 'an empty [] is an empty sheet' );
	is_deeply( $back->{nada}, [], 'an empty {} is an empty sheet' );
	is( scalar @w, 1, 'one warning: the HoH sheet\'s unnamed key column' );
	like( $w[0], qr/^write_table: sheet 'hoh': the row-name column \(column 1\) of '\Q$f\E' has no name/,
		'a warning names the sheet it is about' );
}

# Options apply to every sheet
SKIP: {
	skip 'IO::Uncompress::Unzip (core) not available', 4 unless $have_unzip;
	my $f = path();
	write_table({ A => [ { a => 1, b => undef } ], B => { a => [2], b => [undef] } }, $f,
		col_names => ['b', 'a'], undef_val => 'NA', xlsx_freeze_rows => 1, quiet => 1);
	for my $k (1, 2) {
		my $ws = member($f, "xl/worksheets/sheet$k.xml");
		like( $ws, qr/<pane ySplit="1" topLeftCell="A2"/, "sheet $k is frozen below its header" );
	}
	my $back = read_table($f, na_strings => []);
	is_deeply( $back->{A}, [ { b => 'NA', a => 1 } ], 'col_names and undef_val apply to the first sheet' );
	is_deeply( $back->{B}, [ { b => 'NA', a => 2 } ], 'and to the second' );
}

# A workbook's sheet names come from Latin-1 and UTF-8 keys alike
{
	my $f = path();
	write_table({ "caf\x{e9}" => [ { a => 1 } ], "\x{394}elta" => [ { a => 2 } ] }, $f, quiet => 1);
	my $back = read_table($f);
	# read_table gives a sheet name as the UTF-8 bytes workbook.xml holds
	my @want = ("caf\x{e9}", "\x{394}elta");
	utf8::encode($_) for @want;
	is_deeply( [ sort keys %$back ], [ sort @want ], 'non-ASCII sheet names are written as UTF-8' );
}

# A tied workbook hash, and tied sheets in it
{
	tie my %book, 'Tie::StdHash';
	tie my %hoa, 'Tie::StdHash';
	%hoa = (a => [1, 2]);
	%book = (T => \%hoa, P => [ { a => 3 } ]);
	my $f = path();
	write_table(\%book, $f, quiet => 1);
	my $back = read_table($f);
	is_deeply( $back, { T => [ { a => 1 }, { a => 2 } ], P => [ { a => 3 } ] }, 'a tied workbook and a tied sheet' );
}

# A hash whose values are all empty is still the HoA it was
{
	my $f = path('csv');
	write_table({ a => [], b => [] }, $f, quiet => 1);
	open my $fh, '<', $f or die "cannot read $f: $!";
	is( do { local $/; <$fh> }, "a,b\n", 'a HoA of empty columns writes its header, as before' );
	close $fh;
}

# Excel::Writer::XLSX 1.15 workbook_check_sheetname.t, as a workbook's keys:
# each refused before the file is opened, so an existing file is left intact
{
	my $f = path();
	open my $keep, '>', $f or die "cannot write $f: $!";
	print {$keep} "precious\n";
	close $keep;
	throws_ok { write_table({ Sheet1 => [ { a => 1 } ], sheet1 => [ { a => 2 } ] }, $f) }
		qr/^write_table: worksheet names 'Sheet1' and 'sheet1' are the same with case ignored/,
		'Sheet1 and sheet1 are one name to Excel';
	foreach my $c ('[', ']', ':', '*', '/', '\\', '?') {
		throws_ok { write_table({ "Sheet$c" => [ { a => 1 } ] }, $f) }
			qr/^write_table: worksheet name 'Sheet\Q$c\E' may not contain '\Q$c\E'/, "a sheet named 'Sheet$c' dies";
	}
	foreach my $n (q(Sheet'), q('Sheet), q('Sheet')) {
		throws_ok { write_table({ $n => [ { a => 1 } ] }, $f) }
			qr/^write_table: worksheet name '\Q$n\E' may not start or end with an apostrophe/, "a sheet named $n dies";
	}
	throws_ok { write_table({ '' => [ { a => 1 } ] }, $f) }
		qr/^write_table: 'data' has an empty key, and a worksheet name must have at least one character/,
		'an empty key dies';
	throws_ok { write_table({ "\x{394}" => [ { a => 1 } ], "\x{3B4}" => [ { a => 2 } ] }, $f) }
		qr/are the same with case ignored/, 'case is folded beyond ASCII';
	open $keep, '<', $f or die "cannot read $f: $!";
	is( scalar <$keep>, "precious\n", 'a refused workbook leaves an existing file intact' );
	close $keep;
	my @w;
	{
		local $SIG{__WARN__} = sub { push @w, @_ };
		write_table({ name_that_is_longer_than_thirty_one_characters => [ { a => 1 } ], x => [ { a => 2 } ] },
			path(), quiet => 1);
	}
	is( scalar @w, 1, 'a name longer than 31 characters warns, once' );
	like( $w[0], qr/^write_table: worksheet name 'name_that_is_longer_than_thirty_one_characters' is more than 31 characters/,
		'the warning names it' );
}

# A character XML 1.0 cannot hold is refused in a name.  Up to 0.341 it was
# dropped from workbook.xml after the checks had passed, so "a\x01" beside "a"
# wrote two sheets named "a" and "\x02" one named "", and a surrogate died
# inside lc() with "Operation "lc" returns its argument".
{
	my $f = path();
	my @cases;
	{
		no warnings;    # a surrogate or noncharacter literal is a compile-time warning on 5.10 and 5.12, fatal here
		@cases = (["a\x01", '0001'], ["\x02", '0002'], ["\x1F", '001F'],
		          ['s' . chr(0xD800) . 't', 'D800'], ['x' . chr(0xFFFE) . 'y', 'FFFE'], ['x' . chr(0xFFFF), 'FFFF']);
	}
	for my $case (@cases) {
		my ($n, $u) = @$case;
		throws_ok { write_table({ $n => [ { a => 1 } ], a => [ { a => 2 } ] }, $f) }
			qr/^write_table: worksheet name '.*' may not contain U\+$u, which XML cannot hold/s,
			"a sheet name holding U+$u dies";
		throws_ok { write_table([ { a => 1 } ], $f, xlsx_sheet => $n) }
			qr/\nwrite_table: error: 'xlsx_sheet' may not contain U\+$u, which XML cannot hold/,
			"an xlsx_sheet holding U+$u dies";
	}
	ok( !-e $f, 'none of them wrote the file' );
	# Excel counts a sheet name's 31 in UTF-16 code units, so a character past
	# U+FFFF counts two: 15 emoji are 30 units and fit, 16 are 32 and do not.
	# Up to 0.341 code points were counted, and 16 passed.
	for my $case ([15, 0], [16, 1]) {
		my ($k, $warns) = @$case;
		my @w;
		{
			local $SIG{__WARN__} = sub { push @w, @_ };
			write_table({ "\x{1F600}" x $k => [ { a => 1 } ], b => [ { a => 2 } ] }, path(), quiet => 1);
		}
		is( scalar @w, $warns, "$k characters past U+FFFF " . ($warns ? 'warn' : 'do not warn') . ' as too long' );
	}
}

# write_table() leaves the caller's $@ alone.  Up to 0.341 an .xlsx write
# cleared it, through the evals of _xlsx_provenance() and, on the first .tex or
# .xlsx write of a program, those Cwd.pm runs as it loads.  Cwd is in by now
# (File::Temp loads it), so the second is checked only by hand.
for my $ext (qw(xlsx tex)) {
	eval { die "boom\n" };
	write_table([ { a => 1 } ], path($ext), quiet => 1);
	is( $@, "boom\n", "a .$ext write_table() keeps \$@" );
}

# A login name that is UTF-8 bytes, as getpwuid() returns one in a UTF-8
# locale, is read as UTF-8.  Up to 0.341 it was taken for Latin-1, and "josé"
# was written into dc:creator and dc:description as "JosÃ©".
SKIP: {
	skip 'IO::Uncompress::Unzip is not available', 2 unless $have_unzip;
	no warnings 'redefine';
	local *Stats::LikeR::_xlsx_provenance = sub { ("jos\xc3\xa9", "user: jos\xc3\xa9") };
	my $f = path();
	write_table([ { a => 1 } ], $f, quiet => 1);
	my $core = member($f, 'docProps/core.xml');
	like( $core, qr{<dc:creator>jos\xc3\xa9</dc:creator>}, 'a UTF-8 login name is the author as UTF-8' );
	like( $core, qr{\nuser: jos\xc3\xa9</dc:description>}, 'and in the comments as UTF-8' );
}

# xlsx_sheet is checked the same way for a single table
throws_ok { write_table([ { a => 1 } ], path(), xlsx_sheet => q('Sheet)) }
	qr/\nwrite_table: error: 'xlsx_sheet' may not start or end with an apostrophe/,
	'an xlsx_sheet starting with an apostrophe dies';

# Refusals
{
	my $book = { A => [ { a => 1 } ], B => [ { a => 2 } ] };
	throws_ok { write_table($book, path('csv')) }
		qr/^write_table: 'data' is a hash of data frames, which is written as a workbook .* only to an \.xlsx file/,
		'a workbook is refused for a delimited file';
	throws_ok { write_table($book, path('tex')) }
		qr/only to an \.xlsx file/, 'and for LaTeX';
	throws_ok { write_table($book, path(), xlsx_sheet => 'X') }
		qr/\nwrite_table: error: 'xlsx_sheet' names the worksheet of a single table/,
		'xlsx_sheet has nothing to name in a workbook';
	throws_ok { write_table({ A => [ { a => 1 } ], b => [1, 2] }, path()) }
		qr/^write_table: the value of 'A' is a data frame, which makes 'data' a workbook of one worksheet per key, but the value of 'b' is not a data frame/,
		'a column beside a frame is refused, naming both keys';
	throws_ok { write_table({ A => [ { a => 1 } ], s => 'x' }, path()) }
		qr/but the value of 's' is not a data frame/, 'so is a scalar beside a frame';
	throws_ok { write_table({ A => [ { a => 1 } ], B => [ { a => [1] } ] }, path()) }
		qr/^write_table: sheet 'B': Cannot write nested reference types to table/,
		'a nested reference names the sheet it is in';
	throws_ok { write_table({ A => [ { a => 1 } ], B => [ { a => 1 }, [2] ] }, path()) }
		qr/^write_table: sheet 'B': Mixed data types detected in Array of Hashes/,
		'a malformed sheet is refused, naming it';
}

# One announcement for the workbook.  It goes to fd 1 through PerlIO_stdout(),
# which a perl-level STDOUT redirect does not see, so a child perl prints it
# (as in t/write_table.announce.t), with the file name in @ARGV.
{
	my $f = path();
	my $script = "$dir/announce.pl";
	open my $sfh, '>', $script or die "cannot write $script: $!";
	print {$sfh} "use Stats::LikeR; write_table({ A => [ { a => 1 } ], B => [ { a => 2 } ] }, \$ARGV[0]);\n";
	close $sfh or die "cannot write $script: $!";
	my @inc = map { "-I$_" } grep { !ref $_ } @INC;
	open my $ph, '-|', $^X, @inc, $script, $f or die "cannot run a child perl: $!";
	my $out = do { local $/; <$ph> };
	close $ph;
	is( $out, "wrote \033[30;46m$f\033[0m\n", 'a workbook is announced once, as one file' );
}

# Down a pipe, each worksheet is gathered in memory, and the workbook comes out
# byte for byte the one written to a file (see t/write_table.xlsx.t)
SKIP: {
	skip 'needs /dev/stdout and a list-form pipe open', 1 if $^O eq 'MSWin32' || !-e '/dev/stdout';
	my $script = "$dir/pipe.pl";
	open my $sfh, '>', $script or die "cannot write $script: $!";
	print {$sfh} 'use Stats::LikeR; my %b = (A => [ map { +{ id => $_, v => $_ / 7 } } 1 .. 3000 ], B => { x => [1 .. 9] }, C => []);',
		" write_table(\\\%b, \$ARGV[0], xlsx => 1, quiet => 1, xlsx_freeze_rows => 1);",
		" write_table(\\\%b, '/dev/stdout', xlsx => 1, quiet => 1, xlsx_freeze_rows => 1);\n";
	close $sfh or die "cannot write $script: $!";
	my $to_file = "$dir/piped_book.xlsx";
	my @inc = map { "-I$_" } grep { !ref $_ } @INC;
	open my $ph, '-|', $^X, @inc, $script, $to_file or die "cannot run a child perl: $!";
	binmode $ph;
	my $piped = do { local $/; <$ph> };
	close $ph;
	open my $ffh, '<', $to_file or die "cannot read $to_file: $!";
	binmode $ffh;
	my $filed = do { local $/; <$ffh> };
	close $ffh;
	ok( length($piped) > 65536 && $piped eq $filed,
		'a workbook written down a pipe is byte for byte the one written to a file' );
}

my $leak_book = { A => [ { a => 1, b => 'x' } ], B => { c => [1, 2] }, C => { r => { d => 3 } }, D => [] };
my $leak_file = path();
no_leaks_ok {
	write_table($leak_book, $leak_file, quiet => 1, row_names => 0, xlsx_freeze_rows => 1);
} 'no leaks: a workbook of every shape';
no_leaks_ok {
	eval { write_table({ A => [ { a => 1 } ], a => [ { a => 2 } ] }, $leak_file) };
	eval { write_table({ A => [ { a => 1 } ], B => [ { a => [1] } ] }, $leak_file) };
	eval { write_table({ A => [ { a => 1 } ], b => [1] }, $leak_file) };
} 'no leaks: the workbook croaks';

done_testing();
