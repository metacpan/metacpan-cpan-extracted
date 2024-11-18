#!/usr/bin/env perl

use 5.016;    # minimum version OpenAPI::Client supports
use strict;
use warnings;
use lib 'lib';
use OpenAPI::Client::OpenAI;
use Data::Printer;
use JSON::XS qw( decode_json );
use Feature::Compat::Try;

my $client = OpenAPI::Client::OpenAI->new;

# Get a single embedding
my $response = $client->createEmbedding(
    {
        body => {
            input => "This is my text",
            model => "text-embedding-3-small"
        }
    },
);

if ( $response->res->is_success ) {
    try {
        my $result    = decode_json( $response->res->content->asset->slurp );
        my $embedding = $result->{data}[0]{embedding};
        p $embedding;
    } catch ($e) {
        die "Error decoding JSON: $e\n";
    }
} else {
    my $res = $response->res;
    p $res;
}

# Get multiple embeddings
$response = $client->createEmbedding(
    {
        body => {
            input => [ "This is my text", "This is another text" ],
            model => "text-embedding-3-small"
        }
    },
);

if ( $response->res->is_success ) {
    try {
        my $result = decode_json( $response->res->content->asset->slurp );
        my $data   = $result->{data};
        foreach my $item (@$data) {
            p $item->{embedding};
        }
    } catch ($e) {
        die "Error decoding JSON: $e\n";
    }
} else {
    my $res = $response->res;
    p $res;
}

__END__

=head1 NAME

get-embeddings.pl - Get embeddings from the OpenAI API

=head1 SYNOPSIS

    perl get-embeddings.pl

=head1 DESCRIPTION

When working with LLMs, strings are first tokenized and then converted into
embeddings. Sometimes, when working with other tools, they expect embeddings
instead of the strings. This script demonstrates how to get embeddings from
the OpenAI API using the `createEmbedding` method.

=head1 MODELS

=over 4

=item * text-embedding-3-small

This model is the most cost-effective, optimized for latency and storage. This is
5x cheaper than text-embedding-ada-002 ($0.00002 per 1k tokens).

1536 dimensions

=item * text-embedding-3-large

This model is priced higher and is best suited for tasks requiring high accuracy.

$0.00013 per 1k tokens.

Up to 3072 dimensions

=item * text-embedding-ada-002

This model falls between the two in terms of pricing.

$0.0001 per 1k tokens.

1536 dimensions

=back
