#!/usr/bin/perl

# NIP-03: OpenTimestamps Attestations for Events
# https://github.com/nostr-protocol/nips/blob/master/03.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use MIME::Base64 ();

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Timestamp;

my $alice_pk  = 'a' x 64;
my $bob_pk    = 'b' x 64;
my $event1_id = '1' x 64;
my $event2_id = '2' x 64;

# Fake OTS data for testing (not a real proof, just plausible bytes)
my $ots_bytes   = "\x00\x4f\x70\x65\x6e\x54\x69\x6d\x65\x73\x74\x61\x6d\x70\x73\x00\x00\x50\x72\x6f\x6f\x66\x00\xbf\x89\xe2\xe8\x84\xe8\x92\x94";
my $ots_base64  = MIME::Base64::encode_base64($ots_bytes, '');

###############################################################################
# "This NIP defines an event with kind:1040"
###############################################################################

subtest 'timestamp attestation is kind 1040' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $alice_pk,
        event_id => $event1_id,
        kind     => 1,
        ots_data => $ots_base64,
    );
    my $event = $ts->to_event;
    is $event->kind, 1040, 'kind is 1040';
    isa_ok $event, 'Net::Nostr::Event';
};

###############################################################################
# Tags: ["e", <target-event-id>, <relay-url>] and ["k", "<target-event-kind>"]
###############################################################################

subtest 'e tag references target event' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $alice_pk,
        event_id => $event1_id,
        kind     => 1,
        ots_data => $ots_base64,
    );
    my $event = $ts->to_event;
    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is scalar @e, 1, 'one e tag';
    is $e[0][1], $event1_id, 'e tag references target event id';
};

subtest 'e tag includes relay URL when provided' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey    => $alice_pk,
        event_id  => $event1_id,
        kind      => 1,
        ots_data  => $ots_base64,
        relay_url => 'wss://relay.example.com',
    );
    my $event = $ts->to_event;
    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is $e[0][2], 'wss://relay.example.com', 'e tag has relay URL';
};

subtest 'e tag without relay URL has only 2 elements' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $alice_pk,
        event_id => $event1_id,
        kind     => 1,
        ots_data => $ots_base64,
    );
    my $event = $ts->to_event;
    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is scalar @{$e[0]}, 2, 'e tag has 2 elements (no relay)';
};

subtest 'k tag contains target event kind as string' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $alice_pk,
        event_id => $event1_id,
        kind     => 30023,
        ots_data => $ots_base64,
    );
    my $event = $ts->to_event;
    my @k = grep { $_->[0] eq 'k' } @{$event->tags};
    is scalar @k, 1, 'one k tag';
    is $k[0][1], '30023', 'k tag value is stringified kind';
};

###############################################################################
# Content MUST be base64-encoded OTS file data
###############################################################################

subtest 'content is base64-encoded OTS data' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $alice_pk,
        event_id => $event1_id,
        kind     => 1,
        ots_data => $ots_base64,
    );
    my $event = $ts->to_event;
    is $event->content, $ots_base64, 'content is the base64 OTS data';
};

###############################################################################
# JSON example from spec
###############################################################################

subtest 'matches spec JSON structure' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey    => $alice_pk,
        event_id  => $event1_id,
        kind      => 1,
        ots_data  => $ots_base64,
        relay_url => 'wss://relay.example.com',
    );
    my $event = $ts->to_event;

    is $event->kind, 1040, 'kind 1040';

    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is $e[0][1], $event1_id, 'e tag event id';
    is $e[0][2], 'wss://relay.example.com', 'e tag relay url';

    my @k = grep { $_->[0] eq 'k' } @{$event->tags};
    is $k[0][1], '1', 'k tag kind';

    is $event->content, $ots_base64, 'content is base64 OTS';
};

subtest 'tag order: e before k (matches spec JSON)' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey    => $alice_pk,
        event_id  => $event1_id,
        kind      => 1,
        ots_data  => $ots_base64,
        relay_url => 'wss://relay.example.com',
    );
    my $event = $ts->to_event;
    my $tags = $event->tags;
    is $tags->[0][0], 'e', 'first tag is e';
    is $tags->[1][0], 'k', 'second tag is k';
};

###############################################################################
# Verification example from spec uses concrete event ID
###############################################################################

subtest 'spec verification example event ID' => sub {
    my $spec_event_id = 'e71c6ea722987debdb60f81f9ea4f604b5ac0664120dd64fb9d23abc4ec7c323';
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 1040,
        content => $ots_base64,
        tags    => [
            ['e', $spec_event_id, 'wss://nostr-pub.wellorder.net'],
            ['k', '1'],
        ],
    );
    my $ts = Net::Nostr::Timestamp->from_event($event);
    is $ts->event_id, $spec_event_id, 'parses spec example event ID';
    is $ts->relay_url, 'wss://nostr-pub.wellorder.net', 'parses spec example relay';
};

