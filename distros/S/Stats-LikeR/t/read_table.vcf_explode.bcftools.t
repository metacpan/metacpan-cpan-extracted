#!/usr/bin/env perl
# read_table()'s explode => 1, the default for a VCF: every sample column
# split on ':' into one column per FORMAT key, named "<sample>.<key>", and a
# hoh keyed by CHROM:POS:REF:ALT.
#
# Provenance. Every fixture is a file of bcftools' own test suite, copied byte
# for byte from bcftools 1.21, test/: ex2.vcf (the VCF 4.x specification's
# example records, with a CNL key added, and samples that drop trailing
# values), view.omitgenotypes.vcf (FORMAT varying by record, whole samples
# of "." and "./."), indel-stats.vcf (six samples, FORMAT GT then GT:AD), and
# norm.string-tags.vcf (records whose FORMAT is "."). Each value of a key
# that a record's FORMAT has, and that the sample's text gives, is htslib's
# reading of it: `bcftools query -f '[%KEY\t]\n'` with bcftools 1.21 (using
# htslib 1.21). Where the key is absent, or the sample dropped the value
# (VCF 4.2/4.3 section 1.6.2: "trailing fields can be dropped"), the
# expected value is undef; bcftools prints those as ".". The fixed columns
# are `bcftools view -H --no-version`'s, which these files' are unchanged by.
# The generator is t/read_table.vcf_explode.bcftools.pl next to this file;
# run it as
#
#   perl t/read_table.vcf_explode.bcftools.pl /path/to/bcftools-1.21/test
#
# and paste what it prints over %fixture below. This test never runs it.
#
# The cases after the fixture loop -- option interplay, the croaks -- are
# this module's own surface and have no reference.
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

# The error, or '' if none, and every warning
sub outcome {
	my ($code) = @_;
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, $_[0] };
	my $r = eval { $code->(); 1 } ? '' : $@;
	return ($r, \@warn);
}

