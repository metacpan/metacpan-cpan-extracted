package OpenAPI::Client::Pinecone;

use strict;
use warnings;

use Carp;
use File::ShareDir ':ALL';
use File::Spec::Functions qw(catfile);

use Mojo::Base 'OpenAPI::Client';
use Mojo::URL;

our $VERSION = '0.03';

sub new {
    my ( $class, $specification ) = ( shift, shift );
    my $attrs = @_ == 1 ? shift : {@_};

    if ( !$ENV{PINECONE_API_KEY} ) {
        Carp::croak('PINECONE_API_KEY environment variable must be set');
    }

    if ( !$ENV{PINECONE_API_KEY} && !$attrs->{base_url} ) {
        Carp::croak('PINECONE_API_KEY environment variable must be set');
    }

    if ( !$specification ) {
        eval {
            $specification = dist_file( 'OpenAPI-Client-Pinecone', 'pinecone.yaml' );
            1;
        } or do {
            # Fallback to local share directory during development
            warn $@;
            $specification = catfile( 'share', 'pinecone.yaml' );
        };
    }

    my $self = $class->SUPER::new( $specification, %{$attrs} );

    $self->ua->on(
        start => sub {
            my ( $ua, $tx ) = @_;
            $tx->req->headers->header( 'Api-Key' => $ENV{PINECONE_API_KEY} );
        }
    );

    if ( !$attrs->{base_url} ) {
        $self->base_url( Mojo::URL->new("https://controller.$ENV{PINECONE_ENVIRONMENT}.pinecone.io") );
    }

    return $self;
}

# install snake case aliases

{
    my %snake_case_alias = (
        DescribeIndexStats => 'describe_index_stats',
        Query              => 'query',
        Delete             => 'delete_vector',
        Fetch              => 'fetch_vector',
        Update             => 'update_vector',
        Upsert             => 'upsert_vector',
    );

    for my $camel_case_method ( keys %snake_case_alias ) {
        no strict 'refs';
        *{"$snake_case_alias{$camel_case_method}"} = sub {
            my $self = shift;
            $self->$camel_case_method(@_);
        }
    }
}

1;

__END__

=head1 NAME

OpenAPI::Client::Pinecone - A client for the Pinecone API

=head1 SYNOPSIS

  use OpenAPI::Client::Pinecone;

  my $client = OpenAPI::Client::Pinecone->new(); # see ENVIRONMENT VARIABLES

  my $tx = $client->list_collections();

  my $response_data = $tx->res->json;

  #print Dumper($response_data);

=head1 DESCRIPTION

OpenAPI::Client::Pinecone is a client for the Pinecone API built on
top of L<OpenAPI::Client>. This module automatically handles the API
key authentication and sets the base URL according to the provided
environment.

=head1 METHODS

=head2 Constructor

=head3 new

    my $client = OpenAPI::Client::Pinecone->new( $specification, %options );

Create a new Pinecone API client. The following options can be provided:

=over

=item * C<$specification>

The path to the OpenAPI specification file (YAML). Defaults to the
"pinecone.yaml" file in the distribution's "share" directory.

Note: this is a reverse engineered specification, available
L<here|https://github.com/sigpwned/pinecone-openapi-spec>.

=item * C<%options>

=over

=item * base_url

The base URL for the Pinecone API. Defaults to
"https://controller.$ENV{PINECONE_ENVIRONMENT}.pinecone.io".

=back

=back

Additional options are passed to the parent class, OpenAPI::Client.

=head2 Index Operations

=head3 list_collections

List collections. This operation returns a list of your Pinecone
collections.

=head3 create_collection

Create collection. This operation creates a Pinecone collection.

=head3 describe_collection

Describe collection. Get a description of a collection.

=head3 delete_collection

Delete Collection. This operation deletes an existing collection.

=head3 list_indexes

List indexes. This operation returns a list of your Pinecone indexes.

=head3 create_index

Create index. This operation creates a Pinecone index.

=head3 describe_index

Describe index. Get a description of an index.

=head3 delete_index

Delete Index. This operation deletes an existing index.

=head3 configure_index

Configure index. This operation specifies the pod type and number of
replicas for an index.

=head2 Vector Operations

=head3 describe_index_stats

Describe Index Stats. The `DescribeIndexStats` operation returns
statistics about the index's contents, including the vector count per
namespace and the number of dimensions.

=head3 query

Query. The `Query` operation searches a namespace, using a query
vector. It retrieves the ids of the most similar items in a namespace,
along with their similarity scores.

=head3 delete_vector

Delete. The `Delete` operation deletes vectors, by id, from a single
namespace. You can delete items by their id, from a single namespace.

=head3 fetch_vector

Fetch. The `Fetch` operation looks up and returns vectors, by ID,
from a single namespace. The returned vectors include the vector data
and/or metadata.

=head3 update_vector

Update. The `Update` operation updates vector in a namespace. If a value
is included, it will overwrite the previous value. If a set_metadata
is included, the values of the fields specified in it will be added or
overwrite the previous value.

=head3 upsert_vector

Upsert. The Upsert operation writes vectors into a namespace. If a
new value is upserted for an existing vector id, it will overwrite the
previous value.

=head1 ENVIRONMENT VARIABLES

The following environment variables are used by this module:

=over 4

=item * PINECONE_API_KEY

The API key used to authenticate requests to the Pinecone API.

=item * PINECONE_ENVIRONMENT

The environment for the Pinecone API. The environment is used to build the base URL.

=back

=head1 SEE ALSO

L<OpenAPI::Client>

=head1 AUTHOR

Nelson Ferraz, E<lt>nferraz@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2023 by Nelson Ferraz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
