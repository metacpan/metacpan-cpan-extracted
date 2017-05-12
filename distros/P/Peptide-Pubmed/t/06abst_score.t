# -*-perl-*-

#use Test::More qw(no_plan);
use Test::More tests => 33;

use Peptide::Pubmed;
use Data::Dumper;
use Carp;
use warnings;
use strict;

my $verbose = defined $ENV{TEST_VERBOSE} ? $ENV{TEST_VERBOSE} : 1;


############################################################
## begin examples for POD 
############################################################

my $parser;
my $in;
my $out;
my $abst;
my @words;
my @seqs;

$parser = Peptide::Pubmed->new;
$in = { 
   PMID		=> q[15527327],
   Author	=> q[Doe JJ, Smith Q],
   Journal	=> q[J Biological Foo. 2004;8(2):123-30.],
   Title	=> q[Foo, bar and its significance in phage display.],
   Abstract	=> q[Peptide sequences EYHHYNK and Arg-Gly-Asp, but not ACCCGTNA or VEGFRI.],
   Mesh		=> q[Genes, p53/genetics; Humans; Bar],
   Chemical	=> q[Multienzyme Complexes; Peptide Library; Foo],
  };
$parser->parse_abstract($in);

# get the peptide sequences in 1 letter symbols (select all words where the 
# combined word/abstract score is above threshold: 
# WordAbstScore >= WordAbstScoreMin):
@seqs = $parser->get_seqs;
print "@seqs\n"; # prints: 'EYHHYNK RGD'
is("@seqs", 'EYHHYNK RGD', 'get_seqs: default WordAbstScoreMin: EYHHYNK RGD');

# same, set threshold explicitly:
$parser->WordAbstScoreMin(0.4);
@seqs = $parser->get_seqs;
print "@seqs\n"; # prints: 'EYHHYNK RGD'

# set low threshold to get more peptide sequences (but at a cost of getting 
# more false positives) 
$parser->WordAbstScoreMin(-1);
@seqs = $parser->get_seqs;
print "@seqs\n"; # prints: 'EYHHYNK RGD ACCCGTNA VEGFRI'
is("@seqs", 'EYHHYNK RGD ACCCGTNA VEGFRI', 'get_seqs: WordAbstScoreMin = -1: all');

# reset threshold back:
$parser->WordAbstScoreMin(0.4);

# get more data for the abstract:
$abst = $parser->get_abst;
print "$abst->{AbstScore}\n"; # abstract score, in the [0,1] interval
print "$abst->{AbstMtext}\n"; # abstract with sequences marked up: 
# 'Peptide sequences <mark>EYHHYNK</mark> and <mark>Arg-Gly-Asp,</mark> but not ACCCGTNA or VEGFRI.'
is($abst->{AbstMtext}, 'Peptide sequences <mark>EYHHYNK</mark> and <mark>Arg-Gly-Asp,</mark> but not ACCCGTNA or VEGFRI.', 'get_abst AbstMtext');

# get more data for the words, in addition to peptide sequences:
@words = $parser->get_words;
for my $word (@words) {
    print "$word->{WordAbstScore}\n"; # combined word/abstract score, in the [0,1] interval
    print "$word->{WordOrig}\n"; # word as found in the abstract, eg 'Arg-Gly-Asp,'
    print "$word->{WordSequence}\n"; # peptide sequence in 1 letter symbols, eg 'RGD'
}
is($words[1]->{WordSequence}, 'RGD', 'get_words: WordSequence');

# There are no mandatory input fields. This will work too, but may give lower score.
$in = { 
       Abstract	=> q[Peptide sequences EYHHYNK and Arg-Gly-Asp, but not ACCCGTNA or VEGFRI.],
      };
$parser->parse_abstract($in);

# No peptide sequences are found in empty input:
$in = undef;
$parser->parse_abstract($in);
@words = $parser->get_words;
is(scalar(@words), 0, 'empty input - no sequences');

