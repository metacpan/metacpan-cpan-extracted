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

# --- round-trip an Array of Hashes -----------------------------------------
{
	my @aoh = (
		{ name => 'Mazda RX4',  mpg => 21.0, cyl => 6,     note => 'A & B <ok>' },
		{ name => 'Datsun 710', mpg => 22.8, cyl => 4,     note => ''           },
		{ name => 'Hornet',     mpg => 21.4, cyl => undef, note => q{q"x}       },
	);
	my $f = xlsx_path();
	lives_ok { write_table(\@aoh, $f, 'row.names' => 0) }
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

# --- numeric detection: leading-zero / non-plain strings stay text ----------
{
	my @aoh = (
		{ id => '007', sci => '1e3', bad => 'Inf', plain => 42 },
	);
	my $f = xlsx_path();
	write_table(\@aoh, $f, 'row.names' => 0);
	my $r = read_table($f)->[0];
	is( $r->{id},    '007', 'leading-zero string is preserved (written as text)' );
	is( $r->{sci},   '1e3', 'scientific-notation numeric string round-trips' );
	is( $r->{bad},   'Inf', '"Inf" is written as text, not an invalid number cell' );
	is( $r->{plain}, '42',  'a plain number round-trips' );
}

# --- HoA shape, forced on via xlsx => 1 for a non-.xlsx name ----------------
{
	my %hoa = ( x => [1, 2, 3], y => [4, 5, 6] );
	my $f = "$dir/forced.dat";
	lives_ok { write_table(\%hoa, $f, xlsx => 1, 'row.names' => 0) }
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

# --- provenance lands in the document "comments" property -------------------
SKIP: {
	skip 'IO::Uncompress::Unzip (core) not available', 4 unless $have_unzip;

	my $f = xlsx_path();
	write_table([{ a => 1, b => 2 }], $f, 'row.names' => 0,
		'xlsx.sheet' => 'Results', 'xlsx.comment' => 'batch 9');

	my $core = member($f, 'docProps/core.xml');
	ok( defined $core, 'docProps/core.xml is present' );
	like( $core, qr{<dc:description>written by }s,
		'the provenance line is stored as the document comments (dc:description)' );
	like( $core, qr{batch 9}s,
		'a user-supplied xlsx.comment is appended after the provenance' );

	my $wb = member($f, 'xl/workbook.xml');
	like( $wb, qr{name="Results"}, 'xlsx.sheet sets the worksheet name' );
}

# --- freeze panes -----------------------------------------------------------
SKIP: {
	skip 'IO::Uncompress::Unzip (core) not available', 8 unless $have_unzip;

	my @aoh = map { { a => $_, b => $_ * 2, c => $_ * 3 } } 1 .. 5;

	# freezing the top row: xSplit absent, ySplit=1, anchor A2
	my $f1 = xlsx_path();
	write_table(\@aoh, $f1, 'row.names' => 0, 'xlsx.freeze.rows' => 1);
	my $ws1 = member($f1, 'xl/worksheets/sheet1.xml');
	like( $ws1, qr{<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>},
		'freeze.rows => 1 writes a top-row frozen pane anchored at A2' );
	is( read_table($f1)->[0]{a}, '1', 'data still round-trips with a frozen row' );

	# freezing rows and columns: xSplit=2, ySplit=1, anchor C2, bottomRight
	my $f2 = xlsx_path();
	write_table(\@aoh, $f2, 'row.names' => 0,
		'xlsx.freeze.rows' => 1, 'xlsx.freeze.cols' => 2);
	like( member($f2, 'xl/worksheets/sheet1.xml'),
		qr{<pane xSplit="2" ySplit="1" topLeftCell="C2" activePane="bottomRight" state="frozen"/>},
		'freeze.rows + freeze.cols writes a bottomRight pane anchored at C2' );

	# freezing only columns: xSplit=1, ySplit absent, anchor B1, topRight
	my $f3 = xlsx_path();
	write_table(\@aoh, $f3, 'row.names' => 0, 'xlsx.freeze.cols' => 1);
	like( member($f3, 'xl/worksheets/sheet1.xml'),
		qr{<pane xSplit="1" topLeftCell="B1" activePane="topRight" state="frozen"/>},
		'freeze.cols => 1 writes a left-column frozen pane anchored at B1' );

	# no freeze options: no <sheetViews> block at all
	my $f0 = xlsx_path();
	write_table(\@aoh, $f0, 'row.names' => 0);
	unlike( member($f0, 'xl/worksheets/sheet1.xml'), qr{<sheetViews>},
		'no freeze options leaves the worksheet without a <sheetViews> block' );

	throws_ok { write_table(\@aoh, xlsx_path(), 'xlsx.freeze.rows' => -1) }
		qr/'xlsx\.freeze\.rows' must be a non-negative integer/,
		'a negative freeze count dies with a clear message';
	throws_ok { write_table(\@aoh, xlsx_path(), 'xlsx.freeze.cols' => -3) }
		qr/'xlsx\.freeze\.cols' must be a non-negative integer/,
		'a negative freeze column count dies too';
}

# --- tex and xlsx are mutually exclusive ------------------------------------
throws_ok { write_table([{ a => 1 }], "$dir/x.out", xlsx => 1, tex => 1) }
	qr/mutually exclusive/,
	"requesting both 'tex' and 'xlsx' dies with a clear message";

done_testing;
