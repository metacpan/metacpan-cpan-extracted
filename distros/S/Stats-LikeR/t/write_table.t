use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);
use Stats::LikeR;
use Test::Exception;
use Test::LeakTrace 'no_leaks_ok';

# NOTE: row_names defaults OFF, in every format, for every shape but a hash of
# hashes. A call that omits it writes the data columns and nothing else.
# row_names => 1 opts in and prepends a leading empty header cell plus a
# per-row label column (1..n); row_names => 'col' promotes an existing column
# to the labels, headed with its own name. A HoH defaults it ON, because its
# outer keys are the row identifiers and exist nowhere else: row_names => 0
# turns them off, and row_names => 'name' writes 'name' as the key column's
# header.

# Every temporary file this test writes goes inside this one directory, which
# File::Temp removes at exit: a fixed name in the shared temporary directory is
# shared with every other process on the machine, and a smoker testing several
# perls at once runs two copies of this file side by side.
my $dir = tempdir( CLEANUP => 1 );

# An unchecked open() reports a missing file as "readline() on closed
# filehandle" without ever naming it; name the path and errno instead.
sub file2string {
	my $file = shift;
	open my $fh, '<', $file or die "cannot read \"$file\": $!";
	return do { local $/; <$fh> };
}
my %data = (
	'Row_A' => { 'Col1' => 10, 'Col2' => 20 },
	'Row_B' => { 'Col1' => 30, 'Col3' => 40 },
);
my $tmp_file = "$dir/test.tsv";
write_table(\%data, $tmp_file, sep => "\t", 'row_names' => 1, 'undef_val' => 'NA');
my $str = file2string($tmp_file);
my $expected = "\tCol1\tCol2\tCol3\nRow_A\t10\t20\tNA\nRow_B\t30\tNA\t40\n";
if (is($str, $expected, 'write_table successfully wrote a tab-delimited file')) {
	unlink $tmp_file;
} else {
	diag("see $tmp_file");
}
no_leaks_ok {
	eval {
		write_table(\%data, $tmp_file, sep => "\t", 'row_names' => 1);
	};
} 'write_table: no memory leaks with row_names = true' unless $INC{'Devel/Cover.pm'};
# TEST 1: HASH OF HASHES (positional)
# Demonstrates: HoH, sorted rows/columns, "NA" for missing values,
#               quoting when separator ("\t") or " appears inside data
my $fh = File::Temp->new(DIR => $dir, SUFFIX => '.tsv', UNLINK => 1);
close $fh;
$tmp_file = $fh->filename;
my %data_hoh = (
	'r1' => { 'c1' => 42,        'c2' => 'hello,world' },
	'r2' => { 'c1' => 99,        'c3' => 'quote"here' },
	'r3' => { 'c2' => "tab\tin", 'c4' => undef },
);

write_table(\%data_hoh, $tmp_file, sep => "\t", 'row_names' => 1, 'undef_val' => 'NA');
$str = file2string($tmp_file);
$expected = "\tc1\tc2\tc3\tc4\nr1\t42\thello,world\tNA\tNA\nr2\t99\tNA\t\"quote\"\"here\"\tNA\nr3\tNA\t\"tab\tin\"\tNA\tNA\n";
if (is($str, $expected, 'write_table successfully wrote a tab-delimited file (Hash of Hashes)')) {
	unlink $tmp_file;
} else {
	diag("see $tmp_file");
}
no_leaks_ok {
	eval {
		write_table(\%data_hoh, $tmp_file, sep => "\t", 'row_names' => 1, 'undef_val' => 'NA');
	};
} 'write_table: no memory leaks with hash-of-hash input' unless $INC{'Devel/Cover.pm'};
# TEST 2: HASH OF ARRAYS (positional)
# Demonstrates: HoA, auto-generated V1/V2... headers, padding shorter arrays with "NA",
#               quoting when separator ("\t") or " appears inside data
$tmp_file = "$dir/test_hoa.tsv";
my %data_hoa = (
	'r1' => [42, 'hello,world', undef, undef],
	'r2' => [99, undef, 'quote"here', undef],
	'r3' => [undef, "tab\tin", undef, undef],
);

write_table(\%data_hoa, $tmp_file, sep => "\t", 'row_names' => 1, 'undef_val' => 'NA');
$str = file2string($tmp_file);
$expected = "\tr1\tr2\tr3\n1\t42\t99\tNA\n2\thello,world\tNA\t\"tab\tin\"\n3\tNA\t\"quote\"\"here\"\tNA\n4\tNA\tNA\tNA\n";
if (is($str, $expected, 'write_table successfully wrote a tab-delimited file (Hash of Arrays)')) {
    unlink $tmp_file;
} else {
    diag("see $tmp_file");
}
no_leaks_ok {
	eval {
		write_table(\%data_hoa, $tmp_file, sep => "\t", 'row_names' => 1);
	};
} 'write_table: no memory leaks with hash-of-hash input' unless $INC{'Devel/Cover.pm'};
# No row_names passed: the default is OFF, so there is no label column and no
# leading empty header cell. undef_val still fills the gaps.
write_table(\%data_hoa, "$dir/undef.val.tsv", sep => "\t", 'undef_val' => 'nan');
$str = file2string("$dir/undef.val.tsv");
$expected = "r1\tr2\tr3\n42\t99\tnan\nhello,world\tnan\t\"tab\tin\"\nnan\t\"quote\"\"here\"\tnan\nnan\tnan\tnan\n";
is($str, $expected, 'undefined values are switched to nan (no row labels by default)');

# 4. write_table: Nested Reference Memory Leaks
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
unlink 'test_output_dummy.csv';
# test write_table with implicit separator from filename
my %hoa = (
	a => [1..3],
	b => [4..9],
	c => [0..5]
);
$fh = File::Temp->new(DIR => $dir, SUFFIX => '.tsv', UNLINK => 1);
close $fh;
write_table(
	\%hoa, $fh->filename,
	'col_names' => [qw(a b)],
	'row_names' => 0, 'undef_val' => 'NA'
);
$str = file2string($fh->filename);
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

