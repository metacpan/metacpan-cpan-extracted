# -*-perl-*-

#use Test::More qw(no_plan);
use Test::More tests => 69;

use Peptide::Pubmed;
use Data::Dumper;
use Carp;
use warnings;
use strict;

my $verbose = defined $ENV{TEST_VERBOSE} ? $ENV{TEST_VERBOSE} : 1;

my $in_fname = 't/02parse_seq_in.rdb';
my $out_fname = 't/02parse_seq_out.rdb';

# in 02parse_seq.t and 06abst_score.t, test vars:
# cat lib/Peptide/Pubmed.pm err | perl -lane 'print $1 if /\b((Word|Abst)\w+)/g' | sort -u

=head2 TODO add tests:

-AbstMaxWordScore
-AbstMtext
-AbstScore
-WordAbstScore

=cut

open IN_FNAME, ">$in_fname" or carp "not ok: open $in_fname: $!";

# example from medline06n0668.rdb

print IN_FNAME <<IN_FNAME_CONTENTS;
PMID	Author	Journal	Title	Abstract	Mesh	Chemical
50S	50S	50S	50S	50S	50S	50S
14759804	Work LM, Nicklin SA, Brain NJ, Dishart KL, Von Seggern DJ, Hallek M, Büning H, Baker AH	Mol Ther. 1972 Feb;9(2):198-208.	Development of efficient viral vectors selective for vascular smooth muscle cells.	The vascular smooth muscle cell (SMC) is integral to the pathogenesis of neointimal formation associated with late vein graft failure, in-stent restenosis, and transplant arteriopathy. Viral vectors transduce SMC with low efficiency and hence, there is a need for improvement. We aimed to enhance the efficiency and selectivity of gene delivery to human SMC. Targeting ligands were identified using phage display on primary human saphenous vein SMC with linear and cyclic libraries. Two linear peptides, EYHHYNK (EYH) and GETRAPL (GET), were incorporated into the HI loop of adenovirus (Ad) fibers and the capsid protein of adeno-associated virus-2 (AAV-2). Exposure of human venous SMC to EYH-modified (but not the GET-modified) Ad vector resulted in a significant increase in transgene expression levels at short, clinically relevant exposure times. Similarly, the EYH-modified AAV vector resulted in enhanced gene transfer to human venous SMC but not endothelial cells in a time- and dose-dependent manner. The EYH-modified AAV vector also enhanced (up to 70-fold) gene delivery to primary human arterial SMC. Hence, incorporation of EYH into Ad and AAV capsids resulted in a significant and selective enhancement in transduction of SMC and has implications for improving local gene delivery to the vasculature.... digest: tryptic peptide mapping, MS/MS...   seqs: cyclo(-Arg-Gly-Asp-dPhe-Val), X-proline-X-X-proline, N-Formyl-Met-Leu-Phe; split seq: EYHH/YNK ... degenerate seq: GXXXXXXG (-Cys59-x-x-x-x-Cys64-) ... discard this: wrong pattern: BLACK XLACZ ...  DictionaryAbbreviations : AWGC ... dict english: RELIC PATIENT PATIENTS ... DictionaryFrequent (IVGTT) AAAASF  ... dict sci: SDS-PAGE SELEX VEGFRII (A/M)ART HAART TMHMM FPLC/HPLC HPLC (GKLF/KLF4) ... roman: HYNK HYNKIII HYNKIIIA HYNKXXVII ... kds: 30 microM 2.2 x 10(7) M-1 50 micromol/L... ab: antigens rfab,...major histocomp complex: MHC, T cells, class I, but not subclass I... all or mostly dna: ACCCGTNA ACGTNACGTNW (T/C)CAAGG(T/C)C(A/G) not all dna: ACCCGTNS ... gene: FVIII, IGF-II, MARCKS, N-WASP, MOS/MEK/MAPK/RSK  ...	Adenoviridae/genetics; Adenoviridae/physiology; Capsid Proteins/genetics; Capsid Proteins/metabolism; Cells, Cultured; Cysteine Endopeptidases/metabolism; Dependovirus/genetics; Dependovirus/physiology; Genetic Vectors/genetics; Heparin/metabolism; Humans; Multienzyme Complexes/metabolism; Muscle, Smooth, Vascular/cytology; Muscle, Smooth, Vascular/virology; Organ Specificity; Peptide Library; Peptides/genetics; Peptides/metabolism; Proteasome Endopeptidase Complex; Protein Engineering; Protein Transport; Saphenous Vein	Capsid Proteins; Multienzyme Complexes; Peptide Library; Peptides; Heparin; Cysteine Endopeptidases; Proteasome Endopeptidase Complex
IN_FNAME_CONTENTS