carp((caller(0))[3], "test dump $0 (@_)", ' ', Data::Dumper->Dump([$abst], ['abst'])) 
      if $verbose > 2;

carp((caller(0))[3], "test dump $0 (@_)", ' ', Data::Dumper->Dump([\@words], ['*words'])) 
      if $verbose > 2;

############################################################
## end examples for POD 
############################################################

my $rh_pm_in;
my $rh_pm_out;
my $got;

$rh_pm_in = 
  { 
   Abstract	=> q[], 
  };
$parser = Peptide::Pubmed->new(
			       AbstScoreMin => -1, WordScoreMin => -1, WordAbstScoreMin => -1, WordNumPrintMin => -1, WordNumPrintMax => -1, 
			       verbose => $verbose,
			      );
ok($parser, 'Peptide::Pubmed->new');

$rh_pm_out = $parser->parse_abstract($rh_pm_in);
ok($rh_pm_out,						'parse_abstract empty Abstract');
is(@{ $rh_pm_out->{words} },			0, 'number of elements in words; unlimited number of words per abstract, empty Abstract');

$parser = Peptide::Pubmed->new(
			       AbstScoreMin => -1, WordScoreMin => -1, WordAbstScoreMin => -1, WordNumPrintMin => 1, WordNumPrintMax => 1, 
			       verbose => $verbose,
			      );
$rh_pm_out = $parser->parse_abstract($rh_pm_in);
is($rh_pm_out->{abst}{AbstScore},		'0.0000', 'AbstScore empty Abstract');
is(@{ $rh_pm_out->{words} },			1, 'number of elements in words; exactly 1 word per abstract, empty Abstract');
$got = join '',
  map { sprintf("%.0f", $rh_pm_out->{words}[0]{$_} ? $rh_pm_out->{words}[0]{$_} : 0) ? 1 : 0 } 
  sort keys %{ $rh_pm_out->{words}[0] };
like($got, qr/^0+$/, 'Word* vars = 0 or empty, empty Abstract');

$rh_pm_in = undef;
$rh_pm_out = $parser->parse_abstract($rh_pm_in);
is($rh_pm_out->{abst}{AbstScore},		'0.0000', 'AbstScore undef input');

$got = join '',
  map { sprintf("%.0f", $rh_pm_out->{words}[0]{$_} ? $rh_pm_out->{words}[0]{$_} : 0) ? 1 : 0 } 
  sort keys %{ $rh_pm_out->{words}[0] };
like($got,	qr/^0+$/, 'Word* vars = 0 or empty, undef input');

$parser = Peptide::Pubmed->new(
			       AbstScoreMin => -1, WordScoreMin => 1e-6, WordAbstScoreMin => -1, WordNumPrintMin => -1, WordNumPrintMax => -1, 
			       verbose => $verbose,
			      );
$rh_pm_in = 
  { 
   Abstract	=> qq[ Peptide  phage\t\tdisplay sequences EYHHYNK and GETRAPL.],
  };
$rh_pm_out = $parser->parse_abstract($rh_pm_in);

# linear terms: += 2 + 2
# AbstScore = 4
# interaction terms: += 2 * 2
# AbstScore = 8
# AbstPropAllCap: *= (1 - 2 / 7)
# AbstScore = 5.71428571428571
# y = x / (1 + x) : 
# AbstScore = 0.851063829787234

