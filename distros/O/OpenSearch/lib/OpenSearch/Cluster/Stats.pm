package OpenSearch::Cluster::Stats;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;
use OpenSearch::Cluster::Stats::Get;

sub get( $self, @params ) {
  return ( OpenSearch::Cluster::Stats::Get->new(@params)->execute );
}

1;