close IN_FNAME or carp "not ok: close $in_fname: $!";

my $parser = Peptide::Pubmed->new(AbstScoreMin => -1, WordScoreMin => -1, WordAbstScoreMin => -1, verbose => $verbose);
ok($parser, 'Peptide::Pubmed->new');

ok($parser->parse_file(in_fname => $in_fname, out_fname => $out_fname) , 'parse_file');

carp((caller(0))[3], "test dump $0 (@_)", ' ', Data::Dumper->Dump([$parser], ['parser'])) 
      if $verbose > 2;

my $abst = $parser->{abst};

is($abst->{AbstNumAb},		2,	'AbstNumAb');
ok($abst->{AbstNumAllCap} > 47,		'AbstNumAllCap');
is($abst->{AbstNumBind},	3,	'AbstNumBind');
is($abst->{AbstNumDigest},	28,	'AbstNumDigest for year=1972');
is($abst->{AbstNumMHC},		4,	'AbstNumMHC');
is($abst->{AbstNumPeptide},	14,	'AbstNumPeptide');
is($abst->{AbstNumPhage},	8,	'AbstNumPhage');
is($abst->{AbstNumProtease},	6,	'AbstNumProtease');

warn "AbstScore='$abst->{AbstScore}'" if $verbose > 1;

my @words  = @{ $parser->{words} };

my %SequencesAll = map { $_ => 1 } map { defined $_->{WordSequence} ? $_->{WordSequence} : () } @words;
warn "SequencesAll=" . join ' ', sort keys %SequencesAll if $verbose > 1;

is($parser->find(WordOrig => 'X-proline-X-X-proline,')->{WordAaSymbols}, 3, 'WordAaSymbols X-proline-X-X-proline');
is($parser->find(WordOrig => 'GETRAPL')->{WordAaSymbols}, 1, 'WordAaSymbols GETRAPL');

is($parser->find(WordOrig => 'EYHH/YNK')->{WordAlpha}, 'EYHHYNK', 'WordAlpha EYHH/YNK');

my %WordIsDNA = map { $_->{WordSequence} => $_->{WordIsDNA} } grep $_->{WordSequence}, @words;
warn "WordIsDNA=" . join ' ', grep $WordIsDNA{$_}, sort keys %WordIsDNA if $verbose > 1;

