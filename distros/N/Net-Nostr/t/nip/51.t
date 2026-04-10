#!/usr/bin/perl

# NIP-51: Lists
# https://github.com/nostr-protocol/nips/blob/master/51.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::List;
use Net::Nostr::Key;
use Net::Nostr::Encryption;

my $JSON = JSON->new->utf8;

my $alice_pk = 'a' x 64;
my $bob_pk   = 'b' x 64;
my $carol_pk = 'c' x 64;
my $event_id = '1' x 64;
my $event_id2 = '2' x 64;

###############################################################################
# Constructor
###############################################################################

subtest 'new creates empty list with kind' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    is($list->kind, 10000, 'kind is set');
    is($list->items, [], 'no public items');
    is($list->private_items, [], 'no private items');
};

subtest 'new croaks without kind' => sub {
    ok(dies { Net::Nostr::List->new }, 'croaks without kind');
};

###############################################################################
# Adding public items
###############################################################################

subtest 'add appends public items' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);
    $list->add('p', $bob_pk);

    is($list->items, [['p', $alice_pk], ['p', $bob_pk]], 'two public items');
};

subtest 'add with multiple tag elements' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk, 'wss://relay.com/', 'alice');

    is($list->items, [['p', $alice_pk, 'wss://relay.com/', 'alice']],
        'tag has all elements');
};

subtest 'add returns self for chaining' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    my $ret = $list->add('p', $alice_pk);
    is($ret, $list, 'returns self');
};

subtest 'add croaks without arguments' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    ok(dies { $list->add }, 'croaks without arguments');
};

subtest 'items are appended in chronological order (SHOULD)' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);
    $list->add('t', 'nostr');
    $list->add('e', $event_id);

    is($list->items->[0][0], 'p', 'first item is p');
    is($list->items->[1][0], 't', 'second item is t');
    is($list->items->[2][0], 'e', 'third item is e');
};

###############################################################################
# Adding private items
###############################################################################

subtest 'add_private appends private items' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add_private('p', $alice_pk);
    $list->add_private('p', $bob_pk);

    is($list->private_items, [['p', $alice_pk], ['p', $bob_pk]],
        'two private items');
    is($list->items, [], 'no public items');
};

subtest 'add_private returns self for chaining' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    my $ret = $list->add_private('p', $alice_pk);
    is($ret, $list, 'returns self');
};

subtest 'add_private croaks without arguments' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    ok(dies { $list->add_private }, 'croaks without arguments');
};

subtest 'mixed public and private items' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);
    $list->add_private('p', $bob_pk);
    $list->add('t', 'nostr');
    $list->add_private('word', 'spam');

    is(scalar @{$list->items}, 2, 'two public items');
    is(scalar @{$list->private_items}, 2, 'two private items');
};

###############################################################################
# Set metadata (title, image, description, identifier)
###############################################################################

subtest 'identifier for sets' => sub {
    my $list = Net::Nostr::List->new(kind => 30002, identifier => 'my-relays');
    is($list->identifier, 'my-relays', 'identifier is set');
};

subtest 'identifier defaults to empty string for sets' => sub {
    my $list = Net::Nostr::List->new(kind => 30002);
    is($list->identifier, '', 'identifier defaults to empty string');
};

subtest 'title accessor' => sub {
    my $list = Net::Nostr::List->new(kind => 30004, identifier => 'yaks');
    $list->title('Yaks');
    is($list->title, 'Yaks', 'title is set');
};

subtest 'image accessor' => sub {
    my $list = Net::Nostr::List->new(kind => 30004, identifier => 'yaks');
    $list->image('https://example.com/yak.jpg');
    is($list->image, 'https://example.com/yak.jpg', 'image is set');
};

subtest 'description accessor' => sub {
    my $list = Net::Nostr::List->new(kind => 30004, identifier => 'yaks');
    $list->description('All about yaks');
    is($list->description, 'All about yaks', 'description is set');
};

###############################################################################
# to_event - public items only
###############################################################################

subtest 'to_event produces event with correct kind' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);

    my $event = $list->to_event(pubkey => $alice_pk);
    is($event->kind, 10000, 'kind is 10000');
    isa_ok($event, 'Net::Nostr::Event');
};

