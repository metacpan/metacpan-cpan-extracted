#!/usr/bin/env perl
# Generator for the frozen table in t/read_table.vcf.htslib.t.
#
# Re-run from the distribution root, with htslib's source tree and bcftools on
# the PATH:
#
#   perl t/read_table.vcf.htslib.pl /home/con/prog/htslib/test > /tmp/vcf.pl
#
# and paste what it prints over the %fixture table in the .t file. The test
# never runs this; it needs neither htslib nor bcftools.
#
# For each fixture it prints the file's bytes verbatim, and what htslib makes
# of them: the columns are the eight fixed ones of the VCF spec, then FORMAT
# and the sample names from `bcftools query -l` when there are samples, and
# the rows are `bcftools view -H --no-version`, split on tabs. Only fixtures
# whose records bcftools writes back byte for byte are used, so htslib's
# reading of each field is the file's own text.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Data::Dumper;

my $dir = shift // die "usage: $0 <htslib test directory>\n";
my @fixtures = qw(formatmissing.vcf formatcols.vcf vcf_meta_meta.vcf
	test-vcf-hdr-in.vcf modhdr.expected.vcf);
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
	my @samples = split /\n/, run('bcftools', 'query', '-l', $path);
	my @rows = map { [ split /\t/, $_, -1 ] }
		split /\n/, run('bcftools', 'view', '-H', '--no-version', $path);
	$out{$name} = {
		vcf    => $vcf,
		header => [ @fixed, @samples ? ('FORMAT', @samples) : () ],
		rows   => \@rows,
	};
}
print "my %fixture = %{ ", Dumper(\%out), " };\n";
