#!/usr/bin/perl

# NIP-72 conformance tests: Moderated Communities (Reddit Style)

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON ();

use Net::Nostr::Community;
use Net::Nostr::Event;

my $JSON = JSON->new->utf8;

my $owner_pk = 'aa' x 32;
my $mod1_pk  = 'bb' x 32;
my $mod2_pk  = 'cc' x 32;
my $mod3_pk  = 'dd' x 32;
my $user_pk  = 'ee' x 32;

###############################################################################
# Kind 34550 — community definition (addressable replaceable event)
###############################################################################

subtest 'kind 34550 is addressable' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $owner_pk, kind => 34550, content => '',
        tags => [['d', 'test-community']],
    );
    ok($event->is_addressable, 'kind 34550 is addressable');
};

###############################################################################
# Spec example — community definition with all fields
###############################################################################

subtest 'spec example: community definition with moderators and relays' => sub {
    my $event = Net::Nostr::Community->community(
        pubkey      => $owner_pk,
        identifier  => 'mycommunityd',
        name        => 'My Community',
        description => 'A great community',
        image       => ['https://example.com/img.jpg', '800x600'],
        moderators  => [
            { pubkey => $mod1_pk, relay => 'wss://relay1' },
            { pubkey => $mod2_pk, relay => 'wss://relay2' },
            { pubkey => $mod3_pk },
        ],
        relays      => [
            { url => 'wss://author-relay.com', marker => 'author' },
            { url => 'wss://requests-relay.com', marker => 'requests' },
            { url => 'wss://approvals-relay.com', marker => 'approvals' },
            { url => 'wss://general-relay.com' },
        ],
    );

    is($event->kind, 34550, 'kind 34550');
    is($event->d_tag, 'mycommunityd', 'd tag');

    my @name = grep { $_->[0] eq 'name' } @{$event->tags};
    is($name[0][1], 'My Community', 'name tag');

    my @desc = grep { $_->[0] eq 'description' } @{$event->tags};
    is($desc[0][1], 'A great community', 'description tag');

    my @img = grep { $_->[0] eq 'image' } @{$event->tags};
    is($img[0][1], 'https://example.com/img.jpg', 'image url');
    is($img[0][2], '800x600', 'image dimensions');

    my @mods = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @mods, 3, 'three moderator p tags');
    is($mods[0][1], $mod1_pk, 'mod1 pubkey');
    is($mods[0][2], 'wss://relay1', 'mod1 relay');
    is($mods[0][3], 'moderator', 'mod1 role');
    is($mods[2][3], 'moderator', 'mod3 role');

    my @relays = grep { $_->[0] eq 'relay' } @{$event->tags};
    is(scalar @relays, 4, 'four relay tags');
    is($relays[0], ['relay', 'wss://author-relay.com', 'author'], 'author relay');
    is($relays[1], ['relay', 'wss://requests-relay.com', 'requests'], 'requests relay');
    is($relays[2], ['relay', 'wss://approvals-relay.com', 'approvals'], 'approvals relay');
    is($relays[3], ['relay', 'wss://general-relay.com'], 'general relay (no marker)');
};

###############################################################################
# Community with minimal fields
###############################################################################

subtest 'community: minimal (only pubkey and identifier)' => sub {
    my $event = Net::Nostr::Community->community(
        pubkey     => $owner_pk,
        identifier => 'minimal',
    );
    is($event->kind, 34550, 'kind 34550');
    is($event->d_tag, 'minimal', 'd tag');
    is($event->content, '', 'empty content');
};

###############################################################################
# d tag MAY double as name
###############################################################################

subtest 'd tag doubles as name when no name tag' => sub {
    my $event = Net::Nostr::Community->community(
        pubkey     => $owner_pk,
        identifier => 'cool-community',
    );
    my $info = Net::Nostr::Community->from_event($event);
    is($info->identifier, 'cool-community', 'd tag value');
    is($info->name, undef, 'no name tag');
    # Caller can use identifier as display name when name is undef
};

subtest 'name tag SHOULD be displayed instead of d tag' => sub {
    my $event = Net::Nostr::Community->community(
        pubkey     => $owner_pk,
        identifier => 'cool-community',
        name       => 'Cool Community',
    );
    my $info = Net::Nostr::Community->from_event($event);
    is($info->identifier, 'cool-community', 'd tag');
    is($info->name, 'Cool Community', 'name tag preferred');
};

