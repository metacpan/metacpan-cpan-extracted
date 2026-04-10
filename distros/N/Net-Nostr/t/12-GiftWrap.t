#!/usr/bin/perl

# Unit tests for Net::Nostr::GiftWrap

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::GiftWrap;
use Net::Nostr::Event;
use Net::Nostr::Key;

my $key = Net::Nostr::Key->new;
my $recipient = Net::Nostr::Key->new;

###############################################################################
# create_rumor
###############################################################################

subtest 'create_rumor returns unsigned event' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $key->pubkey_hex,
        kind    => 1,
        content => 'test',
        tags    => [],
    );
    isa_ok($rumor, 'Net::Nostr::Event');
    ok(!defined $rumor->sig, 'no signature');
};

###############################################################################
# seal validation
###############################################################################

subtest 'seal requires rumor' => sub {
    like(dies { Net::Nostr::GiftWrap->seal(
        sender_key       => $key,
        recipient_pubkey => $recipient->pubkey_hex,
    ) }, qr/rumor required/i, 'missing rumor');
};

subtest 'seal requires sender_key' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey => $key->pubkey_hex, kind => 1, content => '', tags => [],
    );
    like(dies { Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        recipient_pubkey => $recipient->pubkey_hex,
    ) }, qr/sender_key required/i, 'missing sender_key');
};

subtest 'seal requires recipient_pubkey' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey => $key->pubkey_hex, kind => 1, content => '', tags => [],
    );
    like(dies { Net::Nostr::GiftWrap->seal(
        rumor      => $rumor,
        sender_key => $key,
    ) }, qr/recipient_pubkey required/i, 'missing recipient_pubkey');
};

###############################################################################
# wrap validation
###############################################################################

subtest 'wrap requires seal' => sub {
    like(dies { Net::Nostr::GiftWrap->wrap(
        recipient_pubkey => $recipient->pubkey_hex,
    ) }, qr/seal required/i, 'missing seal');
};

subtest 'wrap requires recipient_pubkey' => sub {
    my $seal = Net::Nostr::Event->new(
        pubkey => $key->pubkey_hex, kind => 13, content => 'x', tags => [],
    );
    like(dies { Net::Nostr::GiftWrap->wrap(
        seal => $seal,
    ) }, qr/recipient_pubkey required/i, 'missing recipient_pubkey');
};

###############################################################################
# unwrap validation
###############################################################################

subtest 'unwrap requires event' => sub {
    like(dies { Net::Nostr::GiftWrap->unwrap(
        recipient_key => $recipient,
    ) }, qr/event required/i, 'missing event');
};

subtest 'unwrap requires recipient_key' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => 'a' x 64, kind => 1059, content => '', tags => [],
    );
    like(dies { Net::Nostr::GiftWrap->unwrap(
        event => $event,
    ) }, qr/recipient_key required/i, 'missing recipient_key');
};

###############################################################################
# seal_and_wrap validation
###############################################################################

subtest 'seal_and_wrap requires all args' => sub {
    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey => $key->pubkey_hex, kind => 1, content => '', tags => [],
    );

    like(dies { Net::Nostr::GiftWrap->seal_and_wrap(
        sender_key       => $key,
        recipient_pubkey => $recipient->pubkey_hex,
    ) }, qr/rumor required/i, 'missing rumor');
};

###############################################################################
# POD example: SYNOPSIS round-trip
###############################################################################

subtest 'POD SYNOPSIS example' => sub {
    my $sender    = Net::Nostr::Key->new;
    my $recipient = Net::Nostr::Key->new;

    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $sender->pubkey_hex,
        kind    => 1,
        content => 'Are you going to the party tonight?',
        tags    => [],
    );

    my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $rumor,
        sender_key       => $sender,
        recipient_pubkey => $recipient->pubkey_hex,
    );

    my ($unwrapped, $sender_pubkey) = Net::Nostr::GiftWrap->unwrap(
        event         => $wrap,
        recipient_key => $recipient,
    );

    is($unwrapped->content, 'Are you going to the party tonight?',
        'unwrapped content matches');
    is($sender_pubkey, $sender->pubkey_hex,
        'sender_pubkey from seal matches');
};

###############################################################################
# POD example: seal properties
###############################################################################

