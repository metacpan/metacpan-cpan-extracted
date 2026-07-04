#!/usr/bin/perl

# NIP-61: Nutzaps
# https://github.com/nostr-protocol/nips/blob/master/61.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON ();

use Net::Nostr::Event;
use Net::Nostr::Nutzap;

my $PUBKEY  = 'aa' x 32;
my $PUBKEY2 = 'bb' x 32;
my $P2PK_PUBKEY = 'cc' x 32;
my $EVENTID = 'dd' x 32;

###############################################################################
# kind:10019 - Nutzap informational event
# "kind:10019 is an event that is useful for others to know how to send
#  money to the user"
###############################################################################

subtest 'info_event: creates kind 10019' => sub {
    my $event = Net::Nostr::Nutzap->info_event(
        pubkey => $PUBKEY,
        relays => ['wss://relay1', 'wss://relay2'],
        mints  => [
            { url => 'https://mint1', units => ['usd', 'sat'] },
            { url => 'https://mint2', units => ['sat'] },
        ],
        p2pk_pubkey => $P2PK_PUBKEY,
    );

    is($event->kind, 10019, 'kind is 10019');

    my @relay_tags = grep { $_->[0] eq 'relay' } @{$event->tags};
    is(scalar @relay_tags, 2, 'two relay tags');
    is($relay_tags[0][1], 'wss://relay1', 'first relay');
    is($relay_tags[1][1], 'wss://relay2', 'second relay');

    my @mint_tags = grep { $_->[0] eq 'mint' } @{$event->tags};
    is(scalar @mint_tags, 2, 'two mint tags');
    is($mint_tags[0][1], 'https://mint1', 'first mint url');
    is($mint_tags[0][2], 'usd', 'first mint unit 1');
    is($mint_tags[0][3], 'sat', 'first mint unit 2');
    is($mint_tags[1][1], 'https://mint2', 'second mint url');
    is($mint_tags[1][2], 'sat', 'second mint unit');

    my @pk_tags = grep { $_->[0] eq 'pubkey' } @{$event->tags};
    is(scalar @pk_tags, 1, 'one pubkey tag');
    is($pk_tags[0][1], $P2PK_PUBKEY, 'p2pk pubkey');
};

subtest 'info_event: requires pubkey, relays, mints, p2pk_pubkey' => sub {
    like(dies { Net::Nostr::Nutzap->info_event(
        relays => ['wss://r'], mints => [{url => 'https://m', units => ['sat']}],
        p2pk_pubkey => $P2PK_PUBKEY) },
        qr/pubkey/, 'missing pubkey');
    like(dies { Net::Nostr::Nutzap->info_event(
        pubkey => $PUBKEY, mints => [{url => 'https://m', units => ['sat']}],
        p2pk_pubkey => $P2PK_PUBKEY) },
        qr/relay/, 'missing relays');
    like(dies { Net::Nostr::Nutzap->info_event(
        pubkey => $PUBKEY, relays => ['wss://r'],
        p2pk_pubkey => $P2PK_PUBKEY) },
        qr/mint/, 'missing mints');
    like(dies { Net::Nostr::Nutzap->info_event(
        pubkey => $PUBKEY, relays => ['wss://r'],
        mints => [{url => 'https://m', units => ['sat']}]) },
        qr/p2pk_pubkey/, 'missing p2pk_pubkey');
};

subtest 'info_event: is replaceable (kind 10019)' => sub {
    my $event = Net::Nostr::Nutzap->info_event(
        pubkey => $PUBKEY,
        relays => ['wss://r'],
        mints  => [{ url => 'https://m', units => ['sat'] }],
        p2pk_pubkey => $P2PK_PUBKEY,
    );
    ok($event->is_replaceable, 'kind 10019 is replaceable');
};

###############################################################################
# Spec example: kind 10019
###############################################################################