###############################################################################
# Image tag with optional dimensions
###############################################################################

subtest 'image with dimensions' => sub {
    my $event = Net::Nostr::Community->community(
        pubkey     => $owner_pk,
        identifier => 'img-test',
        image      => ['https://example.com/img.jpg', '800x600'],
    );
    my @img = grep { $_->[0] eq 'image' } @{$event->tags};
    is($img[0], ['image', 'https://example.com/img.jpg', '800x600'], 'image with dims');
};

subtest 'image without dimensions' => sub {
    my $event = Net::Nostr::Community->community(
        pubkey     => $owner_pk,
        identifier => 'img-test2',
        image      => ['https://example.com/img.jpg'],
    );
    my @img = grep { $_->[0] eq 'image' } @{$event->tags};
    is($img[0], ['image', 'https://example.com/img.jpg'], 'image without dims');
};

###############################################################################
# Moderators — p tags with "moderator" role
###############################################################################

subtest 'moderator p tags: pubkey, optional relay, moderator role' => sub {
    my $event = Net::Nostr::Community->community(
        pubkey     => $owner_pk,
        identifier => 'mod-test',
        moderators => [
            { pubkey => $mod1_pk, relay => 'wss://relay1' },
            { pubkey => $mod2_pk },
        ],
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0], ['p', $mod1_pk, 'wss://relay1', 'moderator'], 'mod with relay');
    is($p[1], ['p', $mod2_pk, '', 'moderator'], 'mod without relay');
};

###############################################################################
# Relay tags with optional markers
###############################################################################

subtest 'relay tags: url with optional marker' => sub {
    my $event = Net::Nostr::Community->community(
        pubkey     => $owner_pk,
        identifier => 'relay-test',
        relays     => [
            { url => 'wss://r1.com', marker => 'author' },
            { url => 'wss://r2.com', marker => 'requests' },
            { url => 'wss://r3.com', marker => 'approvals' },
            { url => 'wss://r4.com' },
        ],
    );
    my @r = grep { $_->[0] eq 'relay' } @{$event->tags};
    is(scalar @r, 4, 'four relay tags');
    is($r[0][2], 'author', 'author marker');
    is($r[1][2], 'requests', 'requests marker');
    is($r[2][2], 'approvals', 'approvals marker');
    is(scalar @{$r[3]}, 2, 'no marker on general relay');
};

###############################################################################
# Posting to a community — kind 1111 top-level post
###############################################################################

subtest 'spec example: top-level post (kind 1111)' => sub {
    my $coord = "34550:$owner_pk:mycommunityd";
    my $post = Net::Nostr::Community->post(
        pubkey           => $user_pk,
        content          => "Hi everyone. It's great to be here!",
        community_pubkey => $owner_pk,
        community_d      => 'mycommunityd',
        relay            => 'wss://relay.com',
    );

    is($post->kind, 1111, 'kind 1111');

    my @A = grep { $_->[0] eq 'A' } @{$post->tags};
    is($A[0][1], $coord, 'A tag = community coordinate');
    is($A[0][2], 'wss://relay.com', 'A tag relay hint');

    my @a = grep { $_->[0] eq 'a' } @{$post->tags};
    is($a[0][1], $coord, 'a tag = community coordinate (top-level)');

    my @Pk = grep { $_->[0] eq 'P' } @{$post->tags};
    is($Pk[0][1], $owner_pk, 'P tag = community author');

    my @p = grep { $_->[0] eq 'p' } @{$post->tags};
    is($p[0][1], $owner_pk, 'p tag = community author (top-level)');

    my @K = grep { $_->[0] eq 'K' } @{$post->tags};
    is($K[0][1], '34550', 'K tag = 34550');

    my @k = grep { $_->[0] eq 'k' } @{$post->tags};
    is($k[0][1], '34550', 'k tag = 34550 (top-level)');
};

###############################################################################
# Posting — nested reply
###############################################################################

