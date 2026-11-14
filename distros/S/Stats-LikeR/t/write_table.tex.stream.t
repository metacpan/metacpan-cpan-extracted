#!/usr/bin/env perl

# write_table's LaTeX output is streamed: each record is written as it
# arrives, where up to 0.3418 every field was first copied into an SV (a
# 20 x 200000 table of doubles peaked at 486 MB against 152 MB for csv, 153 MB
# now; 0.94 s down to 0.59 s, measured 2026-11-09, one process per format).
#
# Provenance: there is no LaTeX writer in R's or Python's suites, so the
# expected bytes are the output of the 0.3418 build for the same calls, frozen
# here (write_table() of each input below under that build, minus its
# "%written by" line).  A differential run of 56 table/option combinations
# between the two builds -- every shape, every tex_* option, the empty tables --
# found no byte different.
#
# What the change does alter, and what this file therefore pins on purpose:
#  - a table with no columns is refused before the file is opened, so an
#    existing file survives (unchanged);
#  - a croak from the data after the header (a tied cell whose FETCH dies) now
#    leaves the file as far as it got, as csv and .xlsx have always done; it
#    used to leave an existing file alone, because nothing was written until
#    every record had been read.

require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp;
use Test::More;
use Stats::LikeR qw(write_table);

my $dir = File::Temp->newdir;
my $seq = 0;
sub texfile { $seq++; return "$dir/t$seq.tex" }
# the default layers are :crlf where perl is a CRLF shop, as in
# t/write_table.tex.comment.t, whose probe this repeats
my $CRLF = do {
	open my $fh, '>', "$dir/nl.probe" or die "cannot write a probe: $!";
	my $crlf = grep { $_ eq 'crlf' } PerlIO::get_layers($fh);
	close $fh;
	$crlf;
};
sub slurp {
	my $file = shift;
	open my $fh, '<:raw', $file or die "cannot read $file: $!";
	local $/;
	my $text = <$fh>;
	$text =~ s/\r\n/\n/g if $CRLF;
	return $text;
}
sub body { my $t = slurp(shift); $t =~ s/\A%written by [^\n]*\n//; return $t }

my @cases = (
	['HoA, undef, UTF-8 and escapes',
		{ a => [1, 2.5, undef], b => ["\x{3b1}", "caf\x{e9}", "x_y&z"] }, [],
		"\\begin{tabular}{|c|c|} \\hline\n\\textbf{a} & \\textbf{b} \\\\ \\hline\n\\textbf{1} & \\textalpha{}\\\\\n\\textbf{2.5} & caf\xe9\\\\\n\\textbf{} & x\\_y\\&z\\\\\n\\hline \\end{tabular}\n"],
	['HoA, tex_format, tex_bold_1st_col, tex_size',
		{ a => [1, 2.123456789, undef], b => ["50%", "\$5", "{x}"] },
		[tex_format => 1, tex_bold_1st_col => 1, tex_size => '\small'],
		"\\begin{tabular}{|c|c|} \\hline\n\\small\n\\textbf{a} & \\textbf{b} \\\\ \\hline\n\\textbf{1} & 50\\%\\\\\n\\textbf{2.123} & \$5\\\\\n\\textbf{} & {x}\\\\\n\\hline \\end{tabular}\n"],
	['AoH, longtable with a head',
		[{ n => 1, m => "a#b" }, { n => 2, m => undef }],
		[tex_longtable => 1, tex_longtable_head => 'cap'],
		"% \\begin{longtable}{cc}\n\\textbf{m} & \\textbf{n} \\\\ \\hline\n\\endfirsthead\n\\caption[]{cap}\\\\\n\\hline\n\\textbf{m} & \\textbf{n} \\\\ \\hline\n\\endhead\n\\hline\n\\endfoot\n\\textbf{a\\#b} & 1\\\\\n\\textbf{} & 2\\\\\n"],
	['AoA with col_names and a wide character',
		[[1, 2], [3, "\x{263a}"]], [col_names => ['p', 'q']],
		"\\begin{tabular}{|c|c|} \\hline\n\\textbf{p} & \\textbf{q} \\\\ \\hline\n\\textbf{1} & 2\\\\\n\\textbf{3} & \xe2\x98\xba\\\\\n\\hline \\end{tabular}\n"],
);
for my $c (@cases) {
	my $f = texfile();
	write_table($c->[1], $f, @{ $c->[2] }, quiet => 1);
	is(body($f), $c->[3], "byte-identical to 0.3418: $c->[0]");
}

# a table with no columns is refused before the file is touched
for my $empty ([], {}, [{}]) {
	my $f = texfile();
	open my $o, '>', $f or die; print $o "KEEP\n"; close $o;
	ok(!eval { write_table($empty, $f, quiet => 1); 1 }, 'no columns croaks');
	like($@, qr/would be a LaTeX table with no columns/, '... with the usual message');
	is(slurp($f), "KEEP\n", '... and the existing file is left alone');
}

# a croak from the data once the header is out: the file holds what was
# written, as csv's does (opened before its first record too)
{
	package DieAt3;
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
	sub FETCH { die "boom\n" if $_[1] == 3; $_[0]->[$_[1]] }
}
for my $ext (qw(csv tex)) {
	my $f = texfile(); $f =~ s/tex$/$ext/;
	tie my @t, 'DieAt3'; @t = (1 .. 6);
	ok(!eval { write_table({ a => \@t, b => [1 .. 6] }, $f, quiet => 1); 1 }, "$ext: a dying FETCH croaks");
	is($@, "boom\n", "$ext: the croak is the FETCH's own");
	my $got = slurp($f);
	like($got, $ext eq 'csv' ? qr/\Aa,b\n1,1\n2,2\n3,3\n\z/ : qr/\\textbf\{3\} & 3\\\\\n\z/,
		"$ext: the file holds the rows written before the croak");
}

done_testing;
