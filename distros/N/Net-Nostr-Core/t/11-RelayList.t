#!/usr/bin/perl

# Unit tests for Net::Nostr::RelayList

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::RelayList;

###############################################################################
# Constructor
###############################################################################

subtest 'new creates empty relay list' => sub {
    my $rl = Net::Nostr::RelayList->new;
    isa_ok($rl, 'Net::Nostr::RelayList');
    is($rl->count, 0, 'starts empty');
};

###############################################################################
# add validation
###############################################################################

subtest 'add requires a URL' => sub {
    my $rl = Net::Nostr::RelayList->new;
    like(dies { $rl->add(undef) }, qr/url required/i, 'undef rejected');
};

subtest 'add rejects invalid marker' => sub {
    my $rl = Net::Nostr::RelayList->new;
    like(dies { $rl->add('wss://r.com', marker => 'both') },
        qr/marker/, 'invalid marker rejected');
    like(dies { $rl->add('wss://r.com', marker => 'WRITE') },
        qr/marker/, 'uppercase marker rejected');
};

subtest 'add accepts valid markers' => sub {
    my $rl = Net::Nostr::RelayList->new;
    ok(lives { $rl->add('wss://r1.com') }, 'no marker ok');
    ok(lives { $rl->add('wss://r2.com', marker => 'read') }, 'read ok');
    ok(lives { $rl->add('wss://r3.com', marker => 'write') }, 'write ok');
    is($rl->count, 3, 'three relays added');
};

###############################################################################
# from_event validation
###############################################################################

subtest 'from_event requires kind 10002' => sub {
    require Net::Nostr::Event;
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1, content => '', tags => [],
    );
    like(dies { Net::Nostr::RelayList->from_event($event) },
        qr/kind 10002/, 'wrong kind rejected');
};

###############################################################################
# relays returns list in order
###############################################################################

subtest 'relays preserves insertion order' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://first.com');
    $rl->add('wss://second.com');
    $rl->add('wss://third.com');

    my @relays = $rl->relays;
    is($relays[0]{url}, 'wss://first.com', 'first');
    is($relays[1]{url}, 'wss://second.com', 'second');
    is($relays[2]{url}, 'wss://third.com', 'third');
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::RelayList->new(bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

###############################################################################
# remove basic
###############################################################################

subtest 'remove basic' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://a.com');
    $rl->add('wss://b.com');
    $rl->remove('wss://a.com');
    is($rl->count, 1, 'count is 1 after remove');
    is($rl->contains('wss://a.com'), 0, 'removed URL no longer present');
    is($rl->contains('wss://b.com'), 1, 'other URL still present');
};

###############################################################################
# remove non-existent is no-op
###############################################################################

subtest 'remove non-existent is no-op' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://a.com');
    $rl->remove('wss://nope.com');
    is($rl->count, 1, 'count unchanged');
};

###############################################################################
# remove returns self for chaining
###############################################################################

subtest 'remove returns self for chaining' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://r.com');
    my $ret = $rl->remove('wss://r.com');
    ref_is($ret, $rl, 'remove returns same object');
};

###############################################################################
# contains true and false
###############################################################################

subtest 'contains true and false' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://yes.com');
    is($rl->contains('wss://yes.com'), 1, 'known URL returns 1');
    is($rl->contains('wss://no.com'), 0, 'unknown URL returns 0');
};

###############################################################################
# write_relays POD example
###############################################################################

subtest 'write_relays POD example' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://both.example.com');
    $rl->add('wss://w.example.com', marker => 'write');
    $rl->add('wss://r.example.com', marker => 'read');
    my @write = $rl->write_relays;
    is(\@write,
        bag { item 'wss://both.example.com'; item 'wss://w.example.com'; end },
        'write_relays returns unmarked + write-marked');
};

###############################################################################
# read_relays POD example
###############################################################################

subtest 'read_relays POD example' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://both.example.com');
    $rl->add('wss://w.example.com', marker => 'write');
    $rl->add('wss://r.example.com', marker => 'read');
    my @read = $rl->read_relays;
    is(\@read,
        bag { item 'wss://both.example.com'; item 'wss://r.example.com'; end },
        'read_relays returns unmarked + read-marked');
};

###############################################################################
# to_tags format
###############################################################################

subtest 'to_tags format' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://plain.com');
    $rl->add('wss://w.com', marker => 'write');
    $rl->add('wss://r.com', marker => 'read');
    my $tags = $rl->to_tags;
    is($tags, [
        ['r', 'wss://plain.com'],
        ['r', 'wss://w.com', 'write'],
        ['r', 'wss://r.com', 'read'],
    ], 'to_tags produces correct arrayrefs');
};

###############################################################################
# to_event creates kind 10002
###############################################################################

subtest 'to_event creates kind 10002' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://relay.com');
    my $event = $rl->to_event(pubkey => 'a' x 64);
    isa_ok($event, 'Net::Nostr::Event');
    is($event->kind, 10002, 'kind is 10002');
    is($event->content, '', 'content is empty string');
};

###############################################################################
# Round-trip: add -> to_event -> from_event
###############################################################################

subtest 'round-trip: add -> to_event -> from_event' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://both.com');
    $rl->add('wss://r.com', marker => 'read');
    $rl->add('wss://w.com', marker => 'write');

    my $event = $rl->to_event(pubkey => 'a' x 64);
    my $rl2 = Net::Nostr::RelayList->from_event($event);

    is($rl2->count, 3, 'same count after round-trip');
    my @relays = $rl2->relays;
    is($relays[0]{url}, 'wss://both.com', 'first URL');
    is($relays[0]{marker}, '', 'first marker empty');
    is($relays[1]{url}, 'wss://r.com', 'second URL');
    is($relays[1]{marker}, 'read', 'second marker read');
    is($relays[2]{url}, 'wss://w.com', 'third URL');
    is($relays[2]{marker}, 'write', 'third marker write');
};

###############################################################################
# add replaces existing URL
###############################################################################

subtest 'add replaces existing URL' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://r.com');
    $rl->add('wss://r.com', marker => 'write');
    is($rl->count, 1, 'count stays 1');
    my @relays = $rl->relays;
    is($relays[0]{marker}, 'write', 'marker updated to write');
};

###############################################################################
# POD: chaining add calls
###############################################################################

subtest 'POD: chaining add calls' => sub {
    my $rl = Net::Nostr::RelayList->new;
    $rl->add('wss://r1.com')->add('wss://r2.com');
    is($rl->count, 2, 'chained add produces 2 relays');
};

done_testing;
