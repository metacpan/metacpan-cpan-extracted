package OpenSearch::Cluster::Health;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;

with 'OpenSearch::Parameters::ClusterHealth';
with 'OpenSearch::Helper';

# Base singleton
has 'base' => ( is => 'rw', isa => 'OpenSearch::Base', lazy => 1, default => sub { OpenSearch::Base->instance } );

sub get_p($self) {
  my $params = {
    optional => {
      url => [
        qw/
          expand_wildcards level awareness_attribute local cluster_manager_timeout timeout wait_for_active_shards
          wait_for_nodes wait_for_events wait_for_no_relocating_shards wait_for_no_initializing_shards wait_for_status
          /
      ]
    }
  };

  return ( $self->base->_get( $self, [ '_cluster', 'health', ( $self->index // () ) ], $params ) );
}

sub get($self) {
  my ($res);
  $self->health_p->then( sub { $res = shift } )->wait;
  return ($res);
}

1;
__END__

=encoding utf-8

=head1 NAME

C<OpenSearch::Cluster::Health> - OpenSearch Cluster Health API

=head1 SYNOPSIS

    use strict;
    use warnings;
    use OpenSearch;

    my $opensearch = OpenSearch->new(
      user => 'admin',
      pass => 'admin',
      hosts => ['http://localhost:9200'],
      secure => 0,
      allow_insecure => 1,
    );

    my $cluster = $opensearch->cluster;

    my $health = $cluster->health;

    my $response = $health->get;

=head1 DESCRIPTION

This is the Module for the OpenSearch Cluster Allocation API.

=head1 ATTRIBUTES (optional)

For a detailed description of these attributes, see the OpenSearch documentation.
Attrubutes can be chained like:

    my $response = $object
      ->attribute_1(1)
      ->attribute_2('string')

=head2 index

=head2 expand_wildcards

=head2 level

=head2 local

=head2 cluster_manager_timeout

=head2 awareness_attribute

=head2 timeout

=head2 wait_for_active_shards

=head2 wait_for_nodes

=head2 wait_for_events

=head2 wait_for_no_relocating_shards

=head2 wait_for_no_initializing_shards

=head2 wait_for_status

=head1 METHODS

=head2 get

returns the results of the query as a hash reference.

    my $response = $health->get;

=head2 get_p

returns the results of the query as a promise.

    $health->get_p->then(sub {
      my $response = shift;
    });

=head1 LICENSE

Copyright (C) localh0rst.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

localh0rst E<lt>git@fail.ninjaE<gt>

=cut

