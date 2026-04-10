#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON;

use Net::Nostr::List;
use Net::Nostr::Event;
use Net::Nostr::Key;

my $JSON = JSON->new->utf8;

###############################################################################
# Construction
###############################################################################

subtest 'new creates an empty list' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    isa_ok($list, 'Net::Nostr::List');
    is($list->kind, 10000, 'kind');
    is($list->items, [], 'no items');
    is($list->private_items, [], 'no private items');
};

subtest 'new requires kind' => sub {
    ok(dies { Net::Nostr::List->new }, 'croaks without kind');
};

subtest 'new with identifier' => sub {
    my $list = Net::Nostr::List->new(kind => 30002, identifier => 'relays');
    is($list->identifier, 'relays', 'identifier set');
};

subtest 'identifier defaults to empty string' => sub {
    my $list = Net::Nostr::List->new(kind => 30002);
    is($list->identifier, '', 'default empty');
};

###############################################################################
# add / items
###############################################################################

subtest 'add appends items in order' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', 'a' x 64);
    $list->add('t', 'nostr');
    $list->add('e', 'b' x 64);

    my $items = $list->items;
    is(scalar @$items, 3, 'three items');
    is($items->[0], ['p', 'a' x 64], 'first');
    is($items->[1], ['t', 'nostr'], 'second');
    is($items->[2], ['e', 'b' x 64], 'third');
};

subtest 'add preserves multi-element tags' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', 'a' x 64, 'wss://relay.com/', 'alice');

    is($list->items->[0], ['p', 'a' x 64, 'wss://relay.com/', 'alice'],
        'all elements preserved');
};

subtest 'add returns self for chaining' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    my $ret = $list->add('p', 'a' x 64)->add('p', 'b' x 64);
    is($ret, $list, 'same object');
    is(scalar @{$list->items}, 2, 'both added');
};

subtest 'add croaks with no args' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    ok(dies { $list->add }, 'croaks');
};

subtest 'items returns a defensive copy' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', 'a' x 64);

    my $copy = $list->items;
    push @$copy, ['p', 'b' x 64];
    is(scalar @{$list->items}, 1, 'original unchanged');
};

###############################################################################
# add_private / private_items
###############################################################################

subtest 'add_private appends private items' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add_private('p', 'a' x 64);
    $list->add_private('word', 'spam');

    is(scalar @{$list->private_items}, 2, 'two private items');
    is($list->private_items->[0], ['p', 'a' x 64], 'first');
    is($list->private_items->[1], ['word', 'spam'], 'second');
};

subtest 'add_private does not affect public items' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add_private('p', 'a' x 64);
    is($list->items, [], 'no public items');
};

subtest 'add_private returns self for chaining' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    my $ret = $list->add_private('p', 'a' x 64)->add_private('t', 'spam');
    is($ret, $list, 'same object');
    is(scalar @{$list->private_items}, 2, 'both added');
};

subtest 'add_private croaks with no args' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    ok(dies { $list->add_private }, 'croaks');
};

subtest 'private_items returns a defensive copy' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add_private('p', 'a' x 64);

    my $copy = $list->private_items;
    push @$copy, ['p', 'b' x 64];
    is(scalar @{$list->private_items}, 1, 'original unchanged');
};

###############################################################################
# Set metadata accessors
###############################################################################

subtest 'title get/set' => sub {
    my $list = Net::Nostr::List->new(kind => 30004, identifier => 'x');
    is($list->title, undef, 'initially undef');
    $list->title('My Set');
    is($list->title, 'My Set', 'set and get');
};

subtest 'image get/set' => sub {
    my $list = Net::Nostr::List->new(kind => 30004, identifier => 'x');
    is($list->image, undef, 'initially undef');
    $list->image('https://example.com/pic.png');
    is($list->image, 'https://example.com/pic.png', 'set and get');
};

subtest 'description get/set' => sub {
    my $list = Net::Nostr::List->new(kind => 30004, identifier => 'x');
    is($list->description, undef, 'initially undef');
    $list->description('Some description');
    is($list->description, 'Some description', 'set and get');
};

subtest 'identifier get/set' => sub {
    my $list = Net::Nostr::List->new(kind => 30002, identifier => 'old');
    is($list->identifier, 'old', 'initial value');
    $list->identifier('new');
    is($list->identifier, 'new', 'updated value');
};