# Test 1: Flat hash with row_names = 0
# The output should exactly match: A,B \n 1,2
my ($fh1, $file1) = tempfile(DIR => $dir, SUFFIX => '.csv', UNLINK => 1);
write_table($flat_hash, $file1, sep => ',', 'row_names' => 0);

open my $in1, '<', $file1 or die "Could not open $file1: $!";
my @lines1 = <$in1>;
close $in1;
chomp @lines1;

like($lines1[0], qr/^(?:""|'')?A(?:""|'')?,(?:""|'')?B(?:""|'')?$/, "Flat hash (rownames=0) Headers are keys");
like($lines1[1], qr/^(?:""|'')?1(?:""|'')?,(?:""|'')?2(?:""|'')?$/, "Flat hash (rownames=0) Values are on row 1");

# Test 2: Flat hash with row_names => 1 (explicit; also the default now)
# Output gracefully prepends the implicit "1" row identifier:
# "",A,B
# "1",1,2
my ($fh2, $file2) = tempfile(DIR => $dir, SUFFIX => '.csv', UNLINK => 1);
write_table($flat_hash, $file2, sep => ',', 'row_names' => 1);

open my $in2, '<', $file2 or die "Could not open temp file: $!";
my @lines2 = <$in2>;
close $in2;
chomp @lines2;

like($lines2[0], qr/^(?:""|'')?,(?:""|'')?A(?:""|'')?,(?:""|'')?B(?:""|'')?$/, "Flat hash (rownames=1) Header prepends blank");
like($lines2[1], qr/^(?:""|'')?1(?:""|'')?,(?:""|'')?1(?:""|'')?,(?:""|'')?2(?:""|'')?$/, "Flat hash (rownames=1) Row prepends '1'");

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

# 0. Default row_names is OFF, for every shape but a HoH and in every format.
#    Omitting it writes the data columns and nothing else -- no label column,
#    and no empty leading header cell. row_names => 1 opts in; the labels are
#    1..n. An explicit 0 is the default. A HoH keeps its outer keys unless
#    told row_names => 0 (see section 2a).
wrote_ok( "age,name\n30,Alice\n25,Bob\n",
	'default row_names off (HoA): no label column', \%hoa, 'undef_val' => 'NA' );
wrote_ok( ",a,b\nr1,1,2\nr2,3,4\n",
	'default row_names on (HoH): the outer key is the label', \%hoh, 'undef_val' => 'NA' );
wrote_ok( "x,y\n1,2\n3,4\n",
	'default row_names off (AoH): no label column', \@aoh, 'undef_val' => 'NA' );
wrote_ok( "a,b,c\n1,2,3\n",
	'default row_names off (flat hash): no label column', \%flat );
wrote_ok( "k,v\nx,1\ny,2\n",
	'default row_names off (AoA): no label column', [ [qw(k v)], [ 'x', 1 ], [ 'y', 2 ] ] );
# The opt-in restores the label column, and the empty header cell it needs.
wrote_ok( ",a,b,c\n1,1,2,3\n",
	'row_names => 1 opts in (flat hash)', \%flat, 'row_names' => 1 );
wrote_ok( ",a,b\nr1,1,2\nr2,3,4\n",
	'row_names => 1 opts in (HoH): outer key as label', \%hoh, 'row_names' => 1, 'undef_val' => 'NA' );
wrote_ok( ",k,v\n1,x,1\n2,y,2\n",
	'row_names => 1 opts in (AoA): numeric labels', [ [qw(k v)], [ 'x', 1 ], [ 'y', 2 ] ],
	'row_names' => 1 );
# An explicit 0 says exactly what the default already does.
wrote_ok( "a,b,c\n1,2,3\n",
	'row_names => 0 matches the default (flat hash)', \%flat, 'row_names' => 0 );
wrote_ok( "age,name\n30,Alice\n25,Bob\n",
	'row_names => 0 matches the default (HoA)', \%hoa, 'row_names' => 0, 'undef_val' => 'NA' );

# 1. Hash of arrays: columns sorted, numeric row names by default.
wrote_ok( ",age,name\n1,30,Alice\n2,25,Bob\n", 'HoA: sorted cols + numeric row names', \%hoa, 'row_names' => 1, 'undef_val' => 'NA' );
# 2. Hash of hashes: rows sorted, columns sorted, outer key as the row label.
wrote_ok( ",a,b\nr1,1,2\nr2,3,4\n", 'HoH: sorted rows and columns', \%hoh, 'row_names' => 1, 'undef_val' => 'NA' );
# 2a. HoH row_names: the outer keys are data, so they are written unless turned
#     off, and a name for them becomes the key column's header.
my %taxa = (
	'9606'  => { species => 'Homo sapiens', genus => 'Homo' },
	'10090' => { species => 'Mus musculus' },
);
wrote_ok( "\tgenus\tspecies\n10090\t\tMus musculus\n9606\tHomo\tHomo sapiens\n",
	'HoH default: the taxid keys lead each row under an empty header', \%taxa, sep => "\t" );
wrote_ok( "genus\tspecies\n\tMus musculus\nHomo\tHomo sapiens\n",
	'HoH row_names => 0: the keys are dropped', \%taxa, sep => "\t", 'row_names' => 0 );
wrote_ok( "taxid\tgenus\tspecies\n10090\t\tMus musculus\n9606\tHomo\tHomo sapiens\n",
	"HoH row_names => 'taxid': the key column is headed taxid", \%taxa, sep => "\t", 'row_names' => 'taxid' );
wrote_ok( "taxid,species\n10090,Mus musculus\n9606,Homo sapiens\n",
	"HoH row_names => 'taxid' with col_names", \%taxa, 'row_names' => 'taxid', 'col_names' => ['species'] );
wrote_ok( "genus,species\n10090,Mus musculus\n9606,Homo sapiens\n",
	'HoH row_names naming a column that col_names leaves out is no clash',
	\%taxa, 'row_names' => 'genus', 'col_names' => ['species'] );
