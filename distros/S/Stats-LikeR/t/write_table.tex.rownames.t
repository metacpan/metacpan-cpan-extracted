#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use File::Temp;
use Stats::LikeR;
use Test::Exception; # dies_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Slurp a file into a scalar (chomped list of lines returned in list context).
sub slurp_lines {
	my ($path) = @_;
	open my $fh, '<', $path or die "cannot read $path: $!";
	my @lines = <$fh>;
	close $fh;
	chomp @lines;
	return @lines;
}

# Number of columns declared in a \begin{tabular}{|c|c|...|} preamble.
sub tabular_cols {
	my ($line) = @_;
	my ($spec) = $line =~ /\\begin\{tabular\}\{([^}]*)\}/;
	return 0 unless defined $spec;
	my $n = ($spec =~ tr/clr//); # count column-type letters c / l / r
	return $n;
}

#--------
# HoH: LaTeX leads with row names by default (R-compatible)
#--------
my %hoh = (
	'1cka' => { b_factor => 674, binding => 'Kd' },
	'1ckb' => { b_factor => 569, binding => 'Kd' },
	'1d4t' => { b_factor => 915, binding => 'Kd' },
);

{
	my $tmp = File::Temp->new(SUFFIX => '.tex');
	write_table(\%hoh, "$tmp");
	my @l = slurp_lines("$tmp");

	my ($preamble) = grep { /\\begin\{tabular\}/ } @l;
	is(tabular_cols($preamble), 3,
		'HoH tex: row-name column added (2 data cols + 1 row-name col)');

	my ($header) = grep { /\\hline$/ && /&/ } @l;
	like($header, qr/^\\textbf\{\} &/,
		'HoH tex: leading header cell is empty (row-name column header)');

	# Data rows: keys are sorted, so 1cka is first and leads its row (bold).
	my ($first_data) = grep { /^\\textbf\{1cka\}/ } @l;
	ok(defined $first_data, 'HoH tex: first data row leads with row name 1cka');
	like($first_data, qr/^\\textbf\{1cka\} & 674 & Kd\\\\$/,
		'HoH tex: row name is column 0; data columns follow (b_factor not bolded)');

	# Every key must appear as a leading (bold) first cell.
	for my $k (sort keys %hoh) {
		ok(scalar(grep { /^\Q\textbf{$k}\E &/ } @l),
			"HoH tex: '$k' present as the first item of its row");
	}
}

#--------
# row.names => 0 opts out even for tex (no leading row-name column)
#--------
{
	my $tmp = File::Temp->new(SUFFIX => '.tex');
	write_table(\%hoh, "$tmp", 'row.names' => 0);
	my @l = slurp_lines("$tmp");

	my ($preamble) = grep { /\\begin\{tabular\}/ } @l;
	is(tabular_cols($preamble), 2,
		'HoH tex + row.names=>0: no row-name column (2 data cols only)');

	my ($header) = grep { /\\hline$/ && /&/ } @l;
	unlike($header, qr/^\\textbf\{\} &/,
		'HoH tex + row.names=>0: header does not start with an empty cell');
	like($header, qr/^\\textbf\{b\\_factor\}/,
		'HoH tex + row.names=>0: first header is a real data column');

	ok(!scalar(grep { /^\\textbf\{1cka\}/ } @l),
		'HoH tex + row.names=>0: row names are not emitted');
}

#--------
# HoA: default tex uses numeric row labels (1..N) as the leading column
#--------
{
	my %hoa = (x => [10, 20], 'y' => [30, 40]);
	my $tmp = File::Temp->new(SUFFIX => '.tex');
	write_table(\%hoa, "$tmp");
	my @l = slurp_lines("$tmp");

	my ($preamble) = grep { /\\begin\{tabular\}/ } @l;
	is(tabular_cols($preamble), 3,
		'HoA tex: numeric row-label column added (2 data cols + 1 label col)');

	ok(scalar(grep { /^\\textbf\{1\} & 10 & 30\\\\$/ } @l),
		'HoA tex: first data row leads with numeric label 1');
	ok(scalar(grep { /^\\textbf\{2\} & 20 & 40\\\\$/ } @l),
		'HoA tex: second data row leads with numeric label 2');
}

#--------
# Delimited output is unchanged: still off-by-default (no row-name column)
#--------
#{
#my $tmp = File::Temp->new(SUFFIX => '.csv');
#write_table(\%hoh, "$tmp");
#my @l = slurp_lines("$tmp");
#is($l[0], 'b_factor,binding',
#	'CSV: delimited default is unchanged (no leading row-name column)');
#is($l[1], '674,Kd', 'CSV: first data row has no leading row name');
#}

#--------
# Nested reference in a cell still croaks (unchanged error path)
#--------
{
	my %bad = ('1cka' => { b_factor => [1, 2] });
	my $tmp = File::Temp->new(SUFFIX => '.tex');
	dies_ok { write_table(\%bad, "$tmp") }
		'tex: nested reference cell dies';
}

#--------
# No memory leaks on the tex write path
#--------
no_leaks_ok {
	my $tmp = File::Temp->new(SUFFIX => '.tex');
	eval { write_table(\%hoh, "$tmp") };
} 'write_table() tex row-names: no memory leaks'
	unless $INC{'Devel/Cover.pm'};

done_testing();
