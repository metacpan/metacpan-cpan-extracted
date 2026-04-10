#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;
use MIME::Base64 ();

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Event;
use Net::Nostr::Timestamp;

my $my_pubkey = 'a' x 64;
my $target_event_id = '1' x 64;

my $ots_base64 = MIME::Base64::encode_base64("fake-ots-proof-data", '');

###############################################################################
# POD SYNOPSIS examples
###############################################################################

subtest 'POD: create a timestamp attestation' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey    => $my_pubkey,
        event_id  => $target_event_id,
        kind      => 1,
        ots_data  => $ots_base64,
        relay_url => 'wss://relay.example.com',
    );
    my $event = $ts->to_event;
    is $event->kind, 1040, 'kind 1040';
    is $event->content, $ots_base64, 'content is OTS data';
};

subtest 'POD: parse a received timestamp attestation' => sub {
    my $event = make_event(
        pubkey  => $my_pubkey,
        kind    => 1040,
        content => $ots_base64,
        tags    => [
            ['e', $target_event_id, 'wss://relay.example.com'],
            ['k', '1'],
        ],
    );
    my $ts = Net::Nostr::Timestamp->from_event($event);
    is $ts->event_id, $target_event_id, 'event_id';
    is $ts->kind, 1, 'kind';
    is $ts->relay_url, 'wss://relay.example.com', 'relay_url';
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::Timestamp->new(pubkey => 'a' x 64, bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

###############################################################################
# Round-trip tests
###############################################################################

subtest 'round-trip without relay_url' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $my_pubkey,
        event_id => $target_event_id,
        kind     => 1,
        ots_data => $ots_base64,
    );
    my $event = $ts->to_event;
    my $ts2 = Net::Nostr::Timestamp->from_event($event);
    is $ts2->pubkey,    $my_pubkey,        'pubkey survives round-trip';
    is $ts2->event_id,  $target_event_id,  'event_id survives round-trip';
    is $ts2->kind,      1,                 'kind survives round-trip';
    is $ts2->ots_data,  $ots_base64,       'ots_data survives round-trip';
    is $ts2->relay_url, undef,             'relay_url is undef when absent';
};

subtest 'round-trip with relay_url' => sub {
    my $relay = 'wss://relay.example.com';
    my $ts = Net::Nostr::Timestamp->new(
        pubkey    => $my_pubkey,
        event_id  => $target_event_id,
        kind      => 1,
        ots_data  => $ots_base64,
        relay_url => $relay,
    );
    my $event = $ts->to_event;
    my $ts2 = Net::Nostr::Timestamp->from_event($event);
    is $ts2->pubkey,    $my_pubkey,        'pubkey survives round-trip';
    is $ts2->event_id,  $target_event_id,  'event_id survives round-trip';
    is $ts2->kind,      1,                 'kind survives round-trip';
    is $ts2->ots_data,  $ots_base64,       'ots_data survives round-trip';
    is $ts2->relay_url, $relay,            'relay_url survives round-trip';
};

###############################################################################
# to_event rejection tests
###############################################################################

subtest 'to_event rejects missing pubkey' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        event_id => $target_event_id,
        kind     => 1,
        ots_data => $ots_base64,
    );
    like(
        dies { $ts->to_event },
        qr/pubkey is required/,
        'missing pubkey rejected'
    );
};

subtest 'to_event rejects missing event_id' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $my_pubkey,
        kind     => 1,
        ots_data => $ots_base64,
    );
    like(
        dies { $ts->to_event },
        qr/event_id is required/,
        'missing event_id rejected'
    );
};

subtest 'to_event rejects missing kind' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $my_pubkey,
        event_id => $target_event_id,
        ots_data => $ots_base64,
    );
    like(
        dies { $ts->to_event },
        qr/kind is required/,
        'missing kind rejected'
    );
};

subtest 'to_event rejects missing ots_data' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $my_pubkey,
        event_id => $target_event_id,
        kind     => 1,
    );
    like(
        dies { $ts->to_event },
        qr/ots_data is required/,
        'missing ots_data rejected'
    );
};

subtest 'to_event rejects invalid event_id hex' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $my_pubkey,
        event_id => 'ZZZZ' x 16,
        kind     => 1,
        ots_data => $ots_base64,
    );
    like(
        dies { $ts->to_event },
        qr/event_id.*hex/,
        'invalid hex event_id rejected'
    );
};

###############################################################################
# from_event rejection tests
###############################################################################

subtest 'from_event rejects wrong kind' => sub {
    my $event = make_event(
        pubkey  => $my_pubkey,
        kind    => 1,
        content => $ots_base64,
        tags    => [
            ['e', $target_event_id],
            ['k', '1'],
        ],
    );
    like(
        dies { Net::Nostr::Timestamp->from_event($event) },
        qr/kind 1040/,
        'non-1040 event rejected'
    );
};

###############################################################################
# to_event output verification
###############################################################################

subtest 'to_event passes through created_at' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $my_pubkey,
        event_id => $target_event_id,
        kind     => 1,
        ots_data => $ots_base64,
    );
    my $event = $ts->to_event(created_at => 1700000000);
    is $event->created_at, 1700000000, 'created_at passed through';
};

subtest 'to_event sets kind 1040' => sub {
    my $ts = Net::Nostr::Timestamp->new(
        pubkey   => $my_pubkey,
        event_id => $target_event_id,
        kind     => 1,
        ots_data => $ots_base64,
    );
    my $event = $ts->to_event;
    is $event->kind, 1040, 'event kind is 1040';
};

done_testing;
