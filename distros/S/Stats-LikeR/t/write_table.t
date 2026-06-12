use strict;
use warnings;
use Test::More;
use feature 'say';
use File::Temp qw(tempdir tempfile);
use Stats::LikeR;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';

sub file2string {
	my $file = shift;
	open my $fh, '<', $file;
	return do { local $/; <$fh> };
}
my %data = (
	'Row_A' => { 'Col1' => 10, 'Col2' => 20 },
	'Row_B' => { 'Col1' => 30, 'Col3' => 40 },
);
my $tmp_file = '/tmp/test.tsv';
write_table(\%data, $tmp_file, sep => "\t", 'row.names' => 1, 'undef.val' => 'NA');
my $str = file2string($tmp_file);
my $expected = "\tCol1\tCol2\tCol3\nRow_A\t10\t20\tNA\nRow_B\t30\tNA\t40\n";
if (is($str, $expected, 'write_table successfully wrote a tab-delimited file')) {
	unlink $tmp_file;
} else {
	diag("see $tmp_file");
}
no_leaks_ok {
	eval {
		write_table(\%data, $tmp_file, sep => "\t", 'row.names' => 1);
	};
} 'write_table: no memory leaks with row.names = true' unless $INC{'Devel/Cover.pm'};
# === TEST 1: HASH OF HASHES (positional) ===
# Demonstrates: HoH, sorted rows/columns, "NA" for missing values,
#               quoting when separator ("\t") or " appears inside data
my $fh = File::Temp->new(DIR => '/tmp', SUFFIX => '.tsv', UNLINK => 1);
close $fh;
$tmp_file = $fh->filename;
my %data_hoh = (
	'r1' => { 'c1' => 42,        'c2' => 'hello,world' },
	'r2' => { 'c1' => 99,        'c3' => 'quote"here' },
	'r3' => { 'c2' => "tab\tin", 'c4' => undef },
);

write_table(\%data_hoh, $tmp_file, sep => "\t", 'row.names' => 1, 'undef.val' => 'NA');
$str = file2string($tmp_file);
$expected = "\tc1\tc2\tc3\tc4\nr1\t42\thello,world\tNA\tNA\nr2\t99\tNA\t\"quote\"\"here\"\tNA\nr3\tNA\t\"tab\tin\"\tNA\tNA\n";
if (is($str, $expected, 'write_table successfully wrote a tab-delimited file (Hash of Hashes)')) {
	unlink $tmp_file;
} else {
	diag("see $tmp_file");
}
no_leaks_ok {
	eval {
		write_table(\%data_hoh, $tmp_file, sep => "\t", 'row.names' => 1, 'undef.val' => 'NA');
	};
} 'write_table: no memory leaks with hash-of-hash input' unless $INC{'Devel/Cover.pm'};
# === TEST 2: HASH OF ARRAYS (positional) ===
# Demonstrates: HoA, auto-generated V1/V2... headers, padding shorter arrays with "NA",
#               quoting when separator ("\t") or " appears inside data
$tmp_file = '/tmp/test_hoa.tsv';
my %data_hoa = (
	'r1' => [42, 'hello,world', undef, undef],
	'r2' => [99, undef, 'quote"here', undef],
	'r3' => [undef, "tab\tin", undef, undef],
);

write_table(\%data_hoa, $tmp_file, sep => "\t", 'row.names' => 1, 'undef.val' => 'NA');
$str = file2string($tmp_file);
$expected = "\tr1\tr2\tr3\n1\t42\t99\tNA\n2\thello,world\tNA\t\"tab\tin\"\n3\tNA\t\"quote\"\"here\"\tNA\n4\tNA\tNA\tNA\n";
if (is($str, $expected, 'write_table successfully wrote a tab-delimited file (Hash of Arrays)')) {
    unlink $tmp_file;
} else {
    diag("see $tmp_file");
}
no_leaks_ok {
	eval {
		write_table(\%data_hoa, $tmp_file, sep => "\t", 'row.names' => 1);
	};
} 'write_table: no memory leaks with hash-of-hash input' unless $INC{'Devel/Cover.pm'};
#---------
write_table(\%data_hoa, '/tmp/undef.val.tsv', sep => "\t", 'undef.val' => 'nan');
$str = file2string('/tmp/undef.val.tsv');
$expected = "\tr1\tr2\tr3\n1\t42\t99\tnan\n2\thello,world\tnan\t\"tab\tin\"\n3\tnan\t\"quote\"\"here\"\tnan\n4\tnan\tnan\tnan\n";
is($str, $expected, 'undefined values are switched to nan');