###############################################################################
# to_event
###############################################################################

subtest 'to_event produces correct event type' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    my $event = $list->to_event(pubkey => 'a' x 64);
    isa_ok($event, 'Net::Nostr::Event');
    is($event->kind, 10000, 'kind');
    is($event->pubkey, 'a' x 64, 'pubkey');
};

subtest 'to_event public items become tags' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', 'a' x 64);
    $list->add('t', 'nostr');

    my $event = $list->to_event(pubkey => 'b' x 64);
    is($event->tags, [['p', 'a' x 64], ['t', 'nostr']], 'tags match items');
};

subtest 'to_event empty content without private items' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', 'a' x 64);

    my $event = $list->to_event(pubkey => 'a' x 64);
    is($event->content, '', 'empty content');
};

subtest 'to_event croaks without pubkey' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    ok(dies { $list->to_event }, 'croaks');
};

subtest 'to_event forwards extra args' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    my $event = $list->to_event(pubkey => 'a' x 64, created_at => 42);
    is($event->created_at, 42, 'created_at forwarded');
};

subtest 'to_event set includes d tag first' => sub {
    my $list = Net::Nostr::List->new(kind => 30002, identifier => 'relays');
    $list->add('relay', 'wss://r.com');

    my $event = $list->to_event(pubkey => 'a' x 64);
    is($event->tags->[0], ['d', 'relays'], 'd tag first');
    is($event->tags->[1], ['relay', 'wss://r.com'], 'item after d tag');
};

subtest 'to_event set includes metadata tags when set' => sub {
    my $list = Net::Nostr::List->new(kind => 30004, identifier => 'x');
    $list->title('T');
    $list->image('I');
    $list->description('D');

    my $event = $list->to_event(pubkey => 'a' x 64);
    my %tag_map;
    for my $tag (@{$event->tags}) {
        $tag_map{$tag->[0]} = $tag->[1];
    }
    is($tag_map{d}, 'x', 'd tag');
    is($tag_map{title}, 'T', 'title tag');
    is($tag_map{image}, 'I', 'image tag');
    is($tag_map{description}, 'D', 'description tag');
};

subtest 'to_event set omits unset metadata tags' => sub {
    my $list = Net::Nostr::List->new(kind => 30002, identifier => 'x');

    my $event = $list->to_event(pubkey => 'a' x 64);
    my @tag_names = map { $_->[0] } @{$event->tags};
    is(\@tag_names, ['d'], 'only d tag');
};

subtest 'to_event standard list has no d tag' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', 'a' x 64);

    my $event = $list->to_event(pubkey => 'a' x 64);
    my @d_tags = grep { $_->[0] eq 'd' } @{$event->tags};
    is(scalar @d_tags, 0, 'no d tag for standard list');
};

###############################################################################
# to_event with private items (encryption)
###############################################################################

subtest 'to_event encrypts private items' => sub {
    my $key = Net::Nostr::Key->new;

    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', 'a' x 64);
    $list->add_private('p', 'b' x 64);

    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);

    # Content should be non-empty base64 (NIP-44 payload)
    ok(length($event->content) > 0, 'content non-empty');
    ok($event->content !~ /^\[/, 'not raw JSON');

    # Public items still in tags
    is(scalar @{$event->tags}, 1, 'one public tag');
};

subtest 'to_event croaks without key when private items exist' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add_private('p', 'a' x 64);

    ok(dies { $list->to_event(pubkey => 'a' x 64) },
        'croaks without key');
};

subtest 'from_event croaks on NIP-04 encrypted content' => sub {
    my $key = Net::Nostr::Key->new;
    my $event = Net::Nostr::Event->new(
        pubkey  => $key->pubkey_hex,
        kind    => 10000,
        content => 'ciphertext?iv=base64nonce==',
        tags    => [],
    );

    like(
        dies { Net::Nostr::List->from_event($event, key => $key) },
        qr/NIP-04/,
        'croaks mentioning NIP-04',
    );
};

subtest 'to_event ignores key when no private items' => sub {
    my $key = Net::Nostr::Key->new;
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', 'a' x 64);

    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);
    is($event->content, '', 'content empty');
};

###############################################################################
# from_event
###############################################################################