###############################################################################
# from_event: parse a kind 1040 event
###############################################################################

subtest 'from_event parses a kind 1040 event' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 1040,
        content => $ots_base64,
        tags    => [
            ['e', $event1_id, 'wss://relay.example.com'],
            ['k', '1'],
        ],
    );
    my $ts = Net::Nostr::Timestamp->from_event($event);
    is $ts->event_id, $event1_id, 'event_id';
    is $ts->kind, 1, 'kind parsed from k tag';
    is $ts->ots_data, $ots_base64, 'ots_data';
    is $ts->relay_url, 'wss://relay.example.com', 'relay_url';
};

subtest 'from_event without relay URL' => sub {
    my $event = make_event(
        pubkey  => $alice_pk,
        kind    => 1040,
        content => $ots_base64,
        tags    => [
            ['e', $event1_id],
            ['k', '1'],
        ],
    );
    my $ts = Net::Nostr::Timestamp->from_event($event);
    is $ts->event_id, $event1_id, 'event_id';
    ok !defined($ts->relay_url), 'relay_url is undef';
};

subtest 'from_event croaks on non-kind-1040 event' => sub {
    my $event = make_event(pubkey => $alice_pk, kind => 1, content => 'hello');
    ok dies { Net::Nostr::Timestamp->from_event($event) }, 'croaks on non-1040';
};

###############################################################################
# Round-trip: Timestamp -> Event -> Timestamp
###############################################################################

subtest 'round-trip preserves all fields' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey    => $alice_pk,
        event_id  => $event1_id,
        kind      => 30023,
        ots_data  => $ots_base64,
        relay_url => 'wss://nostr-pub.wellorder.net',
    );
    my $event = $ts->to_event;
    my $ts2 = Net::Nostr::Timestamp->from_event($event);

    is $ts2->event_id, $event1_id, 'event_id round-trips';
    is $ts2->kind, 30023, 'kind round-trips';
    is $ts2->ots_data, $ots_base64, 'ots_data round-trips';
    is $ts2->relay_url, 'wss://nostr-pub.wellorder.net', 'relay_url round-trips';
};

subtest 'round-trip without relay URL' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $alice_pk,
        event_id => $event1_id,
        kind     => 1,
        ots_data => $ots_base64,
    );
    my $event = $ts->to_event;
    my $ts2 = Net::Nostr::Timestamp->from_event($event);

    is $ts2->event_id, $event1_id, 'event_id round-trips';
    is $ts2->kind, 1, 'kind round-trips';
    ok !defined($ts2->relay_url), 'relay_url stays undef';
};

###############################################################################
# Validation
###############################################################################

subtest 'new croaks without event_id' => sub {
    ok dies {
        Net::Nostr::Timestamp->new(
            pubkey => $alice_pk, kind => 1, ots_data => $ots_base64,
        )->to_event;
    }, 'croaks without event_id';
};

subtest 'new croaks without kind' => sub {
    ok dies {
        Net::Nostr::Timestamp->new(
            pubkey => $alice_pk, event_id => $event1_id, ots_data => $ots_base64,
        )->to_event;
    }, 'croaks without kind';
};

subtest 'new croaks without ots_data' => sub {
    ok dies {
        Net::Nostr::Timestamp->new(
            pubkey => $alice_pk, event_id => $event1_id, kind => 1,
        )->to_event;
    }, 'croaks without ots_data';
};

subtest 'new croaks without pubkey' => sub {
    ok dies {
        Net::Nostr::Timestamp->new(
            event_id => $event1_id, kind => 1, ots_data => $ots_base64,
        )->to_event;
    }, 'croaks without pubkey';
};

###############################################################################
# Extra event args pass through to Event constructor
###############################################################################

subtest 'extra args pass through to Event constructor' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $alice_pk,
        event_id => $event1_id,
        kind     => 1,
        ots_data => $ots_base64,
    );
    my $event = $ts->to_event(created_at => 1700000000);
    is $event->created_at, 1700000000, 'created_at passed through';
};

###############################################################################
# Hex64 validation for event_id
###############################################################################

subtest 'rejects invalid hex64 in event_id' => sub {
    ok dies {
        Net::Nostr::Timestamp->new(
            pubkey => $alice_pk, event_id => 'not-valid-hex', kind => 1, ots_data => $ots_base64,
        )->to_event;
    }, 'croaks on non-hex event_id';

    ok dies {
        Net::Nostr::Timestamp->new(
            pubkey => $alice_pk, event_id => 'AABB' x 16, kind => 1, ots_data => $ots_base64,
        )->to_event;
    }, 'croaks on uppercase event_id';

    ok dies {
        Net::Nostr::Timestamp->new(
            pubkey => $alice_pk, event_id => 'aa' x 31, kind => 1, ots_data => $ots_base64,
        )->to_event;
    }, 'croaks on too-short event_id';
};

done_testing;
