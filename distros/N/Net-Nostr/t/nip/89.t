#!/usr/bin/perl

# NIP-89: Recommended Application Handlers
# https://github.com/nostr-protocol/nips/blob/master/89.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON ();

use Net::Nostr::Event;
use Net::Nostr::AppHandler;

my $JSON = JSON->new->utf8;

my $PUBKEY  = 'aa' x 32;
my $APP_PK  = 'bb' x 32;
my $APP_PK2 = 'cc' x 32;

###############################################################################
# kind:31989 - Recommendation event
# "a way to discover applications that can handle unknown event-kinds"
###############################################################################

subtest 'recommendation: creates kind 31989 event' => sub {
    my $event = Net::Nostr::AppHandler->recommendation(
        pubkey     => $PUBKEY,
        event_kind => '31337',
        apps       => [
            { coordinate => "31990:$APP_PK:abcd", relay => 'wss://relay1', platform => 'web' },
        ],
    );
    is($event->kind, 31989, 'kind is 31989');
    ok($event->is_addressable, 'recommendation is addressable');
    is($event->d_tag, '31337', 'd tag is the supported event kind');
};

###############################################################################
# "The d tag in kind:31989 is the supported event kind this event is
#  recommending"
###############################################################################

subtest 'recommendation: d tag is the supported event kind' => sub {
    my $event = Net::Nostr::AppHandler->recommendation(
        pubkey     => $PUBKEY,
        event_kind => '1',
        apps       => [
            { coordinate => "31990:$APP_PK:handler1" },
        ],
    );
    is($event->d_tag, '1', 'd tag matches event_kind');
};

###############################################################################
# "Multiple a tags can appear on the same kind:31989"
###############################################################################

subtest 'recommendation: multiple a tags' => sub {
    my $event = Net::Nostr::AppHandler->recommendation(
        pubkey     => $PUBKEY,
        event_kind => '31337',
        apps       => [
            { coordinate => "31990:$APP_PK:abcd", relay => 'wss://relay1', platform => 'web' },
            { coordinate => "31990:$APP_PK2:efgh", relay => 'wss://relay2', platform => 'ios' },
        ],
    );

    my @a_tags = grep { $_->[0] eq 'a' } @{$event->tags};
    is(scalar @a_tags, 2, 'two a tags');
    is($a_tags[0], ['a', "31990:$APP_PK:abcd", 'wss://relay1', 'web'], 'first a tag');
    is($a_tags[1], ['a', "31990:$APP_PK2:efgh", 'wss://relay2', 'ios'], 'second a tag');
};

###############################################################################
# "The second value of the tag SHOULD be a relay hint"
# "The third value of the tag SHOULD be the platform"
###############################################################################

subtest 'recommendation: relay hint and platform are optional' => sub {
    my $event = Net::Nostr::AppHandler->recommendation(
        pubkey     => $PUBKEY,
        event_kind => '31337',
        apps       => [
            { coordinate => "31990:$APP_PK:abcd" },
        ],
    );

    my @a_tags = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a_tags[0], ['a', "31990:$APP_PK:abcd"], 'a tag without relay or platform');
};

subtest 'recommendation: relay hint without platform' => sub {
    my $event = Net::Nostr::AppHandler->recommendation(
        pubkey     => $PUBKEY,
        event_kind => '31337',
        apps       => [
            { coordinate => "31990:$APP_PK:abcd", relay => 'wss://relay1' },
        ],
    );

    my @a_tags = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a_tags[0], ['a', "31990:$APP_PK:abcd", 'wss://relay1'], 'a tag with relay but no platform');
};

###############################################################################
# Spec example: User A recommends a kind:31337-handler
###############################################################################

subtest 'spec example: user A recommends kind:31337 handler' => sub {
    my $event = Net::Nostr::AppHandler->recommendation(
        pubkey     => $PUBKEY,
        event_kind => '31337',
        apps       => [
            {
                coordinate => '31990:1743058db7078661b94aaf4286429d97ee5257d14a86d6bfa54cb0482b876fb0:abcd',
                relay      => 'wss://relay.example.com',
                platform   => 'web',
            },
        ],
    );

    is($event->kind, 31989, 'kind 31989');
    is($event->d_tag, '31337', 'd tag');

    my @a_tags = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a_tags[0][1], '31990:1743058db7078661b94aaf4286429d97ee5257d14a86d6bfa54cb0482b876fb0:abcd', 'a tag coordinate');
    is($a_tags[0][3], 'web', 'platform is web');
};