# ==============================================================================
# 4. write_table: Nested Reference Memory Leaks
# ==============================================================================
# We supply a valid Array-of-Hashes, but one of the cells contains an Array reference.
# write_table cannot write deeply nested structures to a flat CSV and will croak.
# The fix ensures that the previously allocated header/row strings are freed before croaking.
my $nested_data = [
	{ Name => 'Alice', Age => 30, Scores => [95, 90] }, # Nested 'Scores' array
	{ Name => 'Bob',   Age => 25, Scores => [80, 85] }
];

no_leaks_ok {
  eval {
      write_table(
          data => $nested_data, 
          file => 'test_output_dummy.csv'
      );
  };
} 'write_table: No memory leaks when encountering illegal nested references' unless $INC{'Devel/Cover.pm'};
# test write_table with implicit separator from filename
my %hoa = (
	a => [1..3],
	b => [4..9],
	c => [0..5]
);
$fh = File::Temp->new(DIR => '/tmp', SUFFIX => '.tsv', UNLINK => 1);
close $fh;
write_table(
	\%hoa, $fh->filename,
	'col.names' => [qw(a b)],
	'row.names' => 0, 'undef.val' => 'NA'
);
$str = file2string($fh->filename);
say $str;
if ($str eq 'a	b
1	4
2	5
3	6
NA	7
NA	8
NA	9
') {
	pass('write_table takes implicit separators');
} else {
	fail('write_table messed up implicit separators');
}

my $flat_hash = {
 A => 1, B => 2
};

# ---------------------------------------------------------
# Test 1: Flat hash with row.names = 0
# The output should exactly match: A,B \n 1,2
# ---------------------------------------------------------
my ($fh1, $file1) = tempfile(SUFFIX => '.csv', UNLINK => 1);
write_table($flat_hash, $file1, sep => ',', 'row.names' => 0);

open my $in1, '<', $file1 or die "Could not open $file1: $!";
my @lines1 = <$in1>;
close $in1;
chomp @lines1;

like($lines1[0], qr/^(?:""|'')?A(?:""|'')?,(?:""|'')?B(?:""|'')?$/, "Flat hash (rownames=0) Headers are keys");
like($lines1[1], qr/^(?:""|'')?1(?:""|'')?,(?:""|'')?2(?:""|'')?$/, "Flat hash (rownames=0) Values are on row 1");

# ---------------------------------------------------------
# Test 2: Flat hash with row.names = 1 (Default behavior)
# Output gracefully prepends the implicit "1" row identifier:
# "",A,B
# "1",1,2
# ---------------------------------------------------------
my ($fh2, $file2) = tempfile(SUFFIX => '.csv', UNLINK => 1);
write_table($flat_hash, $file2, sep => ',');

open my $in2, '<', $file2 or die "Could not open temp file: $!";
my @lines2 = <$in2>;
close $in2;
chomp @lines2;

like($lines2[0], qr/^(?:""|'')?,(?:""|'')?A(?:""|'')?,(?:""|'')?B(?:""|'')?$/, "Flat hash (rownames=1) Header prepends blank");
like($lines2[1], qr/^(?:""|'')?1(?:""|'')?,(?:""|'')?1(?:""|'')?,(?:""|'')?2(?:""|'')?$/, "Flat hash (rownames=1) Row prepends '1'");

