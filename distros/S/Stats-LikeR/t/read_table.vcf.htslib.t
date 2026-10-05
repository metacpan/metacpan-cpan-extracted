#!/usr/bin/env perl
# read_table() on VCF files.
#
# Up to 0.3213 a VCF could not be read at all. Its "##" meta-information lines
# have the marker hugging their text ("##fileformat=VCFv4.2"), which the parser
# hands on as a possible commented-out header, and read_table took the first
# of them for the header on the spot: the file came back as one column called
# "fileformat=VCFv4.2", and the "#CHROM" line was an alignment error. A run of
# such lines is now a run of candidates, the last of which is tried against
# the data (t/read_table.comments.t), and a file named *.vcf, *.vcf.gz or
# *.vcf.bgz is read with a tab sep, a "##" comment marker and the "#" taken
# off "#CHROM". Every read here is with explode => 0, the file's own columns;
# splitting the sample columns by FORMAT is t/read_table.vcf_explode.bcftools.t.
#
# Provenance. Every fixture is a file of htslib's own test suite, copied byte
# for byte from htslib 1.21-34-gb14fffb4, test/: formatmissing.vcf,
# formatcols.vcf (a UTF-8 sample name, "S\302\262"), vcf_meta_meta.vcf (sites
# only, no FORMAT), test-vcf-hdr-in.vcf (a meta line with trailing blanks and
# others with blanks round '='), and modhdr.expected.vcf (a header and no
# records). The expected columns and rows are htslib's reading of each file,
# through bcftools 1.21 (using htslib 1.21): the eight fixed columns of the
# VCF spec, then FORMAT and `bcftools query -l`'s sample names, and the
# records of `bcftools view -H --no-version` split on tabs. Each of these
# files' records comes back from bcftools byte for byte, so htslib's reading
# of a field is its text in the file. The generator is
# t/read_table.vcf.htslib.pl next to this file; run it as
#
#   perl t/read_table.vcf.htslib.pl /path/to/htslib/test
#
# and paste what it prints over %fixture below. This test never runs it.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use File::Temp ();
use File::Spec ();
use Compress::Raw::Zlib ();
use Stats::LikeR qw(read_table);

our $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	} ? 1 : 0;
}

my $dir = File::Temp::tempdir(CLEANUP => 1);

sub fixture {
	my ($name, $bytes) = @_;
	my $path = File::Spec->catfile($dir, $name);
	open my $fh, '>', $path or die "cannot write \"$path\": $!\n";
	binmode $fh;
	print {$fh} $bytes;
	close $fh or die "cannot close \"$path\": $!\n";
	return $path;
}

# The file as written: these tests are of reading a VCF's text, so each is
# made with explode => 0, which is the default's opposite for a file named as
# a VCF and is refused for any other. The exploded table is tested in
# t/read_table.vcf_explode.bcftools.t.
sub read_plain {
	my $path = shift;
	return read_table($path, ($path =~ /\.vcf(?:\.b?gz)?\z/i ? (explode => 0) : ()), @_);
}

# One gzip member holding $text.
sub gz {
	my ($text) = @_;
	my ($z, $err) = Compress::Raw::Zlib::Deflate->new(
		-WindowBits => Compress::Raw::Zlib::WANT_GZIP(), -AppendOutput => 1);
	die "deflate: $err\n" unless $z;
	my $out = '';
	$z->deflate($text, $out) == Compress::Raw::Zlib::Z_OK() or die "deflate\n";
	$z->flush($out) == Compress::Raw::Zlib::Z_OK() or die "flush\n";
	return $out;
}

