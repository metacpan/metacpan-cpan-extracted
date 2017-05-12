#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 50;
use Data::Dump qw( dump );

use_ok('Net::PMP::Client');
use_ok('Net::PMP::CollectionDoc');

# http://code.google.com/p/test-more/issues/detail?id=46
binmode Test::More->builder->output,         ":utf8";
binmode Test::More->builder->failure_output, ":utf8";

sub clean_up_test_docs {
    my $client = shift or die "client required";
    for my $profile (qw( story organization user group )) {
        my $authz_test = $client->search(
            {   profile => $profile,
                text    => 'pmp_sdk_perl',
                limit   => 100,
            }
        );
        if ($authz_test) {
            my $prev_test = $authz_test->get_items();
            while ( my $item = $prev_test->next ) {
                diag( "cleaning up $profile " . $item->get_uri );
                $client->delete($item);
            }
        }
    }
}

SKIP: {
    if ( !$ENV{PMP_CLIENT_ID} or !$ENV{PMP_CLIENT_SECRET} ) {
        diag "set PMP_CLIENT_ID and PMP_CLIENT_SECRET to test API";
        skip "set PMP_CLIENT_ID and PMP_CLIENT_SECRET to test API", 48;
    }

    # create client
    ok( my $client = Net::PMP::Client->new(
            host => ( $ENV{PMP_CLIENT_HOST} || 'https://api-sandbox.pmp.io' ),
            id => $ENV{PMP_CLIENT_ID},
            secret => $ENV{PMP_CLIENT_SECRET},
            debug  => $ENV{PMP_CLIENT_DEBUG},
        ),
        "new client"
    );

    # clean up any previous false runs
    clean_up_test_docs($client);
    if ( $ENV{PMP_CLIENT_CLEAN} ) {
        exit(0);
    }

    # create 3 orgs
    my $org1_pass = Net::PMP::CollectionDoc->create_guid();
    my $org2_pass = Net::PMP::CollectionDoc->create_guid();
    my $org3_pass = Net::PMP::CollectionDoc->create_guid();
    ok( my $org1 = Net::PMP::CollectionDoc->new(
            href       => $client->uri_for_doc($org1_pass),
            version    => $client->get_doc->version,
            attributes => {
                tags  => [qw( pmp_sdk_perl_test_authz )],
                title => 'pmp_sdk_perl test org1',
                auth  => {
                    user     => 'pmp_sdk_perl-org1',
                    password => $org1_pass,
                    scope    => 'write',
                },
                guid => $org1_pass,
            },
            links => {
                profile => [ { href => $client->uri_for_profile('user') } ],
            },
        ),
        "create org1"
    );
    ok( $client->save($org1), "save org1" );
    ok( my $org2 = Net::PMP::CollectionDoc->new(
            href       => $client->uri_for_doc($org2_pass),
            version    => $client->get_doc->version,
            attributes => {
                tags  => [qw( pmp_sdk_perl_test_authz )],
                title => 'pmp_sdk_perl test org2',
                auth  => {
                    user     => 'pmp_sdk_perl-org2',
                    password => $org2_pass,
                },
                guid => $org2_pass,
            },
            links => {
                profile => [ { href => $client->uri_for_profile('user') } ]
            },
        ),
        "create org2"
    );
    ok( $client->save($org2), "save org2" );
    ok( my $org3 = Net::PMP::CollectionDoc->new(
            href       => $client->uri_for_doc($org3_pass),
            version    => $client->get_doc->version,
            attributes => {
                tags  => [qw( pmp_sdk_perl_test_authz )],
                title => 'pmp_sdk_perl test org3',
                auth  => {
                    user     => 'pmp_sdk_perl-org3',
                    password => $org3_pass,
                },
                guid => $org3_pass,
            },
            links => {
                profile => [ { href => $client->uri_for_profile('user') } ]
            },
        ),
        "create org3"
    );
    ok( $client->save($org3), "save org3" );

    # create groups
    my $group_guid = '7ea494e0-a279-4d3f-bd36-bbc649c98733';
    ok( my $group = Net::PMP::CollectionDoc->new(
            href       => $client->uri_for_doc($group_guid),
            version    => $client->get_doc->version,
            attributes => {
                title => 'pmp_sdk_perl permission group',
                tags  => [qw( pmp_sdk_perl_test_authz )],
                guid  => $group_guid,
            },
            links => {
                profile => [ { href => $client->uri_for_profile('group') } ]
            },
        ),
        "create group"
    );
    ok( $group->add_item($org1), "add org1 to group" );
    ok( $group->add_item($org2), "add org2 to group" );
    ok( $client->save($group),   "save group" );

    # group2 with just org1
    my $group2_guid = '2137e7b1-ff10-4961-afa0-a31b7ad98d31';
    ok( my $group2 = Net::PMP::CollectionDoc->new(
            href       => $client->uri_for_doc($group2_guid),
            version    => $client->get_doc->version,
            attributes => {
                title => 'pmp_sdk_perl permission group2',
                tags  => [qw( pmp_sdk_perl_test_authz )],
                guid  => $group2_guid,
            },
            links => {
                profile => [ { href => $client->uri_for_profile('group') } ]
            },
        ),
        "create group2"
    );
    ok( $group2->add_item($org1), "add org1 to group2" );
    ok( $client->save($group2),   "save group2" );

    # group3 with just org2
    my $group3_guid = '249b4afd-4df5-4838-a9c9-00fd2f906b11';
    ok( my $group3 = Net::PMP::CollectionDoc->new(
            href       => $client->uri_for_doc($group3_guid),
            version    => $client->get_doc->version,
            attributes => {
                title => 'pmp_sdk_perl permission group3',
                tags  => [qw( pmp_sdk_perl_test_authz )],
                guid  => $group3_guid,
            },
            links => {
                profile => [ { href => $client->uri_for_profile('group') } ]
            },
        ),
        "create group3"
    );
    ok( $group3->add_item($org2), "add org2 to group3" );
    ok( $client->save($group3),   "save group3" );

    # create an empty group
    my $empty_group_guid = 'a2649d7f-d042-4c73-a968-e30dac66712c';
    ok( my $empty_group = Net::PMP::CollectionDoc->new(
            href       => $client->uri_for_doc($empty_group_guid),
            version    => $client->get_doc->version,
            attributes => {
                title => 'pmp_sdk_perl permission group empty',
                tags  => [qw( pmp_sdk_perl_test_authz )],
                guid  => $empty_group_guid,
            },
            links => {
                profile => [ { href => $client->uri_for_profile('group') } ]
            },
        ),
        "create empty group"
    );
    ok( $client->save($empty_group), "save empty_group" );

    # add fixture docs
    my $doc1_guid = Net::PMP::CollectionDoc->create_guid();
    ok( my $sample_doc1 = Net::PMP::CollectionDoc->new(
            href       => $client->uri_for_doc($doc1_guid),
            version    => $client->get_doc->version,
            attributes => {
                tags => [qw( pmp_sdk_perl_test_authz pmp_sdk_perl_test_doc )],
                title => 'pmp_sdk_perl i am a test document one',
                guid  => $doc1_guid,
            },
            links => {
                profile => [ { href => $client->uri_for_profile('story') } ],
                permission =>
                    [ { href => $group->get_uri(), operation => 'read', }, ],
            },
        ),
        "create new sample doc1"
    );
    ok( $client->save($sample_doc1), "save sample doc1" );

    my $doc2_guid = Net::PMP::CollectionDoc->create_guid();
    ok( my $sample_doc2 = Net::PMP::CollectionDoc->new(
            href       => $client->uri_for_doc($doc2_guid),
            version    => $client->get_doc->version,
            attributes => {
                tags => [qw( pmp_sdk_perl_test_authz pmp_sdk_perl_test_doc )],
                title => 'pmp_sdk_perl i am a test document two',
                guid  => $doc2_guid,
            },
            links => {
                profile => [ { href => $client->uri_for_profile('story') } ],
                permission => [
                    {   href      => $group3->get_uri(),
                        operation => 'read',
                        blacklist => \1,
                    },
                    { href => $group2->get_uri(), operation => 'read', },
                ],
            },
        ),
        "create new sample doc2"
    );
    ok( $client->save($sample_doc2), "save sample doc2" );

    my $doc3_guid = Net::PMP::CollectionDoc->create_guid();
    ok( my $sample_doc3 = Net::PMP::CollectionDoc->new(
            href       => $client->uri_for_doc($doc3_guid),
            version    => $client->get_doc->version,
            attributes => {
                tags => [qw( pmp_sdk_perl_test_authz pmp_sdk_perl_test_doc )],
                title => 'pmp_sdk_perl i am a test document three',
                guid  => $doc3_guid,
            },
            links => {
                profile => [ { href => $client->uri_for_profile('story') } ]
            },
        ),
        "create new sample doc3"
    );
    ok( $client->save($sample_doc3), "save sample doc3" );

    # private doc should be visible only to original $client
    my $private_doc_guid = Net::PMP::CollectionDoc->create_guid();
    ok( my $private_doc = Net::PMP::CollectionDoc->new(
            href       => $client->uri_for_doc($private_doc_guid),
            version    => $client->get_doc->version,
            attributes => {
                tags => [qw( pmp_sdk_perl_test_authz pmp_sdk_perl_test_doc )],
                title => 'pmp_sdk_perl i am a test document private',
                guid  => $private_doc_guid,
            },
            links => {
                profile => [ { href => $client->uri_for_profile('story') } ],
                permission => [
                    {   "href"      => $empty_group->get_uri(),
                        "operation" => "read",
                    }
                ]
            },
        ),
        "create new private doc"
    );
    ok( $client->save($private_doc), "save private doc" );

    # fixtures all in place
    # now create credentials and client for orgs
    ok( my $org1_creds = $client->create_credentials(
            username => $org1->attributes->{auth}->{user},
            password => $org1_pass,
        ),
        "create org1 credentials"
    );
    ok( my $org2_creds = $client->create_credentials(
            username => $org2->attributes->{auth}->{user},
            password => $org2_pass,
        ),
        "create org2 credentials"
    );
    ok( my $org3_creds = $client->create_credentials(
            username => $org3->attributes->{auth}->{user},
            password => $org3_pass,
        ),
        "create org3 credentials"
    );

    sleep(2);    # give 202 responses time to catch up

    ok( my $org1_client = Net::PMP::Client->new(
            id     => $org1_creds->client_id,
            secret => $org1_creds->client_secret,
            debug  => $client->debug,
        ),
        "create org1 client"
    );
    ok( my $org2_client = Net::PMP::Client->new(
            id     => $org2_creds->client_id,
            secret => $org2_creds->client_secret,
            debug  => $client->debug,
        ),
        "create org2 client"
    );
    ok( my $org3_client = Net::PMP::Client->new(
            id     => $org3_creds->client_id,
            secret => $org3_creds->client_secret,
            debug  => $client->debug,
        ),
        "create org3 client"
    );

    # sandbox can have some delay in sync
    diag("sleeping a few seconds to let the server search sync with db...");
    sleep(20);

    # org1 should see doc1, doc2, doc3
    # org2 should see doc1, doc3
    # org3 should see doc3
    ok( my $org1_res
            = $org1_client->search( { tag => 'pmp_sdk_perl_test_doc' }, 10 ),
        "org1 search"
    );
    ok( my $org2_res
            = $org2_client->search( { tag => 'pmp_sdk_perl_test_doc' }, 10 ),
        "org2 search"
    );
    ok( my $org3_res
            = $org3_client->search( { tag => 'pmp_sdk_perl_test_doc' }, 10 ),
        "org3 search"
    );
    is( $org1_res->has_items, 3, "org1 has 3 items" );
    is( $org2_res->has_items, 2, "org2 has 2 items" );
    is( $org3_res->has_items, 1, "org3 has 1 item" );

    #diag( dump $org1_res );
    #diag( dump $org2_res );
    #diag( dump $org3_res );

    ok( my $org1_res_items = $org1_res->get_items(),
        'get org1 search items' );
    ok( my $org2_res_items = $org2_res->get_items(),
        'get org2 search items' );
    ok( my $org3_res_items = $org3_res->get_items(),
        'get org3 search items' );

    while ( my $r = $org1_res_items->next ) {
        diag( sprintf( "org1: [%s] %s", $r->get_title(), $r->get_uri() ) );
        like(
            $r->get_title,
            qr/i am a test document (one|two|three)$/,
            "org1 result for " . $r->get_title()
        );
    }
    while ( my $r = $org2_res_items->next ) {
        diag( sprintf( "org2: [%s] %s", $r->get_title(), $r->get_uri() ) );
        like(
            $r->get_title,
            qr/i am a test document (one|three)$/,
            "org2 result for " . $r->get_title()
        );
    }
    while ( my $r = $org3_res_items->next ) {
        diag( sprintf( "org3: [%s] %s", $r->get_title(), $r->get_uri() ) );
        like(
            $r->get_title,
            qr/i am a test document three$/,
            "org3 result for " . $r->get_title()
        );
    }

    clean_up_test_docs($client);
}

