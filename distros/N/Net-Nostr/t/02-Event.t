#!/usr/bin/perl

use strictures 2;

use Test2::V0 -no_srand => 1;
# use Test2::Plugin::BailOnFail; # bail out of testing on the first failure
use Clone 'clone';

use lib 't/lib';
use TestFixtures qw(%FIATJAF_EVENT);

use Net::Nostr::Key;
use Net::Nostr::Event;

my $EVENT = Net::Nostr::Event->new(%FIATJAF_EVENT);

subtest 'new()' => sub {
    my $event = Net::Nostr::Event->new(
        content => $EVENT->content,
        pubkey => $EVENT->pubkey,
        kind => $EVENT->kind,
        sig => $EVENT->sig,
        created_at => $EVENT->created_at
    );
    is($event->id, $EVENT->id, 'automatically calculates id');
    is(ref($event), 'Net::Nostr::Event', 'constructs a Net::Nostr::Event');

    $event = Net::Nostr::Event->new(
        content => '',
        pubkey => 0,
        kind => 1,
        sig => ''
    );
    is($event->created_at, time(), 'automatically determines created_at');

};

subtest 'json_serialize()' => sub {
    my $event = Net::Nostr::Event->new(
        content => 'hello',
        pubkey => '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d',
        kind => 1,
        sig => '',
        created_at => 1673361254,
        tags => [['p', 'abc123'], ['e', 'def456']]
    );
    my $json = $event->json_serialize;
    my $decoded = JSON::decode_json($json);
    is($decoded->[4], [['p', 'abc123'], ['e', 'def456']], 'tags serialize as array of arrays');
};

subtest 'add_pubkey_ref()' => sub {
    my $event = Net::Nostr::Event->new(
        content => 'hello',
        pubkey => 'abc',
        kind => 1,
        sig => '',
        created_at => 1673361254,
        tags => [['e', 'event1']]
    );
    $event->add_pubkey_ref('pubkey1');
    is($event->tags, [['e', 'event1'], ['p', 'pubkey1']], 'appends p tag without nesting');
};

subtest 'add_event_ref()' => sub {
    my $event = Net::Nostr::Event->new(
        content => 'hello',
        pubkey => 'abc',
        kind => 1,
        sig => '',
        created_at => 1673361254,
        tags => [['p', 'pubkey1']]
    );
    $event->add_event_ref('event1');
    is($event->tags, [['p', 'pubkey1'], ['e', 'event1']], 'appends e tag without nesting');
};

subtest 'created_at 0 is preserved' => sub {
    my $event = Net::Nostr::Event->new(
        content => '', pubkey => 'abc', kind => 1, sig => '',
        created_at => 0, tags => []
    );
    is($event->created_at, 0, 'created_at of 0 is not overwritten');
};

subtest 'to_hash()' => sub {
    my $event = Net::Nostr::Event->new(%FIATJAF_EVENT);
    my $h = $event->to_hash;
    is($h->{id}, $event->id, 'id');
    is($h->{pubkey}, $event->pubkey, 'pubkey');
    is($h->{created_at}, $event->created_at, 'created_at');
    is($h->{kind}, $event->kind, 'kind');
    is($h->{tags}, $event->tags, 'tags');
    is($h->{content}, $event->content, 'content');
    is($h->{sig}, $event->sig, 'sig');
    is(scalar keys %$h, 7, 'exactly 7 fields');
};

subtest 'kind classification' => sub {
    for my $k (1, 2, 4, 44, 1000, 9999) {
        my $e = Net::Nostr::Event->new(
            pubkey => 'a', kind => $k, content => '', sig => '', created_at => 1, tags => []
        );
        ok($e->is_regular, "kind $k is regular");
        ok(!$e->is_replaceable, "kind $k is not replaceable");
        ok(!$e->is_ephemeral, "kind $k is not ephemeral");
        ok(!$e->is_addressable, "kind $k is not addressable");
    }
    for my $k (0, 3, 10000, 19999) {
        my $e = Net::Nostr::Event->new(
            pubkey => 'a', kind => $k, content => '', sig => '', created_at => 1, tags => []
        );
        ok($e->is_replaceable, "kind $k is replaceable");
        ok(!$e->is_regular, "kind $k is not regular");
    }
    for my $k (20000, 25000, 29999) {
        my $e = Net::Nostr::Event->new(
            pubkey => 'a', kind => $k, content => '', sig => '', created_at => 1, tags => []
        );
        ok($e->is_ephemeral, "kind $k is ephemeral");
        ok(!$e->is_regular, "kind $k is not regular");
    }
    for my $k (30000, 35000, 39999) {
        my $e = Net::Nostr::Event->new(
            pubkey => 'a', kind => $k, content => '', sig => '', created_at => 1, tags => []
        );
        ok($e->is_addressable, "kind $k is addressable");
        ok(!$e->is_regular, "kind $k is not regular");
    }
};

subtest 'POD: d_tag returns d tag value' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 30023,
        content => '', tags => [['d', 'my-article']],
    );
    is($event->d_tag, 'my-article', 'd_tag returns value of d tag');
};

subtest 'POD: d_tag returns empty string when no d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 30023,
        content => '', tags => [['t', 'nostr']],
    );
    is($event->d_tag, '', 'd_tag returns empty string without d tag');
};

subtest 'POD: d_tag returns empty string for d tag with no value' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 30023,
        content => '', tags => [['d']],
    );
    is($event->d_tag, '', 'd_tag returns empty string for valueless d tag');
};

subtest 'verify_sig()' => sub {
    my $key = Net::Nostr::Key->new;
    my $event = Net::Nostr::Event->new(
        pubkey => $key->pubkey_hex, kind => 1, content => 'test',
        sig => '', created_at => 1000, tags => []
    );
    my $sig_hex = unpack 'H*', $key->schnorr_sign($event->id);
    $event->sig($sig_hex);
    ok($event->verify_sig($key), 'valid sig verifies');

    my $other_key = Net::Nostr::Key->new;
    ok(!$event->verify_sig($other_key), 'wrong key fails');
};

done_testing;