my %fixture = %{ {
  "formatcols.vcf" => {
    "header" => [
      "CHROM",
      "POS",
      "ID",
      "REF",
      "ALT",
      "QUAL",
      "FILTER",
      "INFO",
      "FORMAT",
      "S1",
      "S\302\262",
      "S3"
    ],
    "rows" => [
      [
        1,
        100,
        "a",
        "A",
        "T",
        ".",
        ".",
        ".",
        "S",
        "a",
        "bbbbbbb",
        "ccccccccc"
      ]
    ],
    "vcf" => "##fileformat=VCFv4.3\n##FILTER=<ID=PASS,Description=\"All filters passed\">\n##contig=<ID=1>\n##FORMAT=<ID=S,Number=1,Type=String,Description=\"Text\">\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS1\tS\302\262\tS3\n1\t100\ta\tA\tT\t.\t.\t.\tS\ta\tbbbbbbb\tccccccccc\n"
  },
  "formatmissing.vcf" => {
    "header" => [
      "CHROM",
      "POS",
      "ID",
      "REF",
      "ALT",
      "QUAL",
      "FILTER",
      "INFO",
      "FORMAT",
      "S1",
      "S2",
      "S3"
    ],
    "rows" => [
      [
        1,
        100,
        "a",
        "A",
        "T",
        ".",
        ".",
        ".",
        ".",
        ".",
        ".",
        "."
      ]
    ],
    "vcf" => "##fileformat=VCFv4.3\n##FILTER=<ID=PASS,Description=\"All filters passed\">\n##contig=<ID=1>\n##FORMAT=<ID=S,Number=1,Type=String,Description=\"Text\">\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS1\tS2\tS3\n1\t100\ta\tA\tT\t.\t.\t.\t.\t.\t.\t.\n"
  },
  "modhdr.expected.vcf" => {
    "header" => [
      "CHROM",
      "POS",
      "ID",
      "REF",
      "ALT",
      "QUAL",
      "FILTER",
      "INFO"
    ],
    "rows" => [],
    "vcf" => "##fileformat=VCFv4.3\n##FILTER=<ID=PASS,Description=\"All filters passed\">\n##contig=<ID=chr22,length=51304566>\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n"
  },
  "test-vcf-hdr-in.vcf" => {
    "header" => [
      "CHROM",
      "POS",
      "ID",
      "REF",
      "ALT",
      "QUAL",
      "FILTER",
      "INFO",
      "FORMAT",
      "NA00001"
    ],
    "rows" => [
      [
        1,
        12065947,
        "PTV001",
        "C",
        "T,A",
        29,
        "PASS",
        ".",
        "GT:GATK:AD:DP:GQ",
        "0/1:0/1:3,2:5:19"
      ],
      [
        1,
        109817590,
        "PTV002",
        "G",
        "T",
        77,
        "PASS",
        ".",
        "GT:GATK:AD:DP:GQ",
        "0/1:0/1:3,2:5:20"
      ],
      [
        1,
        153791300,
        "PTV003",
        "CTG",
        "C",
        81,
        "PASS",
        ".",
        "GT:GATK:AD:DP:GQ",
        "0/1:0/1:3,2:5:21"
      ],
      [
        1,
        156104666,
        "PTV004",
        "TTGAGAGCCGGCTGGCGGAT",
        "TCC",
        30,
        "PASS",
        ".",
        "GT:GATK:AD:DP:GQ",
        "0/1:0/1:3,2:5:22"
      ],
      [
        1,
        156108541,
        "PTV005",
        "G",
        "GG",
        31,
        "PASS",
        ".",
        "GT:GATK:AD:DP:GQ",
        "0/1:0/1:3,2:5:23"
      ],
      [
        1,
        161279695,
        "PTV006",
        "T",
        "C,A",
        32,
        "PASS",
        ".",
        "GT:GATK:AD:DP:GQ",
        "0/1:0/1:3,2:5:24"
      ],
      [
        1,
        169519049,
        "PTV007",
        "T",
        ".",
        35,
        "PASS",
        ".",
        "GT:GATK:AD:DP:GQ",
        "0/1:0/1:3,2:5:24"
      ],
      [
        1,
        226125468,
        "PTV097",
        "G",
        "A",
        99,
        "PASS",
        ".",
        "GT:GATK:AD:DP:GQ",
        "0/1:0/1:3,2:5:109"
      ],
      [
        16,
        2103394,
        "PTV056",
        "C",
        "T",
        68,
        "PASS",
        ".",
        "GT:GATK:AD:DP:GQ",
        "0/1:0/1:3,2:5:72"
      ],
      [
        4,
        31789170,
        "PTV021",
        "G",
        ".",
        77,
        "PASS",
        ".",
        "GT:GATK:AD:DP:GQ",
        "0/1:0/1:3,2:5:38"
      ]
    ],
    "vcf" => "##fileformat=VCFv4.1\n##fileDate=20150126\n##reference=hs37d5\n##phasing=partial\n##FILTER=<ID=INDEL_SPECIFIC_FILTERS,Description=\"QD < 2.0 || ReadPosRankSum < -20.0 || InbreedingCoeff < -0.8 || FS > 200.0\">\n##FILTER=<ID=LowQual,Description=\"Low quality\">\n##FILTER=<ID=VQSRTrancheSNP99.00to99.90,Description=\"Truth sensitivity tranche level for SNP model at VQS Lod: -6.6778 <= x < -0.6832\">\n##FILTER=<ID=VQSRTrancheSNP99.90to100.00+,Description=\"Truth sensitivity tranche level for SNP model at VQS Lod < -36469.5723\">\n##INFO=<ID=TRAILING,Number=.,Type=Integer,Description=\"This line contains trailing spaces for testing purposes\">               \n##FORMAT=<ID=AD,Number=.,Type=Integer,Description=\"Allelic depths for the ref and alt alleles in the order listed\">\n##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Approximate read depth (reads with MQ=255 or with bad mates are filtered)\">\n##FORMAT=<ID=GQ,Number=1,Type=Integer,EmptyWithSpace= ,Description=\"Genotype Quality\">\n##FORMAT=<ID=GATK,Number=1, Type  =   String    ,     Description=\"Genotype as called by GATK. Always a diploid call. All other genotype stats based on this genotype.\">\n##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype after Personalis post-processing to match detected chromosome counts.\">\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tNA00001\n1\t12065947\tPTV001\tC\tT,A\t29\tPASS\t.\tGT:GATK:AD:DP:GQ\t0/1:0/1:3,2:5:19\n1\t109817590\tPTV002\tG\tT\t77\tPASS\t.\tGT:GATK:AD:DP:GQ\t0/1:0/1:3,2:5:20\n1\t153791300\tPTV003\tCTG\tC\t81\tPASS\t.\tGT:GATK:AD:DP:GQ\t0/1:0/1:3,2:5:21\n1\t156104666\tPTV004\tTTGAGAGCCGGCTGGCGGAT\tTCC\t30\tPASS\t.\tGT:GATK:AD:DP:GQ\t0/1:0/1:3,2:5:22\n1\t156108541\tPTV005\tG\tGG\t31\tPASS\t.\tGT:GATK:AD:DP:GQ\t0/1:0/1:3,2:5:23\n1\t161279695\tPTV006\tT\tC,A\t32\tPASS\t.\tGT:GATK:AD:DP:GQ\t0/1:0/1:3,2:5:24\n1\t169519049\tPTV007\tT\t.\t35\tPASS\t.\tGT:GATK:AD:DP:GQ\t0/1:0/1:3,2:5:24\n1\t226125468\tPTV097\tG\tA\t99\tPASS\t.\tGT:GATK:AD:DP:GQ\t0/1:0/1:3,2:5:109\n16\t2103394\tPTV056\tC\tT\t68\tPASS\t.\tGT:GATK:AD:DP:GQ\t0/1:0/1:3,2:5:72\n4\t31789170\tPTV021\tG\t.\t77\tPASS\t.\tGT:GATK:AD:DP:GQ\t0/1:0/1:3,2:5:38\n"
  },
  "vcf_meta_meta.vcf" => {
    "header" => [
      "CHROM",
      "POS",
      "ID",
      "REF",
      "ALT",
      "QUAL",
      "FILTER",
      "INFO"
    ],
    "rows" => [
      [
        1,
        123,
        ".",
        "TC",
        "T",
        ".",
        ".",
        "."
      ]
    ],
    "vcf" => "##fileformat=VCFv4.3\n##FILTER=<ID=PASS,Description=\"All filters passed\">\n##META=<ID=Assay,Number=.,Type=String,Values=[WholeGenome, Exome]>\n##META=<ID=Disease,Number=.,Type=String,Values=[None, Cancer]>\n##META=<ID=Ethnicity,Number=.,Type=String,Values=[AFR, CEU, ASN, MEX]>\n##META=<ID=Tissue,Number=.,Type=String,Values=[Blood, Breast, Colon, Lung, ?]>\n##contig=<ID=1>\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n1\t123\t.\tTC\tT\t.\t.\t.\n"
  }
}
 };

