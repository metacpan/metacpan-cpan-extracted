package OpenSearch::Cluster;
use strict;
use warnings;
use Moose;
use feature qw(signatures);
use Data::Dumper;

use OpenSearch::Cluster::Settings;
use OpenSearch::Cluster::Health;
use OpenSearch::Cluster::Stats;
use OpenSearch::Cluster::Allocation;

sub get_settings( $self, @params ) {
  return ( OpenSearch::Cluster::Settings->new->get(@params) );
}

sub put_settings( $self, @params ) {
  return ( OpenSearch::Cluster::Settings->new->set(@params) );
}

sub health( $self, @params ) {
  return ( OpenSearch::Cluster::Health->new->get(@params) );
}

sub stats( $self, @params ) {
  return ( OpenSearch::Cluster::Stats->new->get(@params) );
}

sub allocation_explain( $self, @params ) {
  return ( OpenSearch::Cluster::Allocation->new->explain(@params) );
}

1;

__END__

=head1 NAME

C<OpenSearch::Cluster> - Cluster API

=head1 SYNOPSIS

  use OpenSearch;
  my $os = OpenSearch->new(
    ...
    async => 1
  );

  my $cluster = $os->cluster;

  # When async is set, this returns a L<Mojo::Promise> object
  # Otherwise, it returns a hashref with the JSON response. 
  my $settings = $cluster->get_settings;

  $cluster->put_settings(
    persistent => {
      'indices.recovery.max_bytes_per_sec' => '50mb'
    },
    transient => {
      'cluster.routing.allocation.enable' => 'all'
    }
    timeout => '30s'
  );

  my $health = $cluster->health(...);

=head1 DESCRIPTION

This module provides an interface to the OpenSearch Cluster API.

=head1 METHODS

=head2 get_settings

  $cluster->get_settings;

=head2 put_settings

  $cluster->put_settings(
    persistent => {
      'indices.recovery.max_bytes_per_sec' => '50mb'
    },
    transient => {
      'cluster.routing.allocation.enable' => 'all'
    }
    timeout => '30s'
  );

=head2 health

  $cluster->health(...);

=head2 stats

  $cluster->stats(...);

=head2 allocation_explain

  $cluster->allocation_explain(...);

=head1 AUTHOR

C<OpenSearch> was written by Sebastian Grenz, C<< <git at fail.ninja> >>