subtest 'to_event has public items as tags' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);
    $list->add('p', $bob_pk);
    $list->add('t', 'nostr');

    my $event = $list->to_event(pubkey => $alice_pk);
    is($event->tags, [
        ['p', $alice_pk],
        ['p', $bob_pk],
        ['t', 'nostr'],
    ], 'tags match public items');
};

subtest 'to_event with no private items has empty content' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);

    my $event = $list->to_event(pubkey => $alice_pk);
    is($event->content, '', 'content is empty');
};

subtest 'to_event croaks without pubkey' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    ok(dies { $list->to_event }, 'croaks without pubkey');
};

subtest 'to_event passes extra args to Event' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);

    my $event = $list->to_event(pubkey => $alice_pk, created_at => 1700000000);
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# to_event - sets with d tag and metadata
###############################################################################

subtest 'to_event for set includes d tag' => sub {
    my $list = Net::Nostr::List->new(kind => 30002, identifier => 'my-relays');
    $list->add('relay', 'wss://relay1.com');

    my $event = $list->to_event(pubkey => $alice_pk);
    my @d_tags = grep { $_->[0] eq 'd' } @{$event->tags};
    is(scalar @d_tags, 1, 'one d tag');
    is($d_tags[0][1], 'my-relays', 'd tag value');
};

subtest 'to_event for set includes title, image, description tags' => sub {
    my $list = Net::Nostr::List->new(kind => 30004, identifier => 'yaks');
    $list->title('Yaks');
    $list->image('https://example.com/yak.jpg');
    $list->description('All about yaks');
    $list->add('a', '30023:' . $alice_pk . ':yak-article');

    my $event = $list->to_event(pubkey => $alice_pk);
    my @title_tags = grep { $_->[0] eq 'title' } @{$event->tags};
    my @image_tags = grep { $_->[0] eq 'image' } @{$event->tags};
    my @desc_tags  = grep { $_->[0] eq 'description' } @{$event->tags};

    is(scalar @title_tags, 1, 'one title tag');
    is($title_tags[0][1], 'Yaks', 'title value');
    is(scalar @image_tags, 1, 'one image tag');
    is($image_tags[0][1], 'https://example.com/yak.jpg', 'image value');
    is(scalar @desc_tags, 1, 'one description tag');
    is($desc_tags[0][1], 'All about yaks', 'description value');
};

subtest 'to_event for set omits unset metadata tags' => sub {
    my $list = Net::Nostr::List->new(kind => 30002, identifier => 'relays');
    $list->add('relay', 'wss://relay1.com');

    my $event = $list->to_event(pubkey => $alice_pk);
    my @title_tags = grep { $_->[0] eq 'title' } @{$event->tags};
    my @image_tags = grep { $_->[0] eq 'image' } @{$event->tags};
    my @desc_tags  = grep { $_->[0] eq 'description' } @{$event->tags};

    is(scalar @title_tags, 0, 'no title tag');
    is(scalar @image_tags, 0, 'no image tag');
    is(scalar @desc_tags, 0, 'no description tag');
};

subtest 'd tag comes before item tags' => sub {
    my $list = Net::Nostr::List->new(kind => 30002, identifier => 'relays');
    $list->add('relay', 'wss://relay1.com');

    my $event = $list->to_event(pubkey => $alice_pk);
    is($event->tags->[0][0], 'd', 'd tag is first');
    is($event->tags->[1][0], 'relay', 'item tag follows');
};

###############################################################################
# to_event - private items with NIP-44 encryption
###############################################################################

subtest 'to_event encrypts private items with key' => sub {
    my $key = Net::Nostr::Key->new;

    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);
    $list->add_private('p', $bob_pk);

    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);

    # Public item is in tags
    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is(scalar @p_tags, 1, 'one public p tag');
    is($p_tags[0][1], $alice_pk, 'public p tag value');

    # Content is non-empty (encrypted)
    ok(length($event->content) > 0, 'content is non-empty');

    # Content is base64 (NIP-44 payload)
    ok($event->content !~ /^\[/, 'content is not raw JSON');
};

subtest 'to_event with private items croaks without key' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add_private('p', $bob_pk);

    ok(dies { $list->to_event(pubkey => $alice_pk) },
        'croaks without key when private items exist');
};

