package OpenSearch::Cluster::Settings;
use strict;
use warnings;
use feature qw(signatures);
use Moose;
use Data::Dumper;

with 'OpenSearch::Parameters::ClusterSettings';

#with 'OpenSearch::Helper';

# Base singleton
has 'base' => (
  is       => 'rw',
  isa      => 'OpenSearch::Base',
  required => 0,
  lazy     => 1,
  default  => sub { OpenSearch::Base->instance; }
);

sub get_p($self) {
  my $params = {
    optional => {
      url => [qw/flat_settings include_defaults cluster_manager_timeout/],
    }
  };
  return ( $self->base->_get( $self, [ '_cluster', 'settings' ], $params ) );
}

sub get($self) {
  my ($res);
  $self->get_p->then( sub { $res = shift; } )->wait;
  return $res;
}

sub set_p( $self, $settings ) {
  $self->cluster_settings($settings) if $settings;

  my $params = {
    optional => {
      url => [qw/flat_settings cluster_manager_timeout timeout/],
    },
    required {
      body => [qw/cluster_settings/]
    }
  };

  return ( $self->base->_put( $self, [ '_cluster', 'settings' ], $params ) );
}

sub set( $self, $settings ) {
  my ($res);
  $self->set_p($settings)->then( sub { $res = shift; } )->wait;
  return $res;
}
1;
__END__

=encoding utf-8

=head1 NAME

C<OpenSearch::Cluster::Settings> - OpenSearch Cluster Settings API

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

    my $settings = $cluster->settings;

    my $response = $settings->get;

=head1 DESCRIPTION

This is the Module for the OpenSearch Cluster Settings API.

=head1 ATTRIBUTES (optional)

For a detailed description of these attributes, see the OpenSearch documentation.
Attrubutes can be chained like:

    my $response = $object
      ->attribute_1(1)
      ->attribute_2('string')

=head2 flat_settings

=head2 include_defaults

=head2 cluster_manager_timeout

=head2 timeout

=head2 cluster_settings

=head1 METHODS

=head2 get

returns the results of the query as a hash reference.

    my $response = $settings->get;

=head2 get_p

returns the results of the query as a promise.

    $settings->get_p->then(sub {
      my $response = shift;
    });

=head2 set

returns the results of the query as a hash reference.

    my $response = $settings->set($hashref);
    # OR
    $response = $settings->cluster_settings($hashref)->set;

=head2 set_p

returns the results of the query as a promise.

    $settings->set_p($hashref)->then(sub {
      my $response = shift;
    });

=head1 LICENSE

Copyright (C) localh0rst.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

localh0rst E<lt>git@fail.ninjaE<gt>

=cut

