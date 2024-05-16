package OpenSearch::Cluster::Settings;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;

with 'OpenSearch::Parameters::ClusterSettings';
#with 'OpenSearch::Helper';

# Base singleton
has 'base'      => (is => 'rw', isa => 'OpenSearch::Base', required => 0, lazy => 1, default => sub {OpenSearch::Base->instance;}     );

sub get_p($self) {
  my $params = {
    optional => {
      url  => [qw/flat_settings include_defaults cluster_manager_timeout/],
    }
  };  
  return( $self->base->_get( 
    $self, ['_cluster', 'settings'], $params 
  ));
}

sub get($self) {
  my ($res);
  $self->get_p->then(sub {$res = shift; })->wait;
  return $res;
}

sub set_p($self, $settings) {
  $self->cluster_settings($settings);
  
  my $params = {
    optional => {
      url  => [qw/flat_settings cluster_manager_timeout timeout/],
    },
    required {
      body => [qw/cluster_settings/]
    }
  };


  return( $self->base->_put(
    $self, ['_cluster', 'settings'],$params
  ));
}

sub set($self, $settings) {
  my ($res);
  $self->set_p($settings)->then(sub {$res = shift; })->wait;
  return $res;
}
1;