subtest 'from_event croaks on NIP-04 encrypted content (deprecated)' => sub {
    my $key = Net::Nostr::Key->new;

    # NIP-04 ciphertext has ?iv= separator
    my $nip04_content = 'TJob1dQrf2ndsmdbeGU+05HT5GMnBSx3fx8QdDY/g3Nv?iv=S3rFeFr1gsYqmQA7bNnNTQ==';
    my $event = make_event(
        pubkey  => $key->pubkey_hex,
        kind    => 10000,
        content => $nip04_content,
        tags    => [['p', $alice_pk]],
    );

    like(
        dies { Net::Nostr::List->from_event($event, key => $key) },
        qr/NIP-04.*deprecated/,
        'croaks with clear message on NIP-04 content',
    );
};

subtest 'to_event without private items ignores key' => sub {
    my $key = Net::Nostr::Key->new;

    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);

    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);
    is($event->content, '', 'content is empty without private items');
};

###############################################################################
# from_event - public items only
###############################################################################

subtest 'from_event parses public items' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 10000,
        content => '',
        tags    => [
            ['p', $alice_pk],
            ['p', $bob_pk],
            ['t', 'nostr'],
        ],
    );

    my $list = Net::Nostr::List->from_event($event);
    is($list->kind, 10000, 'kind preserved');
    is($list->items, [
        ['p', $alice_pk],
        ['p', $bob_pk],
        ['t', 'nostr'],
    ], 'public items parsed');
    is($list->private_items, [], 'no private items');
};

subtest 'from_event with empty tags' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 10001,
        content => '',
        tags    => [],
    );

    my $list = Net::Nostr::List->from_event($event);
    is($list->items, [], 'no public items');
};

###############################################################################
# from_event - sets with d tag and metadata
###############################################################################

subtest 'from_event parses set identifier from d tag' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 30002,
        content => '',
        tags    => [
            ['d', 'my-relays'],
            ['relay', 'wss://relay1.com'],
        ],
    );

    my $list = Net::Nostr::List->from_event($event);
    is($list->identifier, 'my-relays', 'identifier from d tag');
};

subtest 'from_event parses set metadata tags' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 30004,
        content => '',
        tags    => [
            ['d', 'yaks'],
            ['title', 'Yaks'],
            ['image', 'https://example.com/yak.jpg'],
            ['description', 'All about yaks'],
            ['a', '30023:' . $alice_pk . ':yak-article'],
        ],
    );

    my $list = Net::Nostr::List->from_event($event);
    is($list->title, 'Yaks', 'title parsed');
    is($list->image, 'https://example.com/yak.jpg', 'image parsed');
    is($list->description, 'All about yaks', 'description parsed');
};

subtest 'from_event excludes d/title/image/description from items' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 30004,
        content => '',
        tags    => [
            ['d', 'yaks'],
            ['title', 'Yaks'],
            ['image', 'https://example.com/yak.jpg'],
            ['description', 'All about yaks'],
            ['a', '30023:' . $alice_pk . ':yak-article'],
            ['e', $event_id],
        ],
    );

    my $list = Net::Nostr::List->from_event($event);
    is($list->items, [
        ['a', '30023:' . $alice_pk . ':yak-article'],
        ['e', $event_id],
    ], 'metadata tags excluded from items');
};

###############################################################################
# from_event - private items with NIP-44 decryption
###############################################################################

subtest 'encrypted content is nip44(json(tag_arrays)) per spec pseudocode' => sub {
    my $key = Net::Nostr::Key->new;

    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add_private('p', $bob_pk);
    $list->add_private('word', 'spam');

    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);

    # Manually decrypt and verify wire format
    my $conv_key = Net::Nostr::Encryption->get_conversation_key(
        $key->privkey_hex, $key->pubkey_hex,
    );
    my $plaintext = Net::Nostr::Encryption->decrypt($event->content, $conv_key);
    my $decoded = $JSON->decode($plaintext);

    # Must be an array of arrays mimicking tags structure
    is(ref $decoded, 'ARRAY', 'decrypted content is an array');
    is(ref $decoded->[0], 'ARRAY', 'first element is an array');
    is($decoded, [['p', $bob_pk], ['word', 'spam']],
        'wire format matches spec pseudocode');
};

