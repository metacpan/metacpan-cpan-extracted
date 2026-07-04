#!/usr/bin/perl

# NIP-18: Reposts
# https://github.com/nostr-protocol/nips/blob/master/18.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON ();

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Repost;

my $alice_pk = 'a' x 64;
my $bob_pk   = 'b' x 64;

my $event_id_1 = '1' x 64;
my $event_id_2 = '2' x 64;

###############################################################################
# "A repost is a kind 6 event that is used to signal to followers
#  that a kind 1 text note is worth reading."
###############################################################################

subtest 'repost of kind 1 note creates kind 6 event' => sub {
    my $note = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1,
        content => 'hello world', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    );

    is $repost->kind, 6, 'kind is 6 for text note repost';
    is $repost->pubkey, $bob_pk, 'pubkey is reposter';
};

###############################################################################
# "The content of a repost event is the stringified JSON of the reposted note"
###############################################################################

subtest 'content is stringified JSON of reposted note' => sub {
    my $note = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1,
        content => 'hello world', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    );

    my $parsed = JSON::decode_json($repost->content);
    is $parsed->{id}, $event_id_1, 'content JSON has original event id';
    is $parsed->{pubkey}, $alice_pk, 'content JSON has original pubkey';
    is $parsed->{kind}, 1, 'content JSON has original kind';
    is $parsed->{content}, 'hello world', 'content JSON has original content';
};

###############################################################################
# "It MAY also be empty"
###############################################################################

subtest 'content MAY be empty' => sub {
    my $note = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1,
        content => 'hello', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
        content   => '',
    );

    is $repost->content, '', 'content can be empty';
    is $repost->kind, 6, 'still kind 6';
};

###############################################################################
# "The repost event MUST include an e tag with the id of the note that is
#  being reposted. That tag MUST include a relay URL as its third entry
#  to indicate where it can be fetched."
###############################################################################

subtest 'repost MUST include e tag with relay URL' => sub {
    my $note = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1,
        content => 'hello', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$repost->tags};
    is scalar @e_tags, 1, 'one e tag';
    is $e_tags[0][1], $event_id_1, 'e tag has event id';
    is $e_tags[0][2], 'wss://relay.example.com', 'e tag has relay URL';
};

subtest 'repost requires relay_url' => sub {
    my $note = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1,
        content => 'hello', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );

    like dies { Net::Nostr::Repost->repost(
        event  => $note,
        pubkey => $bob_pk,
    ) }, qr/relay_url/, 'croaks without relay_url';
};

###############################################################################
# "The repost SHOULD include a p tag with the pubkey of the event being
#  reposted."
###############################################################################

subtest 'repost SHOULD include p tag' => sub {
    my $note = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1,
        content => 'hello', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    );

    my @p_tags = grep { $_->[0] eq 'p' } @{$repost->tags};
    is scalar @p_tags, 1, 'one p tag';
    is $p_tags[0][1], $alice_pk, 'p tag has original author pubkey';
};

###############################################################################
# Generic Reposts
# "Since kind 6 reposts are reserved for kind 1 contents, we use kind 16
#  as a generic repost, that can include any kind of event inside other
#  than kind 1."
###############################################################################

subtest 'generic repost of non-kind-1 creates kind 16' => sub {
    my $long_form = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 30023,
        content => 'article body', sig => 'a' x 128, created_at => 1000,
        tags => [['d', 'my-article']],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $long_form,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    );

    is $repost->kind, 16, 'kind is 16 for non-kind-1 repost';
};

###############################################################################
# "kind 16 reposts SHOULD contain a k tag with the stringified kind number
#  of the reposted event as its value."
###############################################################################

subtest 'generic repost SHOULD include k tag' => sub {
    my $long_form = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 30023,
        content => 'article', sig => 'a' x 128, created_at => 1000,
        tags => [['d', 'slug']],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $long_form,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    );

    my @k_tags = grep { $_->[0] eq 'k' } @{$repost->tags};
    is scalar @k_tags, 1, 'one k tag';
    is $k_tags[0][1], '30023', 'k tag has stringified kind';
};

subtest 'kind 6 repost does NOT include k tag' => sub {
    my $note = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1,
        content => 'hello', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    );

    my @k_tags = grep { $_->[0] eq 'k' } @{$repost->tags};
    is scalar @k_tags, 0, 'no k tag for kind 6 repost';
};

###############################################################################
# "When reposting a replaceable event, the repost SHOULD include an a tag
#  with the event coordinate (kind:pubkey:d-tag) of the reposted event."
###############################################################################