###############################################################################
# kind:31990 - Handler information
###############################################################################

subtest 'handler: creates kind 31990 event' => sub {
    my $event = Net::Nostr::AppHandler->handler(
        pubkey     => $APP_PK,
        identifier => 'my-app',
        kinds      => ['31337'],
        platforms  => [
            { platform => 'web', url => 'https://app.example.com/e/<bech32>', entity => 'nevent' },
        ],
    );
    is($event->kind, 31990, 'kind is 31990');
    ok($event->is_addressable, 'handler is addressable');
    is($event->d_tag, 'my-app', 'd tag is identifier');
};

###############################################################################
# "k tags' value is the event kind that is supported by this kind:31990"
# "Multiple k tags can exist in the same event"
###############################################################################

subtest 'handler: k tags for supported kinds' => sub {
    my $event = Net::Nostr::AppHandler->handler(
        pubkey     => $APP_PK,
        identifier => 'multi-handler',
        kinds      => ['1', '30023', '31337'],
        platforms  => [
            { platform => 'web', url => 'https://app.example.com/e/<bech32>' },
        ],
    );

    my @k_tags = grep { $_->[0] eq 'k' } @{$event->tags};
    is(scalar @k_tags, 3, 'three k tags');
    is($k_tags[0][1], '1', 'first k tag');
    is($k_tags[1][1], '30023', 'second k tag');
    is($k_tags[2][1], '31337', 'third k tag');
};

###############################################################################
# "content is an optional metadata-like stringified JSON object"
###############################################################################

subtest 'handler: content with metadata JSON' => sub {
    my $meta = { name => 'Zapstr', picture => 'https://example.com/icon.png' };
    my $event = Net::Nostr::AppHandler->handler(
        pubkey     => $APP_PK,
        identifier => 'zapstr',
        kinds      => ['31337'],
        content    => $JSON->encode($meta),
        platforms  => [
            { platform => 'web', url => 'https://zapstr.live/<bech32>', entity => 'nevent' },
        ],
    );

    my $parsed = $JSON->decode($event->content);
    is($parsed->{name}, 'Zapstr', 'content has name');
    is($parsed->{picture}, 'https://example.com/icon.png', 'content has picture');
};

subtest 'handler: empty content when pubkey has kind:0' => sub {
    my $event = Net::Nostr::AppHandler->handler(
        pubkey     => $APP_PK,
        identifier => 'app',
        kinds      => ['1'],
        platforms  => [
            { platform => 'web', url => 'https://app.example.com/<bech32>' },
        ],
    );

    is($event->content, '', 'content defaults to empty string');
};

###############################################################################
# Platform tags: ["web", "url/<bech32>", "nevent"], ["ios", ".../<bech32>"]
# "A tag without a second value in the array SHOULD be considered a generic
#  handler"
###############################################################################

subtest 'handler: platform tags with entity types' => sub {
    my $event = Net::Nostr::AppHandler->handler(
        pubkey     => $APP_PK,
        identifier => 'app',
        kinds      => ['31337'],
        platforms  => [
            { platform => 'web', url => 'https://app.com/a/<bech32>', entity => 'nevent' },
            { platform => 'web', url => 'https://app.com/p/<bech32>', entity => 'nprofile' },
            { platform => 'web', url => 'https://app.com/e/<bech32>' },
            { platform => 'ios', url => 'com.app:///<bech32>' },
        ],
    );

    my @web_tags = grep { $_->[0] eq 'web' } @{$event->tags};
    my @ios_tags = grep { $_->[0] eq 'ios' } @{$event->tags};

    is(scalar @web_tags, 3, 'three web tags');
    is($web_tags[0], ['web', 'https://app.com/a/<bech32>', 'nevent'], 'web tag with nevent');
    is($web_tags[1], ['web', 'https://app.com/p/<bech32>', 'nprofile'], 'web tag with nprofile');
    is($web_tags[2], ['web', 'https://app.com/e/<bech32>'], 'web tag generic (no entity)');
    is($ios_tags[0], ['ios', 'com.app:///<bech32>'], 'ios tag');
};