# slurp() reads bytes, so the header is U+7A2E's UTF-8 encoding.
wrote_ok( "\xE7\xA8\xAE,a,b\nr1,1,2\nr2,3,4\n", 'HoH row_names => a wide-character name',
	\%hoh, 'row_names' => "\x{7a2e}" );
{
	my $f = path();
	write_table( \%taxa, $f, 'row_names' => 'taxid', quiet => 1 );
	my $back = read_table( $f );
	is_deeply( [ map { $_->{taxid} } @$back ], [ '10090', '9606' ],
		'HoH row_names => name: read_table reads the keys back as a named column' );
	is( $back->[1]{species}, 'Homo sapiens', '... aligned with their rows' );
}
# A name that is also a column being written would give the file two columns
# of that name; that is refused, and before the file is opened.
{
	my $f = path();
	open my $fh, '>', $f or die "cannot write $f: $!";
	print {$fh} "keep\n";
	close $fh;
	throws_ok { write_table( \%taxa, $f, 'row_names' => 'genus' ) }
		qr/^write_table: row_names 'genus' collides with an existing column/,
		'HoH row_names naming an inner key croaks';
	throws_ok { write_table( \%taxa, $f, 'row_names' => 'species', 'col_names' => ['species'] ) }
		qr/^write_table: row_names 'species' collides with an existing column/,
		'HoH row_names naming a col_names entry croaks';
	is( slurp($f), "keep\n", 'a refused write leaves the existing file untouched' );
}
no_leaks_ok {
	my $f = path();
	write_table( \%taxa, $f, 'row_names' => 'taxid', quiet => 1 );
} "write_table: no memory leaks with a HoH row_names name" unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { write_table( \%taxa, path(), 'row_names' => 'genus', quiet => 1 ) };
} 'write_table: no memory leaks on the HoH row_names collision croak' unless $INC{'Devel/Cover.pm'};
# 3. Array of hashes: union of keys sorted, numeric row names.
wrote_ok( ",x,y\n1,1,2\n2,3,4\n", 'AoH: union of keys, numeric row names', \@aoh, 'row_names' => 1, 'undef_val' => 'NA' );
# 4. Flat hash: one row, columns sorted, no label column by default.
wrote_ok( "a,b,c\n1,2,3\n", 'flat hash: single row, unlabelled by default', \%flat );
# 5. col_names selects/orders columns.
wrote_ok( "name\nAlice\nBob\n", 'col_names selects a subset in order', \%hoa, 'col_names' => [ 'name' ], 'undef_val' => 'NA' );
# 6. row_names => 0 turns off the row-name column.
wrote_ok( "age,name\n30,Alice\n25,Bob\n", 'row_names => 0 omits the label column', \%hoa, 'row_names' => 0, 'undef_val' => 'NA' );
# 7. row_names => 'col' uses that column as the labels, drops it from headers,
#    and heads the label column with its name.  Up to 0.3212 that header cell
#    was left empty, so the name was lost and read_table() read the column back
#    as row_name.  pandas writes an index's name over it the same way: pandas
#    3.0.4 tests/io/formats/test_to_csv.py, test_to_csv_single_level_multi_index
#    (gh-19589), pins "x,data\n1.0,1\n" for an index named x.
wrote_ok( "name,age\nAlice,30\nBob,25\n", "row_names => 'name' uses that column as labels", \%hoa, 'row_names' => 'name', 'undef_val' => 'NA' );
#    ... including a column name outside Latin-1, which up to 0.319 croaked
#    "Wide character" in the XS digit check before it was ever looked up.  The
#    name is written as its UTF-8 bytes, as every other header is.
wrote_ok( "\xe5\x90\x8d,age\nAlice,30\nBob,25\n", 'row_names => a wide-character column name',
	{ "\x{540d}" => [ 'Alice', 'Bob' ], 'age' => [ 30, 25 ] },
	'row_names' => "\x{540d}", 'undef_val' => 'NA' );
