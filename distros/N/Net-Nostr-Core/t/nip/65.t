#!/usr/bin/perl

# NIP-65 conformance tests: Relay List Metadata

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::RelayList;
use Net::Nostr::Event;

my $PUBKEY = 'a' x 64;

###############################################################################
# Kind 10002 — replaceable event
###############################################################################

subtest 'kind 10002 is replaceable' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 10002, content => '', tags => [],
    );
    ok($event->is_replaceable, 'kind 10002 is replaceable');
};

###############################################################################
# Spec example — exact JSON from NIP-65
###############################################################################

subtest 'spec example: r tags with optional markers' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 10002,
        content => '',
        tags    => [
            ['r', 'wss://alicerelay.example.com'],
            ['r', 'wss://brando-relay.com'],
            ['r', 'wss://expensive-relay.example2.com', 'write'],
            ['r', 'wss://nostr-relay.example.com', 'read'],
        ],
    );

    my $rl = Net::Nostr::RelayList->from_event($event);

    is($rl->count, 4, 'four relays total');

    my @all = $rl->relays;
    is($all[0]{url}, 'wss://alicerelay.example.com', 'first relay url');
    is($all[0]{marker}, '', 'no marker means both');
    is($all[2]{url}, 'wss://expensive-relay.example2.com', 'third relay url');
    is($all[2]{marker}, 'write', 'write marker');
    is($all[3]{url}, 'wss://nostr-relay.example.com', 'fourth relay url');
    is($all[3]{marker}, 'read', 'read marker');
};

###############################################################################
# r tags — MUST include list of r tags with relay URLs
###############################################################################

subtest 'r tags with relay URLs as values' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://relay1.example.com');
    $rl->add('wss://relay2.example.com');

    my $tags = $rl->to_tags;
    is(scalar @$tags, 2, 'two r tags');
    is($tags->[0][0], 'r', 'tag type is r');
    is($tags->[0][1], 'wss://relay1.example.com', 'relay URL is value');
    is($tags->[1][0], 'r', 'second tag type is r');
    is($tags->[1][1], 'wss://relay2.example.com', 'second relay URL');
};

###############################################################################
# Markers — optional read or write
###############################################################################

subtest 'marker omitted means both read and write' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://both.example.com');

    my @write = $rl->write_relays;
    my @read  = $rl->read_relays;

    is(scalar @write, 1, 'unmarked relay in write list');
    is($write[0], 'wss://both.example.com', 'correct URL in write list');
    is(scalar @read, 1, 'unmarked relay in read list');
    is($read[0], 'wss://both.example.com', 'correct URL in read list');
};

subtest 'write marker: relay is write-only' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://write-only.example.com', marker => 'write');

    my @write = $rl->write_relays;
    my @read  = $rl->read_relays;

    is(scalar @write, 1, 'in write list');
    is(scalar @read, 0, 'not in read list');
};

subtest 'read marker: relay is read-only' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://read-only.example.com', marker => 'read');

    my @write = $rl->write_relays;
    my @read  = $rl->read_relays;

    is(scalar @write, 0, 'not in write list');
    is(scalar @read, 1, 'in read list');
};

subtest 'mixed markers' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://both.example.com');
    $rl->add('wss://write.example.com', marker => 'write');
    $rl->add('wss://read.example.com', marker => 'read');

    my @write = $rl->write_relays;
    my @read  = $rl->read_relays;

    is(scalar @write, 2, 'two write relays (unmarked + write)');
    is(scalar @read, 2, 'two read relays (unmarked + read)');
};

###############################################################################
# to_tags — marker encoding
###############################################################################

subtest 'to_tags omits marker for both-direction relays' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://both.example.com');

    my $tags = $rl->to_tags;
    is(scalar @{$tags->[0]}, 2, 'no third element when no marker');
};

subtest 'to_tags includes read/write marker' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://w.example.com', marker => 'write');
    $rl->add('wss://r.example.com', marker => 'read');

    my $tags = $rl->to_tags;
    is($tags->[0], ['r', 'wss://w.example.com', 'write'], 'write tag');
    is($tags->[1], ['r', 'wss://r.example.com', 'read'], 'read tag');
};