subtest 'spec example: kind 10019' => sub {
    my $event = Net::Nostr::Nutzap->info_event(
        pubkey => $PUBKEY,
        relays => ['wss://relay1', 'wss://relay2'],
        mints  => [
            { url => 'https://mint1', units => ['usd', 'sat'] },
            { url => 'https://mint2', units => ['sat'] },
        ],
        p2pk_pubkey => $P2PK_PUBKEY,
    );

    # Verify tag structure matches spec example
    my @tags = @{$event->tags};
    my @relay = grep { $_->[0] eq 'relay' } @tags;
    my @mint  = grep { $_->[0] eq 'mint' } @tags;
    my @pk    = grep { $_->[0] eq 'pubkey' } @tags;

    is(scalar @relay, 2, 'two relay tags');
    is(scalar @mint, 2, 'two mint tags');
    is(scalar @pk, 1, 'one pubkey tag');

    # Mint with multiple units
    is($mint[0], ['mint', 'https://mint1', 'usd', 'sat'], 'mint with multiple units');
    is($mint[1], ['mint', 'https://mint2', 'sat'], 'mint with single unit');
};

###############################################################################
# kind:9321 - Nutzap event
# "Event kind:9321 is a nutzap event published by the sender, p-tagging
#  the recipient"
###############################################################################

subtest 'nutzap: creates kind 9321' => sub {
    my $proof = '{"amount":1,"C":"02...","id":"000a93d6f8a1d2c4","secret":"..."}';

    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey    => $PUBKEY,
        recipient => $PUBKEY2,
        proofs    => [$proof],
        mint_url  => 'https://stablenut.umint.cash',
        unit      => 'sat',
        event_id  => $EVENTID,
        event_kind => '1',
        relay_hint => 'wss://relay.example.com',
        content   => 'Thanks for this great idea.',
    );

    is($event->kind, 9321, 'kind is 9321');
    is($event->content, 'Thanks for this great idea.', 'content is comment');

    my @proof_tags = grep { $_->[0] eq 'proof' } @{$event->tags};
    is(scalar @proof_tags, 1, 'one proof tag');
    is($proof_tags[0][1], $proof, 'proof value');

    my @u_tags = grep { $_->[0] eq 'u' } @{$event->tags};
    is($u_tags[0][1], 'https://stablenut.umint.cash', 'u tag mint url');

    my @unit_tags = grep { $_->[0] eq 'unit' } @{$event->tags};
    is($unit_tags[0][1], 'sat', 'unit tag');

    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p_tags[0][1], $PUBKEY2, 'p tag recipient');

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e_tags[0][1], $EVENTID, 'e tag event id');
    is($e_tags[0][2], 'wss://relay.example.com', 'e tag relay hint');

    my @k_tags = grep { $_->[0] eq 'k' } @{$event->tags};
    is($k_tags[0][1], '1', 'k tag kind');
};

subtest 'nutzap: requires pubkey, recipient, proofs, mint_url' => sub {
    my @base = (proofs => ['x'], mint_url => 'https://m', recipient => $PUBKEY2);
    like(dies { Net::Nostr::Nutzap->nutzap(@base) }, qr/pubkey/, 'missing pubkey');

    @base = (pubkey => $PUBKEY, proofs => ['x'], mint_url => 'https://m');
    like(dies { Net::Nostr::Nutzap->nutzap(@base) }, qr/recipient/, 'missing recipient');

    @base = (pubkey => $PUBKEY, mint_url => 'https://m', recipient => $PUBKEY2);
    like(dies { Net::Nostr::Nutzap->nutzap(@base) }, qr/proof/, 'missing proofs');

    @base = (pubkey => $PUBKEY, proofs => ['x'], recipient => $PUBKEY2);
    like(dies { Net::Nostr::Nutzap->nutzap(@base) }, qr/mint_url/, 'missing mint_url');
};