# 8. Explicit separator.
wrote_ok( "a;b;c\n1;2;3\n", 'sep => ";" is honored', \%flat, 'sep' => ';', 'undef_val' => 'NA' );
# 9. delim is an alias for sep.
wrote_ok( "a|b|c\n1|2|3\n", 'delim => "|" is honored', \%flat, 'delim' => '|', 'undef_val' => 'NA' );
# 10. undef_val fills missing cells (jagged hash of arrays).
my %jag = ( 'a' => [ 1, 2 ], 'b' => [ 10 ] );
wrote_ok( "a,b\n1,10\n2,NA\n", 'missing cells default to NA', \%jag, 'undef_val' => 'NA' );
wrote_ok( "a,b\n1,10\n2,NULL\n", 'undef_val overrides the fill', \%jag, 'undef_val' => 'NULL' );
# 11. CSV quoting: separators, quotes and newlines are quoted; quotes are doubled.
my %quote = ( 'a' => [ 'x,y' ], 'b' => [ 'p"q' ], 'c' => [ "line1\nline2" ]);
wrote_ok( qq{a,b,c\n"x,y","p""q","line1\nline2"\n}, 'quoting: comma, quote, newline', \%quote, 'undef_val' => 'NA' );
# 12. Auto-detect tab separator from a .tsv extension.
{
	my $f = "$dir/auto.tsv";
	write_table( \%flat, $f );
	is( slurp($f), "a\tb\tc\n1\t2\t3\n", '.tsv extension selects a tab separator' );
}
# 13. Auto-detect comma from .csv (and an explicit sep still wins over the extension).
{
	my $f = "$dir/auto2.tsv";
	write_table( \%flat, $f, 'sep' => ',' );
	is( slurp($f), "a,b,c\n1,2,3\n", 'explicit sep overrides the extension' );
}
# 14. Fully-named calling style (exercises the positional/named disambiguation).
{
	my $f = path();
	write_table( 'data' => \%flat, 'file' => $f );
	is( slurp($f), "a,b,c\n1,2,3\n", 'data => ..., file => ... works' );
}
# 15. Positional data with a named file.
{
	my $f = path();
	write_table( \%flat, 'file' => $f );
	is( slurp($f), "a,b,c\n1,2,3\n", 'positional data + named file works' );
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
dies_ok { write_table( \%hoa, path(), 'col_names' => 'x' ) } 'col_names must be an array ref';
# 17. Empty col_names must NOT hang (regression: size_t vs av_len == -1).
lives_ok { write_table( \%flat, path(), 'col_names' => [], 'row_names' => 0 ) } 'empty col_names does not loop forever';
# 18+. Expanded coverage targeting bugs found in the write_table XS.
# These tests assume the updated XS: undef cells render as EMPTY fields by
# default (a,,c), 'undef_val' still overrides, and print_string_row emits
# zero-length fields bare (never '' or "").

# 18. Default undef rendering is an empty field (no 'undef_val' supplied).
my %u_jag = ( 'a' => [ 1, 2 ], 'b' => [ 10 ] );
wrote_ok( "a,b\n1,10\n2,\n", 'default undef renders as an empty field', \%u_jag );

# 19. 'undef_val' => undef must behave like the default and emit NO
#     "uninitialized value" warning (regression: SvPV_nolen on PL_sv_undef).
{
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	my $f = path();
	write_table( \%u_jag, $f, 'undef_val' => undef );
	is( slurp($f), "a,b\n1,10\n2,\n", "undef_val => undef behaves like the default" );
	is( scalar @warnings, 0, "undef_val => undef emits no warnings" )
		or diag( join '', @warnings );
	$f = path();
	write_table( \%u_jag, $f, 'undef_val' => '' );
	is( slurp($f), "a,b\n1,10\n2,\n", "undef_val => '' is identical to the default" );
}

# 20. Empty col_names per input shape. A HANG on any of these is the
#     size_t-index vs av_len() == -1 regression (test 17 covers flat hash).
{
	# HoH: degenerate but defined output - only the row-label column survives.
	# Its header is one empty field, written "" as csv.writer writes [''] (see
	# t/write_table.quoting.t): a bare blank line there was skipped on reading,
	# and r1 was then taken for the header.
	my %hoh2 = ( 'r1' => { 'a' => 1 }, 'r2' => { 'a' => 2 } );
	my $f = path();
	lives_ok { write_table( \%hoh2, $f, 'col_names' => [], 'row_names' => 1 ) }
		'HoH: empty col_names terminates';
	is( slurp($f), "\"\"\nr1\nr2\n", 'HoH: empty col_names leaves only sorted row labels' );

	# AoH: numeric row labels survive.
	my @aoh2 = ( { 'x' => 1 }, { 'x' => 2 } );
	$f = path();
	lives_ok { write_table( \@aoh2, $f, 'col_names' => [], 'row_names' => 1 ) }
		'AoH: empty col_names terminates';
	is( slurp($f), "\"\"\n1\n2\n", 'AoH: empty col_names leaves only numeric row labels' );

	# HoA croaks ("Could not get headers") - and that croak path must close
	# the already-open filehandle and free headers_av (regression: both leaked).
	my %hoa2 = ( 'a' => [ 1, 2 ] );
	throws_ok { write_table( \%hoa2, path(), 'col_names' => [] ) }
		qr/Could not get headers/, 'HoA: empty col_names croaks cleanly';

	no_leaks_ok {
		eval { write_table( \%hoa2, path(), 'col_names' => [] ) };
	} 'HoA: no leaks (fh, headers_av) on the empty-header croak' unless $INC{'Devel/Cover.pm'};
}

# 21. Empty col_names combined with a named row_names column exercises the
#     filtered-headers loop over an EMPTY headers array (second size_t site).
{
	my @aoh3 = ( { 'x' => 'p' }, { 'x' => 'q' } );
	my $f = path();
	lives_ok { write_table( \@aoh3, $f, 'col_names' => [], 'row_names' => 'x' ) }
		"AoH: empty col_names + row_names => 'x' terminates (filtered-header loop)";
	is( slurp($f), "x\np\nq\n", 'AoH: row labels taken from x, under its name; no data columns' );
}

# 22. Numeric row labels in sequence across many rows (regression guard for
#     the per-row label buffer: each label must be printed before reuse).
{
	my @many = map { { 'v' => $_ * 10 } } 1 .. 12;
	my $expected = ",v\n" . join( '', map { "$_," . ( $_ * 10 ) . "\n" } 1 .. 12 );
	wrote_ok( $expected, 'numeric row labels 1..12 correct in sequence', \@many, 'row_names' => 1 );
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
wrote_ok( qq{a\n"x\ry"\n}, 'embedded \r is quoted', { 'a' => [ "x\ry" ] } );
# A column NAME containing the separator is quoted in the header row.
wrote_ok( qq{"a,b"\n1\n}, 'column name containing the separator is quoted',
	{ 'a,b' => [ 1 ] }, 'row_names' => 0 );
# Multi-character separator: only a full separator match triggers quoting.
wrote_ok( qq{a::b\n"x::y"::x:y\n}, 'multi-char separator: full match quotes, partial stays bare',
	{ 'a' => [ 'x::y' ], 'b' => [ 'x:y' ] }, 'sep' => '::', 'row_names' => 0 );

# 25. undef entries inside col_names are skipped, order otherwise preserved.
wrote_ok( "b,a\n2,1\n", 'undef entries in col_names are skipped',
	{ 'a' => [ 1 ], 'b' => [ 2 ] }, 'col_names' => [ 'b', undef, 'a' ] );

# 26. col_names naming a column absent from the data pads with undef_val
#     (or empty by default).
wrote_ok( "a,ghost\n1,NA\n2,NA\n", 'missing col_names column pads with undef_val',
	{ 'a' => [ 1, 2 ] }, 'col_names' => [ 'a', 'ghost' ], 'row_names' => 0, 'undef_val' => 'NA' );
wrote_ok( "a,ghost\n1,\n2,\n", 'missing col_names column pads empty by default',
	{ 'a' => [ 1, 2 ] }, 'col_names' => [ 'a', 'ghost' ], 'row_names' => 0 );

# 27. Empty data is a table with no rows, and is written as one.  Up to 0.3212
#     it returned before a file was opened, so nothing was written and nothing
#     said, and a script that went on to read the file found it missing.  The
#     header is whatever col_names and row_names give: pandas 3.0.4
#     tests/io/formats/test_to_csv.py, test_empty_dataframe, pins ",A\n" for
#     DataFrame({"A": []}).to_csv(), whose index gives the leading empty cell
#     row_names => 1 gives here.  With no columns at all the header is a lone
#     empty record, which is also what a flat hash with col_names => [] writes.
{
	my $f = path();
	my @r = write_table( {}, $f, quiet => 1 );
	is( scalar @r, 0, 'empty hash returns an empty list' );
	is( slurp($f), "\n", 'empty hash writes a file holding one empty header record' );
	$f = path();
	@r = write_table( [], $f, quiet => 1 );
	is( scalar @r, 0, 'empty array returns an empty list' );
	is( slurp($f), "\n", 'empty array writes a file holding one empty header record' );
	wrote_ok( ",A\n", 'empty data with col_names and row_names => 1: pandas test_empty_dataframe',
		[], 'col_names' => ['A'], 'row_names' => 1, quiet => 1 );
	wrote_ok( "A,B\n", 'empty data with col_names: the header alone', {}, 'col_names' => [qw(A B)], quiet => 1 );
	wrote_ok( "id,A\n", "empty data with row_names => 'id': the label column is named", [],
		'col_names' => ['A'], 'row_names' => 'id', quiet => 1 );
}

# 28. Documented limitation: a positional filename equal to an option key is
#     not consumed as a filename (use file => 'sep' for such names).
dies_ok { write_table( { 'a' => 1 }, 'sep' ) }
	"positional filename 'sep' collides with an option key and dies";

# 29. Header loop index width: >65535 columns must terminate (regression:
#     'unsigned short' loop index wrapped and never finished). Gated because
#     it builds a 70k-key hash. Default row_names on -> a leading label cell.
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
	write_table( { $row => { 'a' => 9 } }, $f, 'row_names' => 1 );
	is( slurp($f), ",a\nzeile\x{e2}\x{98}\x{ba},9\n",
		'wide-character HoH row key sorts and fetches correctly (UTF-8 bytes on disk)' );
}

# 31+. Non-ASCII / UTF-8 write coverage and full write->read round trips.
#
# write_table opens the output as a byte stream (PerlIO_open ... "w") and writes
# each cell's bytes verbatim via SvPV: a byte string is written as-is, and a
# wide-character (UTF-8-flagged) string is written as its internal UTF-8 bytes.
# Test 30 above covered wide-character KEYS; the tests below cover non-ASCII
# VALUES and prove that write_table + read_table round-trip non-ASCII data
# byte-for-byte. Byte values are spelled out explicitly (\xC3\xA9 = LATIN SMALL
# LETTER E WITH ACUTE, \xE2\x98\x83 = SNOWMAN) so the expectations never depend
# on this file's own on-disk encoding.
my $utf8_cafe = "caf\xC3\xA9";	# 'cafe' + e-acute  (byte string, no UTF-8 flag)
my $utf8_ole  = "ol\xC3\xA9";	# 'ol'  + e-acute
my $utf8_snow = "\xE2\x98\x83";	# U+2603 SNOWMAN

# 31. A non-ASCII byte value is written verbatim (flat hash, no quoting needed).
wrote_ok( "greeting\n$utf8_cafe\n", 'UTF-8 bytes in a value are written verbatim',
	{ 'greeting' => $utf8_cafe }, 'row_names' => 0 );

# 32. A non-ASCII value that also contains the separator is quoted, bytes intact.
wrote_ok( qq{a\n"$utf8_cafe,$utf8_ole"\n},
	'UTF-8 value containing the separator is quoted, bytes preserved',
	{ 'a' => [ "$utf8_cafe,$utf8_ole" ] } );

# 33. A wide-character (UTF-8-flagged, code point > 0xFF) VALUE is written as
#     its UTF-8 bytes -- the value-side analogue of test 30's key check. Asked
#     for with row_names => 1 so the outer key 'r1' is exercised as a label too.
{
	my $f = path();
	write_table( { 'r1' => { 'a' => "\x{263a}" } }, $f, 'row_names' => 1 );
	is( slurp($f), ",a\nr1,\x{e2}\x{98}\x{ba}\n",
		'a wide-character value is written as its UTF-8 bytes on disk' );
}

# 34. Writing a wide-character value emits no "Wide character in print" warning:
#     the XS writes bytes straight to a byte stream, bypassing Perl's print.
{
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	write_table( { 'r1' => { 'a' => "\x{263a}" } }, path(), 'row_names' => 'id' );
	is( scalar @warnings, 0, 'writing a wide-character value emits no warnings' )
		or diag "warnings seen: @warnings";
}
no_leaks_ok {
	eval { write_table( { 'r1' => { 'a' => "\x{263a}" } }, path() ) };
} 'write_table: no memory leaks writing a wide-character value' unless $INC{'Devel/Cover.pm'};

# 35. Full round trip: write non-ASCII column names and values, then read them
#     back in the aoh and hoa shapes. Both functions are byte-transparent, so
#     the bytes must survive identically.
{
	my $f = path();
	write_table( [ { $utf8_cafe => $utf8_ole, 'city' => $utf8_snow } ], $f, 'row_names' => 0 );
	ok( index( slurp($f), $utf8_ole )  >= 0, 'round trip: UTF-8 value bytes reached the disk' );
	ok( index( slurp($f), $utf8_cafe ) >= 0, 'round trip: UTF-8 column-name bytes reached the disk' );

	my $aoh = read_table( $f );
	is( $aoh->[0]{$utf8_cafe}, $utf8_ole,  'round trip (aoh): value under a non-ASCII column name is byte-identical' );
	is( $aoh->[0]{'city'},     $utf8_snow, 'round trip (aoh): a non-ASCII value is byte-identical' );

	my $hoa = read_table( $f, 'output_type' => 'hoa' );
	is( $hoa->{$utf8_cafe}[0], $utf8_ole,  'round trip (hoa): value under a non-ASCII column key is byte-identical' );
	is( $hoa->{'city'}[0],     $utf8_snow, 'round trip (hoa): a non-ASCII column value is byte-identical' );
}

# 36. Round trip through the hoh shape with a non-ASCII row key and value.
{
	my $f = path();
	write_table( [ { 'id' => $utf8_snow, 'val' => $utf8_cafe } ], $f, 'row_names' => 0 );
	my $hoh = read_table( $f, 'output_type' => 'hoh', 'row_names' => 'id' );
	ok( exists $hoh->{$utf8_snow}, 'round trip (hoh): a non-ASCII row key survives' );
	is( $hoh->{$utf8_snow}{'val'}, $utf8_cafe,
		'round trip (hoh): the value under a non-ASCII row key is byte-identical' );
}
no_leaks_ok {
	eval {
		my $f = path();
		write_table( [ { $utf8_cafe => $utf8_ole, 'city' => $utf8_snow } ], $f, 'row_names' => 0 );
		read_table( $f );
	};
} 'write_table/read_table: no memory leaks on a UTF-8 round trip' unless $INC{'Devel/Cover.pm'};

# 36. A header cell with no name is warned about. For a HoH the empty cell is the
#     key column's, which row_names can name, so the warning says how; the
#     other shapes write that cell empty only when row_names => 1 asked for it,
#     by R's convention, and nothing can name it, so they stay quiet. A data
#     column with an empty name is warned about in every shape.
{
	my $warns = sub {
		my ($code) = @_;
		my @w;
		local $SIG{__WARN__} = sub { push @w, @_ };
		$code->();
		return \@w;
	};
	my %hoh = ( 'r1' => { 'a' => 1 }, 'r2' => { 'a' => 2 } );
	my $rn_re = qr/^write_table: the row-name column \(column 1\) of '[^']*' has no name in the header; name it with row_names => 'name', or drop it with row_names => 0$/;
	my $f = path();
	my $w = $warns->( sub { write_table( \%hoh, $f ) } );
	is( scalar @$w, 1, 'HoH, default row_names: one warning' );
	like( $w->[0], $rn_re, 'HoH, default row_names: the warning names row_names' );
	like( $w->[0], qr/\Q$f\E/, 'HoH, default row_names: the warning names the file' );
	is( slurp($f), ",a\nr1,1\nr2,2\n", 'HoH, default row_names: the output is unchanged' );
	$w = $warns->( sub { write_table( \%hoh, path(), 'row_names' => 1 ) } );
	is( scalar @$w, 1, 'HoH, row_names => 1: one warning' );
	like( $w->[0], $rn_re, 'HoH, row_names => 1: the warning names row_names' );
	$f = path();
	$w = $warns->( sub { write_table( \%hoh, $f, 'row_names' => 'id' ) } );
	is( scalar @$w, 0, 'HoH, row_names => name: no warning' ) or diag "@$w";
	is( slurp($f), "id,a\nr1,1\nr2,2\n", 'HoH, row_names => name: the key column is named' );
	$w = $warns->( sub { write_table( \%hoh, path(), 'row_names' => 0 ) } );
	is( scalar @$w, 0, 'HoH, row_names => 0: no warning' ) or diag "@$w";
	$w = $warns->( sub { write_table( \%hoh, path('t.tex'), quiet => 1 ) } );
	is( scalar @$w, 1, 'HoH to LaTeX, default row_names: one warning' );
	like( $w->[0], $rn_re, 'HoH to LaTeX: the same warning' );
	$w = $warns->( sub { write_table( \%hoh, path('t.xlsx'), quiet => 1 ) } );
	is( scalar @$w, 1, 'HoH to .xlsx, default row_names: one warning' );
	like( $w->[0], $rn_re, 'HoH to .xlsx: the same warning' );

	my @aoh = ( { 'a' => 1 }, { 'a' => 2 } );
	$f = path();
	$w = $warns->( sub { write_table( \@aoh, $f, 'row_names' => 1 ) } );
	is( scalar @$w, 0, 'AoH, row_names => 1: no warning for the R-style label cell' ) or diag "@$w";
	is( slurp($f), ",a\n1,1\n2,2\n", 'AoH, row_names => 1: the label cell is still empty' );
	$w = $warns->( sub { write_table( { 'a' => [1], 'b' => [2] }, path(), 'row_names' => 1 ) } );
	is( scalar @$w, 0, 'HoA, row_names => 1: no warning' ) or diag "@$w";
	$w = $warns->( sub { write_table( { 'a' => 1 }, path(), 'row_names' => 1 ) } );
	is( scalar @$w, 0, 'flat hash, row_names => 1: no warning' ) or diag "@$w";
	$w = $warns->( sub { write_table( [ ['a'], [1] ], path(), 'row_names' => 1 ) } );
	is( scalar @$w, 0, 'AoA, row_names => 1: no warning' ) or diag "@$w";

	$f = path();
	$w = $warns->( sub { write_table( [ [ '', 'b', undef ], [ 1, 2, 3 ] ], $f ) } );
	is( scalar @$w, 1, 'AoA with two unnamed header cells: one warning' );
	like( $w->[0], qr/^write_table: 2 columns of '\Q$f\E' have no name in the header \(the first is column 1\)$/,
		'AoA: the warning counts the unnamed columns and gives the first' );
	is( slurp($f), ",b,\n1,2,3\n", 'AoA with unnamed header cells: the output is unchanged' );
	$f = path();
	$w = $warns->( sub { write_table( \@aoh, $f, 'col_names' => [ 'a', '' ], 'row_names' => 1 ) } );
	is( scalar @$w, 1, 'AoH, an empty col_names entry: one warning' );
	like( $w->[0], qr/^write_table: 1 column of '\Q$f\E' has no name in the header \(the first is column 3\)$/,
		'AoH: the column number counts the label column' );
	$w = $warns->( sub { write_table( \%hoh, path(), 'col_names' => [''] ) } );
	is( scalar @$w, 2, 'HoH, default row_names and an empty col_names entry: both warnings' );
}
no_leaks_ok {
	local $SIG{__WARN__} = sub {};
	write_table( { 'r1' => { 'a' => 1 } }, path(), 'col_names' => [ 'a', '' ] );
} 'write_table: no memory leaks when warning about unnamed columns' unless $INC{'Devel/Cover.pm'};
# The warnings are given after the file is written and every buffer released,
# so a __WARN__ handler that dies loses nothing and leaks nothing.
{
	my $f = path();
	eval {
		local $SIG{__WARN__} = sub { die @_ };
		write_table( { 'r1' => { 'a' => 1 } }, $f, quiet => 1 );
	};
	like( $@, qr/^write_table: the row-name column/, 'a dying __WARN__ handler sees the warning' );
	is( slurp($f), ",a\nr1,1\n", 'a dying __WARN__ handler still leaves the whole file' );
}
no_leaks_ok {
	local $SIG{__WARN__} = sub { die @_ };
	eval { write_table( { 'r1' => { 'a' => 1 } }, path(), 'col_names' => [ 'a', '' ], quiet => 1 ) };
} 'write_table: no memory leaks when a __WARN__ handler dies' unless $INC{'Devel/Cover.pm'};