###############################################################################
# to_event — kind 10002 with empty content
###############################################################################

subtest 'to_event creates kind 10002 with empty content' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://relay.example.com');

    my $event = $rl->to_event(pubkey => $PUBKEY);
    is($event->kind, 10002, 'kind is 10002');
    is($event->content, '', 'content is empty string');
    is(scalar @{$event->tags}, 1, 'one tag');
    is($event->tags->[0][0], 'r', 'tag is r');
};

subtest 'to_event passes extra args to Event' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://relay.example.com');

    my $event = $rl->to_event(pubkey => $PUBKEY, created_at => 1700000000);
    is($event->created_at, 1700000000, 'created_at passed through');
};

###############################################################################
# from_event — parsing kind 10002
###############################################################################

subtest 'from_event croaks on wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 3, content => '', tags => [],
    );
    like(dies { Net::Nostr::RelayList->from_event($event) },
        qr/kind 10002/, 'rejects non-10002 event');
};

subtest 'from_event ignores non-r tags' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 10002,
        content => '',
        tags    => [
            ['r', 'wss://relay.example.com'],
            ['p', 'b' x 64],
            ['e', 'c' x 64],
        ],
    );

    my $rl = Net::Nostr::RelayList->from_event($event);
    is($rl->count, 1, 'only r tags counted');
};

subtest 'from_event preserves markers' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 10002,
        content => '',
        tags    => [
            ['r', 'wss://both.example.com'],
            ['r', 'wss://w.example.com', 'write'],
            ['r', 'wss://r.example.com', 'read'],
        ],
    );

    my $rl = Net::Nostr::RelayList->from_event($event);
    my @relays = $rl->relays;
    is($relays[0]{marker}, '', 'no marker preserved as empty');
    is($relays[1]{marker}, 'write', 'write marker preserved');
    is($relays[2]{marker}, 'read', 'read marker preserved');
};

###############################################################################
# add — management
###############################################################################

subtest 'add returns self for chaining' => sub {
    my $rl = Net::Nostr::RelayList->new;
    my $ret = $rl->add('wss://relay.example.com');
    is($ret, $rl, 'returns self');
};

subtest 'add replaces existing relay in place' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://relay.example.com', marker => 'read');
    $rl->add('wss://relay.example.com', marker => 'write');

    is($rl->count, 1, 'no duplicate');
    my @relays = $rl->relays;
    is($relays[0]{marker}, 'write', 'marker updated');
};

subtest 'add validates marker' => sub {
    my $rl = Net::Nostr::RelayList->new;
    like(dies { $rl->add('wss://relay.example.com', marker => 'invalid') },
        qr/marker/, 'invalid marker rejected');
};

###############################################################################
# remove
###############################################################################

subtest 'remove deletes relay by URL' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://relay1.example.com');
    $rl->add('wss://relay2.example.com');

    $rl->remove('wss://relay1.example.com');
    is($rl->count, 1, 'one relay remaining');
    my @relays = $rl->relays;
    is($relays[0]{url}, 'wss://relay2.example.com', 'correct relay remains');
};

subtest 'remove returns self for chaining' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://relay.example.com');
    my $ret = $rl->remove('wss://relay.example.com');
    is($ret, $rl, 'returns self');
};

subtest 'remove is no-op for absent relay' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://relay.example.com');
    $rl->remove('wss://other.example.com');
    is($rl->count, 1, 'count unchanged');
};

###############################################################################
# contains
###############################################################################

subtest 'contains checks relay presence' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://relay.example.com');

    ok($rl->contains('wss://relay.example.com'), 'present relay found');
    ok(!$rl->contains('wss://other.example.com'), 'absent relay not found');
};

###############################################################################
# Round-trip: from_event -> to_event
###############################################################################

subtest 'round-trip preserves relay list' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 10002,
        content => '',
        tags    => [
            ['r', 'wss://alicerelay.example.com'],
            ['r', 'wss://brando-relay.com'],
            ['r', 'wss://expensive-relay.example2.com', 'write'],
            ['r', 'wss://nostr-relay.example.com', 'read'],
        ],
    );

    my $rl = Net::Nostr::RelayList->from_event($event);
    my $event2 = $rl->to_event(pubkey => $PUBKEY);

    is($event2->kind, 10002, 'kind preserved');
    is($event2->content, '', 'content empty');
    is($event2->tags, $event->tags, 'tags match original');
};

