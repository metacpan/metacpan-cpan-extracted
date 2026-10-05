#!/usr/bin/env perl
# Generator for the frozen table in t/read_table.vcf_explode.bcftools.t.
#
# Re-run from the distribution root, with bcftools 1.21's source tree and
# bcftools on the PATH:
#
#   perl t/read_table.vcf_explode.bcftools.pl /path/to/bcftools-1.21/test > /tmp/x.pl
#
# and paste what it prints over the %fixture table in the .t file. The test
# never runs this; it needs no bcftools.
#
# For each fixture it prints the file's bytes verbatim and the table
# read_table(explode => 1, 'output.type' => 'aoa') should return:
#
#   - the header: the eight fixed columns, then "<sample>.<key>" for every
#     sample and every FORMAT key, keys in the order each first appears in
#     the file's FORMAT column (that order is read_table's definition, so it
#     is taken from the file here);
#   - the fixed columns of each record from `bcftools view -H --no-version`;
#   - each sample's value for a key from `bcftools query -f '[%KEY\t]\n'`,
#     i.e. htslib's reading of it, where the record's FORMAT has the key and
#     the sample's text has a value in that place; undef where it does not
#     (the key is not in that record's FORMAT, FORMAT is ".", or the sample
#     dropped trailing values, which the spec allows and bcftools prints as
#     ".").
#
# Only fixtures whose fixed columns bcftools writes back unchanged are used;
# bcftools rewrites dropped trailing values ("./." as "./.:.:.:."), which is
# why presence is read off the file and only the values come from htslib.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;

my $dir = shift // die "usage: $0 <bcftools test directory>\n";
my @fixtures = qw(ex2.vcf view.omitgenotypes.vcf indel-stats.vcf
	norm.string-tags.vcf);
my @fixed = qw(CHROM POS ID REF ALT QUAL FILTER INFO);

# list-form pipe open, so no shell sees the path
sub run {
	open my $fh, '-|', @_ or die "can't run $_[0]: $!\n";
	local $/;
	my $out = <$fh> // '';
	close $fh or die "@_ failed\n";
	return $out;
}

local $Data::Dumper::Useqq    = 1;
local $Data::Dumper::Indent   = 1;
local $Data::Dumper::Sortkeys = 1;
local $Data::Dumper::Terse    = 1;
my %out;
for my $name (@fixtures) {
	my $path = "$dir/$name";
	open my $in, '<:raw', $path or die "$path: $!\n";
	my $vcf = do { local $/; <$in> };
	close $in;
	my @lines   = grep { !/^#/ } split /\n/, $vcf;
	my ($hline) = grep { /^#CHROM/ } split /\n/, $vcf;
	my @hdr     = split /\t/, $hline, -1;
	my @samples = @hdr[ 9 .. $#hdr ];
	my (@keys, %seen);
	for my $l (@lines) {
		my $fmt = (split /\t/, $l, -1)[8];
		next if $fmt eq '.';
		$seen{$_}++ or push @keys, $_ for split /:/, $fmt, -1;
	}
	my @fixed_rows = map { [ (split /\t/, $_, -1)[ 0 .. 7 ] ] }
		split /\n/, run('bcftools', 'view', '-H', '--no-version', $path);
	my %query;	# key => [ record => [ sample values ] ]
	for my $k (@keys) {
		$query{$k} = [ map { [ split /\t/, $_, -1 ] }
			split /\n/, run('bcftools', 'query', '-f', "[%$k\t]\n", $path) ];
	}
	my @rows;
	for my $r (0 .. $#lines) {
		my @f   = split /\t/, $lines[$r], -1;
		my %pos;
		if ($f[8] ne '.') {
			my @k = split /:/, $f[8], -1;
			@pos{@k} = 0 .. $#k;
		}
		my @row = @{ $fixed_rows[$r] };
		for my $j (0 .. $#samples) {
			my $nval = () = split /:/, $f[ 9 + $j ], -1;
			for my $k (@keys) {
				push @row, (exists $pos{$k} && $pos{$k} < $nval)
					? $query{$k}[$r][$j] : undef;
			}
		}
		push @rows, \@row;
	}
	$out{$name} = {
		vcf  => $vcf,
		want => [ [ @fixed, map { my $s = $_; map { "$s.$_" } @keys } @samples ],
			@rows ],
	};
}
print "my %fixture = %{ ", Dumper(\%out), " };\n";
