#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Comment;

my $alice_pk = 'a' x 64;
my $bob_pk   = 'b' x 64;

my $event_id = '1' x 64;

###############################################################################
# POD SYNOPSIS examples
###############################################################################

subtest 'POD: comment on a nostr event' => sub {
    my $blog_post = make_event(
        id => $event_id, pubkey => $alice_pk, kind => 30023,
        content => '', tags => [['d', 'slug']],
    );
    my $comment = Net::Nostr::Comment->comment(
        event     => $blog_post,
        pubkey    => $bob_pk,
        content   => 'Great blog post!',
        relay_url => 'wss://relay.example.com',
    );
    is $comment->kind, 1111, 'kind 1111';
    ok scalar(grep { $_->[0] eq 'A' } @{$comment->tags}), 'has A tag';
};

subtest 'POD: comment on external identifier' => sub {
    my $comment = Net::Nostr::Comment->comment(
        identifier => 'https://abc.com/articles/1',
        kind       => 'web',
        pubkey     => $bob_pk,
        content    => 'Nice article!',
    );
    is $comment->kind, 1111, 'kind 1111';
    my @I = grep { $_->[0] eq 'I' } @{$comment->tags};
    is $I[0][1], 'https://abc.com/articles/1', 'I tag value';
};

subtest 'POD: reply to comment' => sub {
    my $parent = make_event(
        id => $event_id, pubkey => $alice_pk, kind => 1111,
        content => 'Great!',
        tags => [
            ['E', '2' x 64, 'wss://r.com', $alice_pk],
            ['K', '1063'],
            ['P', $alice_pk],
            ['e', '2' x 64, 'wss://r.com', $alice_pk],
            ['k', '1063'],
            ['p', $alice_pk],
        ],
    );
    my $reply = Net::Nostr::Comment->reply(
        to        => $parent,
        pubkey    => $bob_pk,
        content   => 'I agree!',
        relay_url => 'wss://relay.example.com',
    );
    is $reply->kind, 1111, 'kind 1111';
    my @k = grep { $_->[0] eq 'k' } @{$reply->tags};
    is $k[0][1], '1111', 'parent kind is comment';
};

subtest 'POD: from_event' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'Nice!',
        tags => [
            ['E', $event_id, '', $alice_pk],
            ['K', '1063'],
            ['P', $alice_pk],
            ['e', $event_id, '', $alice_pk],
            ['k', '1063'],
            ['p', $alice_pk],
        ],
    );
    my $info = Net::Nostr::Comment->from_event($event);
    ok defined $info, 'returns Comment object';
    is $info->root_kind, '1063', 'root_kind accessor';
    is $info->parent_kind, '1063', 'parent_kind accessor';
    is $info->root_pubkey, $alice_pk, 'root_pubkey accessor';
};

subtest 'POD: validate' => sub {
    my $event = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'Nice!',
        tags => [
            ['E', $event_id, '', $alice_pk],
            ['K', '1063'],
            ['P', $alice_pk],
            ['e', $event_id, '', $alice_pk],
            ['k', '1063'],
            ['p', $alice_pk],
        ],
    );
    ok lives { Net::Nostr::Comment->validate($event) }, 'validate succeeds';

    my $bad = make_event(pubkey => $bob_pk, kind => 1, content => 'hi', tags => []);
    ok dies { Net::Nostr::Comment->validate($bad) }, 'validate rejects non-1111';
};

subtest 'POD: comment on NIP-94 file' => sub {
    my $file = make_event(
        id => $event_id, pubkey => $alice_pk, kind => 1063, content => '',
    );
    my $comment = Net::Nostr::Comment->comment(
        event   => $file,
        pubkey  => $bob_pk,
        content => 'Great file!',
    );
    is $comment->kind, 1111, 'kind 1111';
    my @E = grep { $_->[0] eq 'E' } @{$comment->tags};
    is $E[0][1], $event_id, 'E tag event id';
};

