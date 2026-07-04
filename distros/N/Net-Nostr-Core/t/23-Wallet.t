use strictures 2;
use Test2::V0 -no_srand => 1;
use JSON ();

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Wallet;

my $json = JSON->new->utf8->canonical;

# === SYNOPSIS examples ===

subtest 'SYNOPSIS: wallet_content' => sub {
    my $pubkey = 'aa' x 32;

    my $wallet_plaintext = Net::Nostr::Wallet->wallet_content(
        privkey => 'bb' x 32,
        mints   => ['https://mint1', 'https://mint2'],
    );
    ok defined $wallet_plaintext, 'wallet_content returns plaintext';
    my $data = $json->decode($wallet_plaintext);
    is ref $data, 'ARRAY', 'plaintext is JSON array';
};

subtest 'SYNOPSIS: wallet_event' => sub {
    my $pubkey = 'aa' x 32;

    my $wallet_ev = Net::Nostr::Wallet->wallet_event(
        pubkey  => $pubkey,
        content => 'encrypted-wallet-content',
    );
    is $wallet_ev->kind, 17375, 'wallet event is kind 17375';
};

subtest 'SYNOPSIS: token_content' => sub {
    my $token_plaintext = Net::Nostr::Wallet->token_content(
        mint   => 'https://stablenut.umint.cash',
        unit   => 'sat',
        proofs => [
            {
                id     => '005c2502034d4f12',
                amount => 1,
                secret => 'z+zyxAVLRqN9lEjxuNPSyRJzEstbl69Jc1vtimvtkPg=',
                C      => '0241d98a8197ef238a192d47edf191a9de78b657308937b4f7dd0aa53beae72c46',
            },
        ],
        del => ['old-token-event-id'],
    );
    my $data = $json->decode($token_plaintext);
    is $data->{mint}, 'https://stablenut.umint.cash', 'mint in token content';
    is $data->{del}, ['old-token-event-id'], 'del in token content';
};

subtest 'SYNOPSIS: token_event' => sub {
    my $pubkey = 'aa' x 32;

    my $token_ev = Net::Nostr::Wallet->token_event(
        pubkey  => $pubkey,
        content => 'encrypted-token-content',
    );
    is $token_ev->kind, 7375, 'token event is kind 7375';
};

subtest 'SYNOPSIS: history_content' => sub {
    my $history_plaintext = Net::Nostr::Wallet->history_content(
        direction => 'out',
        amount    => '4',
        unit      => 'sat',
        e_tags    => [
            ['event-id-1', '', 'destroyed'],
            ['event-id-2', '', 'created'],
        ],
    );
    my $data = $json->decode($history_plaintext);
    my ($dir) = grep { $_->[0] eq 'direction' } @$data;
    is $dir->[1], 'out', 'direction in history content';
};

subtest 'SYNOPSIS: history_event with redeemed_ids' => sub {
    my $pubkey = 'aa' x 32;

    my $history_ev = Net::Nostr::Wallet->history_event(
        pubkey       => $pubkey,
        content      => 'encrypted-history-content',
        redeemed_ids => [['ab' x 32, 'wss://relay']],
    );
    is $history_ev->kind, 7376, 'history event is kind 7376';
    my @tags = @{$history_ev->tags};
    is $tags[0][0], 'e', 'redeemed e tag present';
    is $tags[0][3], 'redeemed', 'redeemed marker';
};

subtest 'SYNOPSIS: quote_event' => sub {
    my $pubkey = 'aa' x 32;

    my $quote_ev = Net::Nostr::Wallet->quote_event(
        pubkey     => $pubkey,
        content    => 'encrypted-quote-id',
        mint_url   => 'https://mint1',
        expiration => time() + 2 * 7 * 86400,
    );
    is $quote_ev->kind, 7374, 'quote event is kind 7374';
};

subtest 'SYNOPSIS: delete_token' => sub {
    my $pubkey = 'aa' x 32;

    my $delete_ev = Net::Nostr::Wallet->delete_token(
        pubkey    => $pubkey,
        event_ids => ['cd' x 32],
    );
    is $delete_ev->kind, 5, 'delete event is kind 5';
    my ($k) = grep { $_->[0] eq 'k' } @{$delete_ev->tags};
    is $k->[1], '7375', 'k tag is 7375';
};

subtest 'SYNOPSIS: parse_wallet_content' => sub {
    my $decrypted = Net::Nostr::Wallet->wallet_content(
        privkey => 'bb' x 32,
        mints   => ['https://mint1'],
    );
    my $wallet = Net::Nostr::Wallet->parse_wallet_content($decrypted);
    is $wallet->privkey, 'bb' x 32, '$wallet->privkey';
    is join(', ', @{$wallet->mints}), 'https://mint1', 'join @{$wallet->mints}';
};

subtest 'SYNOPSIS: parse_token_content' => sub {
    my $decrypted = Net::Nostr::Wallet->token_content(
        mint   => 'https://mint1',
        proofs => [{ id => 'a', amount => 1, secret => 's', C => 'c' }],
    );
    my $token = Net::Nostr::Wallet->parse_token_content($decrypted);
    is $token->mint, 'https://mint1', '$token->mint';
    is scalar @{$token->proofs}, 1, 'scalar @{$token->proofs}';
};

