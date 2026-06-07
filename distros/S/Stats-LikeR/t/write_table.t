use strict;
use warnings;
use Test::More;
use feature 'say';
use File::Temp qw(tempdir tempfile);
use Stats::LikeR;
use Test::Exception;
use Digest::SHA 'sha512_base64';
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
write_table(\%data, $tmp_file, sep => "\t", 'row.names' => 1);
my $str = file2string($tmp_file);
if (sha512_base64($str) eq 'FInYAXZcS7lK1n7osAhVkp5SiQNpt3h4kql9yZ2YCoPQslHKjwfGAXgdiphDSc6wMhlpU5toNmSifEUz1OgHNQ') {
	pass('write_table successfully wrote a tab-delimited file');
	unlink $tmp_file;
} else {
	fail("sha512 does not match for write_table; see $tmp_file");
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

write_table(\%data_hoh, $tmp_file, sep => "\t", 'row.names' => 1);
$str = file2string($tmp_file);
if (sha512_base64($str) eq 'ZYK6zmrT47CLrEc4PSFtCtvdkLtv47MCIMHIg70bARlWO5J9MuzybnV5h7dBSyQn8dOKojaX6pinxOvbTVaI+g') {
	pass('write_table successfully wrote a tab-delimited file (Hash of Hashes)');
	unlink $tmp_file;
} else {
	fail("sha512 does not match for write_table HoH; see $tmp_file");
}
no_leaks_ok {
	eval {
		write_table(\%data_hoh, $tmp_file, sep => "\t", 'row.names' => 1);
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

write_table(\%data_hoa, $tmp_file, sep => "\t", 'row.names' => 1);
$str = file2string($tmp_file);
if (sha512_base64($str) eq '1wv8uFDVQkQ9UZ+50n+r/Z8oj4VFP4eusApZDAY1DB3dXhT+gFFyCR2Z1ZVQDTOJrUaMRpfWt6vLSlaSsNps7g') {
    pass('write_table successfully wrote a tab-delimited file (Hash of Arrays)');
    unlink $tmp_file;
} else {
    fail("sha512 does not match for write_table HoA; see $tmp_file");
}
no_leaks_ok {
	eval {
		write_table(\%data_hoa, $tmp_file, sep => "\t", 'row.names' => 1);
	};
} 'write_table: no memory leaks with hash-of-hash input' unless $INC{'Devel/Cover.pm'};
#---------
write_table(\%data_hoa, '/tmp/undef.val.tsv', sep => "\t", 'undef.val' => 'nan');
$str = file2string('/tmp/undef.val.tsv');
if (sha512_base64($str) eq 'Pbohr5w8D4e6691E0WV3W6RjtjIEvgS1egsPixNkXhZ0Jhu3vmRHoR6Lkxsm0GBJ2c0iT7yYZq4G45w/qwDnKQ') {
	pass('undefined values are switched to nan');
} else {
	fail('undefined values are NOT switched to nan');
}

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
	'row.names' => 0
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
wrote_ok( ",age,name\n1,30,Alice\n2,25,Bob\n", 'HoA: sorted cols + numeric row names', \%hoa );
# 2. Hash of hashes: rows sorted, columns sorted, outer key as the row label.
wrote_ok( ",a,b\nr1,1,2\nr2,3,4\n", 'HoH: sorted rows and columns', \%hoh );
# 3. Array of hashes: union of keys sorted, numeric row names.
wrote_ok( ",x,y\n1,1,2\n2,3,4\n", 'AoH: union of keys, numeric row names', \@aoh );
# 4. Flat hash: one row, columns sorted.
wrote_ok( ",a,b,c\n1,1,2,3\n", 'flat hash: single row', \%flat );
# 5. col.names selects/orders columns.
wrote_ok( ",name\n1,Alice\n2,Bob\n", 'col.names selects a subset in order', \%hoa, 'col.names' => [ 'name' ] );
# 6. row.names => 0 turns off the row-name column.
wrote_ok( "age,name\n30,Alice\n25,Bob\n", 'row.names => 0 omits the label column', \%hoa, 'row.names' => 0 );
# 7. row.names => 'col' uses that column as the labels and drops it from headers.
wrote_ok( ",age\nAlice,30\nBob,25\n", "row.names => 'name' uses that column as labels", \%hoa, 'row.names' => 'name' );
# 8. Explicit separator.
wrote_ok( ";a;b;c\n1;1;2;3\n", 'sep => ";" is honored', \%flat, 'sep' => ';' );
# 9. delim is an alias for sep.
wrote_ok( "|a|b|c\n1|1|2|3\n", 'delim => "|" is honored', \%flat, 'delim' => '|' );
# 10. undef.val fills missing cells (jagged hash of arrays).
my %jag = ( 'a' => [ 1, 2 ], 'b' => [ 10 ] );
wrote_ok( ",a,b\n1,1,10\n2,2,NA\n", 'missing cells default to NA', \%jag );
wrote_ok( ",a,b\n1,1,10\n2,2,NULL\n", 'undef.val overrides the fill', \%jag, 'undef.val' => 'NULL' );
# 11. CSV quoting: separators, quotes and newlines are quoted; quotes are doubled.
my %quote = ( 'a' => [ 'x,y' ], 'b' => [ 'p"q' ], 'c' => [ "line1\nline2" ] );
wrote_ok( qq{,a,b,c\n1,"x,y","p""q","line1\nline2"\n}, 'quoting: comma, quote, newline', \%quote );
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
done_testing();