subtest 'from_event without key silently skips encrypted content' => sub {
    my $key = Net::Nostr::Key->new;

    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);
    $list->add_private('p', $bob_pk);

    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);

    # Parsing without key must not croak, just skip private items
    my $parsed;
    ok(lives { $parsed = Net::Nostr::List->from_event($event) },
        'does not croak without key');
    is($parsed->items, [['p', $alice_pk]], 'public items still parsed');
    is($parsed->private_items, [], 'private items empty');
};

subtest 'from_event decrypts private items with key' => sub {
    my $key = Net::Nostr::Key->new;

    # Build and encrypt a list
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);
    $list->add_private('p', $bob_pk);
    $list->add_private('word', 'spam');

    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);

    # Parse it back
    my $parsed = Net::Nostr::List->from_event($event, key => $key);
    is($parsed->items, [['p', $alice_pk]], 'public items parsed');
    is($parsed->private_items, [
        ['p', $bob_pk],
        ['word', 'spam'],
    ], 'private items decrypted');
};

subtest 'from_event without key leaves private items empty' => sub {
    my $key = Net::Nostr::Key->new;

    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);
    $list->add_private('p', $bob_pk);

    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);

    # Parse without key
    my $parsed = Net::Nostr::List->from_event($event);
    is($parsed->items, [['p', $alice_pk]], 'public items parsed');
    is($parsed->private_items, [], 'private items empty without key');
};

###############################################################################
# Round-trips
###############################################################################

subtest 'round-trip: mute list (kind 10000)' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);
    $list->add('t', 'spam');
    $list->add('word', 'bitcoin');
    $list->add('e', $event_id);

    my $event = $list->to_event(pubkey => $bob_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->kind, 10000, 'kind round-trips');
    is($parsed->items, $list->items, 'items round-trip');
};

subtest 'round-trip: pinned notes (kind 10001)' => sub {
    my $list = Net::Nostr::List->new(kind => 10001);
    $list->add('e', $event_id);
    $list->add('e', $event_id2);

    my $event = $list->to_event(pubkey => $alice_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->items, [['e', $event_id], ['e', $event_id2]], 'pins round-trip');
};

subtest 'round-trip: bookmarks (kind 10003)' => sub {
    my $list = Net::Nostr::List->new(kind => 10003);
    $list->add('e', $event_id);
    $list->add('a', '30023:' . $alice_pk . ':my-article');

    my $event = $list->to_event(pubkey => $alice_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->items, $list->items, 'bookmarks round-trip');
};

subtest 'round-trip: public chats (kind 10005)' => sub {
    my $list = Net::Nostr::List->new(kind => 10005);
    $list->add('e', $event_id);

    my $event = $list->to_event(pubkey => $alice_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->items, [['e', $event_id]], 'public chats round-trip');
};

subtest 'round-trip: blocked relays (kind 10006)' => sub {
    my $list = Net::Nostr::List->new(kind => 10006);
    $list->add('relay', 'wss://evil.relay.com');
    $list->add('relay', 'wss://spam.relay.com');

    my $event = $list->to_event(pubkey => $alice_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->items, $list->items, 'blocked relays round-trip');
};

subtest 'round-trip: search relays (kind 10007)' => sub {
    my $list = Net::Nostr::List->new(kind => 10007);
    $list->add('relay', 'wss://search.relay.com');

    my $event = $list->to_event(pubkey => $alice_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->items, $list->items, 'search relays round-trip');
};

subtest 'round-trip: relay set (kind 30002)' => sub {
    my $list = Net::Nostr::List->new(kind => 30002, identifier => 'my-relays');
    $list->title('My Relays');
    $list->add('relay', 'wss://relay1.com');
    $list->add('relay', 'wss://relay2.com');

    my $event = $list->to_event(pubkey => $alice_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->kind, 30002, 'kind round-trips');
    is($parsed->identifier, 'my-relays', 'identifier round-trips');
    is($parsed->title, 'My Relays', 'title round-trips');
    is($parsed->items, [
        ['relay', 'wss://relay1.com'],
        ['relay', 'wss://relay2.com'],
    ], 'items round-trip');
};

