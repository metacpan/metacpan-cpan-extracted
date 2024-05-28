package OpenSearch::Cluster::Settings;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;
use OpenSearch::Cluster::Settings::Get;
use OpenSearch::Cluster::Settings::Set;

sub get( $self, @params ) {
  return ( OpenSearch::Cluster::Settings::Get->new(@params)->execute );
}

sub set( $self, @params ) {
  return ( OpenSearch::Cluster::Settings::Set->new(@params)->execute );
}

1;
