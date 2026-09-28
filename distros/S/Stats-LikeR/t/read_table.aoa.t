#!/usr/bin/env perl
# read_table(..., 'output.type' => 'aoa'): the header row, then one array per
# data row, every row in file column order.
#
# There is no R or SciPy suite to take these from. R's read.table always gives
# a data frame and pandas' read_csv a DataFrame; the nearest thing to this
# shape is the list of lists Python's csv.reader yields, which this matches
# except that an empty field is undef here, as it is in every other
# read_table shape. So an aoa is checked against what read_table's own aoh
# reads from the same file, which t/read_table.header_quote.R.pandas.t and
# t/read_table.regex_sep.t already pin to R and pandas, and against
# write_table, since the point of the header row is that the two round-trip.
# That the fast path and the closure agree is in t/read_table.fast_path.t, and
# the .xlsx reader's aoa in t/read_table.xlsx.t.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use File::Temp ();
use File::Spec ();
use Stats::LikeR qw(read_table write_table);

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $seq = 0;
sub fixture {
	my ($text, $ext) = @_;
	my $path = File::Spec->catfile($dir, 'f' . $seq++ . ($ext // '.csv'));
	open my $fh, '>', $path or die "cannot write \"$path\": $!\n";
	binmode $fh;
	print {$fh} $text;
	close $fh or die "cannot close \"$path\": $!\n";
	return $path;
}
# No binmode: write_table opens its file in text mode, so on Windows each line
# ends "\r\n", as R's write.csv does there, and the :crlf layer that '<' gets on
# that platform folds them back to the "\n" the fixtures are written with.
# Reading raw is what failed 0.320 on Strawberry Perl 5.42.2.
sub slurp_text {
	my ($path) = @_;
	open my $fh, '<', $path or die "cannot read \"$path\": $!\n";
	local $/;
	return scalar <$fh>;
}

# Every CSV under t/ reads the same as an aoa as it does as an aoh: the first
# row is the aoh's column names in file order, and each later cell is the aoh's
# value for that column. A file whose header repeats a name is left out, since
# its aoh has lost the earlier fields (and t/read_table.fast_path.t pins what an
# aoa does with one).
{
	# forward slashes, which glob() takes on Windows too
	my @csv = sort grep { -s $_ } glob('t/*.csv');
	my $compared = 0;
	for my $f (@csv) {
		my $aoa = read_table($f, 'output.type' => 'aoa');
		my @hdr = @{ $aoa->[0] };
		my %seen;
		next if grep { $seen{$_}++ } @hdr;
		my $aoh = read_table($f);
		my @want = map { my $row = $_; [ map { $row->{$_} } @hdr ] } @$aoh;
		is_deeply( [ @$aoa[ 1 .. $#$aoa ] ], \@want, "$f: aoa agrees with aoh" );
		$compared++;
	}
	# 37 of the 37 CSVs under t/ were compared when this was written (none
	# repeats a column name); the floor catches a glob that finds nothing, as
	# it would if the suite were run from another directory, with room for a
	# few fixtures to be dropped.
	cmp_ok( $compared, '>=', 30, 'the t/*.csv corpus was compared' );
}

# The header row is the header read_table settles on, whatever made it.
{
	my $f = fixture("1,2\n3,4\n");
	is_deeply( read_table($f, 'output.type' => 'aoa', header => 0),
		[ [qw(V1 V2)], [1, 2], [3, 4] ],
		'header => 0: the columns are named V1, V2, as in R' );
	is_deeply( read_table($f, 'output.type' => 'aoa', header => 0, 'col.names' => [qw(p q)]),
		[ [qw(p q)], [1, 2], [3, 4] ],
		'header => 0 with col.names: those names head the table' );
	my $r = fixture("x,y\nA,1,2\nB,3,4\n");
	is_deeply( read_table($r, 'output.type' => 'aoa', 'auto.row.names' => 1),
		[ [qw(row_name x y)], [qw(A 1 2)], [qw(B 3 4)] ],
		'auto.row.names: the synthesized name leads the header' );
	my $e = fixture(",x\nA,1\n");
	is_deeply( read_table($e, 'output.type' => 'aoa'), [ [qw(row_name x)], [qw(A 1)] ],
		'an empty first header cell is named row_name, as in every other shape' );
	my $c = fixture("# a\tb\n1\t2\n", '.tsv');
	is_deeply( read_table($c, 'output.type' => 'aoa'), [ [qw(a b)], [1, 2] ],
		'a commented-out header is recovered' );
}

# A filter sees the row it always has, and a value it rewrites is what lands in
# the aoa.
{
	my $f = fixture("id,v\na,1\nb,2\nc,3\n");
	is_deeply( read_table($f, 'output.type' => 'aoa',
			filter => { v => sub { $_ *= 10; $_ != 20 } }),
		[ [qw(id v)], [ 'a', 10 ], [ 'c', 30 ] ],
		'filter: rows it rejects are dropped and its rewrites are kept' );
}

# Empty input.
{
	my $f = fixture('');
	is_deeply( read_table($f, 'output.type' => 'aoa'), [],
		'an empty file is an empty aoa, as it is an empty aoh' );
}

# write_table reads an AoA's first row as its header, so the two round-trip,
# line for line, in each delimited format (line ends are the platform's).
{
	for my $case ([ ".csv", "taxid,genus,species\n10090,,Mus musculus\n9606,Homo,Homo sapiens\n" ],
	              [ ".tsv", "taxid\tgenus\tspecies\n10090\t\tMus musculus\n9606\tHomo\tHomo sapiens\n" ],
	              [ ".csv", qq{a,b\n"x,1",2\n"he said ""hi""",\n} ]) {
		my ($ext, $text) = @$case;
		my $in  = fixture($text, $ext);
		my $out = File::Spec->catfile($dir, 'out' . $seq++ . $ext);
		write_table(read_table($in, 'output.type' => 'aoa'), $out, quiet => 1);
		is( slurp_text($out), $text, "$ext round trip through an aoa is line for line" );
	}
	my @aoa = ([qw(taxid species)], [ '9606', 'Homo sapiens' ], [ '10090', undef ]);
	my $x = File::Spec->catfile($dir, 'rt.xlsx');
	write_table(\@aoa, $x, quiet => 1);
	is_deeply( read_table($x, 'output.type' => 'aoa'), \@aoa, '.xlsx round trip through an aoa' );
}

# Argument checking.
{
	my $f = fixture("a,b\n1,2\n");
	throws_ok { read_table($f, 'output.type' => 'aoa', 'row.names' => 'a') }
		qr/^read_table: 'row\.names' has no meaning for output\.type "aoa"; the row names column is read as an ordinary column$/,
		'row.names with aoa dies';
	throws_ok { read_table($f, 'output.type' => 'matrix') }
		qr/^read_table: output\.type "matrix" isn't allowed \(aoa, aoh, hoa, hoh\)$/,
		'an unknown output.type lists aoa among the allowed ones';
}

done_testing;