is($rh_pm_out->{abst}{AbstLcAllText},		qq[absttitle: ;; abstabstract:  peptide  phage\t\tdisplay sequences eyhhynk and getrapl.;; abstmesh: ;; abstchemical: ], 'AbstLcAllText EYHHYNK');
is($rh_pm_out->{abst}{AbstMaxWordScore},       	0.9038, 'AbstMaxWordScore EYHHYNK');
is($rh_pm_out->{abst}{AbstMtext},		qq[ Peptide  phage\t\tdisplay sequences <mark>EYHHYNK</mark> and <mark>GETRAPL.</mark>], 'AbstMtext EYHHYNK');
is($rh_pm_out->{abst}{AbstNumAb},		0, 'AbstNumAb EYHHYNK');
is($rh_pm_out->{abst}{AbstNumAllCap},		2, 'AbstNumAllCap EYHHYNK');
is($rh_pm_out->{abst}{AbstNumBind},		0, 'AbstNumBind EYHHYNK');
is($rh_pm_out->{abst}{AbstNumDigest},		0, 'AbstNumDigest EYHHYNK');
is($rh_pm_out->{abst}{AbstNumWords},		7, 'AbstNumWords EYHHYNK');
is($rh_pm_out->{abst}{AbstNumMHC},		0, 'AbstNumMHC EYHHYNK');
is($rh_pm_out->{abst}{AbstNumPeptide},		2, 'AbstNumPeptide EYHHYNK');
is($rh_pm_out->{abst}{AbstNumPhage},		2, 'AbstNumPhage EYHHYNK');
is($rh_pm_out->{abst}{AbstNumProtease},		0, 'AbstNumProtease EYHHYNK');
is($rh_pm_out->{abst}{AbstPropAllCap},		0.2857, 'AbstPropAllCap EYHHYNK');
ok($rh_pm_out->{abst}{AbstScore}		> 0.5, 'AbstScore EYHHYNK');

is(@{ $rh_pm_out->{words} },			15, 'number of elements in words; WordScoreMin => 1e-6 EYHHYNK');

$parser = Peptide::Pubmed->new(
			       AbstScoreMin => -1, WordScoreMin => -1, WordAbstScoreMin => -1, WordNumPrintMin => 1, WordNumPrintMax => 1, 
			       verbose => $verbose,
			      );
$rh_pm_out = $parser->parse_abstract($rh_pm_in);
is(@{ $rh_pm_out->{words} },			1, 'number of elements in words; exactly 1 word per abstract EYHHYNK');

$parser = Peptide::Pubmed->new(
			       AbstScoreMin => -1, WordScoreMin => -1, WordAbstScoreMin => -1, WordNumPrintMin => 1, WordNumPrintMax => 1, 
			       verbose => $verbose,
			      );

my $in_fname = 't/06abst_score_in.rdb';
my $out_fname = 't/06abst_score_out.rdb';

open IN_FNAME, ">$in_fname" or carp "not ok: open $in_fname: $!";

# examples from these files:
# medline06n0668.rdb
# cat medline06n0500.rdb | head -3 > ~/bin/Peptide/t/tmp.06abst_score.txt 