subtest 'repost of addressable event includes a tag' => sub {
    my $article = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 30023,
        content => 'article', sig => 'a' x 128, created_at => 1000,
        tags => [['d', 'my-article']],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $article,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    );

    my @a_tags = grep { $_->[0] eq 'a' } @{$repost->tags};
    is scalar @a_tags, 1, 'one a tag';
    is $a_tags[0][1], "30023:${alice_pk}:my-article", 'a tag has event coordinate';
};

subtest 'repost of replaceable event includes a tag' => sub {
    my $metadata = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 0,
        content => '{}', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $metadata,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    );

    # Replaceable but not addressable — no d tag, so no coordinate
    my @a_tags = grep { $_->[0] eq 'a' } @{$repost->tags};
    is scalar @a_tags, 0, 'no a tag for replaceable-but-not-addressable event';
};

subtest 'repost of regular non-kind-1 has no a tag' => sub {
    my $reaction = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 7,
        content => '+', sig => 'a' x 128, created_at => 1000,
        tags => [['e', $event_id_2]],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $reaction,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    );

    my @a_tags = grep { $_->[0] eq 'a' } @{$repost->tags};
    is scalar @a_tags, 0, 'no a tag for regular event';
};

###############################################################################
# "If the a tag is not present, it indicates that a specific version of a
#  replaceable event is being reposted, in which case the content field must
#  contain the full JSON string of the reposted event."
###############################################################################

subtest 'generic repost content is stringified JSON by default' => sub {
    my $article = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 30023,
        content => 'article body', sig => 'a' x 128, created_at => 1000,
        tags => [['d', 'slug']],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $article,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    );

    my $parsed = JSON::decode_json($repost->content);
    is $parsed->{id}, $event_id_1, 'content has event JSON';
    is $parsed->{kind}, 30023, 'content has correct kind';
};

###############################################################################
# e tag and p tag requirements apply to kind 16 generic reposts too
###############################################################################

subtest 'generic repost includes e tag with relay URL and p tag' => sub {
    my $article = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 30023,
        content => 'article', sig => 'a' x 128, created_at => 1000,
        tags => [['d', 'slug']],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $article,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$repost->tags};
    is scalar @e_tags, 1, 'kind 16 has e tag';
    is $e_tags[0][1], $event_id_1, 'e tag has event id';
    is $e_tags[0][2], 'wss://relay.example.com', 'e tag has relay URL';

    my @p_tags = grep { $_->[0] eq 'p' } @{$repost->tags};
    is scalar @p_tags, 1, 'kind 16 has p tag';
    is $p_tags[0][1], $alice_pk, 'p tag has original author pubkey';
};

###############################################################################
# Quote Reposts
# "q tag ensures quote reposts are not pulled and included as replies"
###############################################################################

subtest 'quote repost creates q tag' => sub {
    my $note = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1,
        content => 'original note', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
        quote     => 1,
    );

    my @q_tags = grep { $_->[0] eq 'q' } @{$repost->tags};
    is scalar @q_tags, 1, 'one q tag';
    is $q_tags[0][1], $event_id_1, 'q tag has event id';
    is $q_tags[0][2], 'wss://relay.example.com', 'q tag has relay URL';
    is $q_tags[0][3], $alice_pk, 'q tag has pubkey';
};

subtest 'quote repost on generic (kind 16) event' => sub {
    my $article = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 30023,
        content => 'article', sig => 'a' x 128, created_at => 1000,
        tags => [['d', 'slug']],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $article,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
        quote     => 1,
    );

    is $repost->kind, 16, 'kind 16 for non-kind-1 quote repost';
    my @q_tags = grep { $_->[0] eq 'q' } @{$repost->tags};
    is scalar @q_tags, 1, 'q tag present on kind 16';
    is $q_tags[0][1], $event_id_1, 'q tag has event id';
    is $q_tags[0][2], 'wss://relay.example.com', 'q tag has relay URL';
    is $q_tags[0][3], $alice_pk, 'q tag has pubkey';
};

subtest 'non-quote repost has no q tag by default' => sub {
    my $note = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1,
        content => 'hello', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );

    my $repost = Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    );

    my @q_tags = grep { $_->[0] eq 'q' } @{$repost->tags};
    is scalar @q_tags, 0, 'no q tag by default';
};

###############################################################################
# from_event - parse repost structure
###############################################################################