subtest 'from_event parses kind and items' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 10001, content => '',
        tags => [['e', 'b' x 64], ['e', 'c' x 64]],
    );

    my $list = Net::Nostr::List->from_event($event);
    is($list->kind, 10001, 'kind');
    is($list->items, [['e', 'b' x 64], ['e', 'c' x 64]], 'items');
    is($list->private_items, [], 'no private items');
};

subtest 'from_event parses set metadata' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 30004, content => '',
        tags => [
            ['d', 'yaks'],
            ['title', 'Yaks'],
            ['image', 'https://yak.jpg'],
            ['description', 'Yak stuff'],
            ['a', '30023:' . 'a' x 64 . ':article'],
        ],
    );

    my $list = Net::Nostr::List->from_event($event);
    is($list->identifier, 'yaks', 'identifier');
    is($list->title, 'Yaks', 'title');
    is($list->image, 'https://yak.jpg', 'image');
    is($list->description, 'Yak stuff', 'description');
    is($list->items, [['a', '30023:' . 'a' x 64 . ':article']], 'items exclude metadata');
};

subtest 'from_event without key skips encrypted content' => sub {
    my $key = Net::Nostr::Key->new;

    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add_private('p', 'a' x 64);
    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);

    my $parsed = Net::Nostr::List->from_event($event);
    is($parsed->private_items, [], 'private items empty');
};

subtest 'from_event with key decrypts private items' => sub {
    my $key = Net::Nostr::Key->new;

    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', 'a' x 64);
    $list->add_private('p', 'b' x 64);
    $list->add_private('word', 'spam');
    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);

    my $parsed = Net::Nostr::List->from_event($event, key => $key);
    is($parsed->items, [['p', 'a' x 64]], 'public items');
    is($parsed->private_items, [['p', 'b' x 64], ['word', 'spam']],
        'private items decrypted');
};

subtest 'from_event with empty content and key does not croak' => sub {
    my $key = Net::Nostr::Key->new;
    my $event = Net::Nostr::Event->new(
        pubkey => $key->pubkey_hex, kind => 10000, content => '',
        tags => [['p', 'a' x 64]],
    );

    my $parsed;
    ok(lives { $parsed = Net::Nostr::List->from_event($event, key => $key) },
        'does not croak');
    is($parsed->private_items, [], 'no private items');
};

###############################################################################
# Round-trips
###############################################################################

subtest 'round-trip: standard list' => sub {
    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', 'a' x 64);
    $list->add('t', 'nostr');
    $list->add('word', 'gm');

    my $event = $list->to_event(pubkey => 'b' x 64);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->kind, 10000, 'kind');
    is($parsed->items, $list->items, 'items');
};

subtest 'round-trip: set with metadata' => sub {
    my $list = Net::Nostr::List->new(kind => 30004, identifier => 'yaks');
    $list->title('Yaks');
    $list->image('https://yak.jpg');
    $list->description('Yak info');
    $list->add('a', '30023:' . 'a' x 64 . ':y1');
    $list->add('e', 'b' x 64);

    my $event = $list->to_event(pubkey => 'c' x 64);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->identifier, 'yaks', 'identifier');
    is($parsed->title, 'Yaks', 'title');
    is($parsed->image, 'https://yak.jpg', 'image');
    is($parsed->description, 'Yak info', 'description');
    is($parsed->items, $list->items, 'items');
};

subtest 'round-trip: mixed public and private' => sub {
    my $key = Net::Nostr::Key->new;

    my $list = Net::Nostr::List->new(kind => 10000);
    $list->add('p', 'a' x 64);
    $list->add_private('p', 'b' x 64);
    $list->add('t', 'hello');
    $list->add_private('t', 'secret');

    my $event = $list->to_event(pubkey => $key->pubkey_hex, key => $key);
    my $parsed = Net::Nostr::List->from_event($event, key => $key);

    is($parsed->items, [['p', 'a' x 64], ['t', 'hello']], 'public');
    is($parsed->private_items, [['p', 'b' x 64], ['t', 'secret']], 'private');
};

subtest 'round-trip: empty list' => sub {
    my $list = Net::Nostr::List->new(kind => 10001);

    my $event = $list->to_event(pubkey => 'a' x 64);
    my $parsed = Net::Nostr::List->from_event($event);

    is($parsed->kind, 10001, 'kind');
    is($parsed->items, [], 'empty');
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::List->new(kind => 10000, bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

done_testing;