subtest 'POD: podcast comment' => sub {
    my $comment = Net::Nostr::Comment->comment(
        identifier => 'podcast:item:guid:d98d189b-...',
        kind       => 'podcast:item:guid',
        pubkey     => $bob_pk,
        content    => 'Great episode!',
        hint       => 'https://fountain.fm/episode/...',
    );
    is $comment->kind, 1111, 'kind 1111';
    my @K = grep { $_->[0] eq 'K' } @{$comment->tags};
    is $K[0][1], 'podcast:item:guid', 'K tag';
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $hex_pubkey = 'aa' x 32;
    my $info = Net::Nostr::Comment->new(
        root_tag_name => 'E',
        root_kind     => '30023',
        root_value    => 'abc123',
        root_pubkey   => $hex_pubkey,
    );
    is $info->root_tag_name, 'E';
    is $info->root_kind, '30023';
    is $info->root_value, 'abc123';
    is $info->root_pubkey, $hex_pubkey;
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Comment->new(root_tag_name => 'E', bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

###############################################################################
# comment() validation
###############################################################################

subtest 'comment() rejects missing pubkey' => sub {
    my $blog = make_event(
        id => $event_id, pubkey => $alice_pk, kind => 30023,
        content => '', tags => [['d', 'slug']],
    );
    like(
        dies { Net::Nostr::Comment->comment(content => 'x', event => $blog) },
        qr/pubkey/,
        'missing pubkey croaks'
    );
};

subtest 'comment() rejects missing content' => sub {
    my $blog = make_event(
        id => $event_id, pubkey => $alice_pk, kind => 30023,
        content => '', tags => [['d', 'slug']],
    );
    like(
        dies { Net::Nostr::Comment->comment(pubkey => $bob_pk, event => $blog) },
        qr/content/,
        'missing content croaks'
    );
};

subtest 'comment() rejects kind 1 event' => sub {
    my $note = make_event(
        id => $event_id, pubkey => $alice_pk, kind => 1, content => 'hello',
    );
    like(
        dies { Net::Nostr::Comment->comment(event => $note, pubkey => $bob_pk, content => 'hi') },
        qr/kind 1/,
        'kind 1 event rejected'
    );
};

subtest 'comment() rejects missing event and identifier' => sub {
    like(
        dies { Net::Nostr::Comment->comment(pubkey => $bob_pk, content => 'hi') },
        qr/event.*identifier/,
        'neither event nor identifier croaks'
    );
};

subtest 'comment() rejects identifier without kind' => sub {
    like(
        dies { Net::Nostr::Comment->comment(identifier => 'https://example.com', pubkey => $bob_pk, content => 'hi') },
        qr/kind/,
        'identifier without kind croaks'
    );
};

###############################################################################
# validate() rejection
###############################################################################

subtest 'validate() rejects missing root scope tag' => sub {
    my $bad = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'hi',
        tags => [
            ['e', $event_id, '', $alice_pk],
            ['k', '1063'],
            ['p', $alice_pk],
        ],
    );
    like(
        dies { Net::Nostr::Comment->validate($bad) },
        qr/root scope/,
        'missing root scope tag rejected'
    );
};

subtest 'validate() rejects missing K tag' => sub {
    my $bad = make_event(
        pubkey => $bob_pk, kind => 1111, content => 'hi',
        tags => [
            ['E', $event_id, '', $alice_pk],
            ['P', $alice_pk],
            ['e', $event_id, '', $alice_pk],
            ['k', '1063'],
            ['p', $alice_pk],
        ],
    );
    like(
        dies { Net::Nostr::Comment->validate($bad) },
        qr/K tag/,
        'missing K tag rejected'
    );
};

###############################################################################
# from_event
###############################################################################

subtest 'from_event returns undef for non-1111' => sub {
    my $note = make_event(
        pubkey => $alice_pk, kind => 1, content => 'hello', tags => [],
    );
    my $result = Net::Nostr::Comment->from_event($note);
    is $result, undef, 'returns undef';
};

###############################################################################
# Round-trip tests
###############################################################################

subtest 'Round-trip: comment on nostr event -> from_event' => sub {
    my $blog = make_event(
        id => $event_id, pubkey => $alice_pk, kind => 30023,
        content => '', tags => [['d', 'slug']],
    );
    my $comment = Net::Nostr::Comment->comment(
        event   => $blog,
        pubkey  => $bob_pk,
        content => 'Nice post!',
    );
    my $info = Net::Nostr::Comment->from_event($comment);
    ok defined $info, 'from_event returned object';
    is $info->root_kind, '30023', 'root_kind matches';
    my $coord = '30023:' . $alice_pk . ':slug';
    is $info->root_value, $coord, 'root_value is event coordinate';
    is $info->root_pubkey, $alice_pk, 'root_pubkey matches';
};

subtest 'Round-trip: comment on external identifier -> from_event' => sub {
    my $comment = Net::Nostr::Comment->comment(
        identifier => 'https://example.com',
        kind       => 'web',
        pubkey     => $bob_pk,
        content    => 'Nice site!',
    );
    my $info = Net::Nostr::Comment->from_event($comment);
    ok defined $info, 'from_event returned object';
    is $info->root_kind, 'web', 'root_kind is web';
    is $info->root_value, 'https://example.com', 'root_value is identifier';
};

done_testing;