###############################################################################
# Spec example handler structure from the spec
###############################################################################

subtest 'spec example: handler information event' => sub {
    my $event = Net::Nostr::AppHandler->handler(
        pubkey     => $APP_PK,
        identifier => 'my-handler',
        kinds      => ['31337'],
        platforms  => [
            { platform => 'web', url => 'https://..../a/<bech32>', entity => 'nevent' },
            { platform => 'web', url => 'https://..../p/<bech32>', entity => 'nprofile' },
            { platform => 'web', url => 'https://..../e/<bech32>' },
            { platform => 'ios', url => '.../<bech32>' },
        ],
    );

    is($event->kind, 31990, 'kind 31990');
    is($event->d_tag, 'my-handler', 'd tag');

    my @k_tags = grep { $_->[0] eq 'k' } @{$event->tags};
    is($k_tags[0][1], '31337', 'k tag for 31337');

    my @web = grep { $_->[0] eq 'web' } @{$event->tags};
    is(scalar @web, 3, 'three web platform entries');
    is($web[0][2], 'nevent', 'first web has nevent entity');
    is($web[1][2], 'nprofile', 'second web has nprofile entity');
    ok(!defined $web[2][2], 'third web is generic handler (no entity)');
};

###############################################################################
# Client tag (MAY)
# ["client", "name", "31990:pubkey:d-id", "relay-hint"]
###############################################################################

subtest 'client_tag: creates client tag' => sub {
    my $tag = Net::Nostr::AppHandler->client_tag(
        name       => 'My Client',
        coordinate => "31990:$APP_PK:handler1",
        relay      => 'wss://relay1',
    );

    is($tag, ['client', 'My Client', "31990:$APP_PK:handler1", 'wss://relay1'], 'client tag');
};

subtest 'client_tag: relay is optional' => sub {
    my $tag = Net::Nostr::AppHandler->client_tag(
        name       => 'My Client',
        coordinate => "31990:$APP_PK:handler1",
    );

    is($tag, ['client', 'My Client', "31990:$APP_PK:handler1"], 'client tag without relay');
};

###############################################################################
# Spec example: client tag
###############################################################################

subtest 'spec example: client tag on kind:1 event' => sub {
    my $tag = Net::Nostr::AppHandler->client_tag(
        name       => 'My Client',
        coordinate => "31990:$APP_PK:handler1",
        relay      => 'wss://relay1',
    );

    my $event = Net::Nostr::Event->new(
        kind    => 1,
        pubkey  => $PUBKEY,
        content => 'Hello, world!',
        tags    => [$tag],
    );

    my @client = grep { $_->[0] eq 'client' } @{$event->tags};
    is(scalar @client, 1, 'one client tag');
    is($client[0][1], 'My Client', 'client name');
    is($client[0][2], "31990:$APP_PK:handler1", 'handler coordinate');
    is($client[0][3], 'wss://relay1', 'relay hint');
};

###############################################################################
# from_event: parse recommendation (kind 31989)
###############################################################################

subtest 'from_event: parses kind 31989 recommendation' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey     => $PUBKEY,
        kind       => 31989,
        content    => '',
        created_at => 1000,
        tags       => [
            ['d', '31337'],
            ['a', "31990:$APP_PK:abcd", 'wss://relay1', 'web'],
            ['a', "31990:$APP_PK2:efgh", 'wss://relay2', 'ios'],
        ],
    );

    my $info = Net::Nostr::AppHandler->from_event($event);
    ok(defined $info, 'parsed successfully');
    is($info->event_kind, '31337', 'event_kind');
    is($info->apps, [
        { coordinate => "31990:$APP_PK:abcd", relay => 'wss://relay1', platform => 'web' },
        { coordinate => "31990:$APP_PK2:efgh", relay => 'wss://relay2', platform => 'ios' },
    ], 'apps parsed');
};

