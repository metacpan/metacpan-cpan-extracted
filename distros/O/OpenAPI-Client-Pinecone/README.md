# NAME

OpenAPI::Client::Pinecone - A client for the Pinecone API

# SYNOPSIS

    use OpenAPI::Client::Pinecone;

    my $client = OpenAPI::Client::Pinecone->new(); # see ENVIRONMENT VARIABLES

    my $tx = $client->list_collections();

    my $response_data = $tx->res->json;

    #print Dumper($response_data);

# DESCRIPTION

OpenAPI::Client::Pinecone is a client for the Pinecone API built on
top of [OpenAPI::Client](https://metacpan.org/pod/OpenAPI%3A%3AClient). This module automatically handles the API
key authentication and sets the base URL according to the provided
environment.

# METHODS

## Constructor

### new

    my $client = OpenAPI::Client::Pinecone->new( $specification, %options );

Create a new Pinecone API client. The following options can be provided:

- `$specification`

    The path to the OpenAPI specification file (YAML). Defaults to the
    "pinecone.yaml" file in the distribution's "share" directory.

    Note: this is a reverse engineered specification, available
    [here](https://github.com/sigpwned/pinecone-openapi-spec).

- `%options`
    - base\_url

        The base URL for the Pinecone API. Defaults to
        "https://controller.$ENV{PINECONE\_ENVIRONMENT}.pinecone.io".

Additional options are passed to the parent class, OpenAPI::Client.

## Index Operations

### list\_collections

List collections. This operation returns a list of your Pinecone
collections.

### create\_collection

Create collection. This operation creates a Pinecone collection.

### describe\_collection

Describe collection. Get a description of a collection.

### delete\_collection

Delete Collection. This operation deletes an existing collection.

### list\_indexes

List indexes. This operation returns a list of your Pinecone indexes.

### create\_index

Create index. This operation creates a Pinecone index.

### describe\_index

Describe index. Get a description of an index.

### delete\_index

Delete Index. This operation deletes an existing index.

### configure\_index

Configure index. This operation specifies the pod type and number of
replicas for an index.

## Vector Operations

### describe\_index\_stats

Describe Index Stats. The \`DescribeIndexStats\` operation returns
statistics about the index's contents, including the vector count per
namespace and the number of dimensions.

### query

Query. The \`Query\` operation searches a namespace, using a query
vector. It retrieves the ids of the most similar items in a namespace,
along with their similarity scores.

### delete\_vector

Delete. The \`Delete\` operation deletes vectors, by id, from a single
namespace. You can delete items by their id, from a single namespace.

### fetch\_vector

Fetch. The \`Fetch\` operation looks up and returns vectors, by ID,
from a single namespace. The returned vectors include the vector data
and/or metadata.

### update\_vector

Update. The \`Update\` operation updates vector in a namespace. If a value
is included, it will overwrite the previous value. If a set\_metadata
is included, the values of the fields specified in it will be added or
overwrite the previous value.

### upsert\_vector

Upsert. The Upsert operation writes vectors into a namespace. If a
new value is upserted for an existing vector id, it will overwrite the
previous value.

# ENVIRONMENT VARIABLES

The following environment variables are used by this module:

- PINECONE\_API\_KEY

    The API key used to authenticate requests to the Pinecone API.

- PINECONE\_ENVIRONMENT

    The environment for the Pinecone API. The environment is used to build the base URL.

# SEE ALSO

[OpenAPI::Client](https://metacpan.org/pod/OpenAPI%3A%3AClient)

# AUTHOR

Nelson Ferraz, <nferraz@gmail.com>

# COPYRIGHT AND LICENSE

Copyright (C) 2023 by Nelson Ferraz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.0 or,
at your option, any later version of Perl 5 you may have available.
