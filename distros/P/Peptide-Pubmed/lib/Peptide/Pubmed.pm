package Peptide::Pubmed;

use vars qw($VERSION);
$VERSION = '1.02';

=head1 NAME

Peptide::Pubmed - extract peptide sequences from MEDLINE article abstracts.

=head1 SYNOPSIS

  use Peptide::Pubmed;
  $parser = Peptide::Pubmed->new;
  $in = { 
     PMID      	=> q[15527327],
     Author	=> q[Doe JJ, Smith Q],
     Journal	=> q[J Biological Foo. 2004;8(2):123-30.],
     Title	=> q[Foo, bar and its significance in phage display.],
     Abstract	=> 
      q[Peptide sequences EYHHYNK and Arg-Gly-Asp, but not ACCCGTNA or VEGFRI.],
     Mesh      	=> q[Genes, p53/genetics; Humans; Bar],
     Chemical	=> q[Multienzyme Complexes; Peptide Library; Foo],
    };
  $parser->parse_abstract($in);

  # get the peptide sequences in 1 letter symbols (select all words where the 
  # combined word/abstract score is above threshold: 
  # WordAbstScore >= WordAbstScoreMin):
  @seqs = $parser->get_seqs;
  print "@seqs\n"; # prints: 'EYHHYNK RGD'

=head1 EXAMPLES

  # same as above, set threshold explicitly:
  $parser->WordAbstScoreMin(0.4);
  @seqs = $parser->get_seqs;

  # set low threshold to get more peptide sequences (but at a cost of getting 
  # more false positives) 
  $parser->WordAbstScoreMin(-1);
  @seqs = $parser->get_seqs;
  print "@seqs\n"; # prints: 'EYHHYNK RGD ACCCGTNA VEGFRI'

  # reset threshold back:
  $parser->WordAbstScoreMin(0.4);

  # get more data for the abstract:
  $abst = $parser->get_abst;
  print "$abst->{AbstScore}\n"; # abstract score, in the [0,1] interval
  print "$abst->{AbstMtext}\n"; # abstract with sequences marked up: 
  # 'Peptide sequences <mark>EYHHYNK</mark> and <mark>Arg-Gly-Asp,</mark> 
  # but not ACCCGTNA or VEGFRI.'

  # get more data for the words, in addition to peptide sequences:
  @words = $parser->get_words;
  for my $word (@words) {
      # combined word/abstract score, in the [0,1] interval
      print "$word->{WordAbstScore}\n"; 
      # word as found in the abstract, eg 'Arg-Gly-Asp,'
      print "$word->{WordOrig}\n";
      # peptide sequence in 1 letter symbols, eg 'RGD'	
      print "$word->{WordSequence}\n";	
  }

  # There are no mandatory input fields. This will work too, but may give lower score.
  $in = { 
	 Abstract => 
          q[Peptide sequences EYHHYNK and Arg-Gly-Asp, but not ACCCGTNA or VEGFRI.],
	};
  $parser->parse_abstract($in);
  @words = $parser->get_words;

  # No peptide sequences are found in empty input:
  $in = undef;
  $parser->parse_abstract($in);
  @words = $parser->get_words;

=head1 DESCRIPTION

Provides common methods to parse peptide sequences from Pubmed
abstracts. The computed variables can be used for classification in
external programs.

For all variables below:

Varables (Abst|Word)Is*: Allowed values: 1/0.

Variables (Abst|Word)Num*: Allowed values: integer.

Variables (Abst|Word)Prop*: Allowed values: real in [0,1].

Variables (Abst|Word)Score*: Allowed values: real in [0,1]. Score near
1 corresponds to "more relevant" abstracts or words (that is, likely
to contain peptide sequences), score near 0 - to "less relevant"
abstracts or words.

Variables (Abst|Word)* (all other): Allowed values: string, unless
otherwise specified below.

=head2 Input variables

Input variables can be used optionally without the 'Abst' prefix, so
'AbstPMID' and 'PMID' are treated identically.

AbstPMID: PubMed ID.

AbstAuthor: article authors.

AbstJournal: journal citation, with year if available. For format, see
examples.

AbstTitle: article title.

AbstAbstract: abstract.

AbstMesh: Medical Subject Headings (MeSH) terms.

AbstChemical: chemical list.

=head2 Output variables, for the abstract text

AbstNumAb: number of matches to words like antibody, epitope, etc.

AbstNumAllCap: number of all capitalized words in the abstract.

AbstNumBind: number of matches to words like binds, interacts, etc.

AbstNumDigest: number of matches to words like Edman, MS/MS, trypsin,
etc.

AbstNumMHC: number of matches to words like MHC, TCR, etc.

AbstNumPeptide: number of matches to words like peptide, oligopeptide,
motif, etc.

AbstNumPhage: number of matches to words like phage, display, etc.

AbstNumProtease: number of matches to words like peptidase, cutting,
etc.

AbstNumWords: number of words. Allowed values: integer.

AbstPropAllCap: proportion of all capitalized words in the abstract (=
AbstNumAllCap / AbstNumWords).

AbstScore: heuristic score to predict whether the abstract contains a
peptide sequence, computed based on Abst* variables.

Other variables:

AbstComment: free text comment for debugging.

AbstMtext: abstract with sequences marked using '<mark>...</mark>'
tags.

=head2 Output variables, for the word

WordIsDNA: is an all DNA sequence? Example: ACCTTG.

WordIsDict: is in the dictionary (currently, of english words and of
scientific terms, software names and abbreviations)? Example:
MATERIALS, RT-PCR.

WordIsGene: is a gene name, protein name, gene symbol, protein symbol,
etc? Example: TFIIA.

WordSeqLen: peptide length, in amino acids.

WordOrig: the word as found in the abstract text.

WordPropDegen: proportion of degenerate amino acids, e.g, 0.6 for
AXXXC.

WordPropProtein: a measure which is positive if a given word
composition looks more like a protein sequence than like an english
word, and negative otherwise. Computed using frequencies of
overlapping k-mers. It is defined as follows: WordPropProtein = sum
(over all overlapping k-mers within the word) of (log10Pp -
log10Pn). log10Pp is log base 10 of the proportion of the k-mer in the
database of known protein sequences, and log10Pn - same, for
non-sequences (here, english words from pubmed abstracts not related
to peptides). For a word with all k-mers equally frequent among
sequences and non-sequences, log10Pp = log10Pn, and WordPropProtein =
0. Allowed values: real, [-Inf,+Inf]

WordScore: heuristic score to predict whether the word contains a
peptide sequence, computed based on Word* variables.

WordAbstScore: heuristic score to predict whether the word contains a
peptide sequence, computed based on both Abst* and Word* variables.

WordSequence: word converted to peptide sequence in 1-letter amino
acid symbols.

Other variables:

WordAaSymbols: amino acid code. Allowed values: 1 (1 letter), 3 (3
letter or full name). Note that separate handling of 3 letter symbols
and full names is currently not implemented.

WordIdx: word index in the abstract. Allowed values: nonnegative
integer.

=head1 NOTES

=head2 WordPropProtein

Note that to optimize classification using frequencies of k-mers, k
should be chosen so that for a given text, there are 'not too many'
empty cells, that is, 'not too many; k-mers that did not occur. For a
typical english text, with the combined text length of 100,000,
alphabet size of 26 (A-Z, case-insensitive), k=3 is a good choice,
because there are 26 ** 3 = 17576 different k-mers, and the expected
frequency of each k-mer is 5.7. Actually, the expected frequency is
somewhat less because of the effect of the word boundaries. That is,
text: 'foobletch' contains more 3-mers than 'foo bletch' because after
splitting on whitespace, 'oob', 'obl' do not occur in 'foo bletch'.

=head2 Variable and method names

By convention, method, variable and keys names like these:
VarNamesLikeThese are used for cases where the corresponding field
names may be printed in the output table, such as the rdb table in
parse_file(). For the rest of the names, var_names_like_these are
used.

=head1 KNOWN BUGS

=head2 False negatives

=head3 Peptide length cutoff

Peptide length cutoff is 20 amino acids. This is a somewhat arbitary
choice. In various sources, cutoffs between 15 and 50 amino acids are
used to define oligopeptides.

=head2 False positives

=head3 Gene symbols, english words, scientific terms and abbreviations

Some of these were misclassified as peptide sequence, even though this
code uses several dictionaries to find such non-sequence words.

=head2 Incorrectly parsed sequence

The recommendations of IUPAC can be found in: Nomenclature and
Symbolism for Amino Acids and Peptides,

http://www.chem.qmul.ac.uk/iupac/AminoAcid/A2021.html

http://www.chem.qmul.ac.uk/iupac/AminoAcid/A1416.html

They are not always followed in the published abstracts. More flexible
input rules are thus allowed for peptide sequences. However, the
following bugs may occur in parsed sequences.

=head3 Amino acid position and the number of repetitions are not
resolved

Y(n) usually means amino acid Y at position n, but sometimes also
means Y repeated n times. It is always resolved as Y, and n is
ignored. However, X(n), where X is 'X', 'Xaa', 'Xxx', etc, usually
means 'any amino acid, repeated n times. It is always resolved as X
repeated n times.

=head1 REFERENCES

=head2 ADAM

This section refers to ADAM, on which Peptide::DictionaryAbbreviations
is based. See http://arrowsmith.psych.uic.edu. I would like to thank
ADAM authors (in particular, Neil Smalheiser) for graciously providing
ADAM.

ADAM citation:

Zhou W, Torvik VI, Smalheiser NR. ADAM: Another Database of
Abbreviations in MEDLINE. Bioinformatics 2006; 22(22): 2813-2818.

 ADAM OVERVIEW                                                                 
                                                                          
     ADAM is an abbreviation database generated from the 2006             
     baseline of MEDLINE. It covers frequently used abbreviations         
     and their definitions (or long-forms), including both                
     acronyms and non-acronym abbreviations.                              
     Reference
     
     Zhou W, Torvik VI, Smalheiser NR. ADAM: Another Database 
     of Abbreviations in MEDLINE. Bioinformatics 2006; 22(22): 2813-2818.

 ADAM Copyright                                                                
                                                                          
     University of Illinois at Chicago, 2006.                             
                                                                          
 ADAM License
                                                                
     By using this software, you expressly agree that your use will be
     noncommercial, that you will not use this software to make money, and that
     you will not distribute the software to anyone else or let anyone else use
     it.  Moreover, you will give credit to the University of Illinois and Dr.
     Smalheiser as the author of the software.  The software is provided "as is"
     and without warranties of any kind, express or implied, including but not
     limited to the implied warranties of merchantability and fitness, and
     statutory warranties of noninfringement.