subtest 'spec example: nested reply (kind 1111)' => sub {
    my $coord = "34550:$owner_pk:mycommunityd";
    my $parent_id = 'ff' x 32;

    my $reply = Net::Nostr::Community->reply(
        pubkey           => $user_pk,
        content          => 'Agreed! Welcome everyone!',
        community_pubkey => $owner_pk,
        community_d      => 'mycommunityd',
        parent_id        => $parent_id,
        parent_pubkey    => $mod1_pk,
        parent_kind      => '1111',
        relay            => 'wss://relay.com',
    );

    is($reply->kind, 1111, 'kind 1111');

    # Uppercase tags point to community definition
    my @A = grep { $_->[0] eq 'A' } @{$reply->tags};
    is($A[0][1], $coord, 'A tag = community coordinate');

    my @Pk = grep { $_->[0] eq 'P' } @{$reply->tags};
    is($Pk[0][1], $owner_pk, 'P tag = community author');

    my @K = grep { $_->[0] eq 'K' } @{$reply->tags};
    is($K[0][1], '34550', 'K tag = 34550');

    # Lowercase tags point to parent post
    my @e = grep { $_->[0] eq 'e' } @{$reply->tags};
    is($e[0][1], $parent_id, 'e tag = parent event id');

    my @p = grep { $_->[0] eq 'p' } @{$reply->tags};
    is($p[0][1], $mod1_pk, 'p tag = parent author');

    my @k = grep { $_->[0] eq 'k' } @{$reply->tags};
    is($k[0][1], '1111', 'k tag = parent kind');
};

###############################################################################
# Top-level post without relay hint
###############################################################################

subtest 'top-level post: relay hint is optional' => sub {
    my $post = Net::Nostr::Community->post(
        pubkey           => $user_pk,
        content          => 'Hello!',
        community_pubkey => $owner_pk,
        community_d      => 'mycommunityd',
    );
    is($post->kind, 1111, 'kind 1111');
    my @A = grep { $_->[0] eq 'A' } @{$post->tags};
    is(scalar @{$A[0]}, 2, 'A tag has no relay when omitted');
};

###############################################################################
# Approval event — kind 4550
###############################################################################

subtest 'spec example: approval event' => sub {
    my $post_event = Net::Nostr::Event->new(
        id      => 'ab' x 32,
        pubkey  => $user_pk,
        kind    => 1111,
        content => 'My post',
        created_at => 1000,
        tags    => [],
    );

    my $approval = Net::Nostr::Community->approval(
        pubkey           => $mod1_pk,
        community_pubkey => $owner_pk,
        community_d      => 'mycommunityd',
        post             => $post_event,
        relay            => 'wss://relay.com',
    );

    is($approval->kind, 4550, 'kind 4550');

    my @a = grep { $_->[0] eq 'a' } @{$approval->tags};
    is($a[0][1], "34550:$owner_pk:mycommunityd", 'a tag = community coordinate');
    is($a[0][2], 'wss://relay.com', 'a tag relay hint');

    my @e = grep { $_->[0] eq 'e' } @{$approval->tags};
    is($e[0][1], 'ab' x 32, 'e tag = post id');

    my @p = grep { $_->[0] eq 'p' } @{$approval->tags};
    is($p[0][1], $user_pk, 'p tag = post author');

    my @k = grep { $_->[0] eq 'k' } @{$approval->tags};
    is($k[0][1], '1111', 'k tag = post kind');

    # content SHOULD be the JSON-stringified post
    my $decoded = $JSON->decode($approval->content);
    is($decoded->{id}, 'ab' x 32, 'content contains post JSON');
    is($decoded->{kind}, 1111, 'content has post kind');
};

###############################################################################
# Approval: MUST include community a tag, post e/a tag, post author p tag
###############################################################################

subtest 'approval: requires community a tag' => sub {
    my $post = Net::Nostr::Event->new(
        id => 'ab' x 32, pubkey => $user_pk, kind => 1111,
        content => 'x', created_at => 1000, tags => [],
    );
    like(dies {
        Net::Nostr::Community->approval(
            pubkey => $mod1_pk,
            post   => $post,
        )
    }, qr/community_pubkey/, 'requires community_pubkey');
};

###############################################################################
# Approval of replaceable event with a tag (authorize future changes)
###############################################################################

