#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;
use PLN::PT;
use utf8;

my $nlp = PLN::PT->new('http://api.pln.pt');
my $data;

# tagger
SKIP: {
  $data = $nlp->tagger('A Maria tem razão .');
  skip 'No data.', 5 unless ($data and @$data);

  ok( scalar(@$data) == 5, 'sentence has 5 tokens' );
  ok( $data->[0]->{lemma} eq 'o', 'first token lemma is "o"' );
  ok( $data->[0]->{pos} eq 'DA0FS0', 'first token pos is "DA0FS0"' );
  ok( $data->[-1]->{lemma} eq '.', 'last token lemma is "."' );
  ok( $data->[-1]->{pos} eq 'Fp', 'last token tag is "Fp"' );
}

