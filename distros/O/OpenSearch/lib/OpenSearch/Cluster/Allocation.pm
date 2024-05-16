package OpenSearch::Cluster::Allocation;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use OpenSearch::Helper qw/build_query_params build_request_body/;
use Data::Dumper;

with 'OpenSearch::Parameters::ClusterAllocationExplain';
with 'OpenSearch::Helper';

# Base singleton
has 'base' => (is => 'rw', isa => 'OpenSearch::Base', required => 0, lazy => 1, default => sub {OpenSearch::Base->instance;});

sub explain_p($self) {
  my $params = {
    optional => {
      url  => [qw/include_yes_decisions include_disk_info/],
      body => [qw/current_node index primary shard/]
    }
  };

  return($self->base->_get(
    $self, ['_cluster', 'allocation', 'explain'], $params
  ));
}

sub explain($self) {
  my ($res);
  $self->explain_p->then(sub {$res = shift; })->wait;
  return $res;
}


1;