###############################################################################
# Size guidance — SHOULD keep lists small (2-4 per category)
###############################################################################

subtest 'size method reports relay count' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://r1.example.com');
    $rl->add('wss://r2.example.com', marker => 'write');
    $rl->add('wss://r3.example.com', marker => 'read');

    is($rl->count, 3, 'total count');
    is(scalar $rl->write_relays, 2, 'write count (unmarked + write)');
    is(scalar $rl->read_relays, 2, 'read count (unmarked + read)');
};

###############################################################################
# Edge cases
###############################################################################

subtest 'empty relay list' => sub {
    my $rl = Net::Nostr::RelayList->new;
    is($rl->count, 0, 'empty count');
    is(scalar $rl->relays, 0, 'no relays');
    is(scalar $rl->write_relays, 0, 'no write relays');
    is(scalar $rl->read_relays, 0, 'no read relays');

    my $event = $rl->to_event(pubkey => $PUBKEY);
    is($event->kind, 10002, 'kind correct');
    is(scalar @{$event->tags}, 0, 'no tags');
};

subtest 'from_event with empty tags' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 10002, content => '', tags => [],
    );
    my $rl = Net::Nostr::RelayList->from_event($event);
    is($rl->count, 0, 'empty relay list');
};

subtest 'spec example: write_relays returns write + unmarked relays' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 10002,
        content => '',
        tags    => [
            ['r', 'wss://alicerelay.example.com'],
            ['r', 'wss://brando-relay.com'],
            ['r', 'wss://expensive-relay.example2.com', 'write'],
            ['r', 'wss://nostr-relay.example.com', 'read'],
        ],
    );

    my $rl = Net::Nostr::RelayList->from_event($event);
    my @write = $rl->write_relays;
    is(\@write, [
        'wss://alicerelay.example.com',
        'wss://brando-relay.com',
        'wss://expensive-relay.example2.com',
    ], 'write relays: unmarked + write-marked');
};

subtest 'spec example: read_relays returns read + unmarked relays' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey  => $PUBKEY,
        kind    => 10002,
        content => '',
        tags    => [
            ['r', 'wss://alicerelay.example.com'],
            ['r', 'wss://brando-relay.com'],
            ['r', 'wss://expensive-relay.example2.com', 'write'],
            ['r', 'wss://nostr-relay.example.com', 'read'],
        ],
    );

    my $rl = Net::Nostr::RelayList->from_event($event);
    my @read = $rl->read_relays;
    is(\@read, [
        'wss://alicerelay.example.com',
        'wss://brando-relay.com',
        'wss://nostr-relay.example.com',
    ], 'read relays: unmarked + read-marked');
};

subtest 'to_event forces empty content even if caller passes content' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://relay.example.com');

    my $event = $rl->to_event(pubkey => $PUBKEY, content => 'should be ignored');
    is($event->content, '', 'content forced to empty string');
};

subtest 'POD example: write_relays excludes read-only' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://both.example.com');
    $rl->add('wss://w.example.com', marker => 'write');
    $rl->add('wss://r.example.com', marker => 'read');
    my @write = $rl->write_relays;
    is(\@write, ['wss://both.example.com', 'wss://w.example.com'],
        'write_relays: unmarked + write');
};

subtest 'POD example: read_relays excludes write-only' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://both.example.com');
    $rl->add('wss://w.example.com', marker => 'write');
    $rl->add('wss://r.example.com', marker => 'read');
    my @read = $rl->read_relays;
    is(\@read, ['wss://both.example.com', 'wss://r.example.com'],
        'read_relays: unmarked + read');
};

subtest 'all relays unmarked (all are both read and write)' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://r1.example.com');
    $rl->add('wss://r2.example.com');

    my @write = $rl->write_relays;
    my @read  = $rl->read_relays;
    is(scalar @write, 2, 'both in write');
    is(scalar @read, 2, 'both in read');
};

done_testing;