subtest 'nutzap: multiple proofs' => sub {
    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey    => $PUBKEY,
        recipient => $PUBKEY2,
        proofs    => ['proof1', 'proof2', 'proof3'],
        mint_url  => 'https://mint.example',
    );

    my @proof_tags = grep { $_->[0] eq 'proof' } @{$event->tags};
    is(scalar @proof_tags, 3, 'three proof tags');
};

###############################################################################
# "content is an optional comment for the nutzap"
###############################################################################

subtest 'nutzap: content defaults to empty string' => sub {
    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey    => $PUBKEY,
        recipient => $PUBKEY2,
        proofs    => ['proof'],
        mint_url  => 'https://m',
    );
    is($event->content, '', 'content defaults to empty');
};

###############################################################################
# "unit: the base unit the proofs are denominated in ... Default: sat if
#  omitted"
###############################################################################

subtest 'nutzap: unit defaults to sat' => sub {
    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey    => $PUBKEY,
        recipient => $PUBKEY2,
        proofs    => ['proof'],
        mint_url  => 'https://m',
    );

    my @unit_tags = grep { $_->[0] eq 'unit' } @{$event->tags};
    is($unit_tags[0][1], 'sat', 'unit defaults to sat');
};

subtest 'nutzap: custom unit' => sub {
    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey    => $PUBKEY,
        recipient => $PUBKEY2,
        proofs    => ['proof'],
        mint_url  => 'https://m',
        unit      => 'usd',
    );

    my @unit_tags = grep { $_->[0] eq 'unit' } @{$event->tags};
    is($unit_tags[0][1], 'usd', 'unit set to usd');
};

###############################################################################
# "e is the event that is being nutzapped, if any"
###############################################################################

subtest 'nutzap: e tag without relay hint' => sub {
    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey    => $PUBKEY,
        recipient => $PUBKEY2,
        proofs    => ['proof'],
        mint_url  => 'https://m',
        event_id  => $EVENTID,
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is(scalar @e_tags, 1, 'e tag present');
    is($e_tags[0], ['e', $EVENTID], 'e tag has id only, no relay hint');
};

subtest 'nutzap: e and k tags are optional' => sub {
    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey    => $PUBKEY,
        recipient => $PUBKEY2,
        proofs    => ['proof'],
        mint_url  => 'https://m',
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    my @k_tags = grep { $_->[0] eq 'k' } @{$event->tags};
    is(scalar @e_tags, 0, 'no e tag when event_id not given');
    is(scalar @k_tags, 0, 'no k tag when event_kind not given');
};

###############################################################################
# kind:7376 - Nutzap redemption history
# "When claiming a token the client SHOULD create a kind:7376 event"
###############################################################################

subtest 'redemption: creates kind 7376' => sub {
    my $nutzap_id = 'ee' x 32;
    my $sender_pk = 'ff' x 32;

    my $event = Net::Nostr::Nutzap->redemption(
        pubkey        => $PUBKEY,
        nutzap_ids    => [$nutzap_id],
        sender_pubkey => $sender_pk,
        relay_hint    => 'wss://relay.example',
    );

    is($event->kind, 7376, 'kind is 7376');

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is(scalar @e_tags, 1, 'one e tag');
    is($e_tags[0][1], $nutzap_id, 'e tag nutzap id');
    is($e_tags[0][2], 'wss://relay.example', 'e tag relay hint');
    is($e_tags[0][3], 'redeemed', 'e tag marker');

    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p_tags[0][1], $sender_pk, 'p tag sender pubkey');
};

###############################################################################
# "Multiple kind:9321 events can be tagged in the same kind:7376 event"
###############################################################################

