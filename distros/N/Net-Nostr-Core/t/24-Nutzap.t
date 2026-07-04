use strictures 2;
use Test2::V0 -no_srand => 1;

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Nutzap;

my $pubkey      = 'aa' x 32;
my $p2pk_pubkey = 'cc' x 32;

# === SYNOPSIS examples ===

subtest 'SYNOPSIS: info_event' => sub {
    my $info = Net::Nostr::Nutzap->info_event(
        pubkey      => $pubkey,
        relays      => ['wss://relay1', 'wss://relay2'],
        mints       => [
            { url => 'https://mint1', units => ['usd', 'sat'] },
            { url => 'https://mint2', units => ['sat'] },
        ],
        p2pk_pubkey => $p2pk_pubkey,
    );
    is $info->kind, 10019, 'info event is kind 10019';
};

subtest 'SYNOPSIS: nutzap' => sub {
    my $proof_json = '{"amount":1,"C":"02...","id":"000a","secret":"..."}';
    my $zap = Net::Nostr::Nutzap->nutzap(
        pubkey     => $pubkey,
        recipient  => 'bb' x 32,
        proofs     => [$proof_json],
        mint_url   => 'https://mint1',
        unit       => 'sat',
        event_id   => 'dd' x 32,
        event_kind => '1',
        content    => 'Great post!',
    );
    is $zap->kind, 9321, 'nutzap event is kind 9321';
    is $zap->content, 'Great post!', 'content set';
};

subtest 'SYNOPSIS: redemption' => sub {
    my $nutzap_event_id = 'ee' x 32;
    my $redeem = Net::Nostr::Nutzap->redemption(
        pubkey        => $pubkey,
        nutzap_ids    => [$nutzap_event_id],
        sender_pubkey => 'bb' x 32,
        relay_hint    => 'wss://relay1',
        content       => 'encrypted-content',
    );
    is $redeem->kind, 7376, 'redemption event is kind 7376';
    is $redeem->content, 'encrypted-content', 'content passed through';
};

subtest 'SYNOPSIS: from_event' => sub {
    my $event = make_event(
        pubkey  => $pubkey,
        kind    => 10019,
        content => '',
        tags    => [
            ['relay', 'wss://relay1'],
            ['mint', 'https://mint1', 'sat'],
            ['pubkey', $p2pk_pubkey],
        ],
    );
    my $parsed = Net::Nostr::Nutzap->from_event($event);
    ok defined $parsed, 'from_event returns object';
    is $parsed->p2pk_pubkey, $p2pk_pubkey, 'p2pk_pubkey parsed';
};

subtest 'SYNOPSIS: validate' => sub {
    my $event = make_event(
        pubkey  => $pubkey,
        kind    => 10019,
        content => '',
        tags    => [
            ['relay', 'wss://relay1'],
            ['mint', 'https://mint1', 'sat'],
            ['pubkey', $p2pk_pubkey],
        ],
    );
    ok(Net::Nostr::Nutzap->validate($event)), 'validate returns true';
};

# === Method doc examples ===

subtest 'info_event doc example' => sub {
    my $hex_pubkey  = 'aa' x 32;
    my $hex_p2pk_key = 'cc' x 32;
    my $event = Net::Nostr::Nutzap->info_event(
        pubkey      => $hex_pubkey,
        relays      => ['wss://relay1'],
        mints       => [{ url => 'https://mint1', units => ['sat'] }],
        p2pk_pubkey => $hex_p2pk_key,
    );
    is $event->kind, 10019, 'kind 10019';
};

subtest 'nutzap doc example' => sub {
    my $hex_pubkey   = 'aa' x 32;
    my $hex_event_id = 'dd' x 32;
    my $proof_json   = '{"proof":"data"}';
    my $event = Net::Nostr::Nutzap->nutzap(
        pubkey     => $hex_pubkey,
        recipient  => 'bb' x 32,
        proofs     => [$proof_json],
        mint_url   => 'https://mint',
        unit       => 'sat',
        event_id   => $hex_event_id,
        event_kind => '1',
        relay_hint => 'wss://relay',
        content    => 'nice!',
    );
    is $event->kind, 9321, 'kind 9321';
};

subtest 'redemption doc example' => sub {
    my $hex_pubkey = 'aa' x 32;
    my $event_id   = 'dd' x 32;
    my $encrypted  = 'encrypted-data';
    my $event = Net::Nostr::Nutzap->redemption(
        pubkey        => $hex_pubkey,
        nutzap_ids    => [$event_id],
        sender_pubkey => 'bb' x 32,
        relay_hint    => 'wss://relay',
        content       => $encrypted,
    );
    is $event->kind, 7376, 'kind 7376';
};

subtest 'from_event doc example' => sub {
    my $event = make_event(
        pubkey  => $pubkey,
        kind    => 9321,
        content => 'Thanks!',
        tags    => [
            ['proof', '{"json":"proof"}'],
            ['u', 'https://mint1'],
            ['p', 'bb' x 32],
        ],
    );
    my $info = Net::Nostr::Nutzap->from_event($event);
    ok defined $info, 'from_event parses kind 9321';
    is $info->mint_url, 'https://mint1', 'mint_url accessor';
    is $info->recipient, 'bb' x 32, 'recipient accessor';
};

subtest 'validate doc example' => sub {
    my $event = make_event(
        pubkey  => $pubkey,
        kind    => 9321,
        content => '',
        tags    => [
            ['proof', 'data'],
            ['u', 'https://mint1'],
            ['p', 'bb' x 32],
        ],
    );
    ok(Net::Nostr::Nutzap->validate($event)), 'validate kind 9321';
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $hex_pubkey = 'bb' x 32;
    my $info = Net::Nostr::Nutzap->new(
        mint_url  => 'https://mint1',
        unit      => 'sat',
        recipient => $hex_pubkey,
        proofs    => [],
    );
    is $info->mint_url, 'https://mint1';
    is $info->unit, 'sat';
    is $info->recipient, $hex_pubkey;
    is $info->proofs, [];
    is $info->relays, [];
    is $info->mints, [];
    is $info->nutzap_ids, [];
};

subtest 'new() rejects unknown arguments' => sub {
    eval { Net::Nostr::Nutzap->new(
        mint_url  => 'https://mint1',
        unit      => 'sat',
        recipient => 'bb' x 32,
        proofs    => [],
        bogus     => 'value',
    ) };
    like($@, qr/unknown.+bogus/i, 'unknown argument rejected');
};

done_testing;
