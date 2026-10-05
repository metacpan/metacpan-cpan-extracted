#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use File::Temp;
use Stats::LikeR;
use Test::Exception; # die_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';
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

# write $content to a fresh temp file and return its path
sub tmp_csv {
	my ($content, $suffix) = @_;
	my $fh = File::Temp->new(SUFFIX => $suffix // '.csv', UNLINK => 1);
	print {$fh} $content;
	close $fh;
	return $fh->filename, $fh;	 # keep the object alive in the caller
}

# a comment line before the header is skipped (the reported bug)
{
	my ($f, $keep) = tmp_csv(<<'CSV');
# This is a comment
id,name,val
1,Alice,10.5
2,Bob,
3,Charlie,15.2
CSV
	my $r = read_table($f);
	is(scalar @$r, 3, 'three data rows parsed (comment not mistaken for a row)');
	is_deeply([sort keys %{ $r->[0] }], [qw(id name val)], 'header is id,name,val');
	is($r->[0]{name}, 'Alice', 'row 1 name');
	ok(!defined $r->[1]{val}, "row 2 (Bob) has undef for the empty val cell");
	is($r->[2]{val}, '15.2', 'row 3 val');
}

# a commented header (marker hugging content) is used as the header
{
	my ($f, $keep) = tmp_csv("#id,val\n\n   \n# a full comment line\n1,10\n2,20\n");
	is_deeply( read_table($f), [ { id => 1, val => 10 }, { id => 2, val => 20 } ],
		"a #-prefixed header has its marker stripped; blank/whitespace/comment lines skipped" );
}

# multiple leading comments, and a comment interspersed in the data
{
	my ($f, $keep) = tmp_csv(<<'CSV');
# comment one
# comment two
id,name,val
1,Alice,10.5
# mid-file comment
2,Bob,20
CSV
	my $r = read_table($f);
	is(scalar @$r, 2, 'leading and mid-file comments are all skipped');
	is($r->[1]{name}, 'Bob', 'data after a mid-file comment still parses');
}

# a file with no comment line still uses line 1 as the header
{
	my ($f, $keep) = tmp_csv("id,name\n1,Alice\n");
	my $r = read_table($f);
	is_deeply([sort keys %{ $r->[0] }], [qw(id name)], 'no-comment file: line 1 is the header');
	is($r->[0]{id}, '1', 'no-comment file: first row parsed');
}

# a comment marker INSIDE a quoted field is preserved (not treated as a comment)
{
	my ($f, $keep) = tmp_csv(<<'CSV');
id,name
1,"Charlie #3"
CSV
	my $r = read_table($f);
	is($r->[0]{name}, 'Charlie #3', 'a # inside a quoted field is kept verbatim');
}

# undef propagates through hoa and hoh outputs too
{
	my ($f, $keep) = tmp_csv(<<'CSV');
# header below
id,name,val
1,Alice,10.5
2,Bob,
CSV
	my $hoa = read_table($f, 'output_type' => 'hoa');
	ok(!defined $hoa->{val}[1], 'hoa: empty cell becomes undef');
	is($hoa->{name}[0], 'Alice', 'hoa: values intact');

	my $hoh = read_table($f, 'output_type' => 'hoh');
	ok(!defined $hoh->{'2'}{val}, 'hoh: empty cell becomes undef');
	is($hoh->{'1'}{name}, 'Alice', 'hoh: keyed by first column');
}

# a custom comment marker is honoured before the header
{
	my ($f, $keep) = tmp_csv("// note\nid,name\n1,Alice\n");
	my $r = read_table($f, comment => '//');
	is_deeply([sort keys %{ $r->[0] }], [qw(id name)], 'custom comment marker skipped before header');
}

# A commented-out header one field short of the data is what auto_row_names
# looks for, as R's read.table does with a header one field short. Up to 0.320
# the width check that confirms a commented header refused it, and the first
# data row became the header.
{
	my ($f, $keep) = tmp_csv("# a\tb\nr1\t1\t2\nr2\t3\t4\n", '.tsv');
	is_deeply( read_table($f, 'auto_row_names' => 1),
		[ { row_name => 'r1', a => 1, b => 2 }, { row_name => 'r2', a => 3, b => 4 } ],
		'auto_row_names: a commented-out header one field short is kept' );
	is_deeply( read_table($f, 'auto_row_names' => 'id', 'output_type' => 'hoh'),
		{ r1 => { a => 1, b => 2 }, r2 => { a => 3, b => 4 } },
		'auto_row_names: and names the rows of a hoh' );
	# two fields short is still a leading comment, not the header
	($f, $keep) = tmp_csv("# a\tb\nx\ty\tz\tw\n1\t2\t3\t4\n", '.tsv');
	is_deeply( read_table($f, 'auto_row_names' => 1),
		[ { x => 1, y => 2, z => 3, w => 4 } ],
		'auto_row_names: a comment two fields short is not taken for the header' );
}

# A leading comment as wide as the header is not the header. Up to 0.3213 a
# comment that split into as many fields as the next line was taken for a
# commented-out header whenever the widths matched, so here "written by foo"
# and " v2" named the columns and the file's own header became the first data
# row, without a warning. R's read.table and pandas' read_csv skip the comment.
# A commented line is now the header only when the line after it has a number
# in it, so looks like data.
{
	my ($f, $keep) = tmp_csv("# written by foo, v2\nid,val\n1,2\n");
	is_deeply( read_table($f), [ { id => 1, val => 2 } ],
		'a comment as wide as the header is a comment, not the header' );
	is_deeply( read_table($f, filter => sub { 1 }), [ { id => 1, val => 2 } ],
		'and so it is through the filter path' );
	is_deeply( read_table($f, 'output_type' => 'aoa'), [ [qw(id val)], [1, 2] ],
		'and in an aoa' );
	($f, $keep) = tmp_csv("# note\tx\nid\tval\n1\t2\n", '.tsv');
	is_deeply( read_table($f), [ { id => 1, val => 2 } ],
		'a tab-separated comment as wide as the header' );
	my $ws = qr/\s+/;
	($f, $keep) = tmp_csv("# two words\nid v\n1 2\n");
	is_deeply( read_table($f, sep => $ws), [ { id => 1, v => 2 } ],
		'a whitespace-separated comment with as many words as the header' );
	# auto_row_names: the header is the one field short of the data, not the
	# comment as wide as the header
	($f, $keep) = tmp_csv("# a\tb\nid\tv\nr1\t1\t2\n", '.tsv');
	is_deeply( read_table($f, 'auto_row_names' => 1),
		[ { row_name => 'r1', id => 1, v => 2 } ],
		'auto_row_names: a comment as wide as the header is a comment' );
	# a commented-out header over rows with a number in them is still found
	($f, $keep) = tmp_csv("# PDB\tscore\n1a2b\t10\n3c4d\t20\n", '.tsv');
	is_deeply( read_table($f),
		[ { PDB => '1a2b', score => 10 }, { PDB => '3c4d', score => 20 } ],
		'a commented-out header is still recovered over numeric data' );
	# A row of nothing but empty fields, or of na_strings tokens, is data too:
	# no header looks like either
	($f, $keep) = tmp_csv("# a\tb\n\t\nx\ty\n", '.tsv');
	is_deeply( read_table($f), [ { a => undef, b => undef }, { a => 'x', b => 'y' } ],
		'a commented-out header over a row of empty fields' );
	($f, $keep) = tmp_csv("# a\tb\nNA\tNA\nx\ty\n", '.tsv');
	is_deeply( read_table($f, 'na_strings' => 'NA'),
		[ { a => undef, b => undef }, { a => 'x', b => 'y' } ],
		'a commented-out header over a row of na_strings tokens' );
	# The limit of the rule, pinned so that moving it is deliberate: over rows
	# with no number in them, a commented-out header cannot be told from a
	# comment, and the first row is read as the header, as R and pandas read it.
	($f, $keep) = tmp_csv("# name\tcity\nAlice\tParis\nBob\tRome\n", '.tsv');
	is_deeply( read_table($f), [ { Alice => 'Bob', Paris => 'Rome' } ],
		'over all-text rows, the first row is the header' );
}

# A run of comment lines whose marker hugs the text. Up to 0.3213 the first of
# them was taken for a commented-out header on the spot, so the rest read as
# one-field data rows and the real header as an alignment error. Each is now a
# candidate, a later one replacing it, and the last is tried against the line
# after it under the rule above; if it fails, that line is the header.
#
# The first case is R 4.6.1's tests/reg-IO2.R test.dat ("comment chars in
# headers"), which R's suite reads with header = FALSE (that reading is in
# t/read_table.header_quote.R.pandas.t). The expected value is R 4.6.1's own
# dput(read.table("test.dat", header = TRUE, sep = s, colClasses =
# "character")) for s = "" and "\t", and for the "%comment" file with
# comment.char = "%"; all three give C1, C2, C3 over the rows below.
{
	my $body = qq{C1\tC2\tC3\n"Panel"\t"Area Examined"\t"# Blemishes"\n}
		. qq{"1"\t"0.8"\t"3"\n"2"\t"0.6"\t"2"\n"3"\t"0.8"\t"3"\n};
	my $want = { C1 => [ 'Panel', '1', '2', '3' ],
		C2 => [ 'Area Examined', '0.8', '0.6', '0.8' ],
		C3 => [ '# Blemishes', '3', '2', '3' ] };
	my ($f, $keep) = tmp_csv("#comment\n\n#another\n#\n#\n$body");
	is_deeply( read_table($f, sep => "\t", 'output_type' => 'hoa'), $want,
		'reg-IO2 test.dat, header = TRUE, sep = "\t": as R reads it' );
	my $ws = qr/\s+/;
	is_deeply( read_table($f, sep => $ws, 'output_type' => 'hoa'), $want,
		'reg-IO2 test.dat, header = TRUE, sep = "": as R reads it' );
	(my $pct = $body) =~ s/# Blemishes/% Blemishes/;
	($f, $keep) = tmp_csv("%comment\n\n%another\n%\n%\n$pct");
	my %pct_want = %$want;
	$pct_want{C3} = [ '% Blemishes', '3', '2', '3' ];
	is_deeply( read_table($f, sep => "\t", comment => '%', 'output_type' => 'hoa'),
		\%pct_want, 'reg-IO2 test.dat, comment.char = "%": as R reads it' );

	# the last of the run, next to the data, is the commented-out header
	($f, $keep) = tmp_csv("#written by foo\n#a,b\n1,2\n");
	is_deeply( read_table($f), [ { a => 1, b => 2 } ],
		'a run of hugging comments: the last is the header' );
	is_deeply( read_table($f, filter => sub { 1 }), [ { a => 1, b => 2 } ],
		'and so it is through the filter path' );
	# one as wide as the header is a comment, as it is in the "# " form
	($f, $keep) = tmp_csv("#note,v2\nid,val\n1,2\n");
	is_deeply( read_table($f), [ { id => 1, val => 2 } ],
		'a hugging comment as wide as the header is a comment' );
	# a "# " line, dropped by the parser, then a hugging one: the later wins
	($f, $keep) = tmp_csv("# a\tb\n#c\td\n1\t2\n", '.tsv');
	is_deeply( read_table($f), [ { c => 1, d => 2 } ],
		'a hugging comment after a "# " one replaces it as the candidate' );
	# a multi-character marker, the way a VCF's meta lines are read
	($f, $keep) = tmp_csv("##fileformat=x\n##source=y\nid\tval\n1\t2\n", '.tsv');
	is_deeply( read_table($f, comment => '##'), [ { id => 1, val => 2 } ],
		"comment => '##': a run of meta lines is skipped" );
	# auto_row_names: the last candidate one field short is the header
	($f, $keep) = tmp_csv("#note\n#a\tb\nr1\t1\t2\n", '.tsv');
	is_deeply( read_table($f, 'auto_row_names' => 1),
		[ { row_name => 'r1', a => 1, b => 2 } ],
		'auto_row_names: a hugging candidate one field short is the header' );
	# Once a header has been taken, a hugging line is data, as it has always
	# been; only the lines before the header are candidates.
	($f, $keep) = tmp_csv("id,val\n1,2\n#3,4\n");
	is_deeply( read_table($f, 'output_type' => 'aoa'),
		[ [qw(id val)], [1, 2], ['#3', 4] ],
		'a hugging line after the header is a data row' );
	is_deeply( read_table($f, 'output_type' => 'aoa', filter => sub { 1 }),
		[ [qw(id val)], [1, 2], ['#3', 4] ],
		'and so it is through the filter path' );
	# a header and no data: the last candidate is accepted
	($f, $keep) = tmp_csv("#note\n#a,b\n");
	is_deeply( read_table($f, 'output_type' => 'aoa'), [ [qw(a b)] ],
		'a run of hugging comments and no data: the last is the header' );
}

# memory
my ($lf, $lkeep) = tmp_csv(<<'CSV');
# c
id,name,val
1,Alice,10.5
2,Bob,
CSV
no_leaks_ok {
	my $r = read_table($lf);
} 'read_table: no memory leaks parsing a commented file' unless $INC{'Devel/Cover.pm'};

done_testing;
