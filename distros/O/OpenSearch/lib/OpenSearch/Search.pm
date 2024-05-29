package OpenSearch::Search;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;
use OpenSearch::Search::Search;
use OpenSearch::Search::Count;

sub search( $self, @params ) {
  return ( OpenSearch::Search::Search->new(@params)->execute );
}

sub count( $self, @params ) {
  return ( OpenSearch::Search::Count->new(@params)->execute );
}

1;