subtest 'SYNOPSIS: parse_history_content' => sub {
    my $decrypted = Net::Nostr::Wallet->history_content(
        direction => 'in',
        amount    => '1',
        e_tags    => [['eid', '', 'created']],
    );
    my $hist = Net::Nostr::Wallet->parse_history_content($decrypted);
    is $hist->direction, 'in', '$hist->direction';
    is $hist->amount, '1', '$hist->amount';
};

subtest 'SYNOPSIS: from_event' => sub {
    my $event = make_event(
        pubkey => 'aa' x 32, kind => 7374, content => 'enc',
        tags => [['expiration', '123'], ['mint', 'https://m']],
    );
    my $parsed = Net::Nostr::Wallet->from_event($event);
    ok defined $parsed, 'from_event returns object';
};

# === Method doc examples ===

subtest 'wallet_content doc example' => sub {
    my $hex_privkey = 'cc' x 32;
    my $plaintext = Net::Nostr::Wallet->wallet_content(
        privkey => $hex_privkey,
        mints   => ['https://mint1', 'https://mint2'],
    );
    ok defined $plaintext, 'returns JSON string';
};

subtest 'token_content doc example' => sub {
    my $plaintext = Net::Nostr::Wallet->token_content(
        mint   => 'https://mint',
        proofs => [{ id => '...', amount => 1, secret => '...', C => '...' }],
        unit   => 'sat',
        del    => ['old-token-id'],
    );
    my $data = $json->decode($plaintext);
    is $data->{unit}, 'sat', 'unit from doc example';
    is $data->{del}, ['old-token-id'], 'del from doc example';
};

subtest 'history_content doc example' => sub {
    my $event_id = 'dd' x 32;
    my $relay_hint = 'wss://relay';
    my $marker = 'destroyed';
    my $plaintext = Net::Nostr::Wallet->history_content(
        direction => 'out',
        amount    => '4',
        unit      => 'sat',
        e_tags    => [
            [$event_id, $relay_hint, $marker],
        ],
    );
    my $data = $json->decode($plaintext);
    my ($e) = grep { $_->[0] eq 'e' } @$data;
    is $e->[1], $event_id, 'event_id in e tag';
    is $e->[2], $relay_hint, 'relay_hint in e tag';
    is $e->[3], $marker, 'marker in e tag';
};

subtest 'parse_wallet_content doc example' => sub {
    my $decrypted_json = Net::Nostr::Wallet->wallet_content(
        privkey => 'ee' x 32,
        mints   => ['https://mint1', 'https://mint2'],
    );
    my $wallet = Net::Nostr::Wallet->parse_wallet_content($decrypted_json);
    ok defined $wallet->privkey, '$wallet->privkey defined';
    is join(', ', @{$wallet->mints}), 'https://mint1, https://mint2', 'join @{$wallet->mints}';
};

subtest 'parse_token_content doc example' => sub {
    my $decrypted_json = Net::Nostr::Wallet->token_content(
        mint   => 'https://mint1',
        proofs => [{ id => 'a', amount => 1, secret => 's', C => 'c' }],
        del    => ['old-id'],
    );
    my $token = Net::Nostr::Wallet->parse_token_content($decrypted_json);
    ok defined $token->mint, '$token->mint defined';
    is $token->unit, 'sat', '$token->unit defaults to sat';
    is scalar @{$token->proofs}, 1, 'scalar @{$token->proofs}';
    is join(', ', @{$token->del}), 'old-id', 'join @{$token->del}';
};

subtest 'parse_history_content doc example' => sub {
    my $decrypted_json = Net::Nostr::Wallet->history_content(
        direction => 'out',
        amount    => '10',
        unit      => 'usd',
        e_tags    => [
            ['id1', 'wss://r', 'destroyed'],
            ['id2', 'wss://r', 'created'],
        ],
    );
    my $hist = Net::Nostr::Wallet->parse_history_content($decrypted_json);
    is $hist->direction, 'out', '$hist->direction';
    is $hist->amount, '10', '$hist->amount';
    is $hist->unit, 'usd', '$hist->unit';
    for my $e (@{$hist->e_tags}) {
        ok defined $e->[0], 'event_id defined';
        ok defined $e->[2], 'marker defined';
    }
};

subtest 'validate doc example' => sub {
    my $event = Net::Nostr::Wallet->quote_event(
        pubkey     => 'aa' x 32,
        content    => 'enc',
        mint_url   => 'https://m',
        expiration => 123,
    );
    ok(Net::Nostr::Wallet->validate($event)), 'validate returns true for valid event';
};

subtest 'new() rejects unknown arguments' => sub {
    eval { Net::Nostr::Wallet->new(
        bogus => 'value',
    ) };
    like($@, qr/unknown.+bogus/i, 'unknown argument rejected');
};

done_testing;