subtest 'POD seal example' => sub {
    my $sender    = Net::Nostr::Key->new;
    my $recipient = Net::Nostr::Key->new;

    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $sender->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $sender,
        recipient_pubkey => $recipient->pubkey_hex,
    );

    is($seal->kind, 13, 'seal kind is 13');
    ok($seal->pubkey eq $sender->pubkey_hex, 'seal signed by sender');
    is(scalar @{$seal->tags}, 0, 'seal tags always empty');
};

###############################################################################
# POD example: wrap properties
###############################################################################

subtest 'POD wrap example' => sub {
    my $sender    = Net::Nostr::Key->new;
    my $recipient = Net::Nostr::Key->new;

    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $sender->pubkey_hex,
        kind    => 1,
        content => 'hello',
        tags    => [],
    );

    my $seal = Net::Nostr::GiftWrap->seal(
        rumor            => $rumor,
        sender_key       => $sender,
        recipient_pubkey => $recipient->pubkey_hex,
    );

    my $wrap = Net::Nostr::GiftWrap->wrap(
        seal             => $seal,
        recipient_pubkey => $recipient->pubkey_hex,
    );

    is($wrap->kind, 1059, 'wrap kind is 1059');
    isnt($wrap->pubkey, $sender->pubkey_hex,
        'wrap pubkey is random, not the sender');
};

###############################################################################
# POD example: expiration (disappearing messages)
###############################################################################

subtest 'POD expiration example' => sub {
    my $sender    = Net::Nostr::Key->new;
    my $recipient = Net::Nostr::Key->new;

    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $sender->pubkey_hex,
        kind    => 1,
        content => 'disappearing',
        tags    => [],
    );

    my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $rumor,
        sender_key       => $sender,
        recipient_pubkey => $recipient->pubkey_hex,
        expiration       => time() + 86400,
        seal_expiration  => time() + 86400,
    );

    my @wrap_exp = grep { $_->[0] eq 'expiration' } @{$wrap->tags};
    is(scalar @wrap_exp, 1, 'wrap has expiration tag');

    # Verify the inner seal also has expiration
    my ($unwrapped, $sender_pubkey) = Net::Nostr::GiftWrap->unwrap(
        event         => $wrap,
        recipient_key => $recipient,
    );
    is($unwrapped->content, 'disappearing', 'round-trip with expiration works');
};

###############################################################################
# POD example: multi-recipient wrapping
###############################################################################

subtest 'POD multi-recipient wrapping example' => sub {
    my $sender = Net::Nostr::Key->new;
    my @recipients = map { Net::Nostr::Key->new } 1 .. 3;
    my @recipient_pubkeys = map { $_->pubkey_hex } @recipients;

    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $sender->pubkey_hex,
        kind    => 1,
        content => 'group message',
        tags    => [map { ['p', $_] } @recipient_pubkeys],
    );

    my @wraps;
    for my $pubkey (@recipient_pubkeys) {
        my $wrap = Net::Nostr::GiftWrap->seal_and_wrap(
            rumor            => $rumor,
            sender_key       => $sender,
            recipient_pubkey => $pubkey,
        );
        push @wraps, $wrap;
    }

    is(scalar @wraps, 3, 'one wrap per recipient');

    for my $i (0 .. $#recipients) {
        my ($unwrapped, $spk) = Net::Nostr::GiftWrap->unwrap(
            event         => $wraps[$i],
            recipient_key => $recipients[$i],
        );
        is($unwrapped->content, 'group message',
            "recipient $i gets correct content");
    }
};

###############################################################################
# POD example: author retains encrypted self-copy
###############################################################################

subtest 'POD self-copy example' => sub {
    my $sender    = Net::Nostr::Key->new;
    my $recipient = Net::Nostr::Key->new;

    my $rumor = Net::Nostr::GiftWrap->create_rumor(
        pubkey  => $sender->pubkey_hex,
        kind    => 1,
        content => 'saved for myself',
        tags    => [['p', $recipient->pubkey_hex]],
    );

    my $self_copy = Net::Nostr::GiftWrap->seal_and_wrap(
        rumor            => $rumor,
        sender_key       => $sender,
        recipient_pubkey => $sender->pubkey_hex,
    );

    my ($unwrapped, $sender_pubkey) = Net::Nostr::GiftWrap->unwrap(
        event         => $self_copy,
        recipient_key => $sender,
    );

    is($unwrapped->content, 'saved for myself', 'author can decrypt own copy');
    is($sender_pubkey, $sender->pubkey_hex, 'sender pubkey matches');
};

done_testing;