# 37. What 0.3212 fixed, one block apiece.
{
	my $capture = sub {
		my ($code) = @_;
		my @w;
		local $SIG{__WARN__} = sub { push @w, @_ };
		$code->();
		return \@w;
	};

	# A write that fails reports it.  The buffer goes out at the close, which
	# nothing checked, so a table written to a full disk returned normally and
	# announced itself.  R's own tests/reg-tests-1d.R (PR#17243) writes to
	# /dev/full and expects R to complain, and guards the test the same way:
	# only where /dev/full exists and can be written.
	SKIP: {
		skip 'no writable /dev/full here', 7 unless -e '/dev/full' && -w '/dev/full';
		my @big = map { { a => $_, b => 'x' x 50 } } 1 .. 20000;
		# The message gives the system's reason, which is what tells a full disk
		# from a quota or an I/O error; $! is formatted here the way the XS reads
		# it, so the text matches in any locale.
		require Errno;
		my $enospc = do { local $! = Errno::ENOSPC(); "$!" };
		foreach my $c ( [ 'small csv', [ { a => 1 } ], [] ], [ 'large csv', \@big, [] ],
		                [ 'LaTeX', [ { a => 1 } ], [ tex => 1 ] ], [ '.xlsx', \@big, [ xlsx => 1 ] ] ) {
			my ($what, $data, $opts) = @$c;
			throws_ok { write_table( $data, '/dev/full', @$opts, quiet => 1 ) }
				qr{^write_table: could not finish writing '/dev/full': \Q$enospc\E\n\z},
				"a full disk croaks, and says why: $what";
		}
		eval { write_table( [ { a => 1 } ], '/dev/full', quiet => 1 ) };
		ok( $!{ENOSPC}, 'a full disk: $! says why too' );
		no_leaks_ok { eval { write_table( [ { a => 1 } ], '/dev/full', quiet => 1 ) } }
			'a full disk: no leaks' unless $INC{'Devel/Cover.pm'};
		no_leaks_ok { eval { write_table( [ { a => 1 } ], '/dev/full', xlsx => 1, quiet => 1 ) } }
			'a full disk: no leaks, .xlsx' unless $INC{'Devel/Cover.pm'};
	}

	# A file that cannot be opened says why, as a file that cannot be finished does.
	{
		require Errno;
		my $enoent = do { local $! = Errno::ENOENT(); "$!" };
		foreach my $name ( 'x.csv', 'x.tex', 'x.xlsx' ) {
			my $f = "$dir/no/such/directory/$name";
			throws_ok { write_table( [ { a => 1 } ], $f, quiet => 1 ) }
				qr{^write_table: Could not open '\Q$f\E' for writing: \Q$enoent\E at },
				"an unopenable $name says why";
		}
	}

	# Tied rows and columns.  A tied hash or array hands back a proxy that has no
	# value until its FETCH runs, and SvOK() does not run it, so every cell of a
	# tied row or column was written empty.  Tie::IxHash, which keeps a hash's
	# keys in order, is the usual way to meet this.
	require Tie::Hash;
	require Tie::Array;
	my @plain_rows = ( { a => 1, b => 'x' }, { a => 2, b => 'y' } );
	my @tied_rows = map { tie my %h, 'Tie::StdHash'; %h = %$_; \%h } @plain_rows;
	my %plain_cols = ( a => [ 1, 2 ], b => [ 'x', 'y' ] );
	my %tied_cols = map { tie my @c, 'Tie::StdArray'; @c = @{ $plain_cols{$_} }; ( $_ => \@c ) } keys %plain_cols;
	tie my %tied_top, 'Tie::StdHash';
	%tied_top = %plain_cols;
	tie my @tied_list, 'Tie::StdArray';
	@tied_list = @plain_rows;
	my $expect = "a,b\n1,x\n2,y\n";
	foreach my $c ( [ 'AoH of tied hashes', \@tied_rows ], [ 'HoA of tied arrays', \%tied_cols ],
	                [ 'a tied HoA', \%tied_top ], [ 'a tied AoH', \@tied_list ] ) {
		my ($what, $data) = @$c;
		my $f = path();
		write_table( $data, $f, quiet => 1 );
		is( slurp($f), $expect, "tied data is written: $what" );
		my $x = path('tied.xlsx');
		write_table( $data, $x, quiet => 1 );
		is_deeply( read_table($x, 'output_type' => 'aoh'), read_table($f, 'output_type' => 'aoh'), "tied data is written: $what, .xlsx" );
	}
	# A FETCH that dies is a croak like any other: the handle is closed and
	# nothing leaks.
	{
		package DyingHash;
		our @ISA = ('Tie::StdHash');
		sub FETCH { die "FETCH failed\n" }
	}
	tie my %dying, 'DyingHash';
	%dying = ( a => 1 );
	throws_ok { write_table( [ { a => 0 }, \%dying ], path(), quiet => 1 ) } qr/^FETCH failed/,
		'a dying FETCH propagates';
	no_leaks_ok { eval { write_table( [ { a => 0 }, \%dying ], path(), quiet => 1 ) } }
		'a dying FETCH leaks nothing' unless $INC{'Devel/Cover.pm'};

	# A number is formatted without caching the text in the caller's SV.  SvPV()
	# upgrades the SV it formats to carry a string buffer, and a numeric table
	# came back from write_table about three times its size.
	require B;
	my @cells = ( 0.37, 12345, -1e300 );
	my @before = map { ref B::svref_2object( \$_ ) } @cells;
	write_table( { v => \@cells }, path(), quiet => 1 );
	is_deeply( [ map { ref B::svref_2object( \$_ ) } @cells ], \@before, 'numeric cells are not upgraded by being written' );
	wrote_ok( "v\n0.37\n12345\n-1e+300\n", 'numeric cells are written as perl formats them', { v => [ 0.37, 12345, -1e300 ] }, quiet => 1 );

	# An array of arrays' row longer than its header: the header is widened
	# with empty cells, where the extra cells used to be dropped without a word,
	# and the long rows are warned about.  pandas pads DataFrame([[1, 2], [4, 5, 6]])
	# the same way (tests/io/json/test_pandas.py, test_frame_from_json_missing_data).
	my $f = path();
	my $w = $capture->( sub { write_table( [ [qw(a b)], [ 1, 2, 3 ], [ 4, 5 ] ], $f, quiet => 1 ) } );
	is( slurp($f), "a,b,\n1,2,3\n4,5,\n", 'AoA: a long row widens the header, and nothing is dropped' );
	is( scalar @$w, 1, 'AoA: one warning for the long row, and none for the widened cells' );
	like( $w->[0], qr/^write_table: 1 data row of '\Q$f\E' has more cells than the header's 2 \(the first is row 1, with 3\)/,
		'AoA: the warning counts the long rows and gives the first' );
	$f = path();
	$w = $capture->( sub { write_table( [ [ 1, 2, 3 ], [ 4, 5, 6 ] ], $f, 'col_names' => [qw(a b)], quiet => 1 ) } );
	is( slurp($f), "a,b,\n1,2,3\n4,5,6\n", 'AoA with col_names: a long row widens the header too' );
	like( $w->[0], qr/^write_table: 2 data rows of '\Q$f\E' have more cells than the header's 2/, 'AoA with col_names: warned' );
	$f = path();
	$w = $capture->( sub { write_table( [ [ '', 'b' ], [ 1, 2, 3 ] ], $f, quiet => 1 ) } );
	is( scalar @$w, 2, 'AoA: a long row and an unnamed column are two warnings' );
	like( $w->[0], qr/1 column of '\Q$f\E' has no name in the header \(the first is column 1\)/,
		'AoA: the unnamed-column warning counts only the columns the data named' );

	# A HoA's row count comes from the columns written.  col_names leaving out a
	# longer array used to add rows of nothing but separators.
	wrote_ok( "a,b\n1,3\n2,4\n", 'HoA: rows run out with the columns written, not with every array',
		{ a => [ 1, 2 ], b => [ 3, 4 ], c => [ 1 .. 6 ] }, 'col_names' => [qw(a b)], quiet => 1 );
	wrote_ok( "c,a\n1,1\n2,2\n3,\n", 'HoA: the label column counts toward the rows',
		{ a => [ 1, 2 ], c => [ 1, 2, 3 ] }, 'col_names' => ['a'], 'row_names' => 'c', quiet => 1 );

	# A HoA col_names naming no column is refused before the file is opened,
	# so an existing file of that name survives.  It used to be emptied first.
	$f = path();
	open my $keep, '>', $f or die "cannot write $f: $!";
	print {$keep} "precious\n";
	close $keep;
	throws_ok { write_table( { a => [1] }, $f, 'col_names' => [] ) } qr/Could not get headers/,
		'HoA: an empty col_names still croaks';
	is( slurp($f), "precious\n", 'HoA: an empty col_names leaves an existing file intact' );
	throws_ok { write_table( { a => [1] }, $f, 'col_names' => [undef] ) } qr/Could not get headers/,
		'HoA: a col_names of nothing but undef croaks the same way';

	# A cell holding a NUL is written whole, raw and unquoted -- what CPython
	# 3.14.2's csv.writer and pandas 3.0.4's to_csv() both write (run, not pinned
	# by either suite).  It used to be cut at the NUL.
	wrote_ok( "a,b\nx\0y,2\n", 'a NUL in a cell is written whole', [ { a => "x\0y", b => 2 } ], quiet => 1 );
	wrote_ok( "a\0b\n1\n", 'a NUL in a header is written whole', [ { "a\0b" => 1 } ], quiet => 1 );
	wrote_ok( "a\nNA\0NA\n", 'a NUL in undef_val is written whole', [ { a => undef } ], 'undef_val' => "NA\0NA", quiet => 1 );

	# A LaTeX table with no columns is "Missing # inserted in alignment
	# preamble" to LaTeX.  It is refused before the file is opened.
	$f = path('none.tex');
	open $keep, '>', $f or die "cannot write $f: $!";
	print {$keep} "precious\n";
	close $keep;
	throws_ok { write_table( [], $f, quiet => 1 ) } qr/^write_table: '\Q$f\E' would be a LaTeX table with no columns/,
		'LaTeX: a table with no columns croaks';
	is( slurp($f), "precious\n", 'LaTeX: and leaves an existing file intact' );
	throws_ok { write_table( [ [] ], path('none2.tex'), quiet => 1 ) } qr/no columns/,
		'LaTeX: an AoA whose header row is empty croaks too';
}
done_testing();