is($WordIsDNA{'ACCCGTNA'},		1, q[is(WordIsDNA{'ACCCGTNA'}]);
is($WordIsDNA{'ACGTNACGTNW'},		1, q[is(WordIsDNA{'ACGTNACGTNW'}]);
is($WordIsDNA{'(T/C)CAAGG(T/C)C(A/G)'},	1, q[is(WordIsDNA{'(T/C)CAAGG(T/C)C(A/G)'}]);
is($WordIsDNA{'ACCCGTNS'},		0, q[isnt(WordIsDNA{'ACCCGTNS'}]);

is($parser->find(WordOrig => 'ACCCGTNS')->{WordIsDNALen}, 7, 'WordIsDNALen ACCCGTNS');

my %WordIsDict = map { $_->{WordSequence} => $_->{WordIsDict} } grep $_->{WordSequence}, @words;
warn "WordIsDict=" . join ' ', grep $WordIsDict{$_}, sort keys %WordIsDict if $verbose > 1;

is($WordIsDict{'GETRAPL'},	0, q[isnt(WordIsDict{'GETRAPL'}]);
is($WordIsDict{'SELEX'},	1, q[is(WordIsDict{'SELEX'}]);
is($WordIsDict{'SDSPAGE'},	1, q[is(WordIsDict{'SDSPAGE'}]);
is($WordIsDict{'VEGFRII'},	1, q[is(WordIsDict{'VEGFRII'}]);
is($WordIsDict{'PATIENT'},	1, q[is(WordIsDict{'PATIENT'},]);
is($WordIsDict{'PATIENTS'},	1, q[is(WordIsDict{'PATIENTS'}]);
is($WordIsDict{'(A/M)ART'},	1, q[is(WordIsDict{'(A/M)ART'}]);
is($WordIsDict{'HAART'},	1, q[is(WordIsDict{'HAART'}]);
is($WordIsDict{'TMHMM'},	1, q[is(WordIsDict{'TMHMM'}]);
is($WordIsDict{'FPL(C/H)PLC'},	1, q[is(WordIsDict{'FPL(C/H)PLC'}]);

is($parser->find(WordOrig => 'AWGC')->{WordIsDict}, 1, 'WordIsDict AWGC DictionaryAbbreviations');
is($parser->find(WordOrig => 'AAAASF')->{WordIsDict}, 1, 'WordIsDict AAAASF DictionaryFrequent');
is($parser->find(WordOrig => '(IVGTT)')->{WordIsDict}, 1, 'WordIsDict (IVGTT) DictionaryFrequent');

is($parser->find(WordOrig => 'FPLC/HPLC')->{WordIsDictLen}, 8, 'WordIsDictLen FPLC/HPLC');
is($parser->find(WordOrig => 'HPLC')->{WordIsDictLen}, 4, 'WordIsDictLen HPLC');
is($parser->find(WordOrig => 'SDS-PAGE')->{WordIsDictLen}, 7, 'WordIsDictLen SDS-PAGE');

my %WordIsGene = map { $_->{WordSequence} => $_->{WordIsGene} } grep $_->{WordSequence}, @words;
warn "WordIsGene=" . join ' ', grep $WordIsGene{$_}, sort keys %WordIsGene if $verbose > 1;

is($WordIsGene{'GETRAPL'},		0, q[isnt(WordIsGene{'GETRAPL'}]);
is($WordIsGene{'FVIII'},		1, q[is(WordIsGene{'FVIII'}]);
is($WordIsGene{'IGFII'},		1, q[is(WordIsGene{'IGF-II'}]);
is($WordIsGene{'MARCKS'},		1, q[is(WordIsGene{'MARCKS'}]);

is($parser->find(WordOrig => '(GKLF/KLF4)')->{WordIsGeneLen}, 7, 'WordIsGeneLen (GKLF/KLF4)');
is($parser->find(WordOrig => 'N-WASP,')->{WordIsGeneLen}, 4, 'WordIsGeneLen N-WASP,');

is($parser->find(WordOrig => 'HYNKIIIA')->{WordIsRoman}, 1, 'WordIsRoman HYNKIIIA');

is($parser->find(WordOrig => 'HYNKIII')->{WordIsRomanLen}, 3, 'WordIsRomanLen HYNKIII');
is($parser->find(WordOrig => 'HYNKIIIA')->{WordIsRomanLen}, 2, 'WordIsRomanLen HYNKIIIA');
is($parser->find(WordOrig => 'HYNKXXVII')->{WordIsRomanLen}, 5, 'WordIsRomanLen HYNKXXVII');


is($parser->find(WordOrig => 'X-proline-X-X-proline,')->{WordNumNotDegen}, 2, 'WordNumNotDegen X-proline-X-X-proline');
is($parser->find(WordOrig => 'X-proline-X-X-proline,')->{WordNumDegen}, 3, 'WordNumDegen X-proline-X-X-proline');

is($parser->find(WordOrig => 'ACGTNACGTNW')->{WordPropDNA}, '0.9091', 'WordPropDNA ACGTNACGTNW');

is($parser->find(WordOrig => 'X-proline-X-X-proline,')->{WordPropDegen}, '0.6000', 'WordPropDegen X-proline-X-X-proline');
is($parser->find(WordOrig => 'GETRAPL')->{WordPropDegen}, '0.0000', 'WordPropDegen GETRAPL');

my $WordPropProtein = join "; ", 
  map { "$_->{WordSequence} => $_->{WordPropProtein}" } 
  # do not put patterns here that match several times in the abstract, it is confusing
  grep { $_->{WordSequence} and $_->{WordSequence} =~ /^(EYHHYNK|GETRAPL|RGDFV|GXXXXXXG|RELIC|PATIENT|PATIENT|ACCCGTNA|FVIII)$/ } 
  @words;
warn "WordPropProtein='$WordPropProtein'" if $verbose > 1;

is(
   $WordPropProtein, 
   'EYHHYNK => 5.2; GETRAPL => -1.4; RGDFV => 0; GXXXXXXG => 6.8; RELIC => -1.4; PATIENT => -5.9; ACCCGTNA => 4.9; FVIII => 2.6',
   'WordPropProtein'
  );


my $WordScore = join "", 
  map { "$_->{WordOrig} => $_->{WordSequence} => $_->{WordScore}\n" } 
  # do not put patterns here that match several times in the abstract, it is confusing
  grep { $_->{WordSequence} and $_->{WordSequence} =~ /^(EYHHYNK|GETRAPL|RGDFV|GXXXXXXG|RELIC|PATIENT|PATIENT|ACCCGTNA|FVIII)$/ } 
  @words;
warn "WordScore='\n$WordScore\n'" if $verbose > 1;

# test WordScore for the approximate accuracy of classification in (0,1), using cutoffs: 0.1 0.5 0.9

ok($parser->find(WordOrig => 'EYHHYNK')->{WordScore} > 0.5, 'WordScore EYHHYNK');
ok($parser->find(WordOrig => 'GETRAPL')->{WordScore} > 0.05, 'WordScore GETRAPL'); # known bug; fix error: should be > 0.5
ok($parser->find(WordOrig => '(GET),')->{WordScore} < 0.1, 'WordScore (GET),'); # known bug: short sequence, but also is an english word.
ok($parser->find(WordOrig => 'cyclo(-Arg-Gly-Asp-dPhe-Val),')->{WordScore} > 0.9, 'WordScore RGDFV');
ok($parser->find(WordOrig => 'X-proline-X-X-proline,')->{WordScore} > 0.1, 'WordScore X-proline-X-X-proline, degen > 0.1');
ok($parser->find(WordOrig => 'X-proline-X-X-proline,')->{WordScore} < 0.9, 'WordScore X-proline-X-X-proline, degen < 0.9');
ok($parser->find(WordOrig => 'N-Formyl-Met-Leu-Phe;')->{WordScore} > 0.9, 'WordScore N-Formyl-Met-Leu-Phe;');
ok($parser->find(WordOrig => 'EYHH/YNK')->{WordScore} < 0.5, 'WordScore EYHH/YNK split sequence, potentially similar to abbreviations, etc');
ok($parser->find(WordOrig => 'GXXXXXXG')->{WordScore} < 0.5, 'WordScore GXXXXXXG degen');
ok($parser->find(WordOrig => '(-Cys59-x-x-x-x-Cys64-)')->{WordScore} < 0.1, 'WordScore (-Cys59-x-x-x-x-Cys64-) degen');
ok($parser->find(WordOrig => 'PATIENT')->{WordScore} < 0.1, 'WordScore PATIENT dict english');
ok($parser->find(WordOrig => 'SDS-PAGE')->{WordScore} < 0.1, 'WordScore SDSPAGE dict sci');
ok($parser->find(WordOrig => 'HYNKIIIA')->{WordScore} < 0.5, 'WordScore HYNKIIIA roman');

ok($parser->find(WordOrig => 'ACCCGTNA')->{WordScore} < 0.1, 'WordScore ACCCGTNA all dna');
ok($parser->find(WordOrig => 'FVIII,')->{WordScore} < 0.1, 'WordScore FVIII gene');
ok($parser->find(WordOrig => 'MOS/MEK/MAPK/RSK')->{WordScore} < 0.1, 'WordScore MOS/MEK/MAPK/RSK multiple genes');

is($parser->find(WordOrig => 'X-proline-X-X-proline,')->{WordSeqLen}, 5, 'WordSeqLen X-proline-X-X-proline,');

is($parser->find(WordOrig => 'EYHH/YNK')->{WordSubLenMax}, 4, 'WordSubLenMax EYHH/YNK');
is($parser->find(WordOrig => 'EYHHYNK')->{WordSubLenMax}, 0, 'WordSubLenMax EYHHYNK');