subtest 'from_event parses kind 6 repost' => sub {
    my $original = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1,
        content => 'hello', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );
    my $content_json = JSON::encode_json($original->to_hash);

    my $repost_event = make_event(
        pubkey => $bob_pk, kind => 6,
        content => $content_json, sig => 'a' x 128, created_at => 2000,
        tags => [
            ['e', $event_id_1, 'wss://relay.example.com'],
            ['p', $alice_pk],
        ],
    );

    my $info = Net::Nostr::Repost->from_event($repost_event);
    ok defined $info, 'parsed successfully';
    is $info->event_id, $event_id_1, 'event_id';
    is $info->relay_url, 'wss://relay.example.com', 'relay_url';
    is $info->author_pubkey, $alice_pk, 'author_pubkey';
    ok defined $info->embedded_event, 'embedded event parsed from content';
    is $info->embedded_event->content, 'hello', 'embedded event content';
};

subtest 'from_event parses kind 16 generic repost' => sub {
    my $article = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 30023,
        content => 'article body', sig => 'a' x 128, created_at => 1000,
        tags => [['d', 'slug']],
    );
    my $content_json = JSON::encode_json($article->to_hash);

    my $repost_event = make_event(
        pubkey => $bob_pk, kind => 16,
        content => $content_json, sig => 'a' x 128, created_at => 2000,
        tags => [
            ['e', $event_id_1, 'wss://relay.example.com'],
            ['p', $alice_pk],
            ['k', '30023'],
            ['a', "30023:${alice_pk}:slug"],
        ],
    );

    my $info = Net::Nostr::Repost->from_event($repost_event);
    ok defined $info, 'parsed successfully';
    is $info->event_id, $event_id_1, 'event_id';
    is $info->reposted_kind, '30023', 'reposted_kind from k tag';
    is $info->event_coordinate, "30023:${alice_pk}:slug", 'event_coordinate from a tag';
    is $info->embedded_event->kind, 30023, 'embedded event kind';
};

subtest 'from_event with empty content' => sub {
    my $repost_event = make_event(
        pubkey => $bob_pk, kind => 6,
        content => '', sig => 'a' x 128, created_at => 2000,
        tags => [
            ['e', $event_id_1, 'wss://relay.example.com'],
            ['p', $alice_pk],
        ],
    );

    my $info = Net::Nostr::Repost->from_event($repost_event);
    ok defined $info, 'parsed successfully';
    is $info->event_id, $event_id_1, 'event_id';
    is $info->embedded_event, undef, 'no embedded event for empty content';
};

###############################################################################
# "If the a tag is not present, it indicates that a specific version of a
#  replaceable event is being reposted, in which case the content field must
#  contain the full JSON string of the reposted event."
###############################################################################

subtest 'from_event: specific version repost (no a tag) has embedded event' => sub {
    my $article = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 30023,
        content => 'specific version', sig => 'a' x 128, created_at => 1000,
        tags => [['d', 'slug']],
    );
    my $content_json = JSON::encode_json($article->to_hash);

    # Kind 16 repost of addressable event WITHOUT a tag = specific version
    my $repost_event = make_event(
        pubkey => $bob_pk, kind => 16,
        content => $content_json, sig => 'a' x 128, created_at => 2000,
        tags => [
            ['e', $event_id_1, 'wss://relay.example.com'],
            ['p', $alice_pk],
            ['k', '30023'],
        ],
    );

    my $info = Net::Nostr::Repost->from_event($repost_event);
    ok defined $info, 'parsed successfully';
    is $info->event_coordinate, undef, 'no event_coordinate (specific version)';
    ok defined $info->embedded_event, 'embedded event present (required for specific version)';
    is $info->embedded_event->kind, 30023, 'embedded event kind';
    is $info->embedded_event->content, 'specific version', 'embedded event content';
};

subtest 'from_event returns undef for non-repost' => sub {
    my $note = make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'hello', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );
    my $info = Net::Nostr::Repost->from_event($note);
    is $info, undef, 'undef for kind 1';
};

###############################################################################
# validate
###############################################################################

subtest 'validate accepts valid kind 6 repost' => sub {
    my $valid = make_event(
        pubkey => $bob_pk, kind => 6,
        content => '{"id":"' . $event_id_1 . '"}', sig => 'a' x 128,
        created_at => 2000,
        tags => [
            ['e', $event_id_1, 'wss://relay.example.com'],
            ['p', $alice_pk],
        ],
    );
    ok lives { Net::Nostr::Repost->validate($valid) }, 'valid kind 6 passes';
};

subtest 'validate accepts valid kind 16 repost' => sub {
    my $valid = make_event(
        pubkey => $bob_pk, kind => 16,
        content => '{"id":"' . $event_id_1 . '"}', sig => 'a' x 128,
        created_at => 2000,
        tags => [
            ['e', $event_id_1, 'wss://relay.example.com'],
            ['p', $alice_pk],
            ['k', '30023'],
        ],
    );
    ok lives { Net::Nostr::Repost->validate($valid) }, 'valid kind 16 passes';
};