=head1 AUTHOR 

Timur Shtatland, tshtatland at mgh dot harvard dot edu

Copyright (C) 2007 by The General Hospital Corporation.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=head1 SEE ALSO

RDB - a fast, portable, relational database management system without
arbitrary limits, (other than memory and processor speed) that runs
under, and interacts with, the UNIX Operating system, by Walter
V. Hobbs.

=head1 APPENDIX

The rest of the documentation details the methods.

=cut

# for printing diagnostic msgs when the module is loaded. 
# use $obj->{verbose} for object related diagnostic msgs.
our $VERBOSE; 
BEGIN { 
    $VERBOSE ||= $ENV{VERBOSE} || $ENV{TEST_VERBOSE} || 0;
}

use Peptide::DictionaryAbbreviations;
use Peptide::DictionaryEnglish;
use Peptide::DictionaryFrequent;
use Peptide::DictionaryScientific;
use Peptide::Gene;
use Peptide::Sequence;
use Peptide::NonSequence;
use Data::Dumper;
use Carp;
use warnings;
use strict;

use constant LOG_10_2 => log(2) / log(10); # empirically derived weight for WordPropProtein
our $MAX_PEPTIDE_LENGTH = 20; # Somewhat arbitrary cutoff, consistent with IUPAC. Find the peptides sequences not longer than this cutoff.

# word / score assignment
#

# for WordScore()

my %Dict = map { $_ => 1 } 
  splitln(Peptide::DictionaryAbbreviations->words),
  splitln(Peptide::DictionaryEnglish->words),
  splitln(Peptide::DictionaryFrequent->words),
  splitln(Peptide::DictionaryScientific->words);
my %Gene = map { $_ => 1 } 
  splitln(Peptide::Gene->words);

# for WordPropProtein()

my %log_prop_sequence = map /(\S+)\s+(\S+)\s*\n/g, Peptide::Sequence->log_prop_kmers;
my %log_prop_nonsequence = map /(\S+)\s+(\S+)\s*\n/g, Peptide::NonSequence->log_prop_kmers;

if ($VERBOSE > 3) { 
    foreach (sort keys %log_prop_sequence) {
	print join("\t", $_, $log_prop_sequence{$_}, $log_prop_nonsequence{$_}), "\n";
    }
}

{
    my %args_default 
      = ( 
	 AbstScoreMin		=> 0.2,
	 WordScoreMin		=> 0.2,  
	 WordAbstScoreMin	=> 0.2, 
	 WordNumPrintMin   	=> -1, 
	 WordNumPrintMax   	=> -1,
	 in_col			=> [ qw(PMID Author Journal Title Abstract Mesh Chemical) ],
	 kmer_length		=> 3,
	 print_col		=> [ qw(
AbstPMID AbstAuthor AbstJournal AbstTitle AbstAbstract AbstMesh AbstChemical 

AbstNumAb AbstNumAllCap AbstNumBind AbstNumDigest AbstNumMHC AbstNumPeptide AbstNumPhage AbstNumProtease AbstNumWords AbstPropAllCap AbstScore AbstComment AbstMtext 

WordAbstScore WordIsDNA WordIsDict WordIsGene WordSeqLen WordOrig WordPropDegen WordPropProtein WordScore WordSequence WordAaSymbols WordIdx

)],
	 print_colf		=> undef,
	 verbose		=> 1,
	);

=head2 new

  Args        : %named_parameters: 

		AbstScoreMin : print abstract data if AbstScore >= this threshold.
		WordScoreMin : print word data if WordScore >=  this threshold.
		WordAbstScoreMin : print word data if WordAbstScore >= this threshold.
		Allowed values: real in [0,1] interval, or -1.
		Set to -1 to undefine these, and print all that satisfy 
		*PrintMin*, *PrintMax* thresholds. 

		WordNumPrintMin : min number of words to print per abstract.
		Allowed values: 1 and -1
		WordNumPrintMax : max number of words to print per abstract.
		Allowed values: non-negative integer, or -1.
		Set to -1 to undefine these, and print all that satisfy 
		*ScoreMin* thresholds. 

		If WordNumPrintMin = 1, at least one line is printed
		per each abstract for which AbstScore satisfies
		AbstScoreMin threshold. That is, 1 line is printed
		even if no sequences were found (many Word* vars will
		be empty or 0 when this happens) or if no sequences
		satisfy WordScore / WordScoreMin threshold. If there
		are sequences found, at least 1 line is printed (which
		may or may not satisfy WordScore / WordScoreMin
		threshold), and the rest are printed only if they
		satisfy it. If WordNumPrintMax = N, where N is a
		positive integer, only the first N words are printed
		(_not_ the best N words by score). A special case is
		(WordNumPrintMin => 1, WordNumPrintMax => 1), which
		prints exactly 1 line per abstract. Word* vars are not
		computed, which make the code much faster. An even
		more special case is (AbstScoreMin => -1, WordScoreMin
		=> -1, WordAbstScoreMin => -1, WordNumPrintMin => 1,
		WordNumPrintMax => 1), which prints all abstracts, 1
		abstract per line, and computes Abst*, but not Word*
		vars, thus allowing to separate computation into 2
		steps: compute and select abstracts with good
		AbstScore, then compute and select abstracts and words
		with good WordAbstScore, WordScore.

		in_col : columns for input
		kmer_length : for computing WordPropProtein:	=> 3,
	 
		print_col : columns for printing
		print_colf : column formats for rdb table, eg [qw(50S 10N)]; 
		default: undef, to be determined automatically from col names.
		verbose : verbosity level for diagnostic msgs. Allowed values: 0..4.
  Example     : my $parser = Peptide::Pubmed->new(verbose => $verbose) or 
			carp "not ok: new Peptide::Pubmed" and return;
  Description : bare constructor. All work done by init().
  Returns     : TRUE if successful, FALSE otherwise.

=cut

    sub new {
	my $class = shift;
	my %args = @_;
	foreach (sort keys %args) {
	    exists $args_default{$_} or carp "not ok: arg=$_ is not allowed in new()" and 
	      return;
	}
	my $self = bless { %args_default, %args  }, ref($class) || $class;
	$self->init or return;
	return $self;
    }
}

=head2 get_abst

  Args        : none
  Example     : $abst = $parser->get_abst;
  Description : get the output data for Abst* variables.
  Returns     : a ref to hash with Abst* variables if successful, 
		ref to empty hash otherwise.

=cut

sub get_abst {
    my ($self) = @_;
    my $abst = {};
    foreach my $key (grep /^Abst/, @{ $self->{abst_col} } ) {
	$abst->{$key} = $self->{abst}{$key} if exists $self->{abst}{$key};
    }
    return $abst;
}

=head2 get_words

  Args        : none
  Example     : # get data for words likely to contain peptide sequences:
		@words = $parser->get_words;
  Description : get the output data for Words* variables.
  Returns     : an array where each element is a ref to hash with
		Word* variables output data for 1 word. Only words
		that satisfy the threshold: combined word/abstract score 
		WordAbstScore greater than or equal to WordAbstScoreMin, 
		are included, otherwise an empty array is returned. 
		To return all words, set WordAbstScoreMin to -1.

=cut

sub get_words {
    my ($self) = @_;
    my @words = ();
    foreach my $rh_word ( @{ $self->{words} } ) {
	next unless $rh_word->{WordAbstScore} >= $self->{WordAbstScoreMin};
	my $rh_word_out = {};
	foreach my $key (grep /^Word/, @{ $self->{words_col} } ) {
	    $rh_word_out->{$key} = $rh_word->{$key} if exists $rh_word->{$key};
	}
	push @words, $rh_word_out;
    }
    return @words;
}


=head2 get_seqs

  Args        : none
  Example     : @seqs = $parser->get_seqs;
  Description : 
  Returns     : a list with sequences for all words in the abstract, 
		empty list if none found.

=cut

sub get_seqs {
    my ($self) = @_;
    my @seqs = ();
    foreach my $rh_word ( @{ $self->{words} } ) {
	next unless $rh_word->{WordAbstScore} >= $self->{WordAbstScoreMin};
	push @seqs, $rh_word->{WordSequence} if $rh_word->{WordSequence};
    }
    return @seqs;
}


=head2 WordAbstScoreMin

  Args        : (optional) new value
  Example     : $parser->WordAbstScoreMin(0.4);
		$parser->WordAbstScoreMin;
  Description : assign to WordAbstScoreMin a new value, if called with an argument.
  Returns     : WordAbstScoreMin value (after assignment)

=cut

sub WordAbstScoreMin {
    my ($self, $val) = @_;
    if (@_ == 2) {
	$self->{WordAbstScoreMin} = $val;
    }
    return $self->{WordAbstScoreMin};
}

=head2 init

  Args        : none
  Example     : $parser->init or return;
  Description : check to see if the entry is ok. Initialize several fields used for 
		printing, such as column definitions.
  Returns     : always TRUE

=cut

sub init {
    my ($self) = @_;
    unless (defined $self->{print_colf}) {
	# assign to numeric or text
	$self->{print_colf} = [ 
			       map { 
				   /^(Abst|Word|AbstWord)(Idx|Is|Num|Prop|Score)([A-Z]|$)/ ? 
				     "10N" : "50S" 
				 } 
			       @{ $self->{print_col} } 
			      ]
    }
    # cols to be printed are either words cols, or abstract cols
    $self->{abst_col} = [ grep { /^Abst/ } @{ $self->{print_col} } ];
    $self->{words_col} = [ grep { /^Word/ } @{ $self->{print_col} } ];
    if ($self->{verbose} > 2) {
	foreach (sort keys %{ $self }) {
	    warn "$_ => $self->{$_}";
	}
    }
    return 1;
}