subtest 'approval: replaceable event via a tag' => sub {
    my $post = Net::Nostr::Event->new(
        id => 'cd' x 32, pubkey => $user_pk, kind => 30023,
        content => 'article', created_at => 1000,
        tags => [['d', 'my-article']],
    );

    my $approval = Net::Nostr::Community->approval(
        pubkey           => $mod1_pk,
        community_pubkey => $owner_pk,
        community_d      => 'comm',
        post             => $post,
        approve_via      => 'a',
        relay            => 'wss://relay.com',
    );

    my @a_tags = grep { $_->[0] eq 'a' } @{$approval->tags};
    # First a tag is community, second is the post coordinate
    my @post_a = grep { $_->[1] =~ /^30023:/ } @a_tags;
    is(scalar @post_a, 1, 'has post a tag');
    is($post_a[0][1], "30023:$user_pk:my-article", 'post coordinate');
    my @e_tags = grep { $_->[0] eq 'e' } @{$approval->tags};
    is(scalar @e_tags, 0, 'no e tag when approve_via is a');
};

subtest 'approval: replaceable event via e tag (specific version)' => sub {
    my $post = Net::Nostr::Event->new(
        id => 'cd' x 32, pubkey => $user_pk, kind => 30023,
        content => 'article', created_at => 1000,
        tags => [['d', 'my-article']],
    );

    my $approval = Net::Nostr::Community->approval(
        pubkey           => $mod1_pk,
        community_pubkey => $owner_pk,
        community_d      => 'comm',
        post             => $post,
        approve_via      => 'e',
        relay            => 'wss://relay.com',
    );

    my @e = grep { $_->[0] eq 'e' } @{$approval->tags};
    is($e[0][1], 'cd' x 32, 'e tag = specific event id');
    my @a_tags = grep { $_->[0] eq 'a' } @{$approval->tags};
    my @post_a = grep { $_->[1] =~ /^30023:/ } @a_tags;
    is(scalar @post_a, 0, 'no post a tag when approve_via is e');
};

subtest 'approval: replaceable event via both e and a tags' => sub {
    my $post = Net::Nostr::Event->new(
        id => 'cd' x 32, pubkey => $user_pk, kind => 30023,
        content => 'article', created_at => 1000,
        tags => [['d', 'my-article']],
    );

    my $approval = Net::Nostr::Community->approval(
        pubkey           => $mod1_pk,
        community_pubkey => $owner_pk,
        community_d      => 'comm',
        post             => $post,
        approve_via      => 'both',
        relay            => 'wss://relay.com',
    );

    my @e = grep { $_->[0] eq 'e' } @{$approval->tags};
    is($e[0][1], 'cd' x 32, 'e tag present');
    my @a_tags = grep { $_->[0] eq 'a' } @{$approval->tags};
    my @post_a = grep { $_->[1] =~ /^30023:/ } @a_tags;
    is(scalar @post_a, 1, 'post a tag present');
};

###############################################################################
# Approval: content MUST have specific version when using e tag
###############################################################################

subtest 'approval: content has full event JSON for e tag approval' => sub {
    my $post = Net::Nostr::Event->new(
        id => 'cd' x 32, pubkey => $user_pk, kind => 30023,
        content => 'article body', created_at => 1000,
        tags => [['d', 'my-article']], sig => 'ab' x 64,
    );

    my $approval = Net::Nostr::Community->approval(
        pubkey           => $mod1_pk,
        community_pubkey => $owner_pk,
        community_d      => 'comm',
        post             => $post,
        approve_via      => 'e',
    );

    my $decoded = $JSON->decode($approval->content);
    is($decoded->{content}, 'article body', 'full event content preserved');
};

###############################################################################
# Approval: default is e tag for regular events
###############################################################################

subtest 'approval: default uses e tag for regular events' => sub {
    my $post = Net::Nostr::Event->new(
        id => 'ab' x 32, pubkey => $user_pk, kind => 1111,
        content => 'post', created_at => 1000, tags => [],
    );
    my $approval = Net::Nostr::Community->approval(
        pubkey           => $mod1_pk,
        community_pubkey => $owner_pk,
        community_d      => 'comm',
        post             => $post,
    );
    my @e = grep { $_->[0] eq 'e' } @{$approval->tags};
    is(scalar @e, 1, 'e tag for regular event');
};

