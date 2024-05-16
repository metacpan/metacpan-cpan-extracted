package OpenSearch::Cluster::Stats;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;

with 'OpenSearch::Parameters::ClusterStats';
#with 'OpenSearch::Helper';

# Base singleton
has 'base' => (is => 'rw', isa => 'OpenSearch::Base', lazy => 1, default => sub {OpenSearch::Base->instance});

sub stats_p($self) {
  return( $self->base->_get(
    ['_cluster', 'stats', ($self->nodes ? ('nodes', $self->nodes->to_string) : ())]
  ));
}

sub stats($self) {
  my ($res);
  $self->stats_p->then(sub {$res = shift; })->wait;
  return $res;
}

1;

__DATA__