subtest 'validate rejects non-repost kind' => sub {
    my $bad = make_event(
        pubkey => $bob_pk, kind => 1,
        content => 'hello', sig => 'a' x 128, created_at => 1000,
        tags => [['e', $event_id_1, 'wss://r.com']],
    );
    like dies { Net::Nostr::Repost->validate($bad) }, qr/kind/, 'rejects non-6/16 kind';
};

subtest 'validate rejects missing e tag' => sub {
    my $bad = make_event(
        pubkey => $bob_pk, kind => 6,
        content => '', sig => 'a' x 128, created_at => 2000,
        tags => [['p', $alice_pk]],
    );
    like dies { Net::Nostr::Repost->validate($bad) }, qr/e tag/, 'rejects missing e tag';
};

subtest 'validate rejects e tag without relay URL' => sub {
    my $bad = make_event(
        pubkey => $bob_pk, kind => 6,
        content => '', sig => 'a' x 128, created_at => 2000,
        tags => [['e', $event_id_1]],
    );
    like dies { Net::Nostr::Repost->validate($bad) }, qr/relay/, 'rejects e tag without relay URL';
};

###############################################################################
# Hex validation on tag fields
###############################################################################

subtest 'repost rejects bad event_id in tags' => sub {
    my $note = make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'hello', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );

    # Mutate the id to invalid hex after Event construction
    $note->{id} = 'ZZZZ' . ('0' x 60);

    like dies { Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    ) }, qr/event_id must be 64-char lowercase hex/, 'rejects bad event_id';
};

subtest 'repost rejects bad author_pubkey in tags' => sub {
    my $note = make_event(
        pubkey => $alice_pk, kind => 1,
        content => 'hello', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );

    $note->{pubkey} = 'ZZZZ' . ('0' x 60);

    like dies { Net::Nostr::Repost->repost(
        event     => $note,
        pubkey    => $bob_pk,
        relay_url => 'wss://relay.example.com',
    ) }, qr/author_pubkey must be 64-char lowercase hex/, 'rejects bad author_pubkey';
};

###############################################################################
# Edge cases
###############################################################################

subtest 'repost requires event' => sub {
    like dies { Net::Nostr::Repost->repost(
        pubkey => $bob_pk, relay_url => 'wss://r.com',
    ) }, qr/event/, 'croaks without event';
};

subtest 'repost requires pubkey' => sub {
    my $note = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1,
        content => 'hello', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );
    like dies { Net::Nostr::Repost->repost(
        event => $note, relay_url => 'wss://r.com',
    ) }, qr/pubkey/, 'croaks without pubkey';
};

subtest 'extra args passed through to Event constructor' => sub {
    my $note = make_event(
        id => $event_id_1, pubkey => $alice_pk, kind => 1,
        content => 'hello', sig => 'a' x 128, created_at => 1000,
        tags => [],
    );

    my $repost = Net::Nostr::Repost->repost(
        event      => $note,
        pubkey     => $bob_pk,
        relay_url  => 'wss://r.com',
        created_at => 1700000000,
    );
    is $repost->created_at, 1700000000, 'created_at passed through';
};

###############################################################################
# Relay integration: kind 6 and kind 16 stored normally
###############################################################################

subtest 'relay stores kind 6 repost as regular event' => sub {
    # kind 6 is a regular event (not replaceable, not ephemeral)
    my $repost_event = make_event(
        pubkey => $bob_pk, kind => 6,
        content => '', sig => 'a' x 128, created_at => 2000,
        tags => [
            ['e', $event_id_1, 'wss://relay.example.com'],
            ['p', $alice_pk],
        ],
    );
    ok !$repost_event->is_replaceable, 'kind 6 is not replaceable';
    ok !$repost_event->is_ephemeral, 'kind 6 is not ephemeral';
    ok !$repost_event->is_addressable, 'kind 6 is not addressable';
};

subtest 'relay stores kind 16 repost as regular event' => sub {
    my $repost_event = make_event(
        pubkey => $bob_pk, kind => 16,
        content => '', sig => 'a' x 128, created_at => 2000,
        tags => [
            ['e', $event_id_1, 'wss://relay.example.com'],
            ['p', $alice_pk],
            ['k', '30023'],
        ],
    );
    ok !$repost_event->is_replaceable, 'kind 16 is not replaceable';
    ok !$repost_event->is_ephemeral, 'kind 16 is not ephemeral';
    ok !$repost_event->is_addressable, 'kind 16 is not addressable';
};

done_testing;
