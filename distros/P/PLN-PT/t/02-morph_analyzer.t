#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;
use PLN::PT;
use utf8;

my $nlp = PLN::PT->new('http://api.pln.pt');
my $data;

# morph_analyzer
SKIP: {
  $data = $nlp->morph_analyzer('cavalgar');
  skip 'No data.', 3 unless ($data and @$data);

  ok( scalar(@$data) == 5, 'word has 5 analysis' );
  ok( $data->[0]->{lemma} eq 'cavalgar', 'first analysis lemma' );
  ok( $data->[0]->{pos} =~ m!^V!, 'first analysis as a verb' );
}