###############################################################################
# Approval for multiple communities
###############################################################################

subtest 'approval: multiple community a tags' => sub {
    my $post = Net::Nostr::Event->new(
        id => 'ab' x 32, pubkey => $user_pk, kind => 1111,
        content => 'post', created_at => 1000, tags => [],
    );

    my $approval = Net::Nostr::Community->approval(
        pubkey      => $mod1_pk,
        communities => [
            { pubkey => $owner_pk, d => 'comm1', relay => 'wss://r1' },
            { pubkey => $owner_pk, d => 'comm2' },
        ],
        post        => $post,
    );

    my @a = grep { $_->[0] eq 'a' } @{$approval->tags};
    is(scalar @a, 2, 'two community a tags');
    is($a[0][1], "34550:$owner_pk:comm1", 'first community');
    is($a[1][1], "34550:$owner_pk:comm2", 'second community');
};

###############################################################################
# from_event — parse community definition
###############################################################################

subtest 'from_event: parse community definition' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $owner_pk, kind => 34550, content => '',
        created_at => 1000,
        tags => [
            ['d', 'mycomm'],
            ['name', 'My Community'],
            ['description', 'A great place'],
            ['image', 'https://example.com/img.jpg', '800x600'],
            ['p', $mod1_pk, 'wss://relay1', 'moderator'],
            ['p', $mod2_pk, '', 'moderator'],
            ['relay', 'wss://r1.com', 'author'],
            ['relay', 'wss://r2.com'],
        ],
    );

    my $info = Net::Nostr::Community->from_event($event);
    is($info->identifier, 'mycomm', 'identifier');
    is($info->name, 'My Community', 'name');
    is($info->description, 'A great place', 'description');
    is($info->image, ['https://example.com/img.jpg', '800x600'], 'image');
    is(scalar @{$info->moderators}, 2, 'two moderators');
    is($info->moderators->[0]{pubkey}, $mod1_pk, 'mod1 pubkey');
    is($info->moderators->[0]{relay}, 'wss://relay1', 'mod1 relay');
    is($info->moderators->[1]{pubkey}, $mod2_pk, 'mod2 pubkey');
    is(scalar @{$info->relays}, 2, 'two relays');
    is($info->relays->[0]{url}, 'wss://r1.com', 'relay url');
    is($info->relays->[0]{marker}, 'author', 'relay marker');
};

###############################################################################
# from_event — parse approval event
###############################################################################

subtest 'from_event: parse approval event' => sub {
    my $post_json = $JSON->encode({
        id => 'ab' x 32, pubkey => $user_pk, kind => 1111,
        content => 'Hello', created_at => 1000, tags => [],
    });
    my $event = Net::Nostr::Event->new(
        pubkey => $mod1_pk, kind => 4550, content => $post_json,
        created_at => 2000,
        tags => [
            ['a', "34550:$owner_pk:comm", 'wss://relay.com'],
            ['e', 'ab' x 32, 'wss://relay.com'],
            ['p', $user_pk, 'wss://relay.com'],
            ['k', '1111'],
        ],
    );

    my $info = Net::Nostr::Community->from_event($event);
    is($info->communities->[0], "34550:$owner_pk:comm", 'community coordinate');
    is($info->post_id, 'ab' x 32, 'post id');
    is($info->post_author, $user_pk, 'post author');
    is($info->post_kind, '1111', 'post kind');
};

###############################################################################
# from_event — returns undef for unknown kinds
###############################################################################

subtest 'from_event: returns undef for non-community kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $owner_pk, kind => 1, content => '', tags => [],
        created_at => 1000,
    );
    is(Net::Nostr::Community->from_event($event), undef, 'undef for kind 1');
};

###############################################################################
# validate
###############################################################################

subtest 'validate: rejects non-community kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $owner_pk, kind => 1, content => '',
        created_at => 1000, tags => [],
    );
    like(dies { Net::Nostr::Community->validate($event) },
        qr/34550|4550/, 'rejects wrong kind');
};

subtest 'validate: community MUST have d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $owner_pk, kind => 34550, content => '',
        created_at => 1000, tags => [],
    );
    like(dies { Net::Nostr::Community->validate($event) },
        qr/d tag/, 'missing d tag');
};

