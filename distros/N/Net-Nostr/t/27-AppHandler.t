#!/usr/bin/perl

# Unit tests for Net::Nostr::AppHandler
# Tests every code example in the POD

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON ();

use Net::Nostr::AppHandler;
use Net::Nostr::Event;

my $JSON = JSON->new->utf8;

my $pubkey = 'aa' x 32;
my $app_pk = 'bb' x 32;

###############################################################################
# SYNOPSIS examples
###############################################################################

subtest 'SYNOPSIS: recommend an app' => sub {
    my $event = Net::Nostr::AppHandler->recommendation(
        pubkey     => $pubkey,
        event_kind => '31337',
        apps       => [
            {
                coordinate => "31990:$app_pk:zapstr",
                relay      => 'wss://relay.example.com',
                platform   => 'web',
            },
        ],
    );
    is($event->kind, 31989, 'kind 31989');
    is($event->d_tag, '31337', 'd tag');
};

subtest 'SYNOPSIS: publish handler information' => sub {
    my $handler = Net::Nostr::AppHandler->handler(
        pubkey     => $app_pk,
        identifier => 'zapstr',
        kinds      => ['31337'],
        content    => '{"name":"Zapstr","picture":"https://example.com/icon.png"}',
        platforms  => [
            { platform => 'web', url => 'https://zapstr.live/a/<bech32>', entity => 'nevent' },
            { platform => 'web', url => 'https://zapstr.live/p/<bech32>', entity => 'nprofile' },
            { platform => 'ios', url => 'com.zapstr:///<bech32>' },
        ],
    );
    is($handler->kind, 31990, 'kind 31990');
    is($handler->d_tag, 'zapstr', 'd tag');
};

subtest 'SYNOPSIS: client tag' => sub {
    my $tag = Net::Nostr::AppHandler->client_tag(
        name       => 'My Client',
        coordinate => "31990:$app_pk:my-client",
        relay      => 'wss://relay1',
    );
    is($tag->[0], 'client', 'tag name');
    is($tag->[1], 'My Client', 'client name');
};

subtest 'SYNOPSIS: from_event' => sub {
    my $event = Net::Nostr::AppHandler->recommendation(
        pubkey     => $pubkey,
        event_kind => '31337',
        apps       => [],
    );
    my $info = Net::Nostr::AppHandler->from_event($event);
    is($info->event_kind, '31337', 'event_kind');
};

subtest 'SYNOPSIS: recommendation_filter' => sub {
    my $filter = Net::Nostr::AppHandler->recommendation_filter(
        event_kind => '31337',
        authors    => [$pubkey],
    );
    is($filter->{kinds}, [31989], 'filter kinds');
};

###############################################################################
# client_tag POD example: embedding in an event
###############################################################################

subtest 'client_tag: embedding in event' => sub {
    my $tag = Net::Nostr::AppHandler->client_tag(
        name       => 'My Client',
        coordinate => "31990:$app_pk:my-client",
        relay      => 'wss://relay1',
    );
    my $event = Net::Nostr::Event->new(
        kind    => 1,
        pubkey  => $pubkey,
        content => 'Hello!',
        tags    => [$tag],
    );
    my @client = grep { $_->[0] eq 'client' } @{$event->tags};
    is(scalar @client, 1, 'one client tag');
    is($client[0][1], 'My Client', 'client name in event');
};

###############################################################################
# Accessor POD examples
###############################################################################

subtest 'accessor: event_kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $pubkey, kind => 31989, content => '',
        created_at => 1000, tags => [['d', '31337']],
    );
    my $info = Net::Nostr::AppHandler->from_event($event);
    is($info->event_kind, '31337', 'event_kind from d tag');
};

subtest 'accessor: apps' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $pubkey, kind => 31989, content => '',
        created_at => 1000,
        tags => [
            ['d', '31337'],
            ['a', "31990:$app_pk:id", 'wss://relay', 'web'],
        ],
    );
    my $info = Net::Nostr::AppHandler->from_event($event);
    is($info->apps->[0]{coordinate}, "31990:$app_pk:id", 'app coordinate');
    is($info->apps->[0]{relay}, 'wss://relay', 'app relay');
    is($info->apps->[0]{platform}, 'web', 'app platform');
};

subtest 'accessor: kinds' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $app_pk, kind => 31990, content => '',
        created_at => 1000,
        tags => [['d', 'h'], ['k', '31337'], ['k', '30023']],
    );
    my $info = Net::Nostr::AppHandler->from_event($event);
    is($info->kinds, ['31337', '30023'], 'kinds from k tags');
};

subtest 'accessor: content' => sub {
    my $meta = '{"name":"Zapstr"}';
    my $event = Net::Nostr::Event->new(
        pubkey => $app_pk, kind => 31990, content => $meta,
        created_at => 1000, tags => [['d', 'h'], ['k', '1']],
    );
    my $info = Net::Nostr::AppHandler->from_event($event);
    is($info->content, $meta, 'content preserved');
};

subtest 'accessor: platforms' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $app_pk, kind => 31990, content => '',
        created_at => 1000,
        tags => [
            ['d', 'h'], ['k', '1'],
            ['web', 'https://app.com/<bech32>', 'nevent'],
        ],
    );
    my $info = Net::Nostr::AppHandler->from_event($event);
    is($info->platforms->[0]{platform}, 'web', 'platform');
    is($info->platforms->[0]{url}, 'https://app.com/<bech32>', 'url');
    is($info->platforms->[0]{entity}, 'nevent', 'entity');
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $info = Net::Nostr::AppHandler->new(
        event_kind => '31337',
        apps       => [],
        kinds      => [1, 30023],
    );
    is $info->event_kind, '31337';
    is $info->apps, [];
    is $info->kinds, [1, 30023];
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::AppHandler->new(
            event_kind => '31337',
            apps       => [],
            bogus      => 'value',
        ) },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

###############################################################################
# client_tag validation
###############################################################################

subtest 'client_tag rejects missing name' => sub {
    like(
        dies { Net::Nostr::AppHandler->client_tag(
            coordinate => "31990:$app_pk:my-client",
        ) },
        qr/name/i,
        'missing name rejected'
    );
};

subtest 'client_tag rejects missing coordinate' => sub {
    like(
        dies { Net::Nostr::AppHandler->client_tag(
            name => 'My Client',
        ) },
        qr/coordinate/i,
        'missing coordinate rejected'
    );
};

subtest 'client_tag rejects both missing' => sub {
    like(
        dies { Net::Nostr::AppHandler->client_tag() },
        qr/name|coordinate/i,
        'missing both rejected'
    );
};

done_testing;