print IN_FNAME <<IN_FNAME_CONTENTS;
PMID	Author	Journal	Title	Abstract	Mesh	Chemical
50S	50S	50S	50S	50S	50S	50S
14759804	Work LM, Nicklin SA, Brain NJ, Dishart KL, Von Seggern DJ, Hallek M, Büning H, Baker AH	Mol Ther. 1972 Feb;9(2):198-208.	Development of efficient viral vectors selective for vascular smooth muscle cells.	The vascular smooth muscle cell (SMC) is integral to the pathogenesis of neointimal formation associated with late vein graft failure, in-stent restenosis, and transplant arteriopathy. Viral vectors transduce SMC with low efficiency and hence, there is a need for improvement. We aimed to enhance the efficiency and selectivity of gene delivery to human SMC. Targeting ligands were identified using phage display on primary human saphenous vein SMC with linear and cyclic libraries. Two linear peptides, EYHHYNK (EYH) and GETRAPL (GET), were incorporated into the HI loop of adenovirus (Ad) fibers and the capsid protein of adeno-associated virus-2 (AAV-2). Exposure of human venous SMC to EYH-modified (but not the GET-modified) Ad vector resulted in a significant increase in transgene expression levels at short, clinically relevant exposure times. Similarly, the EYH-modified AAV vector resulted in enhanced gene transfer to human venous SMC but not endothelial cells in a time- and dose-dependent manner. The EYH-modified AAV vector also enhanced (up to 70-fold) gene delivery to primary human arterial SMC. Hence, incorporation of EYH into Ad and AAV capsids resulted in a significant and selective enhancement in transduction of SMC and has implications for improving local gene delivery to the vasculature.... digest: tryptic peptide mapping, MS/MS... seqs: cyclo(-Arg-Gly-Asp-dPhe-Val), X-proline-X-X-proline, N-Formyl-Met-Leu-Phe, ... degenerate seq: GXXXXXXG ... discard this: wrong pattern: BLACK XLACZ ... dict english: RELIC PATIENT PATIENTS  ... dict sci: SDS-PAGE SELEX VEGFRII (A/M)ART HAART TMHMM ... kds: 30 microM 2.2 x 10(7) M-1 50 micromol/L... ab: antigens rfab,...major histocomp complex: MHC, T cells, class I, but not subclass I... all or mostly dna: ACCCGTNA ACGTNACGTNW (T/C)CAAGG(T/C)C(A/G) not all dna: ACCCGTNS ... gene: FVIII, IGF-II, MARCKS, N-WASP, ...	Adenoviridae/genetics; Adenoviridae/physiology; Capsid Proteins/genetics; Capsid Proteins/metabolism; Cells, Cultured; Cysteine Endopeptidases/metabolism; Dependovirus/genetics; Dependovirus/physiology; Genetic Vectors/genetics; Heparin/metabolism; Humans; Multienzyme Complexes/metabolism; Muscle, Smooth, Vascular/cytology; Muscle, Smooth, Vascular/virology; Organ Specificity; Peptide Library; Peptides/genetics; Peptides/metabolism; Proteasome Endopeptidase Complex; Protein Engineering; Protein Transport; Saphenous Vein	Capsid Proteins; Multienzyme Complexes; Peptide Library; Peptides; Heparin; Cysteine Endopeptidases; Proteasome Endopeptidase Complex
15527327	Sunar-Reeder B, Atha DH, Aydemir S, Reeder DJ, Tully L, Khan AR, O'Connell CD	Mol Diagn. 2004;8(2):123-30.	Use of TP53 reference materials to validate mutations in clinical tissue specimens by single-strand conformational polymorphism analysis.	BACKGROUND: As genetic information moves from basic research laboratories in to the clinical testing environment, there is a critical need for reliable reference materials for the quality assurance of genetic tests. A panel of 12 plasmid clones containing wild-type or point mutations within exons 5-9 have been developed as reference materials for the detection of TP53 mutations. AIM: The goal of this study was to validate the reference materials in providing quality assurance for the detection of TP53 mutations in clinical specimens. METHODS: We studied 33 gynecological samples, 11 apparently normal samples and 22 malignant tumors of various origins. Mutations were identified using single-strand conformational polymorphism analysis with both slab gel and capillary electrophoresis. All DNA samples were amplified with fluorescently labeled PCR primers specific for exons 5-9 for mutation detection. RESULTS: Of the 33 patient samples tested, mutations and polymorphisms were found in six specimens in three of the five exons scanned; no mutations were found in exons 7 or 9. Both a mutation and polymorphism were found in non-malignant specimens from the control group. The mutations were confirmed by DNA sequence analysis of the regions scanned. CONCLUSIONS: Mutations and polymorphisms were detected in the clinical samples. All of the mutations were silent except for one non-conservative mutation in exon 5, codon 181. This study demonstrates the usefulness of the National Institute of Standards and Technology (NIST) TP53 reference panel in TP53 mutation detection in clinical tissue specimens.	Adolescent; Adult; Base Sequence; DNA Mutational Analysis/standards; DNA, Neoplasm/analysis; Electrophoresis, Capillary; Exons/genetics; Female; Genes, p53/genetics; Humans; Middle Aged; Molecular Sequence Data; Mutation; Neoplasms/diagnosis; Neoplasms/genetics; Polymerase Chain Reaction; Polymorphism, Single-Stranded Conformational; Reference Standards; Sequence Analysis, DNA	DNA, Neoplasm
IN_FNAME_CONTENTS