subtest 'from_event: recommendation with minimal a tag (no relay/platform)' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey     => $PUBKEY,
        kind       => 31989,
        content    => '',
        created_at => 1000,
        tags       => [
            ['d', '1'],
            ['a', "31990:$APP_PK:handler1"],
        ],
    );

    my $info = Net::Nostr::AppHandler->from_event($event);
    is($info->event_kind, '1', 'event_kind');
    is($info->apps, [
        { coordinate => "31990:$APP_PK:handler1" },
    ], 'app without relay or platform');
};

###############################################################################
# from_event: parse handler (kind 31990)
###############################################################################

subtest 'from_event: parses kind 31990 handler' => sub {
    my $meta = $JSON->encode({ name => 'Zapstr' });
    my $event = Net::Nostr::Event->new(
        pubkey     => $APP_PK,
        kind       => 31990,
        content    => $meta,
        created_at => 1000,
        tags       => [
            ['d', 'zapstr-handler'],
            ['k', '31337'],
            ['k', '30023'],
            ['web', 'https://zapstr.live/a/<bech32>', 'nevent'],
            ['web', 'https://zapstr.live/p/<bech32>', 'nprofile'],
            ['ios', 'com.zapstr:///<bech32>'],
        ],
    );

    my $info = Net::Nostr::AppHandler->from_event($event);
    ok(defined $info, 'parsed successfully');
    is($info->identifier, 'zapstr-handler', 'identifier');
    is($info->kinds, ['31337', '30023'], 'kinds');
    is($info->platforms, [
        { platform => 'web', url => 'https://zapstr.live/a/<bech32>', entity => 'nevent' },
        { platform => 'web', url => 'https://zapstr.live/p/<bech32>', entity => 'nprofile' },
        { platform => 'ios', url => 'com.zapstr:///<bech32>' },
    ], 'platforms parsed');

    my $parsed_meta = $JSON->decode($info->content);
    is($parsed_meta->{name}, 'Zapstr', 'content metadata preserved');
};

subtest 'from_event: handler with generic platform tag (no entity)' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey     => $APP_PK,
        kind       => 31990,
        content    => '',
        created_at => 1000,
        tags       => [
            ['d', 'handler'],
            ['k', '1'],
            ['web', 'https://app.com/e/<bech32>'],
        ],
    );

    my $info = Net::Nostr::AppHandler->from_event($event);
    is($info->platforms, [
        { platform => 'web', url => 'https://app.com/e/<bech32>' },
    ], 'generic handler (no entity type)');
};

###############################################################################
# from_event: returns undef for non-handler kinds
###############################################################################

subtest 'from_event: returns undef for non-handler kinds' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'note', created_at => 1000,
        tags => [],
    );
    is(Net::Nostr::AppHandler->from_event($event), undef, 'kind 1 returns undef');
};

###############################################################################
# validate
###############################################################################

subtest 'validate: valid recommendation' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 31989, content => '',
        created_at => 1000,
        tags => [['d', '31337'], ['a', "31990:$APP_PK:abcd"]],
    );
    ok(Net::Nostr::AppHandler->validate($event), 'valid recommendation passes');
};

subtest 'validate: valid handler' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $APP_PK, kind => 31990, content => '',
        created_at => 1000,
        tags => [['d', 'handler'], ['k', '31337']],
    );
    ok(Net::Nostr::AppHandler->validate($event), 'valid handler passes');
};

subtest 'validate: wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'note',
        created_at => 1000, tags => [['d', 'x']],
    );
    like(dies { Net::Nostr::AppHandler->validate($event) },
        qr/31989|31990/, 'wrong kind rejected');
};

subtest 'validate: recommendation missing d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 31989, content => '',
        created_at => 1000, tags => [['a', "31990:$APP_PK:abcd"]],
    );
    like(dies { Net::Nostr::AppHandler->validate($event) },
        qr/d tag/, 'missing d tag rejected');
};

subtest 'validate: handler missing d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $APP_PK, kind => 31990, content => '',
        created_at => 1000, tags => [['k', '31337']],
    );
    like(dies { Net::Nostr::AppHandler->validate($event) },
        qr/d tag/, 'missing d tag rejected');
};