subtest 'round-trip: curation set (kind 30004) with all metadata' => sub {
    my $list = Net::Nostr::List->new(kind => 30004, identifier => 'yaks');
    $list->title('Yaks');
    $list->image('https://example.com/yak.jpg');
    $list->description('All about yaks');
    $list->add('a', '30023:' . $alice_pk . ':yak-1');
    $list->add('a', '30023:' . $bob_pk . ':yak-2');
    $list->add('e', $event_id);

    my $event = $list->to_event(pubkey => $alice_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->identifier, 'yaks', 'identifier round-trips');
    is($parsed->title, 'Yaks', 'title round-trips');
    is($parsed->image, 'https://example.com/yak.jpg', 'image round-trips');
    is($parsed->description, 'All about yaks', 'description round-trips');
    is(scalar @{$parsed->items}, 3, 'three items round-trip');
};

subtest 'round-trip: private items with encryption' => sub {
    my $key = Net::Nostr::Key->new;

    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);
    $list->add('t', 'nostr');
    $list->add_private('p', $bob_pk);
    $list->add_private('p', $carol_pk);
    $list->add_private('word', 'spam');

    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);
    my $parsed = Net::Nostr::List->from_event($event, key => $key);

    is($parsed->items, [['p', $alice_pk], ['t', 'nostr']], 'public items round-trip');
    is($parsed->private_items, [
        ['p', $bob_pk],
        ['p', $carol_pk],
        ['word', 'spam'],
    ], 'private items round-trip');
};

subtest 'round-trip: set with private items' => sub {
    my $key = Net::Nostr::Key->new;

    my $list = Net::Nostr::List->new(kind => 30003, identifier => 'secret-bookmarks');
    $list->title('Secret Bookmarks');
    $list->add('e', $event_id);
    $list->add_private('e', $event_id2);
    $list->add_private('a', '30023:' . $alice_pk . ':secret');

    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);
    my $parsed = Net::Nostr::List->from_event($event, key => $key);

    is($parsed->identifier, 'secret-bookmarks', 'identifier round-trips');
    is($parsed->title, 'Secret Bookmarks', 'title round-trips');
    is($parsed->items, [['e', $event_id]], 'public items round-trip');
    is($parsed->private_items, [
        ['e', $event_id2],
        ['a', '30023:' . $alice_pk . ':secret'],
    ], 'private items round-trip');
};

###############################################################################
# Specific list kind tests
###############################################################################

