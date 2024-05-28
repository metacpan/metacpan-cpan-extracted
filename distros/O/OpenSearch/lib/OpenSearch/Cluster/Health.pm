package OpenSearch::Cluster::Health;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;
use OpenSearch::Cluster::Health::Get;

sub get( $self, @params ) {
  return ( OpenSearch::Cluster::Health::Get->new(@params)->execute );
}

1;