subtest 'validate: handler missing k tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $APP_PK, kind => 31990, content => '',
        created_at => 1000, tags => [['d', 'handler']],
    );
    like(dies { Net::Nostr::AppHandler->validate($event) },
        qr/k tag/, 'missing k tag rejected');
};

###############################################################################
# recommendation requires pubkey and event_kind
###############################################################################

subtest 'recommendation requires pubkey and event_kind' => sub {
    like(dies { Net::Nostr::AppHandler->recommendation(event_kind => '1', apps => []) },
        qr/pubkey/, 'missing pubkey');
    like(dies { Net::Nostr::AppHandler->recommendation(pubkey => $PUBKEY, apps => []) },
        qr/event_kind/, 'missing event_kind');
};

###############################################################################
# handler requires pubkey, identifier, kinds
###############################################################################

subtest 'handler requires pubkey, identifier, kinds' => sub {
    like(dies { Net::Nostr::AppHandler->handler(identifier => 'x', kinds => ['1'], platforms => []) },
        qr/pubkey/, 'missing pubkey');
    like(dies { Net::Nostr::AppHandler->handler(pubkey => $APP_PK, kinds => ['1'], platforms => []) },
        qr/identifier/, 'missing identifier');
    like(dies { Net::Nostr::AppHandler->handler(pubkey => $APP_PK, identifier => 'x', platforms => []) },
        qr/kinds/, 'missing kinds');
};

###############################################################################
# Round-trips
###############################################################################

subtest 'round-trip: recommendation' => sub {
    my $event = Net::Nostr::AppHandler->recommendation(
        pubkey     => $PUBKEY,
        event_kind => '31337',
        apps       => [
            { coordinate => "31990:$APP_PK:abcd", relay => 'wss://relay1', platform => 'web' },
            { coordinate => "31990:$APP_PK2:efgh", relay => 'wss://relay2', platform => 'ios' },
        ],
    );

    my $info = Net::Nostr::AppHandler->from_event($event);
    is($info->event_kind, '31337', 'event_kind round-trips');
    is(scalar @{$info->apps}, 2, 'two apps round-trip');
    is($info->apps->[0]{coordinate}, "31990:$APP_PK:abcd", 'first app coordinate');
    is($info->apps->[0]{relay}, 'wss://relay1', 'first app relay');
    is($info->apps->[0]{platform}, 'web', 'first app platform');
    is($info->apps->[1]{coordinate}, "31990:$APP_PK2:efgh", 'second app coordinate');
    is($info->apps->[1]{relay}, 'wss://relay2', 'second app relay');
    is($info->apps->[1]{platform}, 'ios', 'second app platform');
};

subtest 'round-trip: handler' => sub {
    my $meta = $JSON->encode({ name => 'TestApp' });
    my $event = Net::Nostr::AppHandler->handler(
        pubkey     => $APP_PK,
        identifier => 'test-app',
        kinds      => ['1', '31337'],
        content    => $meta,
        platforms  => [
            { platform => 'web', url => 'https://app.com/<bech32>', entity => 'nevent' },
            { platform => 'ios', url => 'com.app:///<bech32>' },
        ],
    );

    my $info = Net::Nostr::AppHandler->from_event($event);
    is($info->identifier, 'test-app', 'identifier round-trips');
    is($info->kinds, ['1', '31337'], 'kinds round-trip');
    is(scalar @{$info->platforms}, 2, 'two platforms round-trip');
    is($info->platforms->[0]{platform}, 'web', 'web platform');
    is($info->platforms->[0]{url}, 'https://app.com/<bech32>', 'web url');
    is($info->platforms->[0]{entity}, 'nevent', 'web entity');
    is($info->platforms->[1]{platform}, 'ios', 'ios platform');
    is($info->platforms->[1]{url}, 'com.app:///<bech32>', 'ios url');
};

###############################################################################
# "The same pubkey can have multiple events with different apps that handle
#  the same event kind"
###############################################################################

