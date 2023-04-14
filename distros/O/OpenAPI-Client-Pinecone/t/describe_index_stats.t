#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Mojo::JSON qw(decode_json);
use Data::Dumper;

BEGIN {
    if ( !$ENV{PINECONE_API_KEY} || !$ENV{PINECONE_ENVIRONMENT} ) {
        plan skip_all => 'PINECONE_API_KEY and PINECONE_ENVIRONMENT environment variables must be set to run this test';
    }
}

use_ok('OpenAPI::Client::Pinecone');

my $client = OpenAPI::Client::Pinecone->new();

isa_ok( $client, 'OpenAPI::Client::Pinecone' );

# Test list_collections method
my $transaction = $client->describe_index_stats();
isa_ok( $transaction, 'Mojo::Transaction::HTTP' );

my $res = $transaction->res();
isa_ok( $res, 'Mojo::Message::Response' );

my $data = decode_json( $res->body );
isa_ok( $data, 'HASH' );    # error

done_testing();
