#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
use feature 'say';
use Stats::LikeR;
use File::Temp qw(tempfile);
use Test::More;

# --- optional test modules: import if present, else install skipping stubs ---
BEGIN {
	if (eval { require Test::Exception; 1 }) {
		Test::Exception->import;
	} else {
		*throws_ok = sub (&;$$) { SKIP: { skip 'Test::Exception not installed', 1 } };
		*dies_ok   = sub (&;$)	{ SKIP: { skip 'Test::Exception not installed', 1 } };
		*lives_ok  = sub (&;$)	{ SKIP: { skip 'Test::Exception not installed', 1 } };
	}
}

# Custom helper for floating-point comparisons
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	my $i = 0;
	foreach my $arg ($got, $expected, $test_name) {
		next if defined $arg;
		die "\$arg[$i] (see subroutine signature for name) isn't defined in $current_sub";
		$i++;
	}
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) {
		pass("$test_name: within $epsilon");
		return 1;
	} else {
		fail($test_name);
		diag("		   got: $got\n	  expected: $expected; diff = $diff");
		return 0;
	}
}

# Write $content to a throwaway .tsv (the .tsv suffix picks the tab default sep).
sub write_tmp_tsv {
	my ($content) = @_;
	my ($fh, $path) = tempfile('rtXXXXXX', SUFFIX => '.tsv', TMPDIR => 1, UNLINK => 1);
	print $fh $content;
	close $fh;
	return $path;
}

# A 3-column mtcars subset as R writes it by default
# (write.table(col.names=TRUE, row.names=TRUE)): the header is one field short
# of every data row, because R omits the label for the row-names column.
my $r_default = <<"EOF";
mpg\tcyl\tdisp
Mazda RX4\t21\t6\t160
Datsun 710\t22.8\t4\t108
Valiant\t18.1\t6\t225
EOF

# 1) strict default still rejects the lopsided file (corruption guard intact)
{
	my $f = write_tmp_tsv($r_default);
	throws_ok { read_table($f) }
		qr/Alignment error.*data row 1 \(4 fields vs 3 headers\)/,
		'strict default croaks on R col.names=TRUE output';
}

# 2) auto.row.names => 1 : leading field becomes row_name, rest align
{
	my $f	= write_tmp_tsv($r_default);
	my $aoh = read_table($f, 'auto.row.names' => 1);
	is(scalar @$aoh, 3, 'auto: all 3 rows read');
	is($aoh->[0]{row_name}, 'Mazda RX4', 'auto: row_name holds the model name');
	is($aoh->[0]{mpg}, 21, 'auto: mpg aligned to its column');
	is_approx($aoh->[1]{mpg}, 22.8, 'auto: fractional value aligned');
	is($aoh->[0]{disp}, 160, 'auto: final column aligned');
}

# 3) auto.row.names => 'model' : custom name for the synthesized column
{
	my $f	= write_tmp_tsv($r_default);
	my $aoh = read_table($f, 'auto.row.names' => 'model');
	is($aoh->[2]{model}, 'Valiant', 'auto: custom column name used');
	ok(!exists $aoh->[2]{row_name}, 'auto: default name absent when custom given');
}

# 4) auto + hoh : key defaults to the synthesized first column (the model)
{
	my $f	= write_tmp_tsv($r_default);
	my $hoh = read_table($f, 'output.type' => 'hoh', 'auto.row.names' => 1);
	is($hoh->{'Datsun 710'}{cyl}, 4, 'auto + hoh: keyed by model name');
	ok(!exists $hoh->{'Datsun 710'}{row_name}, 'auto + hoh: key not duplicated as a field');
}

# 5) auto + hoa : synthesized column present and columns aligned
{
	my $f	= write_tmp_tsv($r_default);
	my $hoa = read_table($f, 'output.type' => 'hoa', 'auto.row.names' => 1);
	is_deeply($hoa->{row_name}, ['Mazda RX4', 'Datsun 710', 'Valiant'],
		'auto + hoa: row_name column collected');
	is_deeply($hoa->{cyl}, [6, 4, 6], 'auto + hoa: data column aligned');
}

# 6) flag ON but the file is already aligned: no synthesis, reads normally
{
	my $f = write_tmp_tsv("a\tb\n1\t2\n3\t4\n");
	my $aoh = read_table($f, 'auto.row.names' => 1);
	is_deeply($aoh, [ { a => 1, b => 2 }, { a => 3, b => 4 } ],
		'auto: aligned file untouched (only a one-field-short header triggers)');
}

# 7) R col.names=NA output (blank leading header) still works with NO flag
{
	my $f = write_tmp_tsv("\tmpg\tcyl\nMazda RX4\t21\t6\n");
	my $aoh = read_table($f);
	is($aoh->[0]{row_name}, 'Mazda RX4', 'col.names=NA: empty header becomes row_name');
	is($aoh->[0]{mpg}, 21, 'col.names=NA: columns aligned');
}

# 8) a genuinely ragged row (two extra fields) still croaks even with the flag
{
	my $f = write_tmp_tsv("a\tb\n1\t2\t3\t4\n");
	throws_ok { read_table($f, 'auto.row.names' => 1) }
		qr/Alignment error/,
		'auto: a 2-extra-field row still croaks (only +1 is special)';
}

done_testing;
