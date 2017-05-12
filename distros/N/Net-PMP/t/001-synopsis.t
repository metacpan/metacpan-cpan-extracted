#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 35;
use Data::Dump qw( dump );

use_ok('Net::PMP::Client');
use_ok('Net::PMP::CollectionDoc');

# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

SKIP: {
    if ( !$ENV{PMP_CLIENT_ID} or !$ENV{PMP_CLIENT_SECRET} ) {
        diag "set PMP_CLIENT_ID and PMP_CLIENT_SECRET to test API";
        skip "set PMP_CLIENT_ID and PMP_CLIENT_SECRET to test API", 33;
    }

    # basic authn

    ok( my $client = Net::PMP::Client->new(
            host => ( $ENV{PMP_CLIENT_HOST} || 'https://api-sandbox.pmp.io' ),
            id => $ENV{PMP_CLIENT_ID},
            secret => $ENV{PMP_CLIENT_SECRET},
            debug  => $ENV{PMP_CLIENT_DEBUG},
        ),
        "new client"
    );

    ok( my $token = $client->get_token(), "get token" );

    cmp_ok( $token->expires_in, '>=', 10, 'token expires_in >= 10' );

    ok( $client->revoke_token(), "revoke_token" );

    # introspection

    ok( my $doc = $client->get_doc(), "client->get_doc()" );

    ok( my $query_rel_types = $doc->get_links('query')->query_rel_types(),
        "get query_rel_types for base endpoint" );

    #diag( dump($query_rel_types) );

    is_deeply(
        $query_rel_types,
        {   "urn:collectiondoc:hreftpl:docs"     => "Access documents",
            "urn:collectiondoc:hreftpl:profiles" => "Access profiles",
            "urn:collectiondoc:hreftpl:schemas"  => "Access schemas",
            "urn:collectiondoc:query:docs"       => "Query for documents",
            "urn:collectiondoc:query:groups"     => "Query for groups",
            "urn:collectiondoc:query:profiles"   => "Query for profiles",
            "urn:collectiondoc:query:schemas"    => "Query for schemas",
            "urn:collectiondoc:query:users"      => "Query for users",
            "urn:collectiondoc:hreftpl:topics"   => "Access topics",
            "urn:collectiondoc:hreftpl:users"    => "Access users",
            "urn:collectiondoc:query:topics"     => "Query for topics",
            "urn:collectiondoc:query:users"      => "Query for users",
            "urn:collectiondoc:query:collection" => "Query within collection",
        },
        "got expected rel types"
    );

    ok( my $query_options
            = $doc->query('urn:collectiondoc:query:docs')->options(),
        "query->options"
    );

    #diag( dump $query_options );

    is_deeply(
        $query_options,
        {   author           => "http://docs.pmp.io/wiki/Querying-the-API#author",
            collection       => "http://docs.pmp.io/wiki/Querying-the-API#collection",
            distributor      => "http://docs.pmp.io/wiki/Querying-the-API#distributor",
            distributorgroup => "http://docs.pmp.io/wiki/Querying-the-API#distributorgroup",
            enddate          => "http://docs.pmp.io/wiki/Querying-the-API#enddate",
            guid             => "http://docs.pmp.io/wiki/Querying-the-API#guid",
            has              => "http://docs.pmp.io/wiki/Querying-the-API#has",
            language         => "http://docs.pmp.io/wiki/Querying-the-API#language",
            limit            => "http://docs.pmp.io/wiki/Querying-the-API#limit",
            offset           => "http://docs.pmp.io/wiki/Querying-the-API#offset",
            profile          => "http://docs.pmp.io/wiki/Querying-the-API#profile",
            searchsort       => "http://docs.pmp.io/wiki/Querying-the-API#searchsort",
            startdate        => "http://docs.pmp.io/wiki/Querying-the-API#startdate",
            tag              => "http://docs.pmp.io/wiki/Querying-the-API#tag",
            text             => "http://docs.pmp.io/wiki/Querying-the-API#text",
            writeable        => "http://docs.pmp.io/wiki/Querying-the-API#writeable",
            creator          => "http://docs.pmp.io/wiki/Querying-the-API#creator",
            item             => "http://docs.pmp.io/wiki/Querying-the-API#item",
            owner            => "http://docs.pmp.io/wiki/Querying-the-API#owner",
            itag             => "http://docs.pmp.io/wiki/Querying-the-API#itag",
        },
        "got expected query options"
    );

    ############################################################################
    # search sample content

    ok( my $search_results
            = $client->search(
            { tag => 'samplecontent', profile => 'story' } ),
        "submit search"
    );
    ok( my $results = $search_results->get_items(),
        "get search_results->get_items()"
    );
    cmp_ok( $results->total, '>=', 2, ">= 2 results" );
    diag( 'total: ' . $results->total );
    while ( my $r = $results->next ) {

        #diag( dump $r );
        diag(
            sprintf( '%s: %s [%s]',
                $results->count, $r->get_uri, $r->get_title, )
        );
        ok( $r->get_uri,     "get uri" );
        ok( $r->get_title,   "get title" );
        ok( $r->get_profile, "get profile" );
    }

    ############################################################################
    # CRUD

    # start clean
    my $existing = $client->search( { tag => 'pmp_sdk_perl_testcontent' } );
    if ($existing) {
        my $items = $existing->get_items();
        while ( my $i = $items->next ) {
            diag( "cleaning up existing test document: " . $i->get_uri );
            $client->delete($i);
        }
    }

    ok( my $sample_doc = Net::PMP::CollectionDoc->new(
            version    => '1.0',
            attributes => {
                tags  => [qw( pmp_sdk_perl_testcontent )],
                title => 'i am a test document',
            },
            links => {
                profile => [ { href => $client->host . '/profiles/story' } ]
            },
        ),
        "create new sample doc"
    );

    # Create
    ok( $client->save($sample_doc), "save sample doc" );
    is( $client->last_response->code, 202, "save response was 202" );
    ok( $sample_doc->get_uri(),  "saved sample doc has uri" );
    ok( $sample_doc->get_guid(), "saved sample doc has guid" );

    # since create is 202, we try a few times while search index syncs ...
    # Read
    ok( $search_results = $client->get_doc( $sample_doc->get_uri(), 30 ),
        "GET " . $sample_doc->get_uri() );
    is( $client->last_response->code, 200, 'search response was 200' );
    is( $search_results->get_guid(),
        $sample_doc->get_guid(),
        "search results guid == sample doc guid"
    );

    # Update
    $sample_doc->attributes->{title} = 'i am a test document, redux';
    ok( $client->save($sample_doc), "update title" );
    is( $client->last_response->code, 202, "save response was 202" );
    ok( $search_results = $client->get_doc( $sample_doc->get_uri, 10 ),
        "re-fetch sample doc" );
    is( $search_results->get_title,
        $sample_doc->get_title, "search results title == sample doc title" );

    # Delete
    ok( $client->delete($sample_doc), "delete sample doc" );
    is( $client->last_response->code, 204, "delete response was 204" );

    # 204 response means it will be deleted, eventually.
    # until doc is actually deleted, will return a 400,
    # so delay a little to avoid that.
    sleep(3);
    ok( !$client->get_doc( $sample_doc->get_uri ),
        "get_doc() for sample now empty"
    );
}