close IN_FNAME or carp "not ok: close $in_fname: $!";

ok($parser->parse_file(in_fname => $in_fname, out_fname => $out_fname) , 'parse_file');

carp((caller(0))[3], "test dump $0 (@_)", ' ', Data::Dumper->Dump([$parser], ['parser'])) 
      if $verbose > 2;

my $out_fh;
open $out_fh, $out_fname or carp "not ok: open $out_fname: $!";
my @out = <$out_fh>;
close $out_fh or carp "not ok: close $out_fname: $!";
is(@out, 4,	'print exactly 1 line per abstract: input = EYHHYNK, DNA (2 abstracts)');

# generated by:
# cat t/06abst_score_in.rdb | row PMID eq 15527327 | ptbl.pl > err
$rh_pm_in = 
  {
   PMID		=> q[15527327],
   Author	=> q[Sunar-Reeder B, Atha DH, Aydemir S, Reeder DJ, Tully L, Khan AR, O'Connell CD],
   Journal	=> q[Mol Diagn. 2004;8(2):123-30.],
   Title	=> q[Use of TP53 reference materials to validate mutations in clinical tissue specimens by single-strand conformational polymorphism analysis.],
   Abstract	=> q[BACKGROUND: As genetic information moves from basic research laboratories in to the clinical testing environment, there is a critical need for reliable reference materials for the quality assurance of genetic tests. A panel of 12 plasmid clones containing wild-type or point mutations within exons 5-9 have been developed as reference materials for the detection of TP53 mutations. AIM: The goal of this study was to validate the reference materials in providing quality assurance for the detection of TP53 mutations in clinical specimens. METHODS: We studied 33 gynecological samples, 11 apparently normal samples and 22 malignant tumors of various origins. Mutations were identified using single-strand conformational polymorphism analysis with both slab gel and capillary electrophoresis. All DNA samples were amplified with fluorescently labeled PCR primers specific for exons 5-9 for mutation detection. RESULTS: Of the 33 patient samples tested, mutations and polymorphisms were found in six specimens in three of the five exons scanned; no mutations were found in exons 7 or 9. Both a mutation and polymorphism were found in non-malignant specimens from the control group. The mutations were confirmed by DNA sequence analysis of the regions scanned. CONCLUSIONS: Mutations and polymorphisms were detected in the clinical samples. All of the mutations were silent except for one non-conservative mutation in exon 5, codon 181. This study demonstrates the usefulness of the National Institute of Standards and Technology (NIST) TP53 reference panel in TP53 mutation detection in clinical tissue specimens.],
   Mesh		=> q[Adolescent; Adult; Base Sequence; DNA Mutational Analysis/standards; DNA, Neoplasm/analysis; Electrophoresis, Capillary; Exons/genetics; Female; Genes, p53/genetics; Humans; Middle Aged; Molecular Sequence Data; Mutation; Neoplasms/diagnosis; Neoplasms/genetics; Polymerase Chain Reaction; Polymorphism, Single-Stranded Conformational; Reference Standards; Sequence Analysis, DNA],
   Chemical	=> q[DNA, Neoplasm],
  };
$parser = Peptide::Pubmed->new(
			       AbstScoreMin => -1, WordScoreMin => 0.2, WordAbstScoreMin => -1, 
			       verbose => $verbose,
			      );
$rh_pm_out = $parser->parse_abstract($rh_pm_in);
ok($rh_pm_out, 'parse_abstract DNA');
ok($rh_pm_out->{abst}{AbstScore} < 0.5,		'AbstScore DNA');





##cc Word* AbstMaxWordScore for 1-2 words