subtest 'validate: valid community passes' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $owner_pk, kind => 34550, content => '',
        created_at => 1000, tags => [['d', 'mycomm']],
    );
    ok(Net::Nostr::Community->validate($event), 'valid community');
};

subtest 'validate: approval MUST have community a tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $mod1_pk, kind => 4550, content => '{}',
        created_at => 1000,
        tags => [['e', 'ab' x 32], ['p', $user_pk], ['k', '1111']],
    );
    like(dies { Net::Nostr::Community->validate($event) },
        qr/community.*a tag/, 'missing community a tag');
};

subtest 'validate: approval MUST have e or a tag for post' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $mod1_pk, kind => 4550, content => '{}',
        created_at => 1000,
        tags => [['a', "34550:$owner_pk:c"], ['p', $user_pk], ['k', '1111']],
    );
    like(dies { Net::Nostr::Community->validate($event) },
        qr/e or a tag/, 'missing post e or a tag');
};

subtest 'validate: approval MUST have p tag for post author' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $mod1_pk, kind => 4550, content => '{}',
        created_at => 1000,
        tags => [['a', "34550:$owner_pk:c"], ['e', 'ab' x 32], ['k', '1111']],
    );
    like(dies { Net::Nostr::Community->validate($event) },
        qr/p tag/, 'missing p tag');
};

subtest 'validate: valid approval passes' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $mod1_pk, kind => 4550, content => '{}',
        created_at => 1000,
        tags => [
            ['a', "34550:$owner_pk:c"],
            ['e', 'ab' x 32],
            ['p', $user_pk],
            ['k', '1111'],
        ],
    );
    ok(Net::Nostr::Community->validate($event), 'valid approval');
};

###############################################################################
# Round-trip: community -> from_event
###############################################################################

subtest 'round-trip: community definition' => sub {
    my $event = Net::Nostr::Community->community(
        pubkey      => $owner_pk,
        identifier  => 'rt-test',
        name        => 'Round Trip',
        description => 'Testing round trip',
        image       => ['https://example.com/img.jpg'],
        moderators  => [
            { pubkey => $mod1_pk, relay => 'wss://r1' },
        ],
        relays      => [
            { url => 'wss://r2.com', marker => 'requests' },
        ],
    );

    my $info = Net::Nostr::Community->from_event($event);
    is($info->identifier, 'rt-test', 'identifier preserved');
    is($info->name, 'Round Trip', 'name preserved');
    is($info->description, 'Testing round trip', 'description preserved');
    is($info->image->[0], 'https://example.com/img.jpg', 'image preserved');
    is($info->moderators->[0]{pubkey}, $mod1_pk, 'moderator preserved');
    is($info->relays->[0]{marker}, 'requests', 'relay marker preserved');
};

###############################################################################
# Extra tags (MAY include other fields)
###############################################################################

subtest 'community: extra_tags for other defining fields' => sub {
    my $event = Net::Nostr::Community->community(
        pubkey     => $owner_pk,
        identifier => 'extra',
        extra_tags => [
            ['rules', 'Be kind'],
            ['t', 'nostr'],
        ],
    );
    my @rules = grep { $_->[0] eq 'rules' } @{$event->tags};
    is($rules[0][1], 'Be kind', 'extra tag preserved');
    my @t = grep { $_->[0] eq 't' } @{$event->tags};
    is($t[0][1], 'nostr', 'hashtag tag preserved');
};

###############################################################################
# Community filter helpers
###############################################################################

subtest 'community_filter: query for community definitions' => sub {
    my $filter = Net::Nostr::Community->community_filter(
        identifiers => ['mycomm'],
        authors     => [$owner_pk],
    );
    is($filter->{kinds}, [34550], 'filter kind');
    is($filter->{'#d'}, ['mycomm'], 'filter d');
    is($filter->{authors}, [$owner_pk], 'filter authors');
};

subtest 'approval_filter: query for approvals' => sub {
    my $filter = Net::Nostr::Community->approval_filter(
        community => "34550:$owner_pk:mycomm",
        authors   => [$mod1_pk],
    );
    is($filter->{kinds}, [4550], 'filter kind');
    is($filter->{'#a'}, ["34550:$owner_pk:mycomm"], 'filter community');
    is($filter->{authors}, [$mod1_pk], 'filter authors');
};

