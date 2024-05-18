[![Actions Status](https://github.com/localh0rst/OpenSearch-Perl/actions/workflows/test.yml/badge.svg)](https://github.com/localh0rst/OpenSearch-Perl/actions)
# NAME

`OpenSearch` - A Perl client for OpenSearch (https://opensearch.org/)

# SYNOPSIS

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

# DESCRIPTION

This module is a Perl client for OpenSearch (https://opensearch.org/).
It currently only supports a small subset of the OpenSearch API.

# ATTRIBUTES

## user

The username to use for authentication

## pass

The password to use for authentication

## hosts

An arrayref of hosts to connect to

## secure

Boolean to indicate if the connection should be secure (https)

## allow\_insecure

Boolean to indicate if insecure connections are allowed

## pool\_count

The number of connections to pool

## clear\_attrs

Boolean to indicate if attributes should be cleared after a request.
By default this is set to false. Usualy all attributes are cached in
the class instance and will be reused for the next request. Switch
this to 1 if you want to clear all attributes after a request. Another
possibility is to create a new instance of the class for each request.

# METHODS

## cluster

returns a new OpenSearch::Cluster object

    my $cluster = $opensearch->cluster;

## cluster\_allocation

returns a new OpenSearch::Cluster::Allocation object

    my $cluster = $opensearch->cluster_allocation;

## cluster\_health

returns a new OpenSearch::Cluster::Health object

    my $cluster = $opensearch->cluster_health;

## cluster\_settings

returns a new OpenSearch::Cluster::Settings object

    my $cluster = $opensearch->cluster_settings;

## cluster\_stats

returns a new OpenSearch::Cluster::Stats object

    my $cluster = $opensearch->cluster_stats;

## remote

returns a new OpenSearch::Remote object

    my $remote = $opensearch->remote;

## remote\_info

returns a new OpenSearch::Remote::Info object

    my $remote = $opensearch->remote_info;

## search

returns a new OpenSearch::Search object

    my $search = $opensearch->search;

# LICENSE

Copyright (C) localh0rst.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

localh0rst <git@fail.ninja>
