[![Actions Status](https://github.com/localh0rst/OpenSearch-Perl/actions/workflows/test.yml/badge.svg)](https://github.com/localh0rst/OpenSearch-Perl/actions)
# NAME

`OpenSearch` - Unofficial Perl client for OpenSearch (https://opensearch.org/)

# SYNOPSIS

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

# DESCRIPTION

`OpenSearch` is an unofficial Perl client for OpenSearch (https://opensearch.org/).
Currently it only supports a subset of the OpenSearch API. However, it is a work in 
progress and more features will be added in the future. Currently, the following
endpoints are (partially) supported:

- Cluster
- Remote
- Search
- Index
- Document

# IMPORTANT

This module is still in development and should not be used in production unless you
are willing to accept the risks associated with using an incomplete and untested
module. It heavily relies on [Moose](https://metacpan.org/pod/Moose) and [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent). Due to the use of
[Moose](https://metacpan.org/pod/Moose), startup time is slower than other modules. However, the use of [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent)
allows for asynchronous requests to be made to the OpenSearch server.

CERTIFICATE AUTHENTICATION IS NOT YET TESTED! Feel free to test it and report back to me.

# METHODS

## new

Creates a new instance of `OpenSearch`.

## cluster

Returns a new instance of `OpenSearch::Cluster`.

## remote

Returns a new instance of `OpenSearch::Remote`.

## search

Returns a new instance of `OpenSearch::Search`.

## index

Returns a new instance of `OpenSearch::Index`.

## document

Returns a new instance of `OpenSearch::Document`.

# ATTRIBUTES

- user

    The username to use when connecting to the OpenSearch server.

- pass

    The password to use when connecting to the OpenSearch server.

- hosts

    An array reference containing the hostnames of the OpenSearch server(s).

- secure

    A boolean value indicating whether to use HTTPS when connecting to the OpenSearch server.

- allow\_insecure

    A boolean value indicating whether to allow insecure connections to the OpenSearch server.

- pool\_count

    The number of connections to pool when connecting to the OpenSearch server.

- clear\_attrs

    A boolean value indicating whether to clear the attributes of most objects.

- async

    A boolean value indicating whether to use asynchronous requests when connecting to the OpenSearch server.
    This will return a [Mojo::Promise](https://metacpan.org/pod/Mojo%3A%3APromise) object instead of the actual response.

- max\_connections

    The maximum number of connections to allow when connecting to the OpenSearch server (see [Mojo::UserAgent](https://metacpan.org/pod/Mojo%3A%3AUserAgent)).

- ca\_cert

    The path to the CA certificate to use when connecting to the OpenSearch server.

- client\_cert

    The path to the client certificate to use when connecting to the OpenSearch server.

- client\_key

    The path to the client key to use when connecting to the OpenSearch server.

# CAVEATS

I am not affiliated with OpenSearch. This module is not officially supported by OpenSearch.
If speed is a concern, you may want to consider using a different module (or maybe language).
Using 'async' while also using 'max\_connections' and 'pool\_count' will result in better performance.

Using the following options:

    async           => 1,
    pool_count      => 10,
    max_connections => 50,

will result in around 1000 requests per second (on my machine). However, using the following options:

    async           => 0,
    pool_count      => 10,
    max_connections => 50,

will result in a maximum of around 200 requests per second (on my machine). This was tested using

    $os->document->index();

with a small test-document:

    {
      test    => 'test',
      test1   => 'test1',
      nesting => {
        test  => 'test',
        test1 => 'test1',
        test2 => [ 
          { 
            wurst => '123' 
          }, 
          { 
            asd => [ 1, 2, 3, 4 ] 
          } 
        ]
      }
    }

# AUTHOR

`OpenSearch` Perl Module was written by Sebastian Grenz, `<git at fail.ninja>`
