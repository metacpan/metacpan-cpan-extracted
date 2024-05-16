package OpenSearch::Cluster::Health;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;

with 'OpenSearch::Parameters::ClusterHealth';
with 'OpenSearch::Helper';

# Base singleton
has 'base' => (is => 'rw', isa => 'OpenSearch::Base', lazy => 1, default => sub {OpenSearch::Base->instance});

sub health_p($self) {
  my $params = {
    optional => {
      url  => [qw/
        expand_wildcards level awareness_attribute local cluster_manager_timeout timeout wait_for_active_shards
        wait_for_nodes wait_for_events wait_for_no_relocating_shards wait_for_no_initializing_shards wait_for_status
      /]
    }
  };

  return( $self->base->_get(
    $self, ['_cluster', 'health', ($self->index // ())], $params
  ));
}

sub health($self) {
  my ($res);
  $self->health_p->then(sub {$res = shift})->wait;
  return($res);
}

1;