subtest 'redemption: multiple nutzap ids' => sub {
    my $id1 = 'e1' x 32;
    my $id2 = 'e2' x 32;

    my $event = Net::Nostr::Nutzap->redemption(
        pubkey        => $PUBKEY,
        nutzap_ids    => [$id1, $id2],
        sender_pubkey => $PUBKEY2,
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is(scalar @e_tags, 2, 'two e tags for two nutzaps');
    is($e_tags[0][1], $id1, 'first nutzap id');
    is($e_tags[0][3], 'redeemed', 'first marker');
    is($e_tags[1][1], $id2, 'second nutzap id');
    is($e_tags[1][3], 'redeemed', 'second marker');
};

subtest 'redemption: requires pubkey, nutzap_ids, sender_pubkey' => sub {
    like(dies { Net::Nostr::Nutzap->redemption(
        nutzap_ids => ['x'], sender_pubkey => $PUBKEY2) },
        qr/pubkey/, 'missing pubkey');
    like(dies { Net::Nostr::Nutzap->redemption(
        pubkey => $PUBKEY, sender_pubkey => $PUBKEY2) },
        qr/nutzap_ids/, 'missing nutzap_ids');
    like(dies { Net::Nostr::Nutzap->redemption(
        pubkey => $PUBKEY, nutzap_ids => ['x']) },
        qr/sender_pubkey/, 'missing sender_pubkey');
};

###############################################################################
# from_event: parse nutzap-related events
###############################################################################

subtest 'from_event: parses kind 10019 info' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 10019, content => '', created_at => 1000,
        tags => [
            ['relay', 'wss://relay1'],
            ['relay', 'wss://relay2'],
            ['mint', 'https://mint1', 'usd', 'sat'],
            ['mint', 'https://mint2', 'sat'],
            ['pubkey', $P2PK_PUBKEY],
        ],
    );

    my $info = Net::Nostr::Nutzap->from_event($event);
    ok(defined $info, 'parsed successfully');
    is($info->relays, ['wss://relay1', 'wss://relay2'], 'relays');
    is(scalar @{$info->mints}, 2, 'two mints');
    is($info->mints->[0]{url}, 'https://mint1', 'first mint url');
    is($info->mints->[0]{units}, ['usd', 'sat'], 'first mint units');
    is($info->mints->[1]{url}, 'https://mint2', 'second mint url');
    is($info->mints->[1]{units}, ['sat'], 'second mint units');
    is($info->p2pk_pubkey, $P2PK_PUBKEY, 'p2pk pubkey');
};

subtest 'from_event: parses kind 9321 nutzap' => sub {
    my $proof = '{"amount":1,"id":"abc"}';
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 9321, content => 'nice!', created_at => 1000,
        tags => [
            ['proof', $proof],
            ['u', 'https://mint.example'],
            ['unit', 'sat'],
            ['p', $PUBKEY2],
            ['e', $EVENTID, 'wss://relay.example'],
            ['k', '1'],
        ],
    );

    my $info = Net::Nostr::Nutzap->from_event($event);
    ok(defined $info, 'parsed successfully');
    is($info->proofs, [$proof], 'proofs');
    is($info->mint_url, 'https://mint.example', 'mint_url');
    is($info->unit, 'sat', 'unit');
    is($info->recipient, $PUBKEY2, 'recipient');
    is($info->event_id, $EVENTID, 'event_id');
    is($info->event_kind, '1', 'event_kind');
};

subtest 'from_event: parses kind 7376 redemption' => sub {
    my $nutzap_id = 'ee' x 32;
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 7376, content => '', created_at => 1000,
        tags => [
            ['e', $nutzap_id, 'wss://r', 'redeemed'],
            ['p', $PUBKEY2],
        ],
    );

    my $info = Net::Nostr::Nutzap->from_event($event);
    ok(defined $info, 'parsed successfully');
    is($info->nutzap_ids, [$nutzap_id], 'nutzap_ids');
    is($info->sender_pubkey, $PUBKEY2, 'sender_pubkey');
};

subtest 'from_event: returns undef for unrelated kinds' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => 'note', created_at => 1000,
        tags => [],
    );
    is(Net::Nostr::Nutzap->from_event($event), undef, 'kind 1 returns undef');
};

