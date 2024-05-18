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
has 'base' => (
  is       => 'rw',
  isa      => 'OpenSearch::Base',
  required => 0,
  lazy     => 1,
  default  => sub { OpenSearch::Base->instance; }
);

sub explain_p($self) {
  my $params = {
    optional => {
      url  => [qw/include_yes_decisions include_disk_info/],
      body => [qw/current_node index primary shard/]
    }
  };

  return ( $self->base->_get( $self, [ '_cluster', 'allocation', 'explain' ], $params ) );
}

sub explain($self) {
  my ($res);
  $self->explain_p->then( sub { $res = shift; } )->wait;
  return $res;
}

1;

__END__

=encoding utf-8

=head1 NAME

C<OpenSearch::Cluster::Allocation> - OpenSearch Cluster Allocation API

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

    my $allocation = $cluster->allocation;

    my $response = $allocation->explain;

=head1 DESCRIPTION

This is the Module for the OpenSearch Cluster Allocation API.

=head1 ATTRIBUTES (optional)

For a detailed description of these attributes, see the OpenSearch documentation.
Attrubutes can be chained like:

    my $response = $object
      ->attribute_1(1)
      ->attribute_2('string')

=head2 include_yes_decisions

=head2 include_disk_info

=head2 current_node

=head2 index

=head2 primary

=head2 shard

=head1 METHODS

=head2 explain

returns the results of the query as a hash reference.

    my $response = $allocation->explain;

=head2 explain_p

returns the results of the query as a promise.

    $allocation->explain_p->then(sub {
      my $response = shift;
    });

=head1 LICENSE

Copyright (C) localh0rst.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

localh0rst E<lt>git@fail.ninjaE<gt>

=cut

