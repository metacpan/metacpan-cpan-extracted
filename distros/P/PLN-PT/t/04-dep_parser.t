#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 5;
use PLN::PT;
use utf8;

my $nlp = PLN::PT->new('http://api.pln.pt');
my $data;

# dep_parser
SKIP: {
  $data = $nlp->dep_parser('A Maria tem razão .');
  skip 'No data.', 5 unless ($data and @$data);

  ok( scalar(@$data) == 5, 'sentence has 5 tokens' );
  ok( $data->[0]->{head} eq '2', 'first token head is "2"' );
  ok( $data->[0]->{deprel} eq 'det', 'first token deprel is "det"' );
  ok( $data->[-1]->{head} eq '3', 'last token head is "3"' );
  ok( $data->[-1]->{deprel} eq 'punct', 'last token deprel is "punct"' );
}

