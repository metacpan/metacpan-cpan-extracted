package OpenSearch;
use strict;
use warnings;
use Moose;
use feature qw(signatures);
use Data::Dumper;
use OpenSearch::Base;

use OpenSearch::Cluster;
use OpenSearch::Remote;
use OpenSearch::Search;
use OpenSearch::Index;
use OpenSearch::Document;

our $VERSION = '0.91';

has 'base' => (
  is      => 'rw',
  isa     => 'OpenSearch::Base',
  lazy    => 1,
  default => sub { OpenSearch::Base->initialize; }
);

sub BUILD( $self, $args ) {
  $self->base( OpenSearch::Base->new(
    user            => $args->{user},
    pass            => $args->{pass},
    hosts           => $args->{hosts},
    secure          => $args->{secure}          // 0,
    allow_insecure  => $args->{allow_insecure}  // 1,
    pool_count      => $args->{pool_count}      // 10,
    clear_attrs     => $args->{clear_attrs}     // 0,
    async           => $args->{async}           // 0,
    max_connections => $args->{max_connections} // 10,
  ) );
}

sub cluster($self) {
  return ( OpenSearch::Cluster->new );
}

sub remote($self) {
  return ( OpenSearch::Remote->new );
}

sub search($self) {
  return ( OpenSearch::Search->new );
}

sub index($self) {
  return ( OpenSearch::Index->new );
}

sub document($self) {
  return ( OpenSearch::Document->new );
}

1;

__END__

=head1 NAME

C<OpenSearch> - Unofficial Perl client for OpenSearch (https://opensearch.org/)

=head1 SYNOPSIS

  use OpenSearch;

  my $opensearch = OpenSearch->new(
    user            => 'admin',
    pass            => 'password',
    hosts           => [ 'http://localhost:9200' ],
    secure          => 0,
    allow_insecure  => 1,
    pool_count      => 10,
    clear_attrs     => 0,
    async           => 0,
    max_connections => 10,
  );

  my $cluster = $opensearch->cluster;
  my $remote  = $opensearch->remote;
  my $search  = $opensearch->search;
  my $index   = $opensearch->index;
  my $document = $opensearch->document;

=head1 DESCRIPTION

C<OpenSearch> is an unofficial Perl client for OpenSearch (https://opensearch.org/).
Currently it only supports a subset of the OpenSearch API. However, it is a work in 
progress and more features will be added in the future. Currently, the following
endpoints are (partially) supported:

=over 4

=item * Cluster

=item * Remote

=item * Search

=item * Index

=item * Document

=back

=head1 IMPORTANT

This module is still in development and should not be used in production unless you
are willing to accept the risks associated with using an incomplete and untested
module. It heavily relies on L<Moose> and L<Mojo::UserAgent>. Due to the use of
L<Moose>, startup time is slower than other modules. However, the use of L<Mojo::UserAgent>
allows for asynchronous requests to be made to the OpenSearch server.

CERTIFICATE AUTHENTICATION IS NOT YET TESTED! Feel free to test it and report back to me.

=head1 METHODS

=head2 new

Creates a new instance of C<OpenSearch>.

=head2 cluster

Returns a new instance of C<OpenSearch::Cluster>.

=head2 remote

Returns a new instance of C<OpenSearch::Remote>.

=head2 search

Returns a new instance of C<OpenSearch::Search>.

=head2 index

Returns a new instance of C<OpenSearch::Index>.

=head2 document

Returns a new instance of C<OpenSearch::Document>.

=head1 ATTRIBUTES

=over 4

=item * user

The username to use when connecting to the OpenSearch server.

=item * pass

The password to use when connecting to the OpenSearch server.

=item * hosts

An array reference containing the hostnames of the OpenSearch server(s).

=item * secure

A boolean value indicating whether to use HTTPS when connecting to the OpenSearch server.

=item * allow_insecure

A boolean value indicating whether to allow insecure connections to the OpenSearch server.

=item * pool_count

The number of connections to pool when connecting to the OpenSearch server.

=item * clear_attrs

A boolean value indicating whether to clear the attributes of most objects.

=item * async

A boolean value indicating whether to use asynchronous requests when connecting to the OpenSearch server.
This will return a L<Mojo::Promise> object instead of the actual response.

=item * max_connections

The maximum number of connections to allow when connecting to the OpenSearch server (see L<Mojo::UserAgent>).

=item * ca_cert

The path to the CA certificate to use when connecting to the OpenSearch server.

=item * client_cert

The path to the client certificate to use when connecting to the OpenSearch server.

=item * client_key

The path to the client key to use when connecting to the OpenSearch server.

=back

=head1 CAVEATS

I am not affiliated with OpenSearch. This module is not officially supported by OpenSearch.

=head1 PERFORMANCE/BENCHMARK

If you need to make a lot of requests to the OpenSearch server, you should consider using
asynchronous requests in combination with the C<bulk> method of the C<OpenSearch::Document> class.
For benchmarking purposes, I have included scripts in the example directory.

=over 4

=item * C<benchmark-bulk-async.pl>

=item * C<benchmark-bulk-sync.pl>

=item * C<benchmark-index.pl>

=item * C<benchmark-index-async.pl>

=back

=head1 BENCHMARK RESULTS

These are the results from my local machine:

C<benchmark-bulk-async.pl> script:

  Pool count: 10
  Max connections: 50
  Bulk doc count: 500
  Count before: 0
  Count after: 234019
  Duration: 10.4876799583435
  Docs per second: 22313.7053122817

C<benchmark-bulk.pl> script:

  Pool count: 10
  Max connections: 50
  Bulk doc count: 500
  Count before: 0
  Count after: 92699
  Duration: 10.0426659584045
  Docs per second: 9230.51711407584

C<benchmark-index.pl> script:

  Pool count: 10
  Max connections: 50
  Count before: 0
  Count after: 1513
  Duration: 10.0066809654236
  Docs per second: 151.19898448126

C<benchmark-index-async.pl> script:

  Pool count: 10
  Max connections: 50
  Count before: 0
  Count after: 8614
  Duration: 10.0460240840912
  Docs per second: 857.453648119465
 

=head1 AUTHOR

C<OpenSearch> Perl Module was written by Sebastian Grenz, C<< <git at fail.ninja> >>

