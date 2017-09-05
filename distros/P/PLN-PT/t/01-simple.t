#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 17;
use PLN::PT;
use utf8;

my $nlp = PLN::PT->new('http://api.pln.pt');
my $data;

# tokenizer
SKIP: {
  $data = $nlp->tokenizer('A Maria tem razão .');
  skip 'No data.', 3 unless $data;

  ok( scalar(@$data) == 5, 'sentence has 5 tokens' );
  ok( $data->[0] eq 'A', 'first token in "A"' );
  ok( $data->[-1] eq '.', 'last token in "."' );
}

# morph_analyzer
SKIP: {
  $data = $nlp->morph_analyzer('cavalgar');
  skip 'No data.', 4 unless $data;

  ok( scalar(@$data) == 6, 'word has 5 analysis' );
  ok( $data->[0] eq 'cavalgar', 'first token is analyzed word' );
  ok( $data->[1]{lemma} eq 'cavalgar', 'first analysis lemma' );
  ok( $data->[1]{analysis} =~ m!^V!, 'first analysis as a verb' );
}


# tagger
SKIP: {
  $data = $nlp->tagger('A Maria tem razão .');
  skip 'No data.', 5 unless $data;

  ok( scalar(@$data) == 5, 'sentence has 5 tokens' );
  ok( $data->[0]->[1] eq 'o', 'first token lemma is "o"' );
  ok( $data->[0]->[2] eq 'DA0FS0', 'first token tag is "DA0FS0"' );
  ok( $data->[-1]->[1] eq '.', 'last token lemma is "."' );
  ok( $data->[-1]->[2] eq 'Fp', 'last token tag is "Fp"' );
}

# dep_parser
SKIP: {
  $data = $nlp->dep_parser('A Maria tem razão .');
  skip 'No data.', 5 unless $data;

  ok( scalar(@$data) == 5, 'sentence has 5 tokens' );
  ok( $data->[0]->[6] eq '2', 'first token parent is "2"' );
  ok( $data->[0]->[7] eq 'det', 'first token rule is "det"' );
  ok( $data->[-1]->[6] eq '3', 'last token parent is "3"' );
  ok( $data->[-1]->[7] eq 'punct', 'last token rule is "punct"' );
}