# The aoa in each other shape, as read_table builds them
sub shapes {
	my ($aoa, $rn) = @_;
	my @hdr  = @{ $aoa->[0] };
	my @rows = @$aoa[ 1 .. $#$aoa ];
	my $aoh  = [ map { my $r = $_; +{ map { $hdr[$_] => $r->[$_] } 0 .. $#hdr } } @rows ];
	my $hoa  = @rows
		? { map { my $i = $_; $hdr[$i] => [ map { $_->[$i] } @rows ] } 0 .. $#hdr }
		: {};
	my %hoh;
	for my $h (@$aoh) {
		my %c = %$h;
		my $k = defined $rn ? delete $c{$rn}
			: join ':', map { $h->{$_} } qw(CHROM POS REF ALT);
		$hoh{$k} = \%c;
	}
	return ($aoh, $hoa, \%hoh);
}

my %fixture = %{ {
  "ex2.vcf" => {
    "vcf" => "##fileformat=VCFv4.1\n##reference=file:///seq/references/1000GenomesPilot-NCBI36.fasta\n##contig=<ID=20,length=62435964,assembly=B36,md5=f126cdf8a6e0c7f379d618ff66beb2da,species=\"Homo sapiens\">\n##INFO=<ID=NS,Number=1,Type=Integer,Description=\"Number of Samples With Data\">\n##INFO=<ID=DP,Number=1,Type=Integer,Description=\"Total Depth\">\n##INFO=<ID=AF,Number=A,Type=Float,Description=\"Allele Frequency\">\n##INFO=<ID=AA,Number=1,Type=String,Description=\"Ancestral Allele\">\n##INFO=<ID=DB,Number=0,Type=Flag,Description=\"dbSNP membership, build 129\">\n##INFO=<ID=H2,Number=0,Type=Flag,Description=\"HapMap2 membership\">\n##INFO=<ID=HOMSEQ,Number=.,Type=String,Description=\"testing\">\n##FILTER=<ID=q10,Description=\"Quality below 10\">\n##FILTER=<ID=s50,Description=\"Less than 50% of samples have data\">\n##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n##FORMAT=<ID=GQ,Number=1,Type=Integer,Description=\"Genotype Quality\">\n##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Read Depth\">\n##FORMAT=<ID=HQ,Number=2,Type=Integer,Description=\"Haplotype Quality\">\n##FORMAT=<ID=CNL,Number=.,Type=Integer,Description=\"Some description\">\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tNA00001\tNA00002\tNA00003\n20\t14370\trs6054257\tG\tA\t29.1\t.\tNS=3;DP=14;AF=0.5;HOMSEQ;DB\tGT:GQ:DP:HQ:CNL\t0|0:48:1:25,30:10,20\t1|0:48:8:49,51:.\t./.:43:5:.,.:1\n20\t17330\t.\tT\tA\t.\tq10;s50\tNS=3;DP=11;AF=0.017;H2\tGT:GQ:DP:HQ\t0|0:49:3:58,50\t0|1:3:5:65,3\t0/0:41:3:4,5\n20\t1110696\trs6040355\tA\tG,T\t67\tPASS\tNS=2;DP=10;AF=0.333,0.667;AA=T;DB\tGT:GQ:DP:HQ\t1|2:21:6:23,27\t2|1:2:0:18,2\t2/2:35:4:10,20\n20\t1230237\t.\tT\t.\t47\tPASS\tNS=3;DP=13;AA=T\tGT:GQ:DP:HQ\t0|0:54:7:56,60\t0|0:48:4:51,51\t./.\n20\t1234567\tmicrosat1\tGTC\tG,GTCT\t50\tPASS\tNS=3;DP=9;AA=G\tGT:GQ:DP\t0/1:35:4\t0/2:17:2\t1/1:40:3\n",
    "want" => [
      [
        "CHROM",
        "POS",
        "ID",
        "REF",
        "ALT",
        "QUAL",
        "FILTER",
        "INFO",
        "NA00001.GT",
        "NA00001.GQ",
        "NA00001.DP",
        "NA00001.HQ",
        "NA00001.CNL",
        "NA00002.GT",
        "NA00002.GQ",
        "NA00002.DP",
        "NA00002.HQ",
        "NA00002.CNL",
        "NA00003.GT",
        "NA00003.GQ",
        "NA00003.DP",
        "NA00003.HQ",
        "NA00003.CNL"
      ],
      [
        20,
        14370,
        "rs6054257",
        "G",
        "A",
        "29.1",
        ".",
        "NS=3;DP=14;AF=0.5;HOMSEQ;DB",
        "0|0",
        48,
        1,
        "25,30",
        "10,20",
        "1|0",
        48,
        8,
        "49,51",
        ".",
        "./.",
        43,
        5,
        ".,.",
        1
      ],
      [
        20,
        17330,
        ".",
        "T",
        "A",
        ".",
        "q10;s50",
        "NS=3;DP=11;AF=0.017;H2",
        "0|0",
        49,
        3,
        "58,50",
        undef,
        "0|1",
        3,
        5,
        "65,3",
        undef,
        "0/0",
        41,
        3,
        "4,5",
        undef
      ],
      [
        20,
        1110696,
        "rs6040355",
        "A",
        "G,T",
        67,
        "PASS",
        "NS=2;DP=10;AF=0.333,0.667;AA=T;DB",
        "1|2",
        21,
        6,
        "23,27",
        undef,
        "2|1",
        2,
        0,
        "18,2",
        undef,
        "2/2",
        35,
        4,
        "10,20",
        undef
      ],
      [
        20,
        1230237,
        ".",
        "T",
        ".",
        47,
        "PASS",
        "NS=3;DP=13;AA=T",
        "0|0",
        54,
        7,
        "56,60",
        undef,
        "0|0",
        48,
        4,
        "51,51",
        undef,
        "./.",
        undef,
        undef,
        undef,
        undef
      ],
      [
        20,
        1234567,
        "microsat1",
        "GTC",
        "G,GTCT",
        50,
        "PASS",
        "NS=3;DP=9;AA=G",
        "0/1",
        35,
        4,
        undef,
        undef,
        "0/2",
        17,
        2,
        undef,
        undef,
        "1/1",
        40,
        3,
        undef,
        undef
      ]
    ]
  },
  "indel-stats.vcf" => {
    "vcf" => "##fileformat=VCFv4.2\n##FILTER=<ID=PASS,Description=\"All filters passed\">\n##contig=<ID=20,length=81195210>\n##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n##FORMAT=<ID=AD,Number=R,Type=Integer,Description=\"Allelic depths\">\n##INFO=<ID=CSQ,Number=.,Type=String,Description=\"Local consequence annotation from BCFtools/csq. Format: '[*]consequence|gene|transcript|biotype[|strand|amino_acid_change|dna_change]'\">\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tchild1\tfather1\tmother1\tchild2\tfather2\tmother2\n20\t310\t.\tT\tA,C\t.\t.\t.\tGT\t1/1\t1/1\t1/1\t1/2\t2/1\t1/1\n20\t311\t.\tT\tTA\t.\t.\t.\tGT:AD\t1/1:0,20\t0/0:20,0\t0/0:20,0\t0/1:10,10\t.\t0/0:20,0\n20\t312\t.\tTAA\tT\t.\t.\tCSQ=inframe_deletion|SAMD11|ENST00000420190|protein_coding|+|74EDG>74D|865683AGGATGG>A\tGT:AD\t0/1:10,10\t1/0:10,10\t0/0:20,0\t0/0:20,0\t0/0:20,0\t0/0:20,0\n20\t313\t.\tA\tATT\t.\t.\tCSQ=frameshift|SAMD11|ENST00000342066|protein_coding|+|333LPPAQA\tGT:AD\t0/1:10,10\t0/0:10,10\t0/0:20,0\t0/0:20,0\t0/0:20,0\t0/0:20,0\n",
    "want" => [
      [
        "CHROM",
        "POS",
        "ID",
        "REF",
        "ALT",
        "QUAL",
        "FILTER",
        "INFO",
        "child1.GT",
        "child1.AD",
        "father1.GT",
        "father1.AD",
        "mother1.GT",
        "mother1.AD",
        "child2.GT",
        "child2.AD",
        "father2.GT",
        "father2.AD",
        "mother2.GT",
        "mother2.AD"
      ],
      [
        20,
        310,
        ".",
        "T",
        "A,C",
        ".",
        ".",
        ".",
        "1/1",
        undef,
        "1/1",
        undef,
        "1/1",
        undef,
        "1/2",
        undef,
        "2/1",
        undef,
        "1/1",
        undef
      ],
      [
        20,
        311,
        ".",
        "T",
        "TA",
        ".",
        ".",
        ".",
        "1/1",
        "0,20",
        "0/0",
        "20,0",
        "0/0",
        "20,0",
        "0/1",
        "10,10",
        ".",
        undef,
        "0/0",
        "20,0"
      ],
      [
        20,
        312,
        ".",
        "TAA",
        "T",
        ".",
        ".",
        "CSQ=inframe_deletion|SAMD11|ENST00000420190|protein_coding|+|74EDG>74D|865683AGGATGG>A",
        "0/1",
        "10,10",
        "1/0",
        "10,10",
        "0/0",
        "20,0",
        "0/0",
        "20,0",
        "0/0",
        "20,0",
        "0/0",
        "20,0"
      ],
      [
        20,
        313,
        ".",
        "A",
        "ATT",
        ".",
        ".",
        "CSQ=frameshift|SAMD11|ENST00000342066|protein_coding|+|333LPPAQA",
        "0/1",
        "10,10",
        "0/0",
        "10,10",
        "0/0",
        "20,0",
        "0/0",
        "20,0",
        "0/0",
        "20,0",
        "0/0",
        "20,0"
      ]
    ]
  },
  "norm.string-tags.vcf" => {
    "vcf" => "##fileformat=VCFv4.3\n##FILTER=<ID=PASS,Description=\"All filters passed\">\n##contig=<ID=12,length=135006516>\n##FILTER=<ID=flt,Description=\"Test FILTER\">\n##INFO=<ID=XRS,Number=R,Type=String,Description=\"Test Number=AGR in INFO\">\n##INFO=<ID=XAS,Number=A,Type=String,Description=\"Test Number=AGR in INFO\">\n##FORMAT=<ID=FRS,Number=R,Type=String,Description=\"Test Number=AR in FORMAT\">\n##FORMAT=<ID=FAS,Number=A,Type=String,Description=\"Test Number=AR in FORMAT\">\n##FORMAT=<ID=FGS,Number=G,Type=String,Description=\"Test Number=G in FORMAT\">\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS1\tS2\tS3\tS4\n12\t111\t.\tCC\tGG,GT\t.\t.\t.\tFRS\ta,b,c\taa,bb,cc\taaa,bbb,ccc\t.\n12\t222\t.\tCC\tGG,GT\t.\t.\t.\tFAS\tb,c\tbb,cc\tbbb,ccc\t.\n12\t333\t.\tCC\tGG,GT\t.\t.\t.\tFGS\t1,2,3\t11,22,33\t111,222,333\t.\n12\t444\t.\tCC\tGG,GT\t.\t.\t.\tFGS\t11,12,22,13,23,33\t1111,1122,2222,1133,2233,3333\t111111,111222,222222,111333,222333,333333\t.\n12\t555\t.\tCC\tGG,GT\t.\t.\tXRS=aaa,bb,c\t.\t.\t.\t.\t.\n12\t666\t.\tCC\tGG,GT\t.\t.\tXRS=aaa\t.\t.\t.\t.\t.\n12\t777\t.\tCC\tGG,GT\t.\t.\tXAS=bbb,cc\t.\t.\t.\t.\t.\n12\t888\t.\tCC\tGG,GT\t.\t.\tXAS=bbb\t.\t.\t.\t.\t.\n",
    "want" => [
      [
        "CHROM",
        "POS",
        "ID",
        "REF",
        "ALT",
        "QUAL",
        "FILTER",
        "INFO",
        "S1.FRS",
        "S1.FAS",
        "S1.FGS",
        "S2.FRS",
        "S2.FAS",
        "S2.FGS",
        "S3.FRS",
        "S3.FAS",
        "S3.FGS",
        "S4.FRS",
        "S4.FAS",
        "S4.FGS"
      ],
      [
        12,
        111,
        ".",
        "CC",
        "GG,GT",
        ".",
        ".",
        ".",
        "a,b,c",
        undef,
        undef,
        "aa,bb,cc",
        undef,
        undef,
        "aaa,bbb,ccc",
        undef,
        undef,
        ".",
        undef,
        undef
      ],
      [
        12,
        222,
        ".",
        "CC",
        "GG,GT",
        ".",
        ".",
        ".",
        undef,
        "b,c",
        undef,
        undef,
        "bb,cc",
        undef,
        undef,
        "bbb,ccc",
        undef,
        undef,
        ".",
        undef
      ],
      [
        12,
        333,
        ".",
        "CC",
        "GG,GT",
        ".",
        ".",
        ".",
        undef,
        undef,
        "1,2,3",
        undef,
        undef,
        "11,22,33",
        undef,
        undef,
        "111,222,333",
        undef,
        undef,
        "."
      ],
      [
        12,
        444,
        ".",
        "CC",
        "GG,GT",
        ".",
        ".",
        ".",
        undef,
        undef,
        "11,12,22,13,23,33",
        undef,
        undef,
        "1111,1122,2222,1133,2233,3333",
        undef,
        undef,
        "111111,111222,222222,111333,222333,333333",
        undef,
        undef,
        "."
      ],
      [
        12,
        555,
        ".",
        "CC",
        "GG,GT",
        ".",
        ".",
        "XRS=aaa,bb,c",
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef
      ],
      [
        12,
        666,
        ".",
        "CC",
        "GG,GT",
        ".",
        ".",
        "XRS=aaa",
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef
      ],
      [
        12,
        777,
        ".",
        "CC",
        "GG,GT",
        ".",
        ".",
        "XAS=bbb,cc",
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef
      ],
      [
        12,
        888,
        ".",
        "CC",
        "GG,GT",
        ".",
        ".",
        "XAS=bbb",
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef,
        undef
      ]
    ]
  },
  "view.omitgenotypes.vcf" => {
    "vcf" => "##fileformat=VCFv4.2\n##reference=file:///seq/references/1000GenomesPilot-NCBI36.fasta\n##contig=<ID=20,length=62435964,assembly=B36,md5=f126cdf8a6e0c7f379d618ff66beb2da,species=\"Homo sapiens\",taxonomy=x>\n##INFO=<ID=NS,Number=1,Type=Integer,Description=\"Number of Samples With Data\">\n##INFO=<ID=DP,Number=1,Type=Integer,Description=\"Total Depth\">\n##FORMAT=<ID=GT,Number=1,Type=String,Description=\"Genotype\">\n##FORMAT=<ID=GQ,Number=1,Type=Integer,Description=\"Genotype Quality\">\n##FORMAT=<ID=DP,Number=1,Type=Integer,Description=\"Read Depth\">\n##FORMAT=<ID=HQ,Number=2,Type=Integer,Description=\"Haplotype Quality\">\n##FORMAT=<ID=TS,Number=2,Type=String,Description=\"Test Empty Format String\">\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tNA00001\tNA00002\tNA00003\n20\t14370\trs6054257\tG\tA\t29\tPASS\tNS=3;DP=14\tGT:GQ:DP:HQ\t0|0:48:1:51,51\t1|0:48:8:51,51\t1/1:43:5:.,.\n20\t17330\t.\tT\tA\t3\tPASS\tNS=3;DP=11\tGT:GQ:DP:HQ\t./.:.:.:.,.\t./.:.:.:.,.\t./.:.:.:.,.\n20\t1110696\trs6040355\tA\tG,T\t67\tPASS\tNS=2;DP=10\tGT:GQ:DP:HQ:TS\t./.\t./.\t./.\n20\t1230237\t.\tT\t.\t47\tPASS\tNS=3;DP=13\tGT:GQ:DP:HQ:TS\t.\t.\t.\n20\t1234567\tmicrosat1\tGTC\tG,GTCT\t50\tPASS\tNS=3;DP=9\tGT:GQ:DP:TS\t0/1:35:4:A,.\t0/2:17:2\t1/1:40:3\n",
    "want" => [
      [
        "CHROM",
        "POS",
        "ID",
        "REF",
        "ALT",
        "QUAL",
        "FILTER",
        "INFO",
        "NA00001.GT",
        "NA00001.GQ",
        "NA00001.DP",
        "NA00001.HQ",
        "NA00001.TS",
        "NA00002.GT",
        "NA00002.GQ",
        "NA00002.DP",
        "NA00002.HQ",
        "NA00002.TS",
        "NA00003.GT",
        "NA00003.GQ",
        "NA00003.DP",
        "NA00003.HQ",
        "NA00003.TS"
      ],
      [
        20,
        14370,
        "rs6054257",
        "G",
        "A",
        29,
        "PASS",
        "NS=3;DP=14",
        "0|0",
        48,
        1,
        "51,51",
        undef,
        "1|0",
        48,
        8,
        "51,51",
        undef,
        "1/1",
        43,
        5,
        ".,.",
        undef
      ],
      [
        20,
        17330,
        ".",
        "T",
        "A",
        3,
        "PASS",
        "NS=3;DP=11",
        "./.",
        ".",
        ".",
        ".,.",
        undef,
        "./.",
        ".",
        ".",
        ".,.",
        undef,
        "./.",
        ".",
        ".",
        ".,.",
        undef
      ],
      [
        20,
        1110696,
        "rs6040355",
        "A",
        "G,T",
        67,
        "PASS",
        "NS=2;DP=10",
        "./.",
        undef,
        undef,
        undef,
        undef,
        "./.",
        undef,
        undef,
        undef,
        undef,
        "./.",
        undef,
        undef,
        undef,
        undef
      ],
      [
        20,
        1230237,
        ".",
        "T",
        ".",
        47,
        "PASS",
        "NS=3;DP=13",
        ".",
        undef,
        undef,
        undef,
        undef,
        ".",
        undef,
        undef,
        undef,
        undef,
        ".",
        undef,
        undef,
        undef,
        undef
      ],
      [
        20,
        1234567,
        "microsat1",
        "GTC",
        "G,GTCT",
        50,
        "PASS",
        "NS=3;DP=9",
        "0/1",
        35,
        4,
        undef,
        "A,.",
        "0/2",
        17,
        2,
        undef,
        undef,
        "1/1",
        40,
        3,
        undef,
        undef
      ]
    ]
  }
}
 };

for my $name (sort keys %fixture) {
	my $fx  = $fixture{$name};
	my $aoa = $fx->{want};
	my ($aoh, $hoa, $hoh) = shapes($aoa);
	my $f = fixture($name, $fx->{vcf});

	is_deeply read_table($f), $hoh, "$name: a hoh by CHROM:POS:REF:ALT, the default";
	is_deeply read_table($f, 'output_type' => 'hoh'), $hoh, "$name: hoh, asked for";
	is_deeply read_table($f, 'output_type' => 'aoa'), $aoa, "$name: aoa";
	is_deeply read_table($f, 'output_type' => 'aoh'), $aoh, "$name: aoh";
	is_deeply read_table($f, 'output_type' => 'hoa'), $hoa, "$name: hoa";
	is_deeply read_table($f, explode => 1, 'output_type' => 'aoa'), $aoa,
		"$name: explode => 1, given";
	is_deeply read_table($f, 'output_type' => 'aoa', filter => sub { 1 }), $aoa,
		"$name: aoa through a filter that keeps every row";
	is_deeply read_table($f, comment => '#', 'output_type' => 'aoa'), $aoa,
		"$name: comment => '#'";
	is_deeply read_table(fixture("$name.gz", gz($fx->{vcf})), 'output_type' => 'aoa'),
		$aoa, "$name: gzipped";
	# row_names by a column whose values are unique in every fixture
	my (undef, undef, $by_pos) = shapes($aoa, 'POS');
	is_deeply read_table($f, 'row_names' => 'POS'), $by_pos, "$name: hoh by POS";
	# an exploded column can name the rows too
	my $col = $aoa->[0][8];
	my @vals = grep { defined } map { $_->[8] } @$aoa[ 1 .. $#$aoa ];
	my %u = map { $_ => 1 } @vals;
	if (@vals == $#$aoa && keys %u == @vals) {
		my (undef, undef, $by_col) = shapes($aoa, $col);
		is_deeply read_table($f, 'row_names' => $col), $by_col,
			"$name: hoh by an exploded column, $col";
	}
	# na_strings reaches the split values as well as the fields
	my $na_aoa = [ $aoa->[0], map { [ map { defined && $_ eq '.' ? undef : $_ } @$_ ] }
		@$aoa[ 1 .. $#$aoa ] ];
	is_deeply read_table($f, 'na_strings' => '.', 'output_type' => 'aoa'), $na_aoa,
		"$name: na_strings => '.' maps fields and split values";
	# explode => 0 is the file's own columns
	my ($hline) = $fx->{vcf} =~ /^#(CHROM\t[^\n]*)/m;
	is_deeply read_table($f, explode => 0, 'output_type' => 'aoa')->[0],
		[ split /\t/, $hline, -1 ], "$name: explode => 0 keeps FORMAT and the samples whole";
	# header => 0 has no FORMAT column to split by, and reads the file plain
	my $plain = read_table($f, header => 0, 'output_type' => 'aoa');
	is $plain->[1][0], '#CHROM', "$name: header => 0 is not exploded";
}

my $ex2 = $fixture{'ex2.vcf'}{vcf};
my $f   = fixture('ex2.vcf', $ex2);

# A filter runs while the file is read, on its own columns, before the split.
# The columns are the keys of the records it kept: CNL is only in the first
# record's FORMAT, so it has no columns here.
{
	my $all  = $fixture{'ex2.vcf'}{want};
	my @keep = grep { $all->[0][$_] !~ /\.CNL\z/ } 0 .. $#{ $all->[0] };
	my $want = [ map { [ @$_[@keep] ] } grep { $_ == $all->[0] || $_->[1] == 17330 } @$all ];
	is_deeply read_table($f, 'output_type' => 'aoa',
			filter => { FORMAT => sub { $_ eq 'GT:GQ:DP:HQ' }, POS => sub { $_ < 1e6 } }),
		$want, 'a filter sees FORMAT, a column the exploded table does not have';
	is_deeply read_table($f, 'output_type' => 'aoa',
			filter => { NA00001 => sub { /^0\|0:49/ } }),
		$want, 'and a sample column unsplit';
	my ($err) = outcome(sub { read_table($f, filter => { 'NA00001.GT' => sub { 1 } }) });
	like $err, qr/^read_table: Filter column 'NA00001\.GT' not found in the header of \Q$f\E;/,
		'an exploded name is not a column a filter can see';
}

# col_names renames the file's columns before the split, so a renamed sample
# names its exploded columns
{
	my @cn = (qw(chr pos id ref alt qual filter info format), qw(s1 s2 s3));
	my $got = read_table($f, 'col_names' => \@cn, 'output_type' => 'aoa');
	is_deeply $got->[0],
		[ qw(chr pos id ref alt qual filter info),
		  map { my $s = $_; map { "$s.$_" } qw(GT GQ DP HQ CNL) } qw(s1 s2 s3) ],
		'col_names: the renamed samples name the exploded columns';
	is_deeply [ sort keys %{ read_table($f, 'col_names' => \@cn) } ],
		[ sort map { join ':', @$_[ 0, 1, 3, 4 ] } @$got[ 1 .. $#$got ] ],
		'col_names: the hoh is still keyed by the CHROM:POS:REF:ALT columns';
}

# a VCF with no samples is its eight fixed columns; one with FORMAT and no
# samples keeps FORMAT, having nothing to split it into
{
	my $sites = "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\n"
		. "1\t10\t.\tA\tG\t5\tPASS\tDP=3\n";
	my $g = fixture('sites.vcf', $sites);
	is_deeply read_table($g),
		{ '1:10:A:G' => { CHROM => 1, POS => 10, ID => '.', REF => 'A', ALT => 'G',
			QUAL => 5, FILTER => 'PASS', INFO => 'DP=3' } },
		'sites only: the fixed columns, keyed by CHROM:POS:REF:ALT';
	(my $fmt_only = $sites) =~ s/\tINFO\n/\tINFO\tFORMAT\n/;
	$fmt_only =~ s/\tDP=3\n/\tDP=3\tGT\n/;
	is_deeply read_table(fixture('fmt.vcf', $fmt_only), 'output_type' => 'aoa'),
		[ [qw(CHROM POS ID REF ALT QUAL FILTER INFO FORMAT)],
		  [ 1, 10, '.', 'A', 'G', 5, 'PASS', 'DP=3', 'GT' ] ],
		'FORMAT and no samples: FORMAT is kept';
	my $empty = "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\tALT\tQUAL\tFILTER\tINFO\tFORMAT\tS1\n";
	my $e = fixture('empty.vcf', $empty);
	is_deeply read_table($e), {}, 'a header and no records: an empty hoh';
	is_deeply read_table($e, 'output_type' => 'hoa'), {}, 'and an empty hoa';
	is_deeply read_table($e, 'output_type' => 'aoa'),
		[ [qw(CHROM POS ID REF ALT QUAL FILTER INFO)] ],
		'and an aoa of the fixed columns: no record gave a FORMAT key';
}

# a repeated key is warned about once, later values winning, as any hoh is
{
	(my $dup = $ex2) =~ s/^(20\t17330\t[^\n]*\n)/$1$1/m;
	my $g = fixture('dup.vcf', $dup);
	my ($err, $warn) = outcome(sub { read_table($g) });
	is $err, '', 'a repeated CHROM:POS:REF:ALT is not an error';
	is_deeply $warn,
		[ "read_table: duplicate row name '20:17330:T:A' in $g (later values win)\n" ],
		'and is warned about, in read_table\'s words';
	($dup = $ex2) =~ s/^(20\t17330\t[^\n]*\n)/$1$1$1/m;
	$g = fixture('dup2.vcf', $dup);
	(undef, $warn) = outcome(sub { read_table($g) });
	is_deeply $warn,
		[ "read_table: 2 rows of $g repeat an earlier row's name (later values "
		  . "win); the first is '20:17330:T:A', on data row 3\n" ],
		'two repeats: one warning with the count';
}

# croaks
{
	my ($err) = outcome(sub { read_table(fixture('x.tsv', "a\tb\n1\t2\n"), explode => 1) });
	like $err, qr/^read_table: 'explode' applies only to a VCF \(\.vcf, \.vcf\.gz or \.vcf\.bgz\), and ".*x\.tsv" is not named as one$/,
		'explode on a file not named as a VCF';
	($err) = outcome(sub { read_table($f, explode => 2) });
	is $err, "read_table: 'explode' must be 0 or 1\n", 'explode => 2';
	($err) = outcome(sub { read_table($f, explode => undef) });
	is $err, "read_table: 'explode' must be 0 or 1\n", 'explode => undef';
	($err) = outcome(sub { read_table($f, 'row_names' => 'NA00001') });
	is $err, "\"NA00001\" isn't in the header of $f\n",
		'row_names naming a sample column, which the exploded table has not got';
	($err) = outcome(sub { read_table($f, 'row_names' => 'QUAL', 'na_strings' => '.') });
	is $err, "read_table: undefined row name (column 'QUAL') in $f data row 2\n",
		'a row name made undef by na_strings';
	($err) = outcome(sub { read_table($f, 'output_type' => 'aoa', 'row_names' => 'POS') });
	like $err, qr/^read_table: 'row_names' has no meaning for output_type "aoa"/,
		'row_names with an aoa';
	(my $long = $ex2) =~ s/\t0\|0:48:1:25,30:10,20\t/\t0|0:48:1:25,30:10,20:9\t/;
	my $g = fixture('long.vcf', $long);
	($err) = outcome(sub { read_table($g) });
	is $err, "read_table: $g data row 1: sample 'NA00001' has 6 values for the 5 keys "
		. "of FORMAT 'GT:GQ:DP:HQ:CNL'\n", 'a sample with more values than FORMAT has keys';
	my $short = "##fileformat=VCFv4.2\n#CHROM\tPOS\tID\tREF\n1\t10\t.\tA\n";
	$g = fixture('short.vcf', $short);
	($err) = outcome(sub { read_table($g) });
	is $err, "read_table: $g has fewer than the 5 columns (CHROM POS ID REF ALT) "
		. "that key a VCF's rows; pass 'row_names'\n", 'too few columns to key a hoh';
	is_deeply read_table($g, 'row_names' => 'POS'),
		{ 10 => { CHROM => 1, ID => '.', REF => 'A' } }, 'unless row_names is given';
}

if ($HAVE_LEAKTRACE && !$INC{'Devel/Cover.pm'}) {
	no_leaks_ok { read_table($f) } 'no leaks exploding a VCF into a hoh';
	no_leaks_ok { read_table($f, 'output_type' => 'aoa', 'na_strings' => '.') }
		'no leaks exploding into an aoa with na_strings';
}

done_testing;