my $dir = tempdir( CLEANUP => 1 );
my $n = 0;
sub path { my $name = shift // ('t' . ++$n . '.csv'); return "$dir/$name"; }
sub slurp { my $f = shift; open my $fh, '<', $f or die "open $f: $!"; local $/; return scalar <$fh>; }
# Helper: run write_table then compare the file's contents to an expected string.
sub wrote_ok {
	my ($expected, $name, $data, @opts) = @_;
	my $f = path();
	write_table( $data, $f, @opts );
	is( slurp($f), $expected, $name );
}
# Fixtures
%hoa  = ( 'name' => [ 'Alice', 'Bob' ], 'age' => [ 30, 25 ] );
my %hoh  = ( 'r1' => { 'a' => 1, 'b' => 2 }, 'r2' => { 'a' => 3, 'b' => 4 } );
my @aoh  = ( { 'x' => 1, 'y' => 2 }, { 'x' => 3, 'y' => 4 } );
my %flat = ( 'a' => 1, 'b' => 2, 'c' => 3 );
# 1. Hash of arrays: columns sorted, numeric row names by default.
wrote_ok( ",age,name\n1,30,Alice\n2,25,Bob\n", 'HoA: sorted cols + numeric row names', \%hoa, 'undef.val' => 'NA' );
# 2. Hash of hashes: rows sorted, columns sorted, outer key as the row label.
wrote_ok( ",a,b\nr1,1,2\nr2,3,4\n", 'HoH: sorted rows and columns', \%hoh, 'undef.val' => 'NA' );
# 3. Array of hashes: union of keys sorted, numeric row names.
wrote_ok( ",x,y\n1,1,2\n2,3,4\n", 'AoH: union of keys, numeric row names', \@aoh, 'undef.val' => 'NA' );
# 4. Flat hash: one row, columns sorted.
wrote_ok( ",a,b,c\n1,1,2,3\n", 'flat hash: single row', \%flat );
# 5. col.names selects/orders columns.
wrote_ok( ",name\n1,Alice\n2,Bob\n", 'col.names selects a subset in order', \%hoa, 'col.names' => [ 'name' ], 'undef.val' => 'NA' );
# 6. row.names => 0 turns off the row-name column.
wrote_ok( "age,name\n30,Alice\n25,Bob\n", 'row.names => 0 omits the label column', \%hoa, 'row.names' => 0, 'undef.val' => 'NA' );
# 7. row.names => 'col' uses that column as the labels and drops it from headers.
wrote_ok( ",age\nAlice,30\nBob,25\n", "row.names => 'name' uses that column as labels", \%hoa, 'row.names' => 'name', 'undef.val' => 'NA' );
# 8. Explicit separator.
wrote_ok( ";a;b;c\n1;1;2;3\n", 'sep => ";" is honored', \%flat, 'sep' => ';', 'undef.val' => 'NA' );
# 9. delim is an alias for sep.
wrote_ok( "|a|b|c\n1|1|2|3\n", 'delim => "|" is honored', \%flat, 'delim' => '|', 'undef.val' => 'NA' );
# 10. undef.val fills missing cells (jagged hash of arrays).
my %jag = ( 'a' => [ 1, 2 ], 'b' => [ 10 ] );
wrote_ok( ",a,b\n1,1,10\n2,2,NA\n", 'missing cells default to NA', \%jag, 'undef.val' => 'NA' );
wrote_ok( ",a,b\n1,1,10\n2,2,NULL\n", 'undef.val overrides the fill', \%jag, 'undef.val' => 'NULL' );
# 11. CSV quoting: separators, quotes and newlines are quoted; quotes are doubled.
my %quote = ( 'a' => [ 'x,y' ], 'b' => [ 'p"q' ], 'c' => [ "line1\nline2" ]);
wrote_ok( qq{,a,b,c\n1,"x,y","p""q","line1\nline2"\n}, 'quoting: comma, quote, newline', \%quote, 'undef.val' => 'NA' );
# 12. Auto-detect tab separator from a .tsv extension.
{
	my $f = "$dir/auto.tsv";
	write_table( \%flat, $f );
	is( slurp($f), "\ta\tb\tc\n1\t1\t2\t3\n", '.tsv extension selects a tab separator' );
}
# 13. Auto-detect comma from .csv (and an explicit sep still wins over the extension).
{
	my $f = "$dir/auto2.tsv";
	write_table( \%flat, $f, 'sep' => ',' );
	is( slurp($f), ",a,b,c\n1,1,2,3\n", 'explicit sep overrides the extension' );
}
# 14. Fully-named calling style (exercises the positional/named disambiguation).
{
	my $f = path();
	write_table( 'data' => \%flat, 'file' => $f );
	is( slurp($f), ",a,b,c\n1,1,2,3\n", 'data => ..., file => ... works' );
}
# 15. Positional data with a named file.
{
	my $f = path();
	write_table( \%flat, 'file' => $f );
	is( slurp($f), ",a,b,c\n1,1,2,3\n", 'positional data + named file works' );
}
# 16. Bad inputs die with a clear message.
dies_ok { write_table() } 'no data dies';
dies_ok { write_table( \%hoa ) } 'missing file dies';
dies_ok { write_table( [ 1, 2, 3 ], path() ) } 'array of non-hashes dies';
dies_ok { write_table( { 'a' => 1, 'b' => [ 2 ] }, path() ) } 'mixed flat/ref values die';
dies_ok { write_table( { 'r1' => { 'a' => 1 }, 'r2' => [ 1 ] }, path() ) } 'mixed HoH/HoA values die';
dies_ok { write_table( { 'r1' => { 'a' => [ 1 ] } }, path() ) } 'nested reference cell dies';
dies_ok { write_table( \%hoa, path(), 'sep' ) } 'odd argument count dies';
dies_ok { write_table( \%hoa, path(), 'bogus' => 1 ) } 'unknown option dies';
dies_ok { write_table( \%hoa, path(), 'col.names' => 'x' ) } 'col.names must be an array ref';
# 17. Empty col.names must NOT hang (regression: size_t vs av_len == -1).
lives_ok { write_table( \%flat, path(), 'col.names' => [], 'row.names' => 0 ) } 'empty col.names does not loop forever';
# ==============================================================================
# 18+. Expanded coverage targeting bugs found in the write_table XS.
# These tests assume the updated XS: undef cells render as EMPTY fields by
# default (a,,c), 'undef.val' still overrides, and print_string_row emits
# zero-length fields bare (never '' or "").
# ==============================================================================

# 18. Default undef rendering is an empty field (no 'undef.val' supplied).
my %u_jag = ( 'a' => [ 1, 2 ], 'b' => [ 10 ] );
wrote_ok( ",a,b\n1,1,10\n2,2,\n", 'default undef renders as an empty field', \%u_jag );

# 19. 'undef.val' => undef must behave like the default and emit NO
#     "uninitialized value" warning (regression: SvPV_nolen on PL_sv_undef).
{
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $f = path();
	write_table( \%u_jag, $f, 'undef.val' => undef );
	is( slurp($f), ",a,b\n1,1,10\n2,2,\n", "undef.val => undef behaves like the default" );
	is( scalar @warnings, 0, "undef.val => undef emits no warnings" )
		or diag( join '', @warnings );
	$f = path();
	write_table( \%u_jag, $f, 'undef.val' => '' );
	is( slurp($f), ",a,b\n1,1,10\n2,2,\n", "undef.val => '' is identical to the default" );
}

# 20. Empty col.names per input shape. A HANG on any of these is the
#     size_t-index vs av_len() == -1 regression (test 17 covers flat hash).
{
	# HoH: degenerate but defined output - only the row-label column survives.
	my %hoh2 = ( 'r1' => { 'a' => 1 }, 'r2' => { 'a' => 2 } );
	my $f = path();
	lives_ok { write_table( \%hoh2, $f, 'col.names' => [] ) }
		'HoH: empty col.names terminates';
	is( slurp($f), "\nr1\nr2\n", 'HoH: empty col.names leaves only sorted row labels' );

	# AoH: numeric row labels survive.
	my @aoh2 = ( { 'x' => 1 }, { 'x' => 2 } );
	$f = path();
	lives_ok { write_table( \@aoh2, $f, 'col.names' => [] ) }
		'AoH: empty col.names terminates';
	is( slurp($f), "\n1\n2\n", 'AoH: empty col.names leaves only numeric row labels' );

	# HoA croaks ("Could not get headers") - and that croak path must close
	# the already-open filehandle and free headers_av (regression: both leaked).
	my %hoa2 = ( 'a' => [ 1, 2 ] );
	throws_ok { write_table( \%hoa2, path(), 'col.names' => [] ) }
		qr/Could not get headers/, 'HoA: empty col.names croaks cleanly';
	no_leaks_ok {
		eval { write_table( \%hoa2, path(), 'col.names' => [] ) };
	} 'HoA: no leaks (fh, headers_av) on the empty-header croak' unless $INC{'Devel/Cover.pm'};
}

# 21. Empty col.names combined with a named row.names column exercises the
#     filtered-headers loop over an EMPTY headers array (second size_t site).
{
	my @aoh3 = ( { 'x' => 'p' }, { 'x' => 'q' } );
	my $f = path();
	lives_ok { write_table( \@aoh3, $f, 'col.names' => [], 'row.names' => 'x' ) }
		"AoH: empty col.names + row.names => 'x' terminates (filtered-header loop)";
	is( slurp($f), "\np\nq\n", 'AoH: row labels taken from x; no data columns' );
}

# 22. Numeric row labels in sequence across many rows (regression guard for
#     the per-row label buffer: each label must be printed before reuse).
{
	my @many = map { { 'v' => $_ * 10 } } 1 .. 12;
	my $expected = ",v\n" . join( '', map { "$_," . ( $_ * 10 ) . "\n" } 1 .. 12 );
	wrote_ok( $expected, 'numeric row labels 1..12 correct in sequence', \@many );
}

# 23. Unopenable output path: must die, and must not leak the pre-gathered
#     HoH row keys (regression: rows_av leaked when PerlIO_open failed).
{
	my %hoh3 = ( 'r1' => { 'a' => 1 } );
	my $bad = "$dir/no/such/subdir/file.csv";
	dies_ok { write_table( \%hoh3, $bad ) } 'unopenable path dies';
	no_leaks_ok {
		eval { write_table( \%hoh3, $bad ) };
	} 'no leaks (rows_av) when the output file cannot be opened' unless $INC{'Devel/Cover.pm'};
}

# 24. Quoting corners.
# Carriage return forces quoting just like newline.
wrote_ok( qq{,a\n1,"x\ry"\n}, 'embedded \r is quoted', { 'a' => [ "x\ry" ] } );
# A column NAME containing the separator is quoted in the header row.
wrote_ok( qq{"a,b"\n1\n}, 'column name containing the separator is quoted',
	{ 'a,b' => [ 1 ] }, 'row.names' => 0 );
# Multi-character separator: only a full separator match triggers quoting.
wrote_ok( qq{a::b\n"x::y"::x:y\n}, 'multi-char separator: full match quotes, partial stays bare',
	{ 'a' => [ 'x::y' ], 'b' => [ 'x:y' ] }, 'sep' => '::', 'row.names' => 0 );

# 25. undef entries inside col.names are skipped, order otherwise preserved.
wrote_ok( ",b,a\n1,2,1\n", 'undef entries in col.names are skipped',
	{ 'a' => [ 1 ], 'b' => [ 2 ] }, 'col.names' => [ 'b', undef, 'a' ] );

# 26. col.names naming a column absent from the data pads with undef.val
#     (or empty by default).
wrote_ok( "a,ghost\n1,NA\n2,NA\n", 'missing col.names column pads with undef.val',
	{ 'a' => [ 1, 2 ] }, 'col.names' => [ 'a', 'ghost' ], 'row.names' => 0, 'undef.val' => 'NA' );
wrote_ok( "a,ghost\n1,\n2,\n", 'missing col.names column pads empty by default',
	{ 'a' => [ 1, 2 ] }, 'col.names' => [ 'a', 'ghost' ], 'row.names' => 0 );

# 27. Empty data returns an empty list and writes NO file (the early return
#     happens before the file is opened).
{
	my $f = path();
	my @r = write_table( {}, $f );
	is( scalar @r, 0, 'empty hash returns an empty list' );
	ok( !-e $f, 'empty hash creates no file' );
	$f = path();
	@r = write_table( [], $f );
	is( scalar @r, 0, 'empty array returns an empty list' );
	ok( !-e $f, 'empty array creates no file' );
}

# 28. Documented limitation: a positional filename equal to an option key is
#     not consumed as a filename (use file => 'sep' for such names).
dies_ok { write_table( { 'a' => 1 }, 'sep' ) }
	"positional filename 'sep' collides with an option key and dies";

# 29. Header loop index width: >65535 columns must terminate (regression:
#     'unsigned short' loop index wrapped and never finished). Gated because
#     it builds a 70k-key hash.
SKIP: {
	skip 'set EXTENDED_TESTING=1 for the 70k-column header test', 2
		unless $ENV{EXTENDED_TESTING};
	my %wide = ( 'r' => { map { ( sprintf( 'c%06d', $_ ) => $_ ) } 1 .. 70_000 } );
	my $f = path();
	lives_ok { write_table( \%wide, $f ) } '70k columns terminates';
	my ($header) = split /\n/, slurp($f), 2;
	my @cells = split /,/, $header, -1;
	is( scalar @cells, 70_001, 'all 70k column names plus the row-label cell are present' );
}

# 30. Wide-character (UTF-8-flagged) hash keys round-trip: column names and
#     HoH row keys are fetched by SV (hv_fetch_ent) and sorted as SVs, so the
#     flag survives. (Formerly a TODO documenting the raw-bytes hv_fetch bug.)
{
	my $col = "caf\x{263a}";
	my $f = path();
	write_table( { 'r1' => { $col => 7 } }, $f );
	like( slurp($f), qr/7/, 'value under a wide-character column name is written' );

	my $row = "zeile\x{263a}";
	$f = path();
	write_table( { $row => { 'a' => 9 } }, $f );
	is( slurp($f), ",a\nzeile\x{e2}\x{98}\x{ba},9\n",
		'wide-character HoH row key sorts and fetches correctly (UTF-8 bytes on disk)' );
}

done_testing();