###############################################################################
# validate
###############################################################################

subtest 'validate: valid kind 10019' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 10019, content => '', created_at => 1000,
        tags => [
            ['relay', 'wss://r'],
            ['mint', 'https://m', 'sat'],
            ['pubkey', $P2PK_PUBKEY],
        ],
    );
    ok(Net::Nostr::Nutzap->validate($event), 'valid 10019');
};

subtest 'validate: kind 10019 missing relay' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 10019, content => '', created_at => 1000,
        tags => [
            ['mint', 'https://m', 'sat'],
            ['pubkey', $P2PK_PUBKEY],
        ],
    );
    like(dies { Net::Nostr::Nutzap->validate($event) }, qr/relay/, 'missing relay');
};

subtest 'validate: kind 10019 missing mint' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 10019, content => '', created_at => 1000,
        tags => [
            ['relay', 'wss://r'],
            ['pubkey', $P2PK_PUBKEY],
        ],
    );
    like(dies { Net::Nostr::Nutzap->validate($event) }, qr/mint/, 'missing mint');
};

subtest 'validate: kind 10019 missing pubkey tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 10019, content => '', created_at => 1000,
        tags => [
            ['relay', 'wss://r'],
            ['mint', 'https://m', 'sat'],
        ],
    );
    like(dies { Net::Nostr::Nutzap->validate($event) }, qr/pubkey/, 'missing pubkey tag');
};

subtest 'validate: valid kind 9321' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 9321, content => '', created_at => 1000,
        tags => [
            ['proof', '{}'],
            ['u', 'https://m'],
            ['p', $PUBKEY2],
        ],
    );
    ok(Net::Nostr::Nutzap->validate($event), 'valid 9321');
};

subtest 'validate: kind 9321 missing proof' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 9321, content => '', created_at => 1000,
        tags => [
            ['u', 'https://m'],
            ['p', $PUBKEY2],
        ],
    );
    like(dies { Net::Nostr::Nutzap->validate($event) }, qr/proof/, 'missing proof');
};

subtest 'validate: kind 9321 missing u tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 9321, content => '', created_at => 1000,
        tags => [
            ['proof', '{}'],
            ['p', $PUBKEY2],
        ],
    );
    like(dies { Net::Nostr::Nutzap->validate($event) }, qr/u tag/, 'missing u tag');
};

subtest 'validate: kind 9321 missing p tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 9321, content => '', created_at => 1000,
        tags => [
            ['proof', '{}'],
            ['u', 'https://m'],
        ],
    );
    like(dies { Net::Nostr::Nutzap->validate($event) }, qr/p tag/, 'missing p tag');
};

subtest 'validate: valid kind 7376' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 7376, content => '', created_at => 1000,
        tags => [
            ['e', $EVENTID, '', 'redeemed'],
            ['p', $PUBKEY2],
        ],
    );
    ok(Net::Nostr::Nutzap->validate($event), 'valid 7376');
};

subtest 'validate: kind 7376 missing e tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 7376, content => '', created_at => 1000,
        tags => [['p', $PUBKEY2]],
    );
    like(dies { Net::Nostr::Nutzap->validate($event) }, qr/e tag/, 'missing e tag');
};

subtest 'validate: wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 1, content => '', created_at => 1000,
        tags => [],
    );
    like(dies { Net::Nostr::Nutzap->validate($event) }, qr/10019|9321|7376/, 'wrong kind');
};

###############################################################################
# Spec example: kind 9321 nutzap event
###############################################################################

