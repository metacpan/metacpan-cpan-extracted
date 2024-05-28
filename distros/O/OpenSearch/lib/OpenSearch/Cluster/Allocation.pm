package OpenSearch::Cluster::Allocation;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;
use OpenSearch::Cluster::Allocation::Explain;

sub explain( $self, @params ) {
  return ( OpenSearch::Cluster::Allocation::Explain->new(@params)->execute );
}

1;
