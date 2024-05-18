package OpenSearch;
use strict;
use warnings;
use Moose;
use feature qw(signatures);
use Data::Dumper;
use OpenSearch::MooseTypes;
use OpenSearch::Base;
use OpenSearch::Search;
use OpenSearch::Cluster;
use OpenSearch::Cluster::Health;
use OpenSearch::Cluster::Stats;
use OpenSearch::Cluster::Allocation;
use OpenSearch::Cluster::Settings;
use OpenSearch::Remote;
use OpenSearch::Remote::Info;

# Filter
use OpenSearch::Filter::Source;

our $VERSION = '0.03';

# Base singleton
has 'base' => (
  is      => 'rw',
  isa     => 'OpenSearch::Base',
  lazy    => 1,
  default => sub { OpenSearch::Base->initialize; }
);

sub BUILD( $self, $args ) {
  $self->base( OpenSearch::Base->new(
    user           => $args->{user},
    pass           => $args->{pass},
    hosts          => $args->{hosts},
    secure         => $args->{secure}         // 0,
    allow_insecure => $args->{allow_insecure} // 1,
    pool_count     => $args->{pool_count}     // 1,
    clear_attrs    => $args->{clear_attrs}    // 0,
  ) );
}

#Search
sub search { shift; return ( OpenSearch::Search->new(@_) ); }

# Cluster
sub cluster            { shift; return ( OpenSearch::Cluster->new(@_) ); }
sub cluster_health     { shift; return ( OpenSearch::Cluster::Health->new(@_) ); }
sub cluster_stats      { shift; return ( OpenSearch::Cluster::Stats->new(@_) ); }
sub cluster_allocation { shift; return ( OpenSearch::Cluster::Allocation->new(@_) ); }
sub cluster_settings   { shift; return ( OpenSearch::Cluster::Settings->new(@_) ); }

# Remote
sub remote      { shift; return ( OpenSearch::Remote->new(@_) ); }
sub remote_info { shift; return ( OpenSearch::Remote::Info->new(@_) ); }

1;

__END__

=encoding utf-8

=head1 NAME

C<OpenSearch> - A Perl client for OpenSearch (https://opensearch.org/)

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

    my $s = $self->search(
      index => 'my_index',
      query => {
        bool => {
          must => [ { range => { '@timestamp' => { gte => 'now-1d' } } } ],
        }
      }
    );

    # Blocking
    my $response = $s->execute; 
    # Non Blocking - Returns a Mojo::Promise;
    my $promise = $s->execute_p->then(...)->catch(...);

    # OR you can do it like this:
    my $response = $s->search
      ->index('my_index')
      ->query({ 
        bool => { 
          must => [ { range => { '@timestamp' => { gte => 'now-1d' } } } ] 
        } 
      }
    )->execute;

=head1 DESCRIPTION

This module is a Perl client for OpenSearch (https://opensearch.org/).
It currently only supports a small subset of the OpenSearch API.

=head1 ATTRIBUTES

=head2 user

The username to use for authentication

=head2 pass

The password to use for authentication

=head2 hosts

An arrayref of hosts to connect to

=head2 secure

Boolean to indicate if the connection should be secure (https)

=head2 allow_insecure

Boolean to indicate if insecure connections are allowed

=head2 pool_count

The number of connections to pool

=head2 clear_attrs

Boolean to indicate if attributes should be cleared after a request.
By default this is set to false. Usualy all attributes are cached in
the class instance and will be reused for the next request. Switch
this to 1 if you want to clear all attributes after a request. Another
possibility is to create a new instance of the class for each request.

=head1 METHODS

=head2 cluster

returns a new OpenSearch::Cluster object

  my $cluster = $opensearch->cluster;

=head2 cluster_allocation

returns a new OpenSearch::Cluster::Allocation object

  my $cluster = $opensearch->cluster_allocation;

=head2 cluster_health

returns a new OpenSearch::Cluster::Health object

  my $cluster = $opensearch->cluster_health;

=head2 cluster_settings

returns a new OpenSearch::Cluster::Settings object

  my $cluster = $opensearch->cluster_settings;

=head2 cluster_stats

returns a new OpenSearch::Cluster::Stats object

  my $cluster = $opensearch->cluster_stats;

=head2 remote

returns a new OpenSearch::Remote object

  my $remote = $opensearch->remote;

=head2 remote_info

returns a new OpenSearch::Remote::Info object

  my $remote = $opensearch->remote_info;

=head2 search

returns a new OpenSearch::Search object

  my $search = $opensearch->search;

=head1 LICENSE

Copyright (C) localh0rst.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

localh0rst E<lt>git@fail.ninjaE<gt>

=cut