subtest 'spec example: kind 9321 nutzap' => sub {
    my $proof = '{"amount":1,"C":"02277c66191736eb72fce9d975d08e3191f8f96afb73ab1eec37e4465683066d3f","id":"000a93d6f8a1d2c4","secret":"[\"P2PK\",{\"nonce\":\"b00bdd0467b0090a25bdf2d2f0d45ac4e355c482c1418350f273a04fedaaee83\",\"data\":\"02eaee8939e3565e48cc62967e2fde9d8e2a4b3ec0081f29eceff5c64ef10ac1ed\"}]"}';
    my $recipient = 'e9fbced3a42dcf551486650cc752ab354347dd413b307484e4fd1818ab53f991';

    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey     => $PUBKEY,
        recipient  => $recipient,
        proofs     => [$proof],
        mint_url   => 'https://stablenut.umint.cash',
        unit       => 'sat',
        event_id   => $EVENTID,
        event_kind => '1',
        relay_hint => 'wss://relay.example',
        content    => 'Thanks for this great idea.',
    );

    is($event->kind, 9321, 'kind 9321');

    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p_tags[0][1], $recipient, 'recipient matches spec');

    my @proof_tags = grep { $_->[0] eq 'proof' } @{$event->tags};
    is($proof_tags[0][1], $proof, 'proof matches spec');

    my @u_tags = grep { $_->[0] eq 'u' } @{$event->tags};
    is($u_tags[0][1], 'https://stablenut.umint.cash', 'mint url matches spec');

    my @unit_tags = grep { $_->[0] eq 'unit' } @{$event->tags};
    is($unit_tags[0][1], 'sat', 'unit matches spec');

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e_tags[0][1], $EVENTID, 'e tag matches spec');

    my @k_tags = grep { $_->[0] eq 'k' } @{$event->tags};
    is($k_tags[0][1], '1', 'k tag stringified kind matches spec');

    is($event->content, 'Thanks for this great idea.', 'content matches spec');
};

###############################################################################
# Spec example: kind 7376 redemption
###############################################################################

subtest 'spec example: kind 7376 redemption' => sub {
    my $nutzap_id = 'ee' x 32;
    my $sender = 'ff' x 32;

    my $event = Net::Nostr::Nutzap->redemption(
        pubkey        => $PUBKEY,
        nutzap_ids    => [$nutzap_id],
        sender_pubkey => $sender,
        relay_hint    => 'wss://r',
    );

    is($event->kind, 7376, 'kind 7376');

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e_tags[0][3], 'redeemed', 'marker is redeemed');

    my @p_tags = grep { $_->[0] eq 'p' } @{$event->tags};
    is($p_tags[0][1], $sender, 'sender pubkey');
};

###############################################################################
# "Clients SHOULD guide their users to use NUT-11 (P2PK) and NUT-12 (DLEQ
#  proofs) compatible-mints"
# "pubkey: Public key that MUST be used to P2PK-lock receiving nutzaps --
#  implementations MUST NOT use the target user's main Nostr public key"
###############################################################################

subtest 'info event p2pk pubkey is separate from event pubkey' => sub {
    my $event = Net::Nostr::Nutzap->info_event(
        pubkey => $PUBKEY,
        relays => ['wss://r'],
        mints  => [{ url => 'https://m', units => ['sat'] }],
        p2pk_pubkey => $P2PK_PUBKEY,
    );

    is($event->pubkey, $PUBKEY, 'event pubkey is nostr pubkey');
    my @pk_tags = grep { $_->[0] eq 'pubkey' } @{$event->tags};
    is($pk_tags[0][1], $P2PK_PUBKEY, 'pubkey tag is separate p2pk key');
    isnt($event->pubkey, $pk_tags[0][1], 'p2pk pubkey != nostr pubkey');
};

###############################################################################
# "Filtering with #u for mints they expect to receive ecash from"
###############################################################################

###############################################################################
# Kind 10019 content MUST be empty
###############################################################################

subtest 'info_event: content is empty' => sub {
    my $event = Net::Nostr::Nutzap->info_event(
        pubkey => $PUBKEY,
        relays => ['wss://r'],
        mints  => [{ url => 'https://m', units => ['sat'] }],
        p2pk_pubkey => $P2PK_PUBKEY,
    );
    is($event->content, '', 'kind 10019 content is empty');
};

