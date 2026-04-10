#!/usr/bin/perl

# Unit tests for Net::Nostr::Community
# Tests every code example in the POD

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON ();

use Net::Nostr::Community;
use Net::Nostr::Event;

my $JSON = JSON->new->utf8;

my $owner_pk = 'aa' x 32;
my $mod_pk   = 'bb' x 32;
my $user_pk  = 'cc' x 32;

###############################################################################
# SYNOPSIS examples
###############################################################################

subtest 'SYNOPSIS: create a community' => sub {
    my $event = Net::Nostr::Community->community(
        pubkey      => $owner_pk,
        identifier  => 'my-community',
        name        => 'My Community',
        description => 'A place for discussion',
        image       => ['https://example.com/banner.jpg', '1200x400'],
        moderators  => [
            { pubkey => $mod_pk, relay => 'wss://relay1' },
        ],
        relays      => [
            { url => 'wss://relay.example.com', marker => 'requests' },
        ],
    );
    is($event->kind, 34550, 'kind 34550');
    is($event->d_tag, 'my-community', 'd tag');
};

subtest 'SYNOPSIS: post to a community' => sub {
    my $post = Net::Nostr::Community->post(
        pubkey           => $user_pk,
        content          => 'Hello community!',
        community_pubkey => $owner_pk,
        community_d      => 'my-community',
    );
    is($post->kind, 1111, 'kind 1111');
};

subtest 'SYNOPSIS: reply to a post' => sub {
    my $parent_id = 'dd' x 32;
    my $reply = Net::Nostr::Community->reply(
        pubkey           => $user_pk,
        content          => 'Great post!',
        community_pubkey => $owner_pk,
        community_d      => 'my-community',
        parent_id        => $parent_id,
        parent_pubkey    => $mod_pk,
        parent_kind      => '1111',
    );
    is($reply->kind, 1111, 'kind 1111');
};

subtest 'SYNOPSIS: approve a post' => sub {
    my $post = Net::Nostr::Event->new(
        id => 'ee' x 32, pubkey => $user_pk, kind => 1111,
        content => 'Hello!', created_at => 1000, tags => [],
    );
    my $approval = Net::Nostr::Community->approval(
        pubkey           => $mod_pk,
        community_pubkey => $owner_pk,
        community_d      => 'my-community',
        post             => $post,
    );
    is($approval->kind, 4550, 'kind 4550');
};

subtest 'SYNOPSIS: parse a community event' => sub {
    my $event = Net::Nostr::Community->community(
        pubkey     => $owner_pk,
        identifier => 'my-community',
        name       => 'My Community',
    );
    my $info = Net::Nostr::Community->from_event($event);
    is($info->name, 'My Community', 'name accessor');
};

###############################################################################
# community() POD examples
###############################################################################

subtest 'community: moderator and relay tags' => sub {
    my $event = Net::Nostr::Community->community(
        pubkey     => $owner_pk,
        identifier => 'test',
        moderators => [{ pubkey => $mod_pk }],
        relays     => [{ url => 'wss://relay.com', marker => 'author' }],
    );
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p[0][3], 'moderator', 'moderator role');
    my @r = grep { $_->[0] eq 'relay' } @{$event->tags};
    is($r[0][2], 'author', 'relay marker');
};

###############################################################################
# post() POD example
###############################################################################

subtest 'post: with relay hint' => sub {
    my $post = Net::Nostr::Community->post(
        pubkey           => $user_pk,
        content          => 'Hello!',
        community_pubkey => $owner_pk,
        community_d      => 'my-community',
        relay            => 'wss://relay.com',
    );
    my @A = grep { $_->[0] eq 'A' } @{$post->tags};
    like($A[0][2], qr/relay\.com/, 'relay hint in A tag');
};

###############################################################################
# approval() POD example
###############################################################################

subtest 'approval: content has JSON event' => sub {
    my $post = Net::Nostr::Event->new(
        id => 'ff' x 32, pubkey => $user_pk, kind => 1111,
        content => 'Test', created_at => 1000, tags => [],
    );
    my $approval = Net::Nostr::Community->approval(
        pubkey           => $mod_pk,
        community_pubkey => $owner_pk,
        community_d      => 'test',
        post             => $post,
    );
    my $decoded = $JSON->decode($approval->content);
    is($decoded->{id}, 'ff' x 32, 'event JSON in content');
};

###############################################################################
# from_event() POD example
###############################################################################

subtest 'from_event: community accessors' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $owner_pk, kind => 34550, content => '',
        created_at => 1000,
        tags => [
            ['d', 'my-community'],
            ['name', 'My Community'],
            ['description', 'Great place'],
            ['p', $mod_pk, '', 'moderator'],
        ],
    );
    my $info = Net::Nostr::Community->from_event($event);
    is($info->identifier, 'my-community', 'identifier');
    is($info->name, 'My Community', 'name');
    is($info->description, 'Great place', 'description');
    is(scalar @{$info->moderators}, 1, 'one moderator');
};

###############################################################################
# validate() POD example
###############################################################################

subtest 'validate: POD example' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $owner_pk, kind => 34550, content => '',
        created_at => 1000, tags => [['d', 'test']],
    );
    ok(Net::Nostr::Community->validate($event), 'valid');

    my $bad = Net::Nostr::Event->new(
        pubkey => $owner_pk, kind => 1, content => '',
        created_at => 1000, tags => [],
    );
    like(dies { Net::Nostr::Community->validate($bad) }, qr/./, 'invalid');
};

###############################################################################
# Filter helpers POD examples
###############################################################################

subtest 'community_filter: POD example' => sub {
    my $filter = Net::Nostr::Community->community_filter(
        identifiers => ['my-community'],
        authors     => [$owner_pk],
    );
    is($filter->{kinds}, [34550], 'kind 34550');
};

subtest 'approval_filter: POD example' => sub {
    my $filter = Net::Nostr::Community->approval_filter(
        community => "34550:$owner_pk:my-community",
        authors   => [$mod_pk],
    );
    is($filter->{kinds}, [4550], 'kind 4550');
};

###############################################################################
# legacy_post_filter() POD example
###############################################################################

subtest 'legacy_post_filter: POD example' => sub {
    my $filter = Net::Nostr::Community->legacy_post_filter(
        community => "34550:$owner_pk:my-community",
    );
    is($filter->{kinds}, [1], 'legacy kind 1');
    is($filter->{'#a'}, ["34550:$owner_pk:my-community"], 'community filter');
};

###############################################################################
# approval() multi-community POD example
###############################################################################

subtest 'approval: multi-community POD example' => sub {
    my $post = Net::Nostr::Event->new(
        id => 'ff' x 32, pubkey => $user_pk, kind => 1111,
        content => 'Test', created_at => 1000, tags => [],
    );
    my $event = Net::Nostr::Community->approval(
        pubkey      => $mod_pk,
        communities => [
            { pubkey => $owner_pk, d => 'comm1', relay => 'wss://r1' },
            { pubkey => $owner_pk, d => 'comm2' },
        ],
        post        => $post,
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is(scalar @a, 2, 'two community a tags');
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $info = Net::Nostr::Community->new(
        identifier  => 'my-community',
        name        => 'My Community',
        description => 'A place for discussion.',
    );
    is $info->identifier, 'my-community';
    is $info->name, 'My Community';
    is $info->description, 'A place for discussion.';
    is $info->moderators, [];
    is $info->relays, [];
    is $info->communities, [];
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Community->new(
            identifier => 'my-community',
            name       => 'My Community',
            bogus      => 'value',
        ) },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

done_testing;
