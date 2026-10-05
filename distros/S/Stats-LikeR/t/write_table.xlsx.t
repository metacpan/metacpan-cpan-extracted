#!/usr/bin/env perl

require 5.010;
use strict;
use warnings;
use File::Temp;
use Stats::LikeR;
use Test::More;
use Test::Exception;

# write_table's .xlsx output is built entirely in XS (no CPAN deps): the table
# is packed into a STORED ZIP of hand-written XML parts, and the provenance line
# is stored in the workbook's document "comments" property (dc:description in
# docProps/core.xml). We verify it two ways: by reading the workbook back with
# read_table (which is itself dependency-free), and by pulling docProps/core.xml
# out with the core IO::Uncompress::Unzip to inspect the properties.

my $have_unzip = eval { require IO::Uncompress::Unzip; 1 };

my $dir = File::Temp->newdir;
my $seq = 0;
sub xlsx_path { $seq++; return "$dir/t$seq.xlsx" }

# Pull a named member out of a .xlsx as a byte string (core module).
sub member {
	my ($file, $name) = @_;
	my $z = IO::Uncompress::Unzip->new($file, Name => $name) or return undef;
	my ($out, $buf) = ('', '');
	$out .= $buf while $z->read($buf) > 0;
	$z->close;
	return $out;
}