###############################################################################
# "Additional markers can be used to list the supported base units of the mint"
# -- units are optional on mint tags
###############################################################################

subtest 'info_event: mint with no units' => sub {
    my $event = Net::Nostr::Nutzap->info_event(
        pubkey => $PUBKEY,
        relays => ['wss://r'],
        mints  => [{ url => 'https://m' }],
        p2pk_pubkey => $P2PK_PUBKEY,
    );

    my @mint_tags = grep { $_->[0] eq 'mint' } @{$event->tags};
    is($mint_tags[0], ['mint', 'https://m'], 'mint tag with no units');
};

###############################################################################
# Redemption with default (empty) relay hint
###############################################################################

subtest 'redemption: default empty relay hint' => sub {
    my $nutzap_id = 'ee' x 32;
    my $event = Net::Nostr::Nutzap->redemption(
        pubkey        => $PUBKEY,
        nutzap_ids    => [$nutzap_id],
        sender_pubkey => $PUBKEY2,
    );

    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e_tags[0][1], $nutzap_id, 'nutzap id present');
    is($e_tags[0][2], '', 'relay hint defaults to empty');
    is($e_tags[0][3], 'redeemed', 'redeemed marker still present');
};

###############################################################################
# Spec REQ filter pattern (line 85):
# { "kinds": [9321], "#p": ["my-pubkey"], "#u": ["<mint-1>", "<mint-2>"],
#   "since": <latest-created_at-of-kind-7376> }
###############################################################################

subtest 'spec filter pattern for receiving nutzaps' => sub {
    require Net::Nostr::Filter;

    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey     => $PUBKEY,
        recipient  => $PUBKEY2,
        proofs     => ['proof'],
        mint_url   => 'https://mint1.example',
        created_at => 2000,
    );

    my $filter = Net::Nostr::Filter->new(
        kinds => [9321],
        '#p'  => [$PUBKEY2],
        '#u'  => ['https://mint1.example', 'https://mint2.example'],
        since => 1500,
    );
    ok($filter->matches($event), 'nutzap matches full spec REQ filter');

    # Event before since should not match
    my $old_event = Net::Nostr::Nutzap->nutzap(
        pubkey     => $PUBKEY,
        recipient  => $PUBKEY2,
        proofs     => ['proof'],
        mint_url   => 'https://mint1.example',
        created_at => 1000,
    );
    ok(!$filter->matches($old_event), 'old nutzap rejected by since filter');

    # Wrong mint should not match
    my $wrong_mint = Net::Nostr::Nutzap->nutzap(
        pubkey     => $PUBKEY,
        recipient  => $PUBKEY2,
        proofs     => ['proof'],
        mint_url   => 'https://unknown-mint.example',
        created_at => 2000,
    );
    ok(!$filter->matches($wrong_mint), 'nutzap from unlisted mint rejected by #u filter');
};

###############################################################################
# "pubkey": "<sender-pubkey>" (spec line 51)
###############################################################################

subtest 'nutzap pubkey is the sender' => sub {
    my $sender = 'ab' x 32;
    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey    => $sender,
        recipient => $PUBKEY2,
        proofs    => ['proof'],
        mint_url  => 'https://m',
    );
    is($event->pubkey, $sender, 'event pubkey is the sender pubkey');
};

###############################################################################
# kind:7376 content can be NIP-44 encrypted data (spec lines 97-102)
# "content": nip44_encrypt([["direction", "in"], ["amount", "1"], ...])
###############################################################################

subtest 'redemption: accepts content for encrypted data' => sub {
    my $encrypted = 'nip44-encrypted-payload-here';
    my $event = Net::Nostr::Nutzap->redemption(
        pubkey        => $PUBKEY,
        nutzap_ids    => ['ee' x 32],
        sender_pubkey => $PUBKEY2,
        content       => $encrypted,
    );

    is($event->content, $encrypted, 'redemption content carries encrypted payload');
};

