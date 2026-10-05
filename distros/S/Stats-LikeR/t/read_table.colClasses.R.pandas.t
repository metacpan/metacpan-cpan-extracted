#!/usr/bin/env perl
#
# read_table's colClasses against the cases R's and pandas' own test suites pin
# for it.
#
# Provenance:
#   R 4.6.1, /home/con/Scripts/r-source:
#     tests/reg-tests-1c.R, PR#16478 -- kkk <- c("a\tb", "3.14\tx") read with
#       colClasses positional, named in another order, named in part, and
#       naming a column that is not there; all four must be identical(), and
#       src/library/utils/R/readtable.R (line 173) warns "not all columns
#       named in 'colClasses' exist" for the last.
#     tests/reg-IO2.R, "test of type conversion in 1.4.0 and later" (foo7),
#       with its printed result in tests/reg-IO2.Rout.save, lines 134-146.
#     What scan() accepts for a numeric or an integer field, used for the
#       recorded divergences at the end: src/main/scan.c extractItem() and
#       Strtoi(), and src/main/util.c R_strtod5().
#   pandas 3.0.4, pandas/tests/io/parser/dtypes/test_dtypes_basic.py:
#     test_dtype_per_column, test_invalid_dtype_per_column, test_numeric_dtype,
#     test_skip_whitespace, test_nullable_int_dtype, test_ea_int_avoid_overflow
#     and test_raise_on_passed_int_dtype_with_nas.  pandas spells the option
#     dtype; the classes map as float64 -> 'numeric', an integer dtype ->
#     'integer', str -> 'character'.
#
# Every expected value is a literal here; nothing calls R or Python.  What a
# cell is stored as -- an NV, an IV, a string, undef -- is checked through B,
# since `is` cannot tell 3.14 from "3.14".

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Config;
use B ();
use File::Temp ();
use File::Spec;
use Stats::LikeR qw(read_table);

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $n = 0;
sub fixture {
	my ($text, $ext) = @_;
	my $path = File::Spec->catfile($dir, 'f' . $n++ . ($ext // '.csv'));
	open my $fh, '>', $path or die "cannot write $path: $!";
	print {$fh} $text;
	close $fh or die "cannot write $path: $!";
	return $path;
}

# 'NV', 'IV', 'PV' or 'undef': what read_table stored, read off the SV itself
sub kind {
	my ($ref) = @_;
	my $f = B::svref_2object($ref)->FLAGS;
	return $f & B::SVf_POK ? 'PV' : $f & B::SVf_NOK ? 'NV' : $f & B::SVf_IOK ? 'IV' : 'undef';
}

# --- R PR#16478 ------------------------------------------------------------------
{
	my $kkk = fixture("a\tb\n3.14\tx\n", '.tsv');
	my $z1 = read_table($kkk, colClasses => ['numeric', 'character']);
	my $z2 = read_table($kkk, colClasses => { b => 'character', a => 'numeric' });
	my @w;
	my $z4 = do {
		local $SIG{__WARN__} = sub { push @w, $_[0] };
		read_table($kkk, colClasses => { c => 'integer', b => 'character', a => 'numeric' });
	};
	is_deeply($z1, [{ a => 3.14, b => 'x' }], 'PR#16478: a is 3.14 and b is "x"');
	is(kind(\$z1->[0]{a}), 'NV', 'PR#16478: a is stored as a number');
	is(kind(\$z1->[0]{b}), 'PV', 'PR#16478: b is stored as text');
	is_deeply($z2, $z1, 'PR#16478: by name, in another order, is the same as by position');
	is(kind(\$z2->[0]{a}), 'NV', 'PR#16478: ... and a is a number by name too');
	is_deeply($z4, $z1, 'PR#16478: naming a column that is not there changes nothing else');
	is_deeply(\@w, ["read_table: not all columns named in 'colClasses' exist\n"],
	          "PR#16478: ... but is warned about, in readtable.R's words");
	# z3 names b only.  R's default for a, type.convert(), makes it 3.14 all
	# the same; read_table's default keeps a column as read, so here a is the
	# text "3.14".  Recorded, not hidden: equal as a value, not as a type.
	my $z3 = read_table($kkk, colClasses => { b => 'character' });
	is($z3->[0]{a}, '3.14', 'PR#16478 z3: a has the same value');
	is(kind(\$z3->[0]{a}), 'PV', 'PR#16478 z3: DIVERGES from R: an undeclared column stays text');
}

# --- R reg-IO2.R foo7 --------------------------------------------------------------
{
	my $foo7 = fixture(join('', "A B C D E F\n", "1 1 1.1 1.1+0i NA F abc\n",
	                       "2 NA NA NA NA NA NA\n", "3 1 2 3 NA TRUE def\n"), '.txt');
	# R's res2 used c("character", rep("numeric", 2), "complex", "integer",
	# "logical", "character"), the first entry for the row-names column R adds
	# because the header is one name short.  read_table has no complex or
	# logical class, so those two columns are read as they are; R's default
	# na.strings = "NA" is spelled out.
	my $r = read_table($foo7, sep => ' ', 'auto_row_names' => 1, 'na_strings' => 'NA',
		colClasses => ['character', 'numeric', 'numeric', undef, 'integer', undef, 'character']);
	# reg-IO2.Rout.save lines 137-140:
	#      A   B      C  D     E    F
	#   1  1 1.1 1.1+0i NA FALSE  abc
	#   2 NA  NA     NA NA    NA <NA>
	#   3  1 2.0 3.0+0i NA  TRUE  def
	is_deeply([ map { $_->{row_name} } @$r ], ['1', '2', '3'], 'foo7: row names, as character');
	is_deeply([ map { $_->{A} } @$r ], [1, undef, 1],     'foo7: A');
	is_deeply([ map { $_->{B} } @$r ], [1.1, undef, 2],   'foo7: B');
	is_deeply([ map { $_->{D} } @$r ], [undef, undef, undef], 'foo7: D, integer and all NA');
	is_deeply([ map { $_->{F} } @$r ], ['abc', undef, 'def'], 'foo7: F, character, NA included');
	is_deeply([ map { kind(\$_->{A}) } @$r ], ['NV', 'undef', 'NV'], 'foo7: A is numeric ("double")');
	is_deeply([ map { kind(\$_->{B}) } @$r ], ['NV', 'undef', 'NV'], 'foo7: B is numeric ("double")');
	is(kind(\$r->[0]{row_name}), 'PV', 'foo7: the row names are character');
	is_deeply([ map { $_->{C} } @$r ], ['1.1+0i', undef, '3'],  'foo7: C, which R reads as complex, is as read');
	is_deeply([ map { $_->{E} } @$r ], ['F', undef, 'TRUE'],    'foo7: E, which R reads as logical, is as read');
}

# --- pandas test_dtype_per_column ----------------------------------------------------
{
	my $f = fixture("one,two\n1,2.5\n2,3.5\n3,4.5\n4,5.5");
	my $r = read_table($f, 'output_type' => 'hoa', colClasses => { one => 'numeric', two => 'character' });
	is_deeply($r, { one => [1, 2, 3, 4], two => ['2.5', '3.5', '4.5', '5.5'] }, 'pandas dtype_per_column');
	is_deeply([ map { kind(\$_) } @{ $r->{one} } ], [('NV') x 4], 'pandas dtype_per_column: one is float64');
	is_deeply([ map { kind(\$_) } @{ $r->{two} } ], [('PV') x 4], 'pandas dtype_per_column: two is str');
	eval { read_table($f, colClasses => { one => 'foo', two => 'integer' }) };
	like($@, qr/^read_table: colClasses 'foo' is not one read_table reads/,
	     'pandas invalid_dtype_per_column: an unknown class is refused');
}

# --- pandas test_numeric_dtype -------------------------------------------------------
for my $cls (qw(numeric integer)) {
	my $r = read_table(fixture("0\n1"), header => 0, 'output_type' => 'hoa', colClasses => $cls);
	is_deeply($r->{V1}, [0, 1], "pandas numeric_dtype ($cls)");
	is_deeply([ map { kind(\$_) } @{ $r->{V1} } ], [ ($cls eq 'numeric' ? 'NV' : 'IV') x 2 ],
	          "pandas numeric_dtype ($cls): stored as that kind");
}

# --- pandas test_skip_whitespace -------------------------------------------------------
{
	my $f = fixture("id\tnum\t\n1\t1.2 \t\n1\t 2.1\t\n2\t 1\t\n2\t 1.2 \t\n", '.tsv');
	# dtype={1: np.float64} is by position; a short list is recycled, as R
	# recycles colClasses, so [undef, 'numeric'] declares the second column only
	my $r = read_table($f, 'output_type' => 'hoa', colClasses => [undef, 'numeric']);
	is_deeply($r->{num}, [1.2, 2.1, 1.0, 1.2], 'pandas skip_whitespace: blanks around a float');
	is_deeply($r->{id}, ['1', '1', '2', '2'], 'pandas skip_whitespace: id as read');
}

# --- pandas test_nullable_int_dtype ----------------------------------------------------
{
	my $r = read_table(fixture("a,b,c\n,3,5\n1,,6\n2,4,"), 'output_type' => 'hoa', colClasses => 'integer');
	is_deeply($r, { a => [undef, 1, 2], b => [3, undef, 4], c => [5, 6, undef] }, 'pandas nullable_int_dtype');
	is_deeply([ map { kind(\$_) } @{ $r->{a} } ], ['undef', 'IV', 'IV'], 'pandas nullable_int_dtype: IVs and undef');
	# test_raise_on_passed_int_dtype_with_nas raises "Integer column has NA
	# values" for numpy's int64, which has no NA; R's integer and pandas'
	# nullable Int64 both have one, and so does this: undef.
}

# --- pandas test_ea_int_avoid_overflow --------------------------------------------------
{
	my $f = fixture("a,b\n1,1\n,1\n1582218195625938945,1\n");
	if ($Config{ivsize} >= 8) {
		my $r = read_table($f, 'output_type' => 'hoa', colClasses => { a => 'integer' });
		is_deeply($r->{a}, [1, undef, '1582218195625938945'], 'pandas ea_int_avoid_overflow: exact');
		is(kind(\$r->{a}[2]), 'IV', 'pandas ea_int_avoid_overflow: an IV, not an NV that rounds');
	} else {	# a 32-bit IV cannot hold it, and that is said, not rounded
		eval { read_table($f, colClasses => { a => 'integer' }) };
		like($@, qr/^read_table: colClasses makes column 'a' \(field 1\) integer, but data row 3 of \S+ has '1582218195625938945' there$/,
		     'pandas ea_int_avoid_overflow: past a 32-bit IV, refused');
		pass('pandas ea_int_avoid_overflow: (no IV check on a 32-bit IV)');
	}
}

# --- divergences from R, recorded -------------------------------------------------------
# Each is what R 4.6.1's scan() does with the text, from its source (see the
# header); read_table's answer is pinned so that changing it is deliberate.
{
	my $f = fixture("x\n0x1A\n");
	eval { read_table($f, colClasses => 'numeric') };
	like($@, qr/has '0x1A' there/, 'DIVERGES: hexadecimal is refused; R_strtod5() reads "0x1A" as 26');
	$f = fixture("x\n1e\n");
	eval { read_table($f, colClasses => 'numeric') };
	like($@, qr/has '1e' there/, 'DIVERGES: an exponent needs digits; R_strtod5() reads "1e" as 1');
	if ($Config{ivsize} >= 8) {
		my $r = read_table(fixture("x\n2147483648\n"), colClasses => 'integer');
		is($r->[0]{x}, 2147483648, 'DIVERGES: an integer is any IV; R\'s Strtoi() refuses past INT_MAX');
	} else {
		pass('(no 64-bit IV here: 2147483648 is past IV_MAX, as it is past R\'s INT_MAX)');
	}
	# the same as R: strtol() takes a leading blank and nothing after the digits
	is(read_table(fixture("x\n 5\n"), colClasses => 'integer')->[0]{x}, 5, 'as R: an integer may have a leading blank');
	eval { read_table(fixture("x\n5 \n"), colClasses => 'integer') };
	like($@, qr/has '5 ' there/, 'as R: an integer may not have a trailing one');
	eval { read_table(fixture("x\nNA\n"), colClasses => 'numeric') };
	like($@, qr/has 'NA' there/, 'as R: "NA" is missing only through na_strings (scan() is called with NA off)');
}

done_testing();