# round-trip an Array of Hashes
{
	my @aoh = (
		{ name => 'Mazda RX4',  mpg => 21.0, cyl => 6,     note => 'A & B <ok>' },
		{ name => 'Datsun 710', mpg => 22.8, cyl => 4,     note => ''           },
		{ name => 'Hornet',     mpg => 21.4, cyl => undef, note => q{q"x}       },
	);
	my $f = xlsx_path();
	lives_ok { write_table(\@aoh, $f, 'row_names' => 0) }
		'write_table writes an .xlsx from an AoH';
	ok( -s $f, 'the .xlsx file exists and is non-empty' );

	my $back = read_table($f);
	is( ref $back, 'ARRAY', 'read_table returns the single worksheet as a table' );
	is( scalar @$back, 3, 'all three data rows survive the round-trip' );
	is( $back->[0]{name}, 'Mazda RX4', 'string cell round-trips' );
	is( $back->[0]{mpg},  '21',        'numeric cell round-trips (stored as a number)' );
	is( $back->[0]{note}, 'A & B <ok>','XML metacharacters are escaped and decoded back' );
	is( $back->[1]{note}, undef,       'empty string round-trips as undef' );
	is( $back->[2]{cyl},  undef,       'undef cell round-trips as undef' );
	is( $back->[2]{note}, 'q"x',       'embedded double quote round-trips' );
}

# HoH: the outer keys are written by default, under the row_names name if given
{
	my %taxa = (
		'9606'  => { species => 'Homo sapiens' },
		'10090' => { species => 'Mus musculus' },
	);
	my $f = xlsx_path();
	write_table(\%taxa, $f, 'row_names' => 'taxid', quiet => 1);
	my $back = read_table($f);
	is_deeply( [ map { $_->{taxid} } @$back ], [ '10090', '9606' ],
		"HoH + row_names=>'taxid': the keys come back as a taxid column" );
	is( $back->[1]{species}, 'Homo sapiens', 'HoH + row_names: keys stay aligned with their rows' );

	my $d = xlsx_path();
	write_table(\%taxa, $d, quiet => 1);
	# read_table names an empty leading header cell row_name.
	is_deeply( [ map { $_->{row_name} } @{ read_table($d) } ], [ '10090', '9606' ],
		'HoH default: the keys are written, under an empty header cell' );
}

# numeric detection: leading-zero / non-plain strings stay text
{
	my @aoh = (
		{ id => '007', sci => '1e3', bad => 'Inf', plain => 42 },
	);
	my $f = xlsx_path();
	write_table(\@aoh, $f, 'row_names' => 0);
	my $r = read_table($f)->[0];
	is( $r->{id},    '007', 'leading-zero string is preserved (written as text)' );
	is( $r->{sci},   '1e3', 'scientific-notation numeric string round-trips' );
	is( $r->{bad},   'Inf', '"Inf" is written as text, not an invalid number cell' );
	is( $r->{plain}, '42',  'a plain number round-trips' );
}

# HoA shape, forced on via xlsx => 1 for a non-.xlsx name
{
	my %hoa = ( x => [1, 2, 3], y => [4, 5, 6] );
	my $f = "$dir/forced.dat";
	lives_ok { write_table(\%hoa, $f, xlsx => 1, 'row_names' => 0) }
		'xlsx => 1 forces .xlsx output for a non-.xlsx file name';
	# read_table keys off the .xlsx extension, so this .dat file can't be routed
	# through the xlsx reader by name; confirm instead that it is a real .xlsx
	# ZIP by pulling its worksheet part out directly.
	SKIP: {
		skip 'IO::Uncompress::Unzip not available', 1 unless $have_unzip;
		ok( defined member($f, 'xl/worksheets/sheet1.xml'),
			'the forced-on file is a valid .xlsx ZIP with a worksheet' );
	}
}

# provenance lands in the document "comments" property
SKIP: {
	skip 'IO::Uncompress::Unzip (core) not available', 4 unless $have_unzip;

	my $f = xlsx_path();
	write_table([{ a => 1, b => 2 }], $f, 'row_names' => 0,
		'xlsx_sheet' => 'Results', 'xlsx_comment' => 'batch 9');

	my $core = member($f, 'docProps/core.xml');
	ok( defined $core, 'docProps/core.xml is present' );
	like( $core, qr{<dc:description>written by }s,
		'the provenance line is stored as the document comments (dc:description)' );
	like( $core, qr{batch 9}s,
		'a user-supplied xlsx_comment is appended after the provenance' );

	my $wb = member($f, 'xl/workbook.xml');
	like( $wb, qr{name="Results"}, 'xlsx_sheet sets the worksheet name' );
}

# freeze panes
SKIP: {
	skip 'IO::Uncompress::Unzip (core) not available', 8 unless $have_unzip;

	my @aoh = map { { a => $_, b => $_ * 2, c => $_ * 3 } } 1 .. 5;

	# freezing the top row: xSplit absent, ySplit=1, anchor A2
	my $f1 = xlsx_path();
	write_table(\@aoh, $f1, 'row_names' => 0, 'xlsx_freeze_rows' => 1);
	my $ws1 = member($f1, 'xl/worksheets/sheet1.xml');
	like( $ws1, qr{<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>},
		'freeze.rows => 1 writes a top-row frozen pane anchored at A2' );
	is( read_table($f1)->[0]{a}, '1', 'data still round-trips with a frozen row' );

	# freezing rows and columns: xSplit=2, ySplit=1, anchor C2, bottomRight
	my $f2 = xlsx_path();
	write_table(\@aoh, $f2, 'row_names' => 0,
		'xlsx_freeze_rows' => 1, 'xlsx_freeze_cols' => 2);
	like( member($f2, 'xl/worksheets/sheet1.xml'),
		qr{<pane xSplit="2" ySplit="1" topLeftCell="C2" activePane="bottomRight" state="frozen"/>},
		'freeze.rows + freeze.cols writes a bottomRight pane anchored at C2' );

	# freezing only columns: xSplit=1, ySplit absent, anchor B1, topRight
	my $f3 = xlsx_path();
	write_table(\@aoh, $f3, 'row_names' => 0, 'xlsx_freeze_cols' => 1);
	like( member($f3, 'xl/worksheets/sheet1.xml'),
		qr{<pane xSplit="1" topLeftCell="B1" activePane="topRight" state="frozen"/>},
		'freeze.cols => 1 writes a left-column frozen pane anchored at B1' );

	# no freeze options: no <sheetViews> block at all
	my $f0 = xlsx_path();
	write_table(\@aoh, $f0, 'row_names' => 0);
	unlike( member($f0, 'xl/worksheets/sheet1.xml'), qr{<sheetViews>},
		'no freeze options leaves the worksheet without a <sheetViews> block' );

	throws_ok { write_table(\@aoh, xlsx_path(), 'xlsx_freeze_rows' => -1) }
		qr/'xlsx_freeze_rows' must be a non-negative integer/,
		'a negative freeze count dies with a clear message';
	throws_ok { write_table(\@aoh, xlsx_path(), 'xlsx_freeze_cols' => -3) }
		qr/'xlsx_freeze_cols' must be a non-negative integer/,
		'a negative freeze column count dies too';
}

# The worksheet name is checked as openpyxl 3.1.5 checks one (the title setter
# in openpyxl/workbook/child.py): empty, or holding any of \ * ? : / [ ], is an
# error; longer than 31 characters is a warning, "Some applications may not be
# able to read the file".  Each is checked before the file is opened.
{
	my $f = xlsx_path();
	open my $keep, '>', $f or die "cannot write $f: $!";
	print {$keep} "precious\n";
	close $keep;
	throws_ok { write_table([{ a => 1 }], $f, 'xlsx_sheet' => '') }
		qr/^write_table: 'xlsx_sheet' must have at least one character/, 'an empty sheet name dies';
	foreach my $c ('\\', '*', '?', ':', '/', '[', ']') {
		throws_ok { write_table([{ a => 1 }], $f, 'xlsx_sheet' => "a${c}b") }
			qr/^write_table: 'xlsx_sheet' may not contain '\Q$c\E'/, "a sheet name holding '$c' dies";
	}
	open $keep, '<', $f or die "cannot read $f: $!";
	is( scalar <$keep>, "precious\n", 'a refused sheet name leaves an existing file intact' );
	close $keep;
	my @w;
	{
		local $SIG{__WARN__} = sub { push @w, @_ };
		write_table([{ a => 1 }], xlsx_path(), 'xlsx_sheet' => 'x' x 31, quiet => 1);
	}
	is( scalar @w, 0, 'a 31-character sheet name is fine' );
	{
		local $SIG{__WARN__} = sub { push @w, @_ };
		write_table([{ a => 1 }], xlsx_path(), 'xlsx_sheet' => 'x' x 32, quiet => 1);
		write_table([{ a => 1 }], xlsx_path(), 'xlsx_sheet' => "\x{394}" x 31, quiet => 1);
	}
	is( scalar @w, 1, 'a 32-character name warns; 31 wide characters do not' );
	like( $w[0], qr/^write_table: 'xlsx_sheet' is more than 31 characters/, 'the warning says why' );
}

# The worksheet is streamed, a chunk at a time, and its local header patched
# once the size is known; a file that cannot seek, such as a pipe, gets the
# worksheet gathered in memory instead.  Both have to make the same bytes, and
# a table spanning many chunks has to read back whole.
{
	my @rows = map { my $i = $_; +{ id => $i, name => "row $i & <more>", v => $i / 7 } } 1 .. 6000;
	my $f = xlsx_path();
	write_table(\@rows, $f, quiet => 1);
	cmp_ok( -s $f, '>', 4 * 65536, 'the table spans several of the chunks it is streamed in' );
	my $back = read_table($f, 'output_type' => 'aoh');
	is( scalar @$back, 6000, 'a streamed workbook reads back every row' );
	is( $back->[5999]{name}, 'row 6000 & <more>', 'a streamed workbook reads back the last row whole' );
	SKIP: {
		skip 'needs /dev/stdout and a list-form pipe open', 1 if $^O eq 'MSWin32' || !-e '/dev/stdout';
		# One child writes the table to a file and then down its stdout, a pipe,
		# so that the provenance line -- which names the script -- is the same in
		# both.  The file's name comes in @ARGV, not in the script's text.
		my $script = "$dir/pipe.pl";
		open my $sfh, '>', $script or die "cannot write $script: $!";
		print {$sfh} 'use Stats::LikeR; my @rows = map { my $i = $_; +{ id => $i, name => "row $i & <more>", v => $i / 7 } } 1 .. 6000;',
			" write_table(\\\@rows, \$ARGV[0], xlsx => 1, quiet => 1);",
			" write_table(\\\@rows, '/dev/stdout', xlsx => 1, quiet => 1);\n";
		close $sfh or die "cannot write $script: $!";
		my $to_file = "$dir/piped_twin.xlsx";
		my @inc = map { "-I$_" } grep { !ref $_ } @INC;
		open my $ph, '-|', $^X, @inc, $script, $to_file or die "cannot run a child perl: $!";
		binmode $ph;
		my $piped = do { local $/; <$ph> };
		close $ph;
		open my $ffh, '<', $to_file or die "cannot read $to_file: $!";
		binmode $ffh;
		my $filed = do { local $/; <$ffh> };
		close $ffh;
		ok( length($piped) > 4 * 65536 && $piped eq $filed,
			'a workbook written down a pipe is byte for byte the one written to a file' );
	}
}

# A NUL cannot appear in XML 1.0 at all, so a cell holding one loses it in the
# worksheet (it used to lose everything after it, at a strlen()); and a sheet
# name given as Latin-1 bytes is written as UTF-8, where its bytes used to go
# into workbook.xml as they were.
SKIP: {
	skip 'IO::Uncompress::Unzip (core) not available', 2 unless $have_unzip;
	my $f = xlsx_path();
	write_table([{ a => "x\0y" }], $f, quiet => 1, 'xlsx_sheet' => "R\xe9sum\xe9");
	like( member($f, 'xl/worksheets/sheet1.xml'), qr{<t xml:space="preserve">xy</t>}, 'a NUL is dropped from an .xlsx cell' );
	like( member($f, 'xl/workbook.xml'), qr{name="R\xc3\xa9sum\xc3\xa9"}, 'a Latin-1 sheet name is written as UTF-8' );
}

# An empty table writes a workbook too: its header row alone, or no cells.
{
	my $f = xlsx_path();
	write_table([], $f, 'col_names' => [qw(a b)], quiet => 1);
	ok( -s $f, 'an empty table writes its workbook' );
	is_deeply( read_table($f, 'output_type' => 'aoh'), [], 'an empty table reads back as no rows' );
}

# tex and xlsx are mutually exclusive
throws_ok { write_table([{ a => 1 }], "$dir/x.out", xlsx => 1, tex => 1) }
	qr/mutually exclusive/,
	"requesting both 'tex' and 'xlsx' dies with a clear message";

done_testing;
