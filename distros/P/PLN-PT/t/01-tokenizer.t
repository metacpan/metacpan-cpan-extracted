#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 3;
use PLN::PT;
use utf8;

my $nlp = PLN::PT->new('http://api.pln.pt');
my $data;

# tokenizer
SKIP: {
  $data = $nlp->tokenizer('A Maria tem razão .');
  skip 'No data.', 3 unless ($data and @$data);

  ok( scalar(@$data) == 5, 'sentence has 5 tokens' );
  ok( $data->[0] eq 'A', 'first token in "A"' );
  ok( $data->[-1] eq '.', 'last token in "."' );
}

