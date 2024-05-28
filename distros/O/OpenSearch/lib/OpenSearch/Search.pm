package OpenSearch::Search;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;
use OpenSearch::Search::Search;

sub search( $self, @params ) {
  return ( OpenSearch::Search::Search->new(@params)->execute );
}

1;