subtest 'same pubkey can have multiple handler events for same kind' => sub {
    my $event1 = Net::Nostr::AppHandler->handler(
        pubkey     => $APP_PK,
        identifier => 'app-a',
        kinds      => ['31337'],
        platforms  => [{ platform => 'web', url => 'https://a.com/<bech32>' }],
    );

    my $event2 = Net::Nostr::AppHandler->handler(
        pubkey     => $APP_PK,
        identifier => 'app-b',
        kinds      => ['31337'],
        platforms  => [{ platform => 'web', url => 'https://b.com/<bech32>' }],
    );

    isnt($event1->d_tag, $event2->d_tag, 'different d tags (different addressable events)');
    is($event1->pubkey, $event2->pubkey, 'same pubkey');

    my @k1 = grep { $_->[0] eq 'k' } @{$event1->tags};
    my @k2 = grep { $_->[0] eq 'k' } @{$event2->tags};
    is($k1[0][1], '31337', 'first handles 31337');
    is($k2[0][1], '31337', 'second handles 31337');
};

###############################################################################
# Query filter helpers
###############################################################################

subtest 'recommendation_filter: query for recommendations' => sub {
    my $filter = Net::Nostr::AppHandler->recommendation_filter(
        event_kind => '31337',
        authors    => [$PUBKEY, $APP_PK],
    );

    is($filter->{'kinds'}, [31989], 'filter kind 31989');
    is($filter->{'#d'}, ['31337'], 'filter by d tag');
    is($filter->{'authors'}, [$PUBKEY, $APP_PK], 'filter by authors');
};

subtest 'handler_filter: query for handlers' => sub {
    my $filter = Net::Nostr::AppHandler->handler_filter(
        event_kind => '31337',
        authors    => [$APP_PK],
    );

    is($filter->{'kinds'}, [31990], 'filter kind 31990');
    is($filter->{'#k'}, ['31337'], 'filter by k tag');
    is($filter->{'authors'}, [$APP_PK], 'filter by authors');
};

###############################################################################
# handler: android platform tag
###############################################################################

subtest 'handler: android platform tag' => sub {
    my $event = Net::Nostr::AppHandler->handler(
        pubkey     => $APP_PK,
        identifier => 'app',
        kinds      => ['1'],
        platforms  => [
            { platform => 'android', url => 'com.example.app:///<bech32>' },
        ],
    );

    my @android = grep { $_->[0] eq 'android' } @{$event->tags};
    is($android[0], ['android', 'com.example.app:///<bech32>'], 'android platform tag');

    my $info = Net::Nostr::AppHandler->from_event($event);
    is($info->platforms->[0]{platform}, 'android', 'android platform round-trips');
};

###############################################################################
# from_event: short/malformed tags are safely skipped
###############################################################################

subtest 'from_event recommendation: short tags are skipped' => sub {
    my $event = Net::Nostr::Event->new(
        kind    => 31989,
        pubkey  => $PUBKEY,
        content => '',
        tags    => [
            ['d', '31337'],
            ['a'],                    # too short
            [],                       # empty
            ['a', "31990:$APP_PK:x"], # no relay/platform (valid, just 2 elements)
        ],
    );
    my $info = Net::Nostr::AppHandler->from_event($event);
    is $info->event_kind, '31337', 'event_kind parsed';
    is scalar @{$info->apps}, 1, 'short a tag skipped, valid one kept';
    is $info->apps->[0]{coordinate}, "31990:$APP_PK:x", 'coordinate parsed';
    ok !exists $info->apps->[0]{relay}, 'no relay when a tag has only 2 elements';
    ok !exists $info->apps->[0]{platform}, 'no platform when a tag has only 2 elements';
};

subtest 'from_event handler: short tags are skipped' => sub {
    my $event = Net::Nostr::Event->new(
        kind    => 31990,
        pubkey  => $APP_PK,
        content => '',
        tags    => [
            ['d', 'myapp'],
            ['k'],               # too short
            ['k', '1'],
            ['web'],             # too short
            ['web', 'https://app.example.com/<bech32>'],  # no entity
        ],
    );
    my $info = Net::Nostr::AppHandler->from_event($event);
    is $info->identifier, 'myapp', 'identifier parsed';
    is $info->kinds, ['1'], 'short k tag skipped, valid one kept';
    is scalar @{$info->platforms}, 1, 'short web tag skipped';
    ok !exists $info->platforms->[0]{entity}, 'no entity when platform tag has only 2 elements';
};

done_testing;