subtest 'redemption: content defaults to empty when not provided' => sub {
    my $event = Net::Nostr::Nutzap->redemption(
        pubkey        => $PUBKEY,
        nutzap_ids    => ['ee' x 32],
        sender_pubkey => $PUBKEY2,
    );

    is($event->content, '', 'redemption content defaults to empty');
};

###############################################################################
# from_event: multiple proofs (spec line 65: "one or more proofs")
###############################################################################

subtest 'from_event: parses multiple proofs from kind 9321' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 9321, content => '', created_at => 1000,
        tags => [
            ['proof', '{"amount":1}'],
            ['proof', '{"amount":2}'],
            ['proof', '{"amount":4}'],
            ['u', 'https://mint.example'],
            ['unit', 'sat'],
            ['p', $PUBKEY2],
        ],
    );

    my $info = Net::Nostr::Nutzap->from_event($event);
    is($info->proofs, ['{"amount":1}', '{"amount":2}', '{"amount":4}'],
        'all three proofs parsed');
};

###############################################################################
# from_event: mint with no units (spec line 39: units are optional markers)
###############################################################################

subtest 'from_event: parses mint with no units' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PUBKEY, kind => 10019, content => '', created_at => 1000,
        tags => [
            ['relay', 'wss://r'],
            ['mint', 'https://m'],
            ['pubkey', $P2PK_PUBKEY],
        ],
    );

    my $info = Net::Nostr::Nutzap->from_event($event);
    is($info->mints->[0]{url}, 'https://m', 'mint url parsed');
    is($info->mints->[0]{units}, [], 'no units yields empty array');
};

###############################################################################
# Spec example kind 7376: verify relay-hint position in e tag
###############################################################################

subtest 'spec example: kind 7376 e tag structure' => sub {
    my $nutzap_id = 'ee' x 32;
    my $event = Net::Nostr::Nutzap->redemption(
        pubkey        => $PUBKEY,
        nutzap_ids    => [$nutzap_id],
        sender_pubkey => $PUBKEY2,
        relay_hint    => 'wss://relay.example',
    );

    # Spec: ["e", "<9321-event-id>", "<relay-hint>", "redeemed"]
    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is($e_tags[0][0], 'e', 'tag name');
    is($e_tags[0][1], $nutzap_id, 'event id at position 1');
    is($e_tags[0][2], 'wss://relay.example', 'relay hint at position 2');
    is($e_tags[0][3], 'redeemed', 'redeemed marker at position 3');
};

###############################################################################
# k tag value must be stringified (consistent with NIP-18 convention)
###############################################################################

subtest 'nutzap: k tag value is stringified' => sub {
    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey     => $PUBKEY,
        recipient  => $PUBKEY2,
        proofs     => ['proof'],
        mint_url   => 'https://m',
        event_kind => 30023,
    );

    my @k_tags = grep { $_->[0] eq 'k' } @{$event->tags};
    my $json = JSON::encode_json($k_tags[0]);
    like($json, qr/\["k","30023"\]/, 'k tag value serializes as string, not number');
};

subtest 'nutzap u tag is filterable' => sub {
    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey    => $PUBKEY,
        recipient => $PUBKEY2,
        proofs    => ['proof'],
        mint_url  => 'https://mint.example',
    );

    require Net::Nostr::Filter;
    my $filter = Net::Nostr::Filter->new(kinds => [9321], '#u' => ['https://mint.example']);
    ok($filter->matches($event), 'nutzap matches #u filter');
};

subtest 'nutzap rejects invalid recipient' => sub {
    like(
        dies { Net::Nostr::Nutzap->nutzap(
            pubkey => 'a' x 64, recipient => 'bad',
            proofs => ['[]'], mint_url => 'https://mint.example.com',
        ) },
        qr/recipient must be 64-char lowercase hex/,
        'invalid recipient rejected'
    );
};

done_testing;