=head2 splitln

  Arg[1]      : string of items, one item per line.
  Arg[2]      : (optional) %named_parameters:
		lc : convert to lowercase? 1 = yes, 0 = no. Default = 1.
  Example     : my %words = map { $_ => 1 } splitln("foo\nbar\n", lc => 0);
		my %words = map { $_ => 1 } $this->splitln("foo\nbar\n");
  Description : parse input string into list of items, remove leading and trailing 
		whitespace, remove empty lines, convert to lc. Can be used as a 
		method call or direct call.
  Returns     : list of items

=cut
    
sub splitln {
    ref $_[0] and shift;
    my $str = shift;
    my %args = (lc => 1, @_);
    my @lines = 
      grep { $_ ne '' }
	map { s/^\s+|\s+$//g; $args{lc} ? lc $_ : $_ } 
	  split /\n/, $str;
    return @lines;
}

=head2 parse_file

  Args        : %named_parameters:
		mandatory:
		in_fname : input file name.
		out_fname : output file name.
  Example     : $parser->parse_file(in_fname => $in_fname, out_fname => $out_fname);
  Description : reads input and write output, both in rdb
		format. Input data is 1 abstract per line. Prints data
		for all sequences found, 1 sequence per line. Skips
		abstracts and words based on rules described in
		new(). Because it prints data for 1 word per line, the
		same abstract data is printed for all sequences from
		the same abstract.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

sub parse_file {
    my ($self, %args) = @_;
    foreach (qw(in_fname out_fname)) {
	$self->{$_} = $args{$_};
    }
    my $in_fh;
    my $out_fh;
    open $in_fh, $self->{in_fname} or carp "not ok: open $self->{in_fname}: $!" and return;
    open $out_fh, ">$self->{out_fname}" or 
      carp "not ok: open $self->{out_fname}: $!" and return;
    my ($comment, $ra_col, $ra_colf) = read_rdb_header($in_fh);
    print_rdb_header($out_fh, $comment, $self->{print_col}, $self->{print_colf});
    while (<$in_fh>) { # for 1 pubmed entry (=abstract)
	chomp;
	print STDERR "processing line $.\n" if ($self->{verbose} > 1 and not $. % 500);
	my $rh_pm_in = {}; # input data for 1 abstract
	@{$rh_pm_in}{ @$ra_col } = split "\t", $_;
	my $rh_pm_out = $self->parse_abstract($rh_pm_in) or 
	  carp "not ok: parse_abstract" and return;
	next unless $rh_pm_out->{abst}{AbstScore} >= $self->{AbstScoreMin};
	my %seen;
	my $num_words = 0;
	foreach my $rh_word (@{ $rh_pm_out->{words} }) {
	    $num_words++;
	    last if $self->{WordNumPrintMax} != -1 and $num_words > $self->{WordNumPrintMax};
	    if ($self->{WordNumPrintMin} == -1 || 
		($self->{WordNumPrintMin} == 1 && $num_words > $self->{WordNumPrintMin}) ) {
		next unless $rh_word->{WordScore} >= $self->{WordScoreMin} && 
		  $rh_word->{WordAbstScore} >= $self->{WordAbstScoreMin};
		next if defined $rh_word->{WordSequence} and 
		  $seen{ $rh_word->{WordSequence} }++;	    
	    }
	    my %line = map { tr/\t/ /; $_ } # tab is used as the delimiter
	      ( 
	       map( { $_ => defined $rh_word->{$_} ? $rh_word->{$_} : '' } 
		   @{ $self->{words_col} }), 
	       map( { $_ => defined $rh_pm_out->{abst}{$_} ? $rh_pm_out->{abst}{$_} : '' } 
		   @{ $self->{abst_col} }),
	      );
	    print $out_fh join("\t", @line{ @{ $self->{print_col} } }), "\n";
	}
    }
    close $out_fh or carp "not ok: close $self->{out_fname}: $!" and return;
    close $in_fh or carp "not ok: close $self->{in_fname}: $!" and return;
    return 1;
}

=head2 read_rdb_header

  Args        : input rdb file handle
  Example     : my ($comment, $ra_col, $ra_colf) = read_rdb_header($in_fh);
  Description : Reads header of an rdb table. 
  Returns     : Returns comment (or empty string), ref to array of column names, 
		reference to array of column definitions.

=cut

sub read_rdb_header {
    my ($in_fh) = @_;
    my ($comment, $ra_col, $ra_colf);
    while (<$in_fh>) {
	$comment .= $_ and next if /^\#/;	# table comments (optional)
	chomp;
	@$ra_col = split /\t/;			# column names (eg, Hit, Expect)
	last unless defined ($_ = <$in_fh> );
	chomp;
	@$ra_colf = split /\t/;			# column formats (eg, 10N, 50S)
	last;
    }
    return $comment || '', $ra_col, $ra_colf;
}

=head2 print_rdb_header

  Args        : output rdb file handle, comment (or undef), ref to array of 
		column names, reference to array of column definitions.
  Example     : print_rdb_header($out_fh, $comment, $self->{print_col}, 
		$self->{print_colf});
  Description : Prints header of an rdb table. If comment is undefined, 
		it is not printed.
  Returns     : always TRUE.

=cut

sub print_rdb_header {
    my ($out_fh, $comment, $ra_col, $ra_colf) = @_;
    print $out_fh $comment if defined $comment;
    print $out_fh join( "\t", @$ra_col  ), "\n";
    print $out_fh join( "\t", @$ra_colf ), "\n" if defined $ra_colf;
    return 1;
}

=head2 parse_abstract

  Args        : ref to hash with input data for one pubmed abstract
  Example     : $parser->parse_abstract($rh_pm_in);
  Description : does all parsing for 1 abstract by calling init_abstract, AbstVars.
  Returns     : ref to hash with parsed data if successful, FALSE if error. 
		If no sequences are found, the hash will have a single sequence 
		consisting of an empty string (this is not considered an error).

=cut

sub parse_abstract { 
    my ($self, $rh_pm_in) = @_;
    my $rh_pm_out = {};
    $self->init_abstract($rh_pm_in) or return;
    $self->AbstVars or return;
    %$rh_pm_out = map { $_ => $self->{$_} } qw(words abst);
    carp((caller(0))[3], "(@_)", ' ', Data::Dumper->Dump([$self], ['self'])) 
      if $self->{verbose} > 2;
    return $rh_pm_out; 
}

{
    my %abst_default = 
      (
       AbstComment	=> undef,
       AbstMtext	=> undef,
       AbstNumAb	=> 0,
       AbstNumAllCap	=> 0,
       AbstNumBind	=> 0,
       AbstNumDigest	=> 0,
       AbstNumMHC	=> 0,
       AbstNumPeptide	=> 0,
       AbstNumPhage	=> 0,
       AbstNumProtease	=> 0,
       AbstNumWords	=> 0,
       AbstPropAllCap	=> 0,
       AbstScore	=> 0,
      );

=head2 init_abstract

  Args        : ref to hash with input data with field names 'Title', 'Abstract', etc 
		(optionally, with prefix 'Abst', eg 'AbstTitle', 'AbstAbstract'). 
		See field names listed in in_col.
  Example     : $rh_pm_in = { Title => q[Some title.], Abstract	=> q[Some abstract.] };
		$self->init_abstract($rh_pm_in) or return;
  Description : Reads the input data and stores in 'Abst*' fields
		('Abst' prefix is added if needed). Adds prefix 'Abst'
		to field names if needed. Converts to lower case and
		stores text in AbstLc* fields. Undefined fields in the
		input are converted to empty strings and
		stored. Currently, there are no mandatory fields:
		undefined $rh_pm_in is not considered an error. In
		such case, all fields will be empty strings. No
		sequences will be found, and the default score (zero)
		will be assigned.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

    sub init_abstract {
	my ($self, $rh_pm_in) = @_;
	# reset abst and words data from the prev parsed abstract, if any
	$self->{abst} = { %abst_default };
	$self->{words} = []; 
	my @in_col = @{ $self->{in_col} };
	foreach (@{ $self->{in_col} }) {
	    $self->{abst}{"Abst$_"} = do {
		if (defined $rh_pm_in->{$_}) {
		    $rh_pm_in->{$_}
		} elsif (defined $rh_pm_in->{"Abst$_"}) {
		    $rh_pm_in->{"Abst$_"}
		} else {
		    ''
		}
	    };
	}
	# mandatory field:
	#my @missing = grep { $self->{abst}{$_} eq '' } qw(AbstAbstract);
	#@missing and carp "not ok: missing fields: @missing" and return;
	$self->{abst}{AbstAllText} = 
	  join(";; ", 
	       map "$_: $self->{abst}{$_}", 
	       qw(AbstTitle AbstAbstract AbstMesh AbstChemical)
	      ) || '';
	$self->{abst}{AbstLcAllText} = lc $self->{abst}{AbstAllText};
	$self->{abst}{AbstLcAbstract} = lc $self->{abst}{AbstAbstract};
	return 1;
    }
}

=head2 AbstVars 

  Args        : none
  Example     : $parser->AbstVars or return;
  Description : Calls all Abst* methods that compute the corresponding variables, 
		eg AbstNumAb. Calls Words which in turn calls Word* methods.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

sub AbstVars {
    my ($self) = @_;
    $self->AbstNumAb or return;
    # AbstNumAllCap is computed in AbstScore()
    $self->AbstNumBind or return;
    $self->AbstNumDigest or return;
    $self->AbstNumMHC or return;
    $self->AbstNumPeptide or return;
    $self->AbstNumPhage or return;
    $self->AbstNumProtease or return;
    $self->AbstScore or return;
    $self->Words or return;
    $self->WordAbstScore or return;
    $self->AbstMtext or return;
    foreach (qw(AbstMaxWordScore AbstPropAllCap AbstScore)) {
	$self->{abst}{$_} = formatScoreProp( $self->{abst}{$_} );
    }
    foreach my $rh_word ( @{ $self->{words} }) {
	foreach (qw(WordScore WordAbstScore WordPropDNA WordPropDegen)) {
	    $rh_word->{$_} = formatScoreProp( $rh_word->{$_} );
	}
    }
    if ($self->{verbose} > 0) {
	$self->{abst}{AbstComment} .= join '; ', map { 
	    defined $self->{abst}{"ra_$_"} && 
	      ref $self->{abst}{"ra_$_"} eq 'ARRAY' ? 
		"$_='" . join(", ", @{ $self->{abst}{"ra_$_"} }) . "'" : "$_=''" 
	    } 
	  qw(
	     AbstNumAb AbstNumBind AbstNumDigest AbstNumMHC AbstNumPeptide 
	     AbstNumPhage AbstNumProtease 
	    );
    }
    return 1;
}

=head2 AbstNum*

All AbstNum* methods use the same general scheme, unless specified otherwise. Each method refers to a specific class of patterns, eg AbstNumAb() refers to antibody related patterns. Each method looks searches the AbstLcAllText field (concatenated abstract, mesh terms, chemical terms) for matches to the class of patterns. The matches are stored in an array ref (eg $self->{abst}{ra_AbstNumAb}). The number of matches is stored in a scalar ref (eg, $self->{abst}{AbstNumAb}).

Pattern matching is done in several steps: patterns that can match anywhere in the word, and patterns that must match the entire word (typically shorter patterns, like 'mab' or 'fab'). Often, there are additional steps. Step 1 pattern matches are mandatory - if there are no matches at step 1, then step 2 is skipped. If step 1 succeeds, then step 2 (optional) pattern matches are done. For example, for AbstNumPeptide(), step 1 patterns include 'peptid', step 2 - 'synthe'. This is because 'synthe' by itself often refers to non-peptides, but together with 'peptid' matches often refers to peptides.

=cut

=head2 AbstNumAb

  Args        : none
  Example     : $parser->AbstNumAb or return;
  Description : See package DESCRIPTION above.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

sub AbstNumAb {
    my ($self) = @_;
    return unless defined $self->{abst}{AbstLcAllText};
    (my $var = (caller(0))[3]) =~ s/.*:://;
    my @matches;
    for ($self->{abst}{AbstLcAllText}) {
	push @matches,
	  m[
	    adjuvant|
	    antibod|
	    antigen|
	    antiser|
	    epitope|
	    freund|
	    heavy\ chain|
	    immun|
	    light\ chain|
	    mimotope|
	    monoclonal|
	    phagotope|
	    polyclonal|
	    recombinant\ fab|
	    vaccin|
	    variable\ region|
	    variable\ regions
	   ]gx,
	     m[
	       \b(
	       mab|
	       mabs|
	       rfab|
	       sera|
	       serum
	      )\b
	      ]gx;
	$self->{abst}{$var} = @matches;
	$self->{abst}{"ra_$var"} = [ @matches ];
    }
    return 1;
}

=head2 AbstNumBind

  Args        : none
  Example     : $parser->AbstNumBind or return;
  Description : See package DESCRIPTION above.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

sub AbstNumBind {
    my ($self) = @_;
    return unless defined $self->{abst}{AbstLcAllText};
    (my $var = (caller(0))[3]) =~ s/.*:://;
    my @matches;
    for ($self->{abst}{AbstLcAllText}) {
	push @matches,
	  m[
	    abolish|
	    activate|
	    adher|
	    adhes|
	    affinit|
	    agonise|
	    agonist|
	    agonize|
	    associat|
	    bind|
	    block|
	    bound|
	    compet|
	    disrupt|
	    dissociat|
	    inhibit|
	    interact|
	    interfere|
	    ligand|
	    prevent|
	    recogn|
	    regulat|
	    suppress
	   ]gx,
	     m[
	       \b(
	       ec50|
	       ic50|
	       kd|
	       ki
	      )\b
	      ]gx;
	$self->{abst}{$var} = @matches;
	$self->{abst}{"ra_$var"} = [ @matches ];
    }
    return 1;
}

{
    # older papers are more likely to have data on protein digestion 
    # into peptides which are relevant only to the protein, 
    # rather than to the peptides.
    # for these time intervals, multiply by this factor
    my %AbstNumDigestScoreForYear;
    for (1900..2100) {
	if ($_ > 1993) {
	    $AbstNumDigestScoreForYear{$_} = 1;
	} elsif ($_ > 1991) {
	    $AbstNumDigestScoreForYear{$_} = 1.5;
	} elsif ($_ > 1990) {
	    $AbstNumDigestScoreForYear{$_} = 2;
	} elsif ($_ > 1989) {
	    $AbstNumDigestScoreForYear{$_} = 3;
	} else { # <= 1989
	    $AbstNumDigestScoreForYear{$_} = 4;
	} ## stopped here 
    }

=head2 AbstNumDigest

  Args        : none
  Example     : $parser->AbstNumDigest or return;
  Description : See package DESCRIPTION above.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

    sub AbstNumDigest {
	my ($self) = @_;
	return unless defined $self->{abst}{AbstLcAllText};
	(my $var = (caller(0))[3]) =~ s/.*:://;
	my @matches;
	for ($self->{abst}{AbstLcAllText}) {
	    # do not shorten to 'trypt' to avoid confusion with tryptophan
	    push @matches,
	      m[
		borohydride|
		complete\ amino\ acid\ sequence|
		chromatogra|
		cnbr|
		cyanogen\ bromide|
		dansyl|
		digest|
		edman|
		hplc|
		lsims|
		maldi-tof|
		mass\ spec|
		matrix-assisted\ laser\ desorption|
		nabh4|
		peptide\ map|
		protease\ digestion|
		proteolytic\ digestion|
		rplc|
		spectrometry,\ mass|
		spectrum analysis,\ mass|
		thermolysin|
		thermolytic|
		tryptic|
		trypsin|
		v-8\ prote|
		v8\ prote
	       ]gx,
		 m[
		   \b(
		   ms
		  )\b
		  ]gx;
	    $self->{abst}{$var} = @matches;
	    $self->{abst}{"ra_$var"} = [ @matches ];
	    for ($self->{abst}{AbstJournal}) {    
		$self->{abst}{$var} *= $AbstNumDigestScoreForYear{$1} if 
		  defined $_ and /\b((19|20)\d\d)\b/ and $AbstNumDigestScoreForYear{$1};
	    }
	    $self->{abst}{$var} = sprintf "%.0f", $self->{abst}{$var};
	}
	return 1;
    }
}

=head2 AbstNumMHC

  Args        : none
  Example     : $parser->AbstNumMHC or return;
  Description : See package DESCRIPTION above.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

sub AbstNumMHC {
    my ($self) = @_;
    return unless defined $self->{abst}{AbstLcAllText};
    (my $var = (caller(0))[3]) =~ s/.*:://;
    my @matches;
    for ($self->{abst}{AbstLcAllText}) {
	push @matches,
	  m[
	    alloge|
	    allograft|
	    antibod|
	    antigen|
	    b\ cell|
	    dendri|
	    epitope|
	    histocompatibility|
	    immun|
	    present|
	    restrict|
	    tolero|
	    t\ cell
	   ]gx,
	     m[
	       \b(
	       cd\d{1,2}|
	       class\ i{1,2}|
	       hla|
	       mhc|
	       self|
	       tcr
	      )\b
	      ]gx;
	$self->{abst}{$var} = @matches;
	$self->{abst}{"ra_$var"} = [ @matches ];
    }
    return 1;
}

=head2 AbstNumPeptide

  Args        : none
  Example     : $parser->AbstNumPeptide or return;
  Description : See package DESCRIPTION above.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

sub AbstNumPeptide {
    my ($self) = @_;
    return unless defined $self->{abst}{AbstLcAllText};
    (my $var = (caller(0))[3]) =~ s/.*:://;
    my @matches;
    my @matches_neg;
    ##cc TODO: possibly add matches to /protein/ and /fragment/ in the same sentence.
    for ($self->{abst}{AbstLcAllText}) {
	# step 1, mandatory matches
	push @matches,
	  m[
	    benzyloxycarbonyl|
	    hormone|
	    peptid
	   ]gx;
	next unless @matches;
	push @matches_neg,
	  m[
	    peptidase|
	    polypeptide
	   ]gx;
	next unless (scalar(@matches) - scalar(@matches_neg)) > 0;
	# step 2, optional matches
	push @matches,
	  m[
	    consensus|
	    constrain|
	    \bcyclic|
	    librar|
	    linear|
	    motif|
	    sequenc|
	    synthe
	   ]gx,
	     m[
	       \b(
	       ac|
	       acetyl|
	       amide|
	       boc|
	       ch2nh|
	       conh|
	       cyclo|
	       dansyl|
	       h2n|
	       nh|
	       nh2|
	       ome|
	       tos
	      )\b
	      ]gx;
	$self->{abst}{$var} = scalar(@matches) - scalar(@matches_neg);
	$self->{abst}{"ra_$var"} = [ @matches ];
    }
    return 1;
}

=head2 AbstNumPhage

  Args        : none
  Example     : $parser->AbstNumPhage or return;
  Description : See package DESCRIPTION above.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

sub AbstNumPhage {
    my ($self) = @_;
    return unless defined $self->{abst}{AbstLcAllText};
    (my $var = (caller(0))[3]) =~ s/.*:://;
    my @matches;
    my @matches_neg;
    for ($self->{abst}{AbstLcAllText}) {
	# step 1, mandatory matches
	push @matches,
	  m[
	    bio-pan|
	    biopan|
	    phagemid|
	    phage\b|
	    phages\b	    
	   ]gx,
	     m[
	       \b(
	       panned|		# match panning related, but not spanning, pan-caspase, etc
	       panning| 
	       pannings| 
	       pans
	      )\b
	      ]gx;
	next unless @matches;
	push @matches_neg,
	  m[
	    macrophage
	   ]gx;
	next unless (scalar(@matches) - scalar(@matches_neg)) > 0;
	# step 2, optional matches
	push @matches,
	  m[
	    clone|   
	    cloni|	    
	    display|
	    librar|
	    screen|
	    select	    
	   ]gx,
	     m[
	       \b(
	       round|
	       rounds
	      )\b
	      ]gx;
	$self->{abst}{$var} = scalar(@matches) - scalar(@matches_neg);
	$self->{abst}{"ra_$var"} = [ @matches ];

    }
    return 1;
}

=head2 AbstNumProtease

  Args        : none
  Example     : $parser->AbstNumProtease or return;
  Description : See package DESCRIPTION above.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

sub AbstNumProtease {
    my ($self) = @_;
    return unless defined $self->{abst}{AbstLcAllText};
    (my $var = (caller(0))[3]) =~ s/.*:://;
    my @matches;
    for ($self->{abst}{AbstLcAllText}) {
	push @matches,
	  m[
	    aminobenzoyl|
	    caspase|
	    cathepsin|
	    convertase|
	    dinitrophenyl|
	    nitroanilide|
	    peptidase|
	    protease|
	    proteasom|
	    proteinase|
	    proteol
	   ]gx;
	next unless @matches;
	# match: MMP, MMPs MMP1, MMP-1, but not MMPFOO
	# match: Dnp-Met
	push @matches,
	  m[
	    (?:\b|[^a-z])(
	    abz|
	    amc
	    dnp|
	    dpa|
	    eddnp|
	    fmk|
	    mca|
	    mmp|
	    mmps
	   )(?:\b|[^a-z]) 
	   ]gx;
	$self->{abst}{$var} = @matches;
	$self->{abst}{"ra_$var"} = [ @matches ];
    }
    return 1;
}

=head2 AbstScore 

  Args        : none
  Example     : $parser->AbstScore or return;
  Description : Computes AbstScore based on the results of Abst* vars in the abstract.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

sub AbstScore {
    my ($self) = @_;
    my $rh_abst = $self->{abst};
    # Split with saving the original whitespace, which is then added back 
    # during join after marking up is done, in AbstMtext(). 
    # This preserves the original character positions.
    @{ $rh_abst->{ra_WordOrig} } = split /(\s+)/, $rh_abst->{AbstAbstract};
    
    $rh_abst->{AbstNumWords} = grep /\S/, @{ $rh_abst->{ra_WordOrig} };
    $rh_abst->{AbstNumAllCap} = @{[grep { /[A-Z]/ and not /[a-z]/ } 
				     @{ $rh_abst->{ra_WordOrig} } ]};
    # initialize:
    $rh_abst->{AbstScore} = 0;
    # linear terms:
    $rh_abst->{AbstScore} += 
      (-1) * $rh_abst->{AbstNumDigest} + $rh_abst->{AbstNumPeptide} + $rh_abst->{AbstNumPhage};
    warn "\$rh_abst->{AbstScore}=$rh_abst->{AbstScore}" if $self->{verbose} > 2;

    # interaction terms (score increases more if both vars increase simultaneously)
    $rh_abst->{AbstScore} += 
      $rh_abst->{AbstNumBind} * 
	($rh_abst->{AbstNumPeptide} + $rh_abst->{AbstNumPhage}) + 
	  $rh_abst->{AbstNumProtease} * 
	    ($rh_abst->{AbstNumPeptide} + $rh_abst->{AbstNumPhage}) + 
	      $rh_abst->{AbstNumPeptide} * $rh_abst->{AbstNumPhage};
    warn "\$rh_abst->{AbstScore}=$rh_abst->{AbstScore}" if $self->{verbose} > 2;

    # abstracts with too many all cap words are more likely to have all cap 
    # non-sequence words rather than true sequences.
    $rh_abst->{AbstPropAllCap} = $rh_abst->{AbstNumAllCap} / ($rh_abst->{AbstNumWords} || 1);
    if ($rh_abst->{AbstPropAllCap} > 0.3 || $rh_abst->{AbstNumAllCap} > 30) { 
	$rh_abst->{AbstScore} *= 0.01; # strong penalty if above threshold
    } else {
	$rh_abst->{AbstScore} *= (1 - $rh_abst->{AbstPropAllCap});
    }
    warn "\$rh_abst->{AbstScore}=$rh_abst->{AbstScore}" if $self->{verbose} > 2;
    # AbstScore < 0 can happen for hi AbstNumDigest:
    $rh_abst->{AbstScore} = 0 if $rh_abst->{AbstScore} < 0; 
    # transform (0, +inf) to (0,1):
    $rh_abst->{AbstScore} = $rh_abst->{AbstScore} / (1 + $rh_abst->{AbstScore});
    warn "\$rh_abst->{AbstScore}=$rh_abst->{AbstScore}" if $self->{verbose} > 2;
    carp((caller(0))[3], "(@_)", ' ', Data::Dumper->Dump([$self], ['self'])) 
      if $self->{verbose} > 2;
    return 1;
}

{
 
    my %word_default = 
      (
       WordAbstScore	=> 0,
       WordAaSymbols	=> 0,
       WordIsDNA	=> 0,
       WordIsDNALen	=> 0,
       WordIsDict	=> 0, 
       WordIsGene	=> 0,
       WordIsRomanLen	=> 0,
       WordNumDegen	=> 0,
       WordOrig		=> undef,
       WordPropDNA	=> 0,
       WordPropDegen	=> 0,
       WordPropProtein	=> 0,
       WordSeqLen	=> 0,
       WordScore	=> 0,
       WordSequence	=> undef,
       WordSubLenMax	=> 0,
       ##cc provide defaults for all , to be used for 3 letter and full names of aa.
      );

=head2 Words
      
  Args        : none
  Example     : $parser->Words or return;
  Description : Parses all peptide sequences from abstract text in AbstAbstract. 
		Calls the necessary methods, and stores results in array ref 
		$parser->{words}.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

    sub Words {
	my ($self) = @_;
	my @words; # each el is a ref to hash with data 
	if ($self->{WordNumPrintMin} == 1 and $self->{WordNumPrintMax} == 1) { 
	    # need exactly 1 empty word
	    $self->{words} = [ { %word_default } ];
	    return 1;
	}
	my $idx = 0;
	my @WordOrig = @{ $self->{abst}{ra_WordOrig} };
	foreach (@WordOrig) {
	    my $rh_word = { %word_default };
	    $rh_word->{WordOrig}	= $_;
	    $rh_word->{WordLcOrig}	= lc $_;
	    $rh_word->{WordIdx} = $idx++;
	    if (not /\S/) {
		# do nothing
	    }
	    elsif ( $_ = $self->aa3_to_aa1( $rh_word->{WordOrig} ) ) {
		$rh_word->{WordAaSymbols} = 3; # 3 letter aa symbols (and full names, too)
		$rh_word->{WordSequence} = $_;
		$self->WordVars($rh_word) or return;
	    }
	    elsif ( $_ = $self->to_aa1( $rh_word->{WordOrig} ) ) {
		$rh_word->{WordAaSymbols} = 1; # 1 letter aa symbols:
		$rh_word->{WordSequence} = $_;
		$self->WordVars($rh_word) or return;
	    }
	    # else: has non-whitespace chars, but is not a sequence: do nothing
	    $self->WordScore($rh_word) or return;
	    push @words, $rh_word;
	}
	if ($self->{WordNumPrintMin} == 1 and not @words) { # need at least 1 word
	    push @words, { %word_default };
	}
	$self->{words} = [ @words ];
	return 1;
    }
}

{
    # See more: Nomenclature and Symbolism for Amino Acids and Peptides
    # http://www.chem.qmul.ac.uk/iupac/AminoAcid/A2021.html
    # Amino acids below are converted to X for blasting, no need to worry here.

    # keep order for correct substitution below. Generally, longer patterns go first, so that less non-replaced chars remain, so that there is less to clean up later.
    my @aa3_to_aa1 = 
      ( 
       # full names:
       # Omitted: B, U, Z
       alanine		=> 'A',
       cysteine 	=> 'C',
       cystein		=> 'C', # alternative spelling
       aspartic 	=> 'D',
       aspartate 	=> 'D',
       glutamic 	=> 'E',
       glutamate 	=> 'E',
       phenylalanine 	=> 'F',
       glycine		=> 'G',
       histidine 	=> 'H',
       isoleucine 	=> 'I',
       lysine		=> 'K',
       leucine		=> 'L',
       methionine 	=> 'M',
       asparagine 	=> 'N',
       proline		=> 'P',
       glutamine 	=> 'Q',
       arginine 	=> 'R',
       serine		=> 'S',
       threonine 	=> 'T',
       selenocysteine	=> 'U', 
       valine		=> 'V',
       tryptophane 	=> 'W', # alternative spelling
       tryptophan 	=> 'W',
       tyrosine 	=> 'Y',

       # full names, 'yl' endings:
       # matches:
       # glycyl-L-prolyl-L-glutamic acid;
       # arginyl glycyl aspartyl serine
       alanyl		=> 'A',
       cysteinyl       	=> 'C',
       aspartyl 	=> 'D',
       glutamyl 	=> 'E',
       phenylalanyl 	=> 'F',
       glycyl		=> 'G',
       histidyl 	=> 'H',
       isoleucyl 	=> 'I',
       lysyl		=> 'K',
       leucyl		=> 'L',
       methionyl 	=> 'M',
       asparaginyl 	=> 'N',
       prolyl		=> 'P',
       glutaminyl 	=> 'Q',
       arginyl	 	=> 'R',
       seryl		=> 'S',
       threonyl 	=> 'T',
       selenocysteinyl	=> 'U',
       valyl		=> 'V',
       tryptophyl 	=> 'W',
       tyrosyl	 	=> 'Y',

       # 3 letter aa symbols to 1 letter.
       Ala => 'A',
       Cys => 'C',
       Asp => 'D',
       Glu => 'E',
       Phe => 'F',
       Gly => 'G',
       His => 'H',
       Ile => 'I',
       Lys => 'K',
       Leu => 'L',
       Met => 'M',
       Asn => 'N',
       Pro => 'P',
       Gln => 'Q',
       Arg => 'R',
       Ser => 'S',
       Thr => 'T',
       Sec => 'U',
       Val => 'V',
       Trp => 'W',       
       Tyr => 'Y',

       # non-standard amino acids are all converted to X
       Aad => 'X',
       Abu => 'X',
       Aib => 'X',
       Ahx => 'X',
       Ape => 'X',
       Apm => 'X',
       Asx => 'X', # B in http://www.chem.qmul.ac.uk/iupac/AminoAcid/A2021.html
       Cit => 'X',
       Dab => 'X',
       Dap => 'X',
       Dpm => 'X',
       Dpr => 'X',
       Glx => 'X', # Z in http://www.chem.qmul.ac.uk/iupac/AminoAcid/A2021.html
       Hyl => 'X',
       Hyp => 'X',
       Nle => 'X',
       Nva => 'X',
       Orn => 'X',
       Pyr => 'X',

       # unknown amino acids
       Xaa => 'X', # keep order as shown, so that these replacements are correct: 'Asn-x-Glu-x-x-(aromatic)-x-x-Gly', 
       # unknown amino acids, not in IUPAC, but frequently used:
       Xxx => 'X', # such as Gly-Xxx-Gly, but some XXX or xxx may refer to X{3}, eg Gly-xxx-Gly
       Yaa => 'X',
       Zaa => 'X',

      );

    my %aa3_to_aa1 = @aa3_to_aa1;
    my @aa3_to_aa1_keys = grep exists $aa3_to_aa1{$_}, @aa3_to_aa1;
    # print to redo sort:
#     for (sort { $aa3_to_aa1{$a} cmp $aa3_to_aa1{$b} } keys %aa3_to_aa1) { 
# 	next unless length $_ == 3; 
# 	print "$_ => '$aa3_to_aa1{$_}',\n";
#     }
    my $aa3_to_aa1 = join "|", @aa3_to_aa1_keys;
    my $aa3_to_aa1_re = qr!$aa3_to_aa1!;

    # enable parsing lowercase 3 letter symbols, eg 'NAc-lys-gly-gln-OH'. 
    my %aa3_to_aa1_lc = map { lc($_) => $aa3_to_aa1{$_} } keys %aa3_to_aa1;
    my @aa3_to_aa1_keys_lc = map { lc $_ } @aa3_to_aa1_keys;
    my $aa3_to_aa1_lc = join "|", @aa3_to_aa1_keys_lc;
    my $aa3_to_aa1_lc_re = qr!$aa3_to_aa1_lc!;

=head2 aa3_to_aa1

  Args        : string with a peptide sequence
  Example     : $str = $self->aa3_to_aa1($str)
  Description : finds the first string that looks like protein
		sequence in 3 letter amino acid symbols or full
		names. Cleans (remove non-informative parens, -, /,
		etc), and returns the cleaned sequence. Currently,
		full names are also handled here, but this may change.
  Returns     : sequence (TRUE) if a sequence is found, FALSE otherwise.

=cut

    sub aa3_to_aa1 {
	my ($self, $str) = @_;
	# first try more frequent, uppercase, then lowercase.
	# tag with _BeginTag_ and _EndTag_ the replaced amino acids, 
	# then use the tag to remove the rest 
	# of the chars, except for a set of allowed chars that did not 
	# need 3 letter to 1 letter conversion and thus did not get tagged.
	# proceed if > 1 replacements , eg > 1 aa.
	return unless 
	  ( 
	   ($_ = $str and s!($aa3_to_aa1_re)!_BeginTag_$aa3_to_aa1{$1}_EndTag_!g > 1) or 
	   ($_ = $str and s!\b($aa3_to_aa1_lc_re)\b!_BeginTag_$aa3_to_aa1_lc{$1}_EndTag_!g > 1)
	  );
	# warn "tag aa3_to_aa1: \$str=$str;" if $self->{verbose} > 2;
	# warn "tag aa3_to_aa1: \$_=$_;" if $self->{verbose} > 2;
	# handle x and X here, so that the method returns TRUE only if 3 letter 
	# symbols occurred. x and X do not count.
	s!\bx\b!_BeginTag_X_EndTag_!g;
	# neg lookbehind: tag each X, except those already tagged
	# (eg, converted from Xaa to X) (= preceded by _), or 
	# those where X means something other than amino acid 
	# (eg, Met(OX) means Met, oxidized) (= preceded by non-X upper case letter).
	s!(?<\![_A-WYZ])X!_BeginTag_X_EndTag_!g;
	# warn "tag X: \$_=$_;" if $self->{verbose} > 2;
	# change 'X(3)' to 'XXX'
	# repeat only Xs, because X(n) usually refers to X repeated n times, 
	# while for other aa, such as G,
	# G(n) refers to the position within the protein.
	# Some cases where X(n) refers to position n are eliminated later if n is too large, 
	# eg X(20) results in sequence length > 20 and is assigned lower score.
	s!_BeginTag_X_EndTag_\W*(\d)\W*!'_BeginTag_X_EndTag_' x $1!eg;
	$_ = join '', grep { defined $_ } m!([\-/()])|_BeginTag_(.)_EndTag_!g;
	return clean_seq($_);
    }
}


{

    # p = phospho, eg pY = phosphotyrosine
    # x and X are both frequently used in motifs as any aa.
    # B, Z, U are not included because they do not occur very frequently in aa sequences in abstracts.
    my $aa1_allowed = '\-/()ACDEFGHIKLMNPQRSTVWYXpx';
    my $aa1_re = qr!
		# not immed preceded by other letters     	
		# optional N-terminus
		(?:N\-|HN\-|H2N\-|H\(2\)N\-|[\W\d]|^)  
		# sequence, >= 2 aa
		([$aa1_allowed]{2,})
		# not immed followed by other letters
		(?:[\W\d]|\-.*|$) 
		!x;

=head2 to_aa1

  Args        : string with a peptide sequence
  Example     : $str = $self->to_aa1($str)
  Description : finds the first string that looks like peptide sequence in uppercase 
		1 letter amino acid symbols. Cleans (remove non-informative parens, 
		-, /, etc), and returns the cleaned sequence.
  Returns     : sequence (TRUE) if a sequence is found, FALSE otherwise.

=cut

    sub to_aa1 {
	my ($self, $str) = @_;
	for ($str) {
	    if (m!$aa1_re!) {
		return clean_seq($1);
	    }
	}
	return;
    }
}

=head2 clean_seq

  Args        : string with a peptide sequence in 1 letter aa symbols
  Example     : $str = clean_seq($str);
  Description : for sequence in 1 letter aa symbols, remove extra parens, etc. 
		Simple motifs are ok: A(B/C/D)E...
  Returns     : cleaned string.

=cut

sub clean_seq {
    my ($str) = @_;
    for ($str) {
	s!\-NH[()\d]*$!!;      	# remove C/N terminal mark
	s!(^[CN]'|[CN]'$)!!g;
	s!FMK\W*$!!;		# remove aa modifications, eg fluorophores
	tr!\-!!d;		# delete connecting '-', eg change 'G-E-T' to 'GET'
	tr!p!!d;		# delete p=phospho, not P=proline. lowercase only.	
	$_ = uc $_;		# do this after resolving: p=phospho, not P=proline; 
				# Xxx = X, not XXX = X{3}
	s!X\W*(\d)\W*!'X' x $1!eg;
	$_ = clean_orphan_parens($_);
	s!^/+!!;		# clean up beginning and end
	s!/+$!!;		# clean up beginning and end
	s!/+!/!g;		# clean up repeated separator chars
	$_ = parse_slashes($_);
	$_ = clean_orphan_parens($_);
	return $_;
    }
}

=head2 clean_orphan_parens

  Args        : string with a sequence to clean up.
  Example     : $_ = clean_orphan_parens($_);
  Description : removes orphan parens from a string.
  Returns     : cleaned string.

=cut

sub clean_orphan_parens {
    my ($str) = @_;
    for (my $i = 0; $i < 100; $i++) { # magic number 100 to prevent inf loops
	my $num_changes = 0;
	$num_changes += s!^\)+!!g;		# delete wrong sided parens
	$num_changes += s!\(+$!!g;		# delete wrong sided parens
	$num_changes += s!\(+!\(!g;		# change '((GET)' to '(GET)'
	$num_changes += s!\)+!\)!g;		# change '(GET))' to '(GET)'
	$num_changes += s!\([^A-Z]*\)!!g;	# remove '(/)', '()'
	$num_changes += s!^\((.)\)!$1!;		# change '(G)ETRAPL' to 'GETRAPL'
	# change 'GETR(A)PL' to 'GETRAPL'
	# change 'GET(RAP)L' to 'GETRAPL'
	$num_changes += s!\(([^()/]*)\)!$1!g;
	# change '(GETR(A)PL)' to 'GETR(A)PL' - delete outer parens in 2 steps:
	$num_changes += s!\(([^()]+)\(!$1\(!g;	# change '(GETR(A)PL)' to 'GETR(A)PL)'
	$num_changes += s!\)([^()]+)\)!\)$1!g;	# change 'GETR(A)PL)' to 'GETR(A)PL'
	my $num_parens = tr!()!!;
	if ($num_parens == 1) {
	    $num_changes += tr!()!!d;	       	# change 'GE(TRAPL' to 'GETRAPL'
	}
	last unless $num_changes; # clean stubborn sequences, eg: 
	# 'G(ET(RA)PL' => 'G(ETRAPL' (after iteration 1), 'GETRAPL' (after iteration 2).
    }
    return $_;
}


=head2 parse_slashes

  Args        : string with a sequence.
  Example     : $_ = parse_slashes($_);
  Description : handles slashes. Changes A/B/C/etc to (A/B/C/etc)
		which means any of A, B, C, etc. Returns the resulting
		string. Exceptions are as follows, based on the the
		fact that the result would make no sense. If X occurs
		next to '/' or if the result would contain a repeated
		character. For exceptions, splits the string on
		slashes, and returns the first longest string.
  Returns     : see above

=cut

sub parse_slashes {
    $_ = $_[0];
    return $_ unless m!/!;
    if (m!/X|X/! or has_repeats_at_slashes($_) ) {
	my $str = '';
	for (split m!/+!) {
	    $str = $_  if length($str) < length($_); # change PXXP/PXPXP to PXPXP
	}
	return $str;
    } else {
	s!(\w(/\w)+)!($1)!g;	# change PXXP/GXPXP to PXX(P/G)XPXP
	return $_;
    }	
}


=head2 has_repeats_at_slashes

  Args        : string with a sequence.
  Example     : print 1 if has_repeats_at_slashes($_);
  Description : see below
  Returns     : TRUE if the string has a repeated char next to a series of 
		slashes and chars, FALSE otherwise.

=cut

sub has_repeats_at_slashes {
    for ($_[0]) {
	for (m!(\w(?:/\w)+)!g) {
	    my %seen;
	    for (/\w/g) {
		return 1 if $seen{$_}++;
	    }
	}
    }
    return;
}

=head2 WordVars

  Args        : $rh_word - ref to hash with data for the word
  Example     : $parser->WordVars($rh_word) or return;
  Description : computes variables for WordScore, eg WordPropDegen, WordIsDNA, etc.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

sub WordVars {
    my ($self, $rh_word) = @_;
    return unless $rh_word and ref $rh_word eq 'HASH';
    $_ = $rh_word->{WordSequence};
    # keep allowed chars in kmers(): 'a'..'z' in sync with 
    # WordPropProtein() args : lc tr/A-Z//cd;
    ( $rh_word->{WordAlpha} = $_ ) =~ tr/A-Z//cd;
    
    if ( $rh_word->{WordSequence} ) {
	$rh_word->{WordSeqLen} = length $rh_word->{WordAlpha};
	$rh_word->{WordNumDegen} = tr/X//;
	$rh_word->{WordNumNotDegen} = $rh_word->{WordSeqLen} - $rh_word->{WordNumDegen};
	$rh_word->{WordPropDegen} = $rh_word->{WordNumDegen} / ($rh_word->{WordSeqLen} || 1);
	$rh_word->{WordLcSequence} = lc $rh_word->{WordSequence};
    }
    
    if ($rh_word->{WordAaSymbols} == 1) {
	# Compute WordPropProtein only for 1 letter symbols, because
	# it is important for classification if 'GET' looks like an english word, 
	# but not important if 'Gly-Glu-Thr' does. 
	$rh_word->{WordPropProtein} = $self->WordPropProtein(lc $rh_word->{WordAlpha});
	$rh_word->{WordIsDNALen} = tr/ACTGN//;
	$rh_word->{WordPropDNA} = $rh_word->{WordIsDNALen} / $rh_word->{WordSeqLen}
	  if $rh_word->{WordSeqLen};
	# if all or mostly dna, eg, '(A/C)TGG' or 'WCCGGGCGGCCCC'
	$rh_word->{WordIsDNA} = 1 if $rh_word->{WordPropDNA} >= 0.9;
    }
    return 1;
}

{
    my $re;

=head2 WordPropProtein

  Args        : $word : string
  Example     : $rh_word->{WordPropProtein} = $self->WordPropProtein($word);
  Description : See package DESCRIPTION above.
  Returns     : sum of log10(proportion(k-mers))

=cut
    
    sub WordPropProtein {
	my ($self, $str) = @_;
	my $WordPropProtein = 0;
	return $WordPropProtein if (length($str) < $self->{kmer_length});
	$re ||= qr/(?=(.{$self->{kmer_length}}))/;
	foreach ($str =~ /$re/g) {
	    unless (defined $log_prop_sequence{$_}) {
		carp "not ok: undefined log_prop_sequence for $_";
		next;
	    }
	    unless (defined $log_prop_nonsequence{$_}) {
		carp "not ok: undefined log_prop_nonsequence for $_";
		next;
	    }
	    $WordPropProtein += ($log_prop_sequence{$_} - $log_prop_nonsequence{$_});
	}
	$WordPropProtein = sprintf("%.1f", $WordPropProtein);
	return $WordPropProtein;
    }   
}

{
    # WordScore factors for different values of vars, eg 
    # for WordAaSymbols = 3, multiply WordScore by 1000.

    # WordScoreForAaSymbols:
    # Keep the ratio of 3 letter or full name symbols relative to 1 letter symbols high, 
    # because even for very short words they are more likely to be a sequence, eg: 
    # 'Pro-Ala-Pro' relative to 'PAP'.
    my %WordScoreForAaSymbols = 
      ( 
       0 => 0,
       1 => 1, 
       3 => 1000, 
       5 => 10000, # full names (not implemented)
      );
    # 
    my %WordScoreForSeqLen =
      (
       0 => 0,
       1 => 0,
       2 => 0.0001,
       3 => 0.1,
       4 => 0.5,
       5 => 1,
      );

    # as WordSeqLen increases between 5 and $MAX_PEPTIDE_LENGTH, 
    # WordScore factor increases linearly from 1 to 5
    foreach (5..$MAX_PEPTIDE_LENGTH) {
	$WordScoreForSeqLen{$_} = 1 + 4 * ($_ - 5) / ($MAX_PEPTIDE_LENGTH - 5);
    }
    my $max_penalized_length = 6; # after this length, flat rate penalty applies:
    my $WordScoreForMatchLenMin = 3**(-$max_penalized_length);
    # up to $max_penalized_length, penalize by this factor (divide score by 3 for each char)
    my %WordScoreForMatchLen = map { ($_ => 3**(-$_)) } 0..$max_penalized_length;

=head2 WordScore

  Args        : $rh_word - ref to hash with word data.
  Example     : $parser->WordScore($rh_word) or return;
  Description : See package DESCRIPTION above.
  Returns     : TRUE if successful, FALSE otherwise.

=cut

    sub WordScore {
	my ($self, $rh_word) = @_;
	ref $rh_word eq 'HASH' or 
	  carp "not ok: expected WordScore arg[1]  = hash ref, got $rh_word" and return;
	$rh_word->{WordScore} = 1; # initialize WordScore
	unless ($rh_word->{WordSequence} and $rh_word->{WordOrig}) {
	    $rh_word->{WordScore} = 0;
	}
	warn "WordScore = $rh_word->{WordScore}; WordOrig = $rh_word->{WordOrig}" if $self->{verbose} > 2;
	return 1 unless $rh_word->{WordScore};
	$rh_word->{WordScore} *= $WordScoreForAaSymbols{ $rh_word->{WordAaSymbols} };
	warn "WordScore = $rh_word->{WordScore}; WordOrig = $rh_word->{WordOrig}" if $self->{verbose} > 2;
	if (exists $WordScoreForSeqLen{ $rh_word->{WordSeqLen} }) {
	    $rh_word->{WordScore} *= $WordScoreForSeqLen{ $rh_word->{WordSeqLen} };
	} else { # if length > $MAX_PEPTIDE_LENGTH, discard regardless of anything else
	    $rh_word->{WordScore} = 0;
	} 	
	warn "WordScore = $rh_word->{WordScore}; WordOrig = $rh_word->{WordOrig}" if $self->{verbose} > 2;
	return 1 unless $rh_word->{WordScore};
	
	if (
	    $rh_word->{WordPropDegen} > 0.95 || 
	    $rh_word->{WordNumNotDegen} <= 1 ||
	    ($rh_word->{WordNumNotDegen} <= 2 && $rh_word->{WordSeqLen} >= 6) # <= 2 of 6 aa
	   ) {
	    $rh_word->{WordScore} = 0;
	}
	elsif (
	       $rh_word->{WordPropDegen} > 0.7 ||
	       ($rh_word->{WordNumNotDegen} <= 2 && $rh_word->{WordSeqLen} >= 5)
	      ) {
	    $rh_word->{WordScore} *= 0.001;
	}
	elsif ($rh_word->{WordPropDegen} > 0.6) {
	    $rh_word->{WordScore} *= 0.01;
	}
	warn "WordScore = $rh_word->{WordScore}; WordOrig = $rh_word->{WordOrig}" if $self->{verbose} > 2;
	return 1 unless $rh_word->{WordScore};

	$self->WordScoreForMatch($rh_word) or return;
	warn "WordScore = $rh_word->{WordScore}; WordOrig = $rh_word->{WordOrig}" if $self->{verbose} > 2;
	return 1 unless $rh_word->{WordScore};
	# normalize for the ease of use, so that (after all transformations), 
	# at WordScore = 0.5, approximately 50% of the words are
	# true positives by manual inspection
	$rh_word->{WordScore} = (1/6) * $rh_word->{WordScore};
	warn "WordScore = $rh_word->{WordScore}; WordOrig = $rh_word->{WordOrig}" if $self->{verbose} > 2;
	# transform (0, +inf) to (0,1):
	$rh_word->{WordScore} = $rh_word->{WordScore} / ( 1 + $rh_word->{WordScore} );
	warn "WordScore = $rh_word->{WordScore}; WordOrig = $rh_word->{WordOrig}" if $self->{verbose} > 2;
	return 1;
    }

=head2 WordScoreForMatch

  Args        : $rh_word - ref to hash with word data.
  Example     : $parser->WordScoreForMatch($rh_word) or return;
  Description : Calls WordIsGeneOrDict to compute WordIsDict, WordIsGene. 
		Changes WordScore based on these vars, as well as based on WordIsDNA, 
		WordPropProtein, etc.
  Returns     : TRUE if successful, FALSE otherwise.

=cut
    
sub WordScoreForMatch {	
    my ($self, $rh_word) = @_;
    ref $rh_word eq 'HASH' or 
      carp "not ok: expected WordScoreForMatch arg[1]: hash ref, got: $rh_word" and 
	return;
    # no need to check this for 3 and full letter symbols:
    return 1 unless $rh_word->{WordAaSymbols} == 1;
    $self->WordIsGeneOrDict($rh_word) or return;
    warn "WordScore = $rh_word->{WordScore}; WordOrig = $rh_word->{WordOrig}" if $self->{verbose} > 2;
    # roman numeral < 50 that ends within 0 or 1 char of the end of word, eg 
    # TFIII or TFIIA. WordIsRomanLen = length of the roman 
    # numeral (minus 1 if there is 1 char between the numeral and the 
    # end of the word).
    while ($rh_word->{WordOrig} =~ /(X{0,3})(I[XV]|V?I{0,3})([A-Z])?\b/g) {
	my $next_roman_len = length($1) + length($2) - ($3 ? length($3) : 0 );
	next unless $next_roman_len > 0; # skip 0 or -1 (not a roman numeral).
	$rh_word->{WordIsRomanLen} += $next_roman_len;
	$rh_word->{WordIsRoman} = 1 if $rh_word->{WordIsRomanLen} >= 2; # eg, HYNKIIIA
    }
    # for these vars with values: 0/1, penalize based on length:
    foreach (qw(WordIsDNA WordIsDict WordIsGene WordIsRoman)) {
	next unless $rh_word->{$_};
	# limit the penalty by the sequence length, eg
	# if 'SDS-PAGE' is entered into dictionary twice, 
	# as both 'SDS-PAGE' and 'SDSPAGE' 
	$rh_word->{"${_}Len"} = $rh_word->{WordSeqLen} 
	  if $rh_word->{"${_}Len"} > $rh_word->{WordSeqLen};
	$rh_word->{WordScore} *= 
	  ( $WordScoreForMatchLen{ $rh_word->{"${_}Len"} } || 
	    $WordScoreForMatchLenMin ); 
	warn "WordScore = $rh_word->{WordScore}; WordOrig = $rh_word->{WordOrig}" if $self->{verbose} > 2;
    }
    # if the word was not flagged by WordIsGene WordIsDict:
    unless ($rh_word->{WordIsGene} || $rh_word->{WordIsDict}) {
	# penalize for similarity to a gene symbol, eg KLF4. 
	foreach ($rh_word->{WordOrig} =~ m!([^A-Z]|\b)[A-Z]{2,3}\d*\b!g) {
	    $rh_word->{WordScore} *= 0.1;
	    warn "WordScore = $rh_word->{WordScore}; WordOrig = $rh_word->{WordOrig}" if $self->{verbose} > 2;
	    # penalize for similarity to abbreviations, or to gene/protein interactions, eg 
	    # 'GM-CSF', 'HPLC/FPLC', 'MAP/MAPKK'.
	    $rh_word->{WordScore} *= 0.01 
	      if $rh_word->{WordSubLenMax} && # if the word could be split into subwords and
		$rh_word->{WordSubLenMax} <= 4; # all sub-words are short
	    warn "WordScore = $rh_word->{WordScore}; WordOrig = $rh_word->{WordOrig}" if $self->{verbose} > 2;
	}
    }
    # WordPropProtein is a good predictor if abs(WordPropProtein) > 8.
    # WordPropProtein is very high for WordIsDNA, eg 'CGGTTAAAA', or 
    # WordIsRoman, eg 'HYNKIIIA', thus not used.
    unless(
	     $rh_word->{WordIsDNA} || $rh_word->{WordIsDict} || 
	     $rh_word->{WordIsGene} || $rh_word->{WordIsRoman}
	  ) {
	$rh_word->{WordScore} *= 
	  (10 ** (LOG_10_2 * $rh_word->{WordPropProtein}) );
    }
    warn "WordScore = $rh_word->{WordScore}; WordOrig = $rh_word->{WordOrig}" if $self->{verbose} > 2;
    carp((caller(0))[3], "(@_)", ' ', Data::Dumper->Dump([$rh_word], ['rh_word'])) 
      if $self->{verbose} > 2;
    return 1;
}
}

=head2 WordIsGeneOrDict

  Args        : $rh_word - ref to hash with word data.
  Example     : $parser->WordIsGeneOrDict($rh_word) or return;
  Description : Computes WordIsDict, WordIsGene and related vars. 
  Returns     : TRUE if successful, FALSE otherwise.

=cut

sub WordIsGeneOrDict {	
    my ($self, $rh_word) = @_;
    ref $rh_word eq 'HASH' or 
      carp "not ok: expected WordIsGeneOrDict arg[1]: hash ref, got: $rh_word" and 
	return;
    # select words for matching. Do not penalize more than once for the 
    # same subword, unless it actually occurs more than once.
    my @subwords = split /[^A-Za-z]+/, lc $rh_word->{WordLcOrig};
    my @subwords_long;
    if (@subwords != 1) { # if could split; otherwise just handle $rh_word->{WordLcOrig} below.
	# select sub-words that are long in absolute terms and also long relative 
	# to the original word 
	# (eg, select 'RAS' in 'RAS/EGFR' , but not in 'RAS/GETRAPLGETRAPL'
	foreach (@subwords) {
	    my $length = length $_;
	    push @subwords_long, $_ 
	      if $length > 2 and ( $length / $rh_word->{WordSeqLen} ) > 0.25;
	    # WordSubLenMax = max sub-word length, if could split; otherwise 0.
	    $rh_word->{WordSubLenMax} = $length if $rh_word->{WordSubLenMax} < $length;
	}
    }
    foreach my $subword ( $rh_word->{WordLcSequence}, 
	      # do not penalize more than once for 1 occurrence:
	      ( $rh_word->{WordLcOrig} eq $rh_word->{WordLcSequence} ? 
		() : $rh_word->{WordLcOrig} ), 
	      @subwords_long ) {
	foreach my $bad (qw(Dict Gene)) {
	    # if ( eval { ${$bad}{$subword} } ) { # eval does not work - ??
	    my $is_bad = do {
		if	($bad eq 'Dict') { $Dict{$subword} }
		elsif	($bad eq 'Gene') { $Gene{$subword} }
	    };
	    if ($is_bad) {
		$rh_word->{"WordIs$bad"} = 1;
		$rh_word->{"WordIs${bad}Len"} += length($subword);
	    }
	}
    }
    return 1;
}

=head2 WordAbstScore 

  Args        : none
  Example     : $parser->WordAbstScore or return;
  Description : Computes WordAbstScore based on the results of
		AbstScore and WordScore vars for all words in the
		abstract. AbstMaxWordScore is high if either AbstScore
		is high or WordScore is high, and higher if both are
		high. Instead of using simply AbstMaxWordScore =
		AbstScore * WordScore, AbstMaxWordScore is also added
		to WordScore with a smaller weight. This is because
		probability that a given word is a sequence increases
		if another word in the same abstract is a
		sequence. The weight for AbstMaxWordScore is smaller
		than that for WordScore in order not to make all words
		have equal AbstMaxWordScore. WordAbstScore = 0 for
		WordScore = 0, to reduce obvious noise (otherwise, all
		words that are clearly not peptide sequences will get
		positive WordAbstScore when they occur in an abstract
		with at least one sequence). Skip transform to (0,1)
		because the scores below are all in (0,1), and the
		weights add to 1, so WordAbstScore is already in
		(0,1).
  Returns     : TRUE if successful, FALSE otherwise.

=cut

sub WordAbstScore {
    my ($self) = @_;
    my $rh_abst = $self->{abst};
    # max WordScore for all words in this abstract:
    $rh_abst->{AbstMaxWordScore} = 0;
    foreach my $rh_word (@{ $self->{words} }) {
	$rh_abst->{AbstMaxWordScore} = $rh_word->{WordScore} 
	  if $rh_abst->{AbstMaxWordScore} < $rh_word->{WordScore};
    }	
    
    foreach my $rh_word (@{ $self->{words} }) {
	$rh_word->{WordAbstScore} = $rh_word->{WordScore} > 0 ?
	  $rh_abst->{AbstScore} *
	    (0.1 * $rh_abst->{AbstMaxWordScore} + 0.9 * $rh_word->{WordScore})
	      : 0; 
    }
    if ($self->{verbose} > 0) {
	$rh_abst->{AbstComment} .= 
	  sprintf("AbstMaxWordScore=%.4f; ", $rh_abst->{AbstMaxWordScore});
    }
    carp((caller(0))[3], "(@_)", ' ', Data::Dumper->Dump([$self], ['self'])) 
      if $self->{verbose} > 2;
    return 1;
}

=head2 AbstMtext

  Args        : none
  Example     : $parser->AbstMtext
  Description : Marks all words that are putative sequences with
		'<mark>...</mark>' tags. This is done only for words
		for which WordScore is at least WordScoreMin.
  Returns     : always TRUE

=cut

sub AbstMtext {
    my ($self) = @_;
    if (
	$self->{words} and 
	ref $self->{words} eq 'ARRAY'
       ) {
	$self->{abst}{AbstMtext} = 
	  join '', map {
	      if (! defined $_->{WordOrig} ) { () } # happens if WordNumPrintMin = 1
	      elsif (
		     $_->{WordScore}		>= $self->{WordScoreMin} && 
		     $_->{WordAbstScore}	>= $self->{WordAbstScoreMin}
		    ) 
		{ "<mark>$_->{WordOrig}</mark>"}
	      else { $_->{WordOrig} }
	    } 
	    @{ $self->{words} } ;
    }
    else {
	$self->{abst}{AbstMtext} = $self->{abst}{AbstAbstract} || '';
    }
    return 1;
}

=head2 formatScoreProp

  Args[1]     : $number - score or proportion.
  Example     : $rh_word->{WordScore} = formatScoreProp($rh_word->{WordScore});
  Description : changes $number to be in (0,1) interval, formats $number 
		for nice printing
  Returns     : formatted score

=cut

sub formatScoreProp {
    my ($number) = @_;
    return unless defined $number;
    # number should be between 0 and 1,
    # In methods in this package, the input $number is supposed to be always in (0,1) - 
    # maybe issue warning otherwise?
    $number = 0 if $number < 0;
    $number = 1 if $number > 1;
    $number = sprintf "%.4f", $number;
}

=head2 find

  Args[1]     : $key - field name
  Args[2]     : $val - value
  Example     : # print WordScore for the first GETRAPL sequence.
		# print $parser->find(WordSequence => 'GETRAPL')->{WordScore};
  Description :  finds the first word for which the value of field $key 
		is equal to $val (string eq, not numeric ==)
  Returns     : returns this word (hash ref) if successful, FALSE otherwise.

=cut

sub find {
    my ($self, $key, $val) = @_;
    foreach ( @{ $self->{words} } ) {
	return $_ if defined $_->{$key} and $_->{$key} eq $val;
    }
    return;
}

1;