###############################################################################
# Backwards compatibility: kind 1 with a tag (MAY query)
###############################################################################

subtest 'backwards compat: kind 1 with community a tag' => sub {
    # Spec says clients MAY still query for kind 1 events
    # Our module should handle this via the filter helper
    my $filter = Net::Nostr::Community->legacy_post_filter(
        community => "34550:$owner_pk:mycomm",
    );
    is($filter->{kinds}, [1], 'legacy filter kind 1');
    is($filter->{'#a'}, ["34550:$owner_pk:mycomm"], 'legacy filter community');
};

###############################################################################
# Non-34550 a tag parsed as post coordinate (spec line 128)
###############################################################################

subtest 'from_event approval: non-34550 a tag is post coordinate' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $mod1_pk, kind => 4550, content => '{}',
        created_at => 1000,
        tags => [
            ['a', "34550:$owner_pk:comm", 'wss://relay.com'],
            ['a', "30023:$user_pk:my-article", 'wss://relay.com'],
            ['p', $user_pk],
            ['k', '30023'],
        ],
    );

    my $info = Net::Nostr::Community->from_event($event);
    is($info->communities->[0], "34550:$owner_pk:comm", 'community a tag');
    is($info->post_coordinate, "30023:$user_pk:my-article", 'non-34550 a tag is post coordinate');
};

###############################################################################
# Cross-posting via NIP-18 repost (MAY)
###############################################################################

subtest 'cross-posting: repost with community a tag' => sub {
    # Spec: "Clients MAY support cross-posting between communities by posting
    # a NIP 18 kind 6 or kind 16 repost to one or more communities using a tags"
    # This is done with existing Repost module; verify the a tag format works.
    my $original = Net::Nostr::Event->new(
        id => 'ab' x 32, pubkey => $user_pk, kind => 1111,
        content => 'Original post', created_at => 1000, tags => [],
    );
    my $repost = Net::Nostr::Event->new(
        pubkey => $user_pk, kind => 6,
        content => $JSON->encode($original->to_hash),
        created_at => 2000,
        tags => [
            ['a', "34550:$owner_pk:comm1"],
            ['a', "34550:$owner_pk:comm2"],
            ['e', 'ab' x 32],
            ['p', $user_pk],
        ],
    );

    # Content MUST be the original event, not the approval event
    my $decoded = $JSON->decode($repost->content);
    is($decoded->{id}, 'ab' x 32, 'repost content is original event');
    is($decoded->{kind}, 1111, 'repost content kind is original');

    # Community a tags present
    my @a = grep { $_->[0] eq 'a' && $_->[1] =~ /^34550:/ } @{$repost->tags};
    is(scalar @a, 2, 'two community a tags for cross-posting');
};

###############################################################################
# Approval: validate accepts approval with a tag (no e tag) for post
###############################################################################

subtest 'validate: approval with a tag for post (no e tag) is valid' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $mod1_pk, kind => 4550, content => '{}',
        created_at => 1000,
        tags => [
            ['a', "34550:$owner_pk:c"],
            ['a', "30023:$user_pk:article"],
            ['p', $user_pk],
            ['k', '30023'],
        ],
    );
    ok(Net::Nostr::Community->validate($event), 'valid with a tag for post');
};

###############################################################################
# Negative validation: invalid pubkeys
###############################################################################

subtest 'post rejects invalid community_pubkey' => sub {
    like(
        dies { Net::Nostr::Community->post(
            pubkey => 'a' x 64, community_pubkey => 'bad',
            community_d => 'test', content => 'hello',
        ) },
        qr/community_pubkey must be 64-char lowercase hex/,
        'invalid community_pubkey rejected'
    );
};

subtest 'community rejects invalid moderator pubkey' => sub {
    like(
        dies { Net::Nostr::Community->community(
            pubkey => 'a' x 64, identifier => 'test',
            moderators => [{ pubkey => 'bad' }],
        ) },
        qr/moderator pubkey must be 64-char lowercase hex/,
        'invalid moderator pubkey rejected'
    );
};

done_testing;
