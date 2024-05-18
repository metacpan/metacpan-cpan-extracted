package OpenSearch::Cluster::Stats;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;

with 'OpenSearch::Parameters::ClusterStats';

#with 'OpenSearch::Helper';

# Base singleton
has 'base' => ( is => 'rw', isa => 'OpenSearch::Base', lazy => 1, default => sub { OpenSearch::Base->instance } );

sub get_p($self) {
  return ( $self->base->_get( [ '_cluster', 'stats', ( $self->nodes ? ( 'nodes', $self->nodes->to_string ) : () ) ] ) );
}

sub get($self) {
  my ($res);
  $self->stats_p->then( sub { $res = shift; } )->wait;
  return $res;
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

    my $stats = $cluster->stats;

    my $response = $stats->get;

=head1 DESCRIPTION

This is the Module for the OpenSearch Cluster Stats API.

=head1 ATTRIBUTES (optional)

For a detailed description of these attributes, see the OpenSearch documentation.
Attrubutes can be chained like:

    my $response = $object
      ->attribute_1(1)
      ->attribute_2('string')

=head2 THERE ARE NONE FOR STATS

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