# the empty BGZF block bgzip writes at the end of every file (SAM/BAM spec,
# section 4.1.2, "End-of-file marker")
my $bgzf_eof = "\x1f\x8b\x08\x04\x00\x00\x00\x00\x00\xff\x06\x00\x42\x43"
	. "\x02\x00\x1b\x00\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00";

for my $name (sort keys %fixture) {
	my $fx   = $fixture{$name};
	my @hdr  = @{ $fx->{header} };
	my $aoa  = [ [@hdr], map { [@$_] } @{ $fx->{rows} } ];
	my $aoh  = [ map { my $r = $_; +{ map { $hdr[$_] => $r->[$_] } 0 .. $#hdr } }
		@{ $fx->{rows} } ];
	my $hoa  = { map { my $i = $_; $hdr[$i] => [ map { $_->[$i] } @{ $fx->{rows} } ] }
		0 .. $#hdr };
	# a header and no records is {}, as read_table has always given it for a hoa
	$hoa = {} unless @{ $fx->{rows} };
	(my $stem = $name) =~ s/\.vcf\z//;
	my $f = fixture($name, $fx->{vcf});

	is_deeply read_plain($f, 'output_type' => 'aoa'), $aoa, "$name: aoa";
	is_deeply read_plain($f), $aoh, "$name: aoh, the default with explode => 0";
	is_deeply read_plain($f, 'output_type' => 'hoa'), $hoa, "$name: hoa";
	is_deeply read_plain($f, filter => sub { 1 }), $aoh,
		"$name: aoh through the filter closure";
	is_deeply read_plain($f, 'output_type' => 'aoa', filter => sub { 1 }), $aoa,
		"$name: aoa through the filter closure";
	# what read.vcf.pl passed, and the marker R and pandas would use
	is_deeply read_plain($f, comment => '##', sep => "\t", 'output_type' => 'aoa'),
		$aoa, "$name: comment => '##', sep => \"\\t\" given explicitly";
	is_deeply read_plain($f, comment => '#', 'output_type' => 'aoa'), $aoa,
		"$name: comment => '#'";
	# the name decides, whatever its case and however it is compressed
	is_deeply read_plain(fixture("$stem.VCF", $fx->{vcf}), 'output_type' => 'aoa'),
		$aoa, "$name: as .VCF";
	is_deeply read_plain(fixture("$name.gz", gz($fx->{vcf})), 'output_type' => 'aoa'),
		$aoa, "$name: gzipped, as .vcf.gz";
	is_deeply read_plain(fixture("$name.bgz", gz($fx->{vcf}) . $bgzf_eof),
			'output_type' => 'aoa'),
		$aoa, "$name: bgzipped, as .vcf.bgz";
	# Under another name it is an ordinary file: "##" lines are comments if
	# asked for, and "#CHROM" keeps its "#", as R's read.table(comment.char =
	# "") would keep it.
	my $as_tsv = [ [ "#$hdr[0]", @hdr[ 1 .. $#hdr ] ], @$aoa[ 1 .. $#$aoa ] ];
	is_deeply read_plain(fixture("$stem.tsv", $fx->{vcf}), comment => '##',
			'output_type' => 'aoa'),
		$as_tsv, "$name: as .tsv with comment => '##', \"#CHROM\" keeps its \"#\"";
	# header => 0: the "#CHROM" line is the first row, as written
	is_deeply read_plain($f, header => 0, 'output_type' => 'aoa'),
		[ [ map { "V$_" } 1 .. @hdr ], @$as_tsv ],
		"$name: header => 0 reads the \"#CHROM\" line as data";
	my @cn = map { "c$_" } 1 .. @hdr;
	is_deeply read_plain($f, 'col_names' => \@cn, 'output_type' => 'aoa'),
		[ \@cn, @$aoa[ 1 .. $#$aoa ] ], "$name: col_names renames the columns";
}

# a hoh, by a column whose values are unique, and by the default (CHROM)
{
	my $fx = $fixture{'test-vcf-hdr-in.vcf'};
	my $f  = fixture('hoh.vcf', $fx->{vcf});
	my @hdr = @{ $fx->{header} };
	my %want;
	for my $r (@{ $fx->{rows} }) {
		$want{ $r->[2] } = { map { $hdr[$_] => $r->[$_] } grep { $_ != 2 } 0 .. $#hdr };
	}
	is_deeply read_plain($f, 'output_type' => 'hoh', 'row_names' => 'ID'), \%want,
		'test-vcf-hdr-in.vcf: hoh by ID';
	$fx = $fixture{'formatmissing.vcf'};
	$f  = fixture('hoh1.vcf', $fx->{vcf});
	@hdr = @{ $fx->{header} };
	my $r = $fx->{rows}[0];
	is_deeply read_plain($f, 'output_type' => 'hoh'),
		{ $r->[0] => { map { $hdr[$_] => $r->[$_] } 1 .. $#hdr } },
		'formatmissing.vcf: hoh by CHROM, the first column, by default';
}

if ($HAVE_LEAKTRACE && !$INC{'Devel/Cover.pm'}) {
	my $f = fixture('leak.vcf', $fixture{'test-vcf-hdr-in.vcf'}{vcf});
	no_leaks_ok { read_plain($f) } 'no leaks reading a VCF';
	no_leaks_ok { read_plain($f, filter => sub { 1 }) }
		'no leaks reading a VCF through the filter closure';
}

done_testing;