subtest 'simple groups list (kind 10009) with group and r tags' => sub {
    my $list = Net::Nostr::List->new(kind => 10009);
    $list->add('group', 'abcdef', 'wss://groups.nostr.com', 'Pizza Lovers');
    $list->add('r', 'wss://groups.nostr.com');

    my $event = $list->to_event(pubkey => $alice_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    my @group_tags = grep { $_->[0] eq 'group' } @{$parsed->items};
    is(scalar @group_tags, 1, 'one group tag');
    is($group_tags[0][1], 'abcdef', 'group id');
    is($group_tags[0][2], 'wss://groups.nostr.com', 'relay URL');
    is($group_tags[0][3], 'Pizza Lovers', 'group name');
};

subtest 'interests list (kind 10015) with t and a tags' => sub {
    my $list = Net::Nostr::List->new(kind => 10015);
    $list->add('t', 'nostr');
    $list->add('t', 'bitcoin');
    $list->add('a', '30015:' . $alice_pk . ':crypto');

    my $event = $list->to_event(pubkey => $alice_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is(scalar @{$parsed->items}, 3, 'three items');
};

subtest 'follow set (kind 30000)' => sub {
    my $list = Net::Nostr::List->new(kind => 30000, identifier => 'devs');
    $list->add('p', $alice_pk);
    $list->add('p', $bob_pk);

    my $event = $list->to_event(pubkey => $carol_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->identifier, 'devs', 'identifier');
    is(scalar @{$parsed->items}, 2, 'two items');
};

subtest 'bookmark set (kind 30003)' => sub {
    my $list = Net::Nostr::List->new(kind => 30003, identifier => 'articles');
    $list->add('e', $event_id);
    $list->add('a', '30023:' . $alice_pk . ':my-article');

    my $event = $list->to_event(pubkey => $alice_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->identifier, 'articles', 'identifier');
    is(scalar @{$parsed->items}, 2, 'two items');
};

###############################################################################
# NIP-34 related follow lists (kinds 10017, 10018)
###############################################################################

subtest 'git authors list (kind 10017) with p tags' => sub {
    my $list = Net::Nostr::List->new(kind => 10017);
    $list->add('p', $alice_pk);
    $list->add('p', $bob_pk, 'wss://relay.com', 'bob');

    my $event = $list->to_event(pubkey => $carol_pk);
    is($event->kind, 10017, 'kind is 10017');

    my $parsed = Net::Nostr::List->from_event($event);
    is(scalar @{$parsed->items}, 2, 'two p tags');
    is($parsed->items->[0], ['p', $alice_pk], 'first author pubkey');
    is($parsed->items->[1], ['p', $bob_pk, 'wss://relay.com', 'bob'],
        'second author with relay hint and petname');
};

subtest 'git repositories list (kind 10018) with a tags' => sub {
    my $repo_coord = "30617:${alice_pk}:my-repo";
    my $repo_coord2 = "30617:${bob_pk}:other-repo";

    my $list = Net::Nostr::List->new(kind => 10018);
    $list->add('a', $repo_coord);
    $list->add('a', $repo_coord2);

    my $event = $list->to_event(pubkey => $carol_pk);
    is($event->kind, 10018, 'kind is 10018');

    my $parsed = Net::Nostr::List->from_event($event);
    is(scalar @{$parsed->items}, 2, 'two a tags');
    is($parsed->items->[0], ['a', $repo_coord], 'first repo coordinate');
    is($parsed->items->[1], ['a', $repo_coord2], 'second repo coordinate');
};

subtest 'round-trip: git authors (kind 10017)' => sub {
    my $list = Net::Nostr::List->new(kind => 10017);
    $list->add('p', $alice_pk, 'wss://relay.com', 'alice');
    $list->add('p', $bob_pk);

    my $event = $list->to_event(pubkey => $carol_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->kind, 10017, 'kind round-trips');
    is($parsed->items, $list->items, 'git authors round-trip');
};

subtest 'round-trip: git repositories (kind 10018)' => sub {
    my $list = Net::Nostr::List->new(kind => 10018);
    $list->add('a', "30617:${alice_pk}:repo-1");
    $list->add('a', "30617:${bob_pk}:repo-2");

    my $event = $list->to_event(pubkey => $carol_pk);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->kind, 10018, 'kind round-trips');
    is($parsed->items, $list->items, 'git repositories round-trip');
};

subtest 'git authors list with private items' => sub {
    my $key = Net::Nostr::Key->new;

    my $list = Net::Nostr::List->new(kind => 10017);
    $list->add('p', $alice_pk);
    $list->add_private('p', $bob_pk, 'wss://relay.com', 'secret-dev');

    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);
    my $parsed = Net::Nostr::List->from_event($event, key => $key);

    is($parsed->items, [['p', $alice_pk]], 'public git author');
    is($parsed->private_items, [['p', $bob_pk, 'wss://relay.com', 'secret-dev']],
        'private git author with relay hint and petname');
};

###############################################################################
# Edge cases
###############################################################################

subtest 'empty list produces valid event' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);

    my $event = $list->to_event(pubkey => $alice_pk);
    is($event->kind, 10000, 'kind correct');
    is($event->tags, [], 'no tags');
    is($event->content, '', 'empty content');
};

subtest 'empty set produces event with only d tag' => sub {
    my $list = Net::Nostr::List->new(kind => 30002, identifier => 'empty');

    my $event = $list->to_event(pubkey => $alice_pk);
    is($event->tags, [['d', 'empty']], 'only d tag');
};

subtest 'items returns a copy not a reference' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', $alice_pk);

    my $items = $list->items;
    push @$items, ['p', $bob_pk];
    is(scalar @{$list->items}, 1, 'original not modified');
};

subtest 'accepts arbitrary kind and tag types (generic design)' => sub {
    my $list = Net::Nostr::List->new(kind => 10999);
    $list->add('x', 'foo');
    $list->add('zzz', 'bar', 'baz');
    my $event = $list->to_event(pubkey => $alice_pk);
    my $parsed = Net::Nostr::List->from_event($event);
    is $parsed->kind, 10999, 'arbitrary kind preserved';
    is $parsed->items, [['x', 'foo'], ['zzz', 'bar', 'baz']],
        'arbitrary tag types preserved';
};

subtest 'private_items returns a copy not a reference' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add_private('p', $alice_pk);

    my $items = $list->private_items;
    push @$items, ['p', $bob_pk];
    is(scalar @{$list->private_items}, 1, 'original not modified');
};

done_testing;
