use strictures 2;
use Test2::V0 -no_srand => 1;
use JSON ();

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Wallet;

my $json = JSON->new->utf8->canonical;

my $pubkey  = 'aa' x 32;
my $privkey = 'bb' x 32;

my $eid1 = '11' x 32;
my $eid2 = '22' x 32;
my $eid3 = '33' x 32;

# === kind 17375: Wallet Event ===

subtest 'wallet_event creates kind 17375' => sub {
    my $ev = Net::Nostr::Wallet->wallet_event(
        pubkey  => $pubkey,
        content => 'encrypted-content',
    );
    is $ev->kind, 17375, 'kind is 17375';
    is $ev->pubkey, $pubkey, 'pubkey set';
    is $ev->content, 'encrypted-content', 'content is pre-encrypted';
    is $ev->tags, [], 'tags are empty (all data in encrypted content)';
};

subtest 'wallet_event requires pubkey' => sub {
    eval { Net::Nostr::Wallet->wallet_event(content => 'x') };
    like $@, qr/pubkey/, 'croaks without pubkey';
};

subtest 'wallet_event requires content' => sub {
    eval { Net::Nostr::Wallet->wallet_event(pubkey => $pubkey) };
    like $@, qr/content/, 'croaks without content';
};

subtest 'wallet_content builds plaintext for encryption' => sub {
    my $plaintext = Net::Nostr::Wallet->wallet_content(
        privkey => $privkey,
        mints   => ['https://mint1', 'https://mint2'],
    );
    my $data = $json->decode($plaintext);
    is ref $data, 'ARRAY', 'plaintext is a JSON array';

    # Find tags by name
    my %tags;
    for my $tag (@$data) {
        push @{$tags{$tag->[0]}}, $tag;
    }

    is scalar @{$tags{privkey}}, 1, 'one privkey tag';
    is $tags{privkey}[0][1], $privkey, 'privkey value correct';

    is scalar @{$tags{mint}}, 2, 'two mint tags';
    is $tags{mint}[0][1], 'https://mint1', 'first mint URL';
    is $tags{mint}[1][1], 'https://mint2', 'second mint URL';
};

subtest 'wallet_content requires privkey' => sub {
    eval { Net::Nostr::Wallet->wallet_content(mints => ['https://m']) };
    like $@, qr/privkey/, 'croaks without privkey';
};

subtest 'wallet_content requires mints with at least one entry' => sub {
    eval { Net::Nostr::Wallet->wallet_content(privkey => $privkey) };
    like $@, qr/mints/, 'croaks without mints';

    eval { Net::Nostr::Wallet->wallet_content(privkey => $privkey, mints => []) };
    like $@, qr/one or more/, 'croaks with empty mints (MUST have one or more)';
};

subtest 'parse_wallet_content parses decrypted wallet data' => sub {
    my $plaintext = $json->encode([
        ['privkey', $privkey],
        ['mint', 'https://mint1'],
        ['mint', 'https://mint2'],
    ]);
    my $wallet = Net::Nostr::Wallet->parse_wallet_content($plaintext);
    is $wallet->privkey, $privkey, 'privkey parsed';
    is $wallet->mints, ['https://mint1', 'https://mint2'], 'mints parsed';
};

subtest 'wallet_content round-trips through parse_wallet_content' => sub {
    my $plaintext = Net::Nostr::Wallet->wallet_content(
        privkey => $privkey,
        mints   => ['https://mint1'],
    );
    my $wallet = Net::Nostr::Wallet->parse_wallet_content($plaintext);
    is $wallet->privkey, $privkey, 'privkey round-trips';
    is $wallet->mints, ['https://mint1'], 'mints round-trip';
};

subtest 'kind 17375 is replaceable (10000-19999 range)' => sub {
    my $ev = Net::Nostr::Wallet->wallet_event(
        pubkey  => $pubkey,
        content => 'encrypted',
    );
    ok $ev->kind >= 10000 && $ev->kind < 20000, 'kind 17375 is in replaceable range';
};

# === kind 7375: Token Event ===

subtest 'token_event creates kind 7375' => sub {
    my $ev = Net::Nostr::Wallet->token_event(
        pubkey  => $pubkey,
        content => 'encrypted-token',
    );
    is $ev->kind, 7375, 'kind is 7375';
    is $ev->pubkey, $pubkey, 'pubkey set';
    is $ev->content, 'encrypted-token', 'content is pre-encrypted';
    is $ev->tags, [], 'tags are empty';
};

subtest 'token_event requires pubkey and content' => sub {
    eval { Net::Nostr::Wallet->token_event(content => 'x') };
    like $@, qr/pubkey/, 'croaks without pubkey';

    eval { Net::Nostr::Wallet->token_event(pubkey => $pubkey) };
    like $@, qr/content/, 'croaks without content';
};

subtest 'token_content builds plaintext with spec example data' => sub {
    # Use the exact proof from the NIP-60 spec example
    my @proofs = ({
        id     => '005c2502034d4f12',
        amount => 1,
        secret => 'z+zyxAVLRqN9lEjxuNPSyRJzEstbl69Jc1vtimvtkPg=',
        C      => '0241d98a8197ef238a192d47edf191a9de78b657308937b4f7dd0aa53beae72c46',
    });
    my $plaintext = Net::Nostr::Wallet->token_content(
        mint   => 'https://stablenut.umint.cash',
        proofs => \@proofs,
        unit   => 'sat',
    );
    my $data = $json->decode($plaintext);
    is $data->{mint}, 'https://stablenut.umint.cash', 'mint set';
    is $data->{unit}, 'sat', 'unit set';
    is scalar @{$data->{proofs}}, 1, 'one proof';
    is $data->{proofs}[0]{id}, '005c2502034d4f12', 'proof id from spec';
    is $data->{proofs}[0]{amount}, 1, 'proof amount';
    is $data->{proofs}[0]{secret}, 'z+zyxAVLRqN9lEjxuNPSyRJzEstbl69Jc1vtimvtkPg=', 'proof secret';
    is $data->{proofs}[0]{C}, '0241d98a8197ef238a192d47edf191a9de78b657308937b4f7dd0aa53beae72c46', 'proof C';
    ok !exists $data->{del}, 'no del field when not provided';
};

subtest 'token_content with del field' => sub {
    my $plaintext = Net::Nostr::Wallet->token_content(
        mint   => 'https://mint1',
        proofs => [{ id => 'a', amount => 1, secret => 's', C => 'c' }],
        del    => ['event-id-1', 'event-id-2'],
    );
    my $data = $json->decode($plaintext);
    is $data->{del}, ['event-id-1', 'event-id-2'], 'del field with destroyed token IDs';
};

subtest 'token_content unit defaults to sat' => sub {
    my $plaintext = Net::Nostr::Wallet->token_content(
        mint   => 'https://mint1',
        proofs => [{ id => 'a', amount => 1, secret => 's', C => 'c' }],
    );
    my $data = $json->decode($plaintext);
    is $data->{unit}, 'sat', 'unit defaults to sat when omitted';
};

subtest 'token_content requires mint and proofs' => sub {
    eval { Net::Nostr::Wallet->token_content(proofs => [{}]) };
    like $@, qr/mint/, 'croaks without mint';

    eval { Net::Nostr::Wallet->token_content(mint => 'https://m') };
    like $@, qr/proofs/, 'croaks without proofs';
};

subtest 'token_content multiple proofs per event' => sub {
    my $plaintext = Net::Nostr::Wallet->token_content(
        mint   => 'https://mint1',
        proofs => [
            { id => '1', amount => 1, secret => 's1', C => 'c1' },
            { id => '2', amount => 2, secret => 's2', C => 'c2' },
            { id => '3', amount => 4, secret => 's3', C => 'c3' },
        ],
    );
    my $data = $json->decode($plaintext);
    is scalar @{$data->{proofs}}, 3, 'multiple proofs in one token event';
};

subtest 'parse_token_content parses decrypted token data' => sub {
    my $plaintext = $json->encode({
        mint   => 'https://stablenut.umint.cash',
        unit   => 'sat',
        proofs => [
            { id => '005c2502034d4f12', amount => 1, secret => 's', C => 'c' },
        ],
        del => ['old-token-id'],
    });
    my $token = Net::Nostr::Wallet->parse_token_content($plaintext);
    is $token->mint, 'https://stablenut.umint.cash', 'mint parsed';
    is $token->unit, 'sat', 'unit parsed';
    is scalar @{$token->proofs}, 1, 'proofs parsed';
    is $token->proofs->[0]{id}, '005c2502034d4f12', 'proof data intact';
    is $token->del, ['old-token-id'], 'del parsed';
};

subtest 'parse_token_content defaults unit to sat' => sub {
    my $plaintext = $json->encode({
        mint   => 'https://mint1',
        proofs => [{ id => 'a', amount => 1, secret => 's', C => 'c' }],
    });
    my $token = Net::Nostr::Wallet->parse_token_content($plaintext);
    is $token->unit, 'sat', 'unit defaults to sat when omitted from content';
};

subtest 'parse_token_content del defaults to empty' => sub {
    my $plaintext = $json->encode({
        mint   => 'https://mint1',
        unit   => 'sat',
        proofs => [{ id => 'a', amount => 1, secret => 's', C => 'c' }],
    });
    my $token = Net::Nostr::Wallet->parse_token_content($plaintext);
    is $token->del, [], 'del defaults to empty array';
};

subtest 'token_content round-trips through parse_token_content' => sub {
    my @proofs = ({ id => 'x', amount => 8, secret => 'sec', C => 'cc' });
    my $plaintext = Net::Nostr::Wallet->token_content(
        mint   => 'https://mint1',
        proofs => \@proofs,
        unit   => 'usd',
        del    => ['old-id'],
    );
    my $token = Net::Nostr::Wallet->parse_token_content($plaintext);
    is $token->mint, 'https://mint1', 'mint round-trips';
    is $token->unit, 'usd', 'unit round-trips';
    is $token->proofs->[0]{id}, 'x', 'proof round-trips';
    is $token->del, ['old-id'], 'del round-trips';
};

# === kind 7376: Spending History Event ===

subtest 'history_event creates kind 7376' => sub {
    my $ev = Net::Nostr::Wallet->history_event(
        pubkey  => $pubkey,
        content => 'encrypted-history',
    );
    is $ev->kind, 7376, 'kind is 7376';
    is $ev->pubkey, $pubkey, 'pubkey set';
    is $ev->content, 'encrypted-history', 'content is pre-encrypted';
    is $ev->tags, [], 'no public tags when no redeemed IDs';
};

subtest 'history_event with unencrypted redeemed e tags' => sub {
    my $ev = Net::Nostr::Wallet->history_event(
        pubkey       => $pubkey,
        content      => 'encrypted',
        redeemed_ids => [
            [$eid1, 'wss://relay1'],
            [$eid2, ''],
        ],
    );
    my @tags = @{$ev->tags};
    is scalar @tags, 2, 'two public e tags';
    is $tags[0], ['e', $eid1, 'wss://relay1', 'redeemed'], 'first e tag with redeemed marker';
    is $tags[1], ['e', $eid2, '', 'redeemed'], 'second e tag with redeemed marker';
};

subtest 'history_event requires pubkey and content' => sub {
    eval { Net::Nostr::Wallet->history_event(content => 'x') };
    like $@, qr/pubkey/, 'croaks without pubkey';

    eval { Net::Nostr::Wallet->history_event(pubkey => $pubkey) };
    like $@, qr/content/, 'croaks without content';
};

subtest 'history_content builds plaintext' => sub {
    my $plaintext = Net::Nostr::Wallet->history_content(
        direction => 'in',
        amount    => '1',
        unit      => 'sat',
        e_tags    => [['event-id-1', '', 'created']],
    );
    my $data = $json->decode($plaintext);
    is ref $data, 'ARRAY', 'plaintext is a JSON array';

    my %tags;
    for my $tag (@$data) {
        push @{$tags{$tag->[0]}}, $tag;
    }
    is $tags{direction}[0][1], 'in', 'direction tag';
    is $tags{amount}[0][1], '1', 'amount tag';
    is $tags{unit}[0][1], 'sat', 'unit tag';
    is $tags{e}[0], ['e', 'event-id-1', '', 'created'], 'e tag with created marker';
};

subtest 'history_content with out direction and multiple e tags' => sub {
    my $plaintext = Net::Nostr::Wallet->history_content(
        direction => 'out',
        amount    => '4',
        unit      => 'sat',
        e_tags    => [
            ['event-id-1', '', 'destroyed'],
            ['event-id-2', '', 'created'],
        ],
    );
    my $data = $json->decode($plaintext);
    my @e_tags = grep { $_->[0] eq 'e' } @$data;
    is scalar @e_tags, 2, 'multiple e tags';
    is $e_tags[0][3], 'destroyed', 'first e tag marker';
    is $e_tags[1][3], 'created', 'second e tag marker';

    my ($dir) = grep { $_->[0] eq 'direction' } @$data;
    is $dir->[1], 'out', 'direction is out';
};

subtest 'history_content unit defaults to sat' => sub {
    my $plaintext = Net::Nostr::Wallet->history_content(
        direction => 'in',
        amount    => '1',
        e_tags    => [['eid', '', 'created']],
    );
    my $data = $json->decode($plaintext);
    my ($unit) = grep { $_->[0] eq 'unit' } @$data;
    is $unit->[1], 'sat', 'unit defaults to sat';
};

subtest 'history_content requires direction, amount, e_tags' => sub {
    eval { Net::Nostr::Wallet->history_content(amount => '1', e_tags => [['x','','created']]) };
    like $@, qr/direction/, 'croaks without direction';

    eval { Net::Nostr::Wallet->history_content(direction => 'in', e_tags => [['x','','created']]) };
    like $@, qr/amount/, 'croaks without amount';

    eval { Net::Nostr::Wallet->history_content(direction => 'in', amount => '1') };
    like $@, qr/e_tags/, 'croaks without e_tags';
};

subtest 'parse_history_content parses decrypted history data' => sub {
    my $plaintext = $json->encode([
        ['direction', 'in'],
        ['amount', '1'],
        ['unit', 'sat'],
        ['e', 'token-id-1', '', 'created'],
    ]);
    my $history = Net::Nostr::Wallet->parse_history_content($plaintext);
    is $history->direction, 'in', 'direction parsed';
    is $history->amount, '1', 'amount parsed';
    is $history->unit, 'sat', 'unit parsed';
    is scalar @{$history->e_tags}, 1, 'e_tags parsed';
    is $history->e_tags->[0], ['token-id-1', '', 'created'], 'e_tag data';
};

subtest 'parse_history_content defaults unit to sat' => sub {
    my $plaintext = $json->encode([
        ['direction', 'out'],
        ['amount', '4'],
        ['e', 'eid', '', 'destroyed'],
    ]);
    my $history = Net::Nostr::Wallet->parse_history_content($plaintext);
    is $history->unit, 'sat', 'unit defaults to sat';
};

subtest 'history_content round-trips through parse_history_content' => sub {
    my $plaintext = Net::Nostr::Wallet->history_content(
        direction => 'out',
        amount    => '10',
        unit      => 'usd',
        e_tags    => [
            ['id1', 'wss://r', 'destroyed'],
            ['id2', 'wss://r', 'created'],
        ],
    );
    my $history = Net::Nostr::Wallet->parse_history_content($plaintext);
    is $history->direction, 'out', 'direction round-trips';
    is $history->amount, '10', 'amount round-trips';
    is $history->unit, 'usd', 'unit round-trips';
    is scalar @{$history->e_tags}, 2, 'e_tags round-trip';
};

# === Spending history spec example from NIP-60 ===

subtest 'spending history spec example: spend 4 sats' => sub {
    # The spec shows: Alice has proofs [1,2,4,8] sats, spends 4
    # History event records the spend
    my $plaintext = Net::Nostr::Wallet->history_content(
        direction => 'out',
        amount    => '4',
        unit      => 'sat',
        e_tags    => [
            ['event-id-1', '', 'destroyed'],
            ['event-id-2', '', 'created'],
        ],
    );
    my $data = $json->decode($plaintext);

    # Verify structure matches spec
    my ($dir) = grep { $_->[0] eq 'direction' } @$data;
    is $dir->[1], 'out', 'direction is out for spending';

    my ($amt) = grep { $_->[0] eq 'amount' } @$data;
    is $amt->[1], '4', 'amount is 4';

    my @e = grep { $_->[0] eq 'e' } @$data;
    is $e[0][3], 'destroyed', 'old token marked destroyed';
    is $e[1][3], 'created', 'new token marked created';
};

# === kind 7374: Quote Redemption Event (optional) ===

subtest 'quote_event creates kind 7374' => sub {
    my $ev = Net::Nostr::Wallet->quote_event(
        pubkey     => $pubkey,
        content    => 'encrypted-quote-id',
        mint_url   => 'https://mint1',
        expiration => 1234567890,
    );
    is $ev->kind, 7374, 'kind is 7374';
    is $ev->pubkey, $pubkey, 'pubkey set';
    is $ev->content, 'encrypted-quote-id', 'content is pre-encrypted quote ID';

    my @tags = @{$ev->tags};
    my ($exp) = grep { $_->[0] eq 'expiration' } @tags;
    is $exp->[1], '1234567890', 'expiration tag (stringified)';

    my ($mint) = grep { $_->[0] eq 'mint' } @tags;
    is $mint->[1], 'https://mint1', 'mint tag';
};

subtest 'quote_event requires pubkey, content, mint_url, expiration' => sub {
    eval { Net::Nostr::Wallet->quote_event(content => 'x', mint_url => 'u', expiration => 1) };
    like $@, qr/pubkey/, 'croaks without pubkey';

    eval { Net::Nostr::Wallet->quote_event(pubkey => $pubkey, mint_url => 'u', expiration => 1) };
    like $@, qr/content/, 'croaks without content';

    eval { Net::Nostr::Wallet->quote_event(pubkey => $pubkey, content => 'x', expiration => 1) };
    like $@, qr/mint_url/, 'croaks without mint_url';

    eval { Net::Nostr::Wallet->quote_event(pubkey => $pubkey, content => 'x', mint_url => 'u') };
    like $@, qr/expiration/, 'croaks without expiration';
};

subtest 'quote_event expiration stringified' => sub {
    my $ev = Net::Nostr::Wallet->quote_event(
        pubkey     => $pubkey,
        content    => 'encrypted',
        mint_url   => 'https://mint1',
        expiration => 9999999999,
    );
    my ($exp) = grep { $_->[0] eq 'expiration' } @{$ev->tags};
    is $exp->[1], '9999999999', 'expiration is a string per NIP-40';
};

# === delete_token: NIP-09 deletion with k tag ===

subtest 'delete_token creates kind 5 with k:7375 tag' => sub {
    my $ev = Net::Nostr::Wallet->delete_token(
        pubkey    => $pubkey,
        event_ids => [$eid1, $eid2],
    );
    is $ev->kind, 5, 'kind is 5 (NIP-09 deletion)';
    is $ev->pubkey, $pubkey, 'pubkey set';

    my @e_tags = grep { $_->[0] eq 'e' } @{$ev->tags};
    is scalar @e_tags, 2, 'two e tags for deleted tokens';
    is $e_tags[0][1], $eid1, 'first token ID';
    is $e_tags[1][1], $eid2, 'second token ID';

    my @k_tags = grep { $_->[0] eq 'k' } @{$ev->tags};
    is scalar @k_tags, 1, 'one k tag';
    is $k_tags[0][1], '7375', 'k tag is "7375" (MUST have per spec)';
};

subtest 'delete_token requires pubkey and event_ids' => sub {
    eval { Net::Nostr::Wallet->delete_token(event_ids => ['x']) };
    like $@, qr/pubkey/, 'croaks without pubkey';

    eval { Net::Nostr::Wallet->delete_token(pubkey => $pubkey) };
    like $@, qr/event_ids/, 'croaks without event_ids';
};

subtest 'delete_token k tag is string not number' => sub {
    my $ev = Net::Nostr::Wallet->delete_token(
        pubkey    => $pubkey,
        event_ids => [$eid1],
    );
    my ($k) = grep { $_->[0] eq 'k' } @{$ev->tags};
    my $serialized = $json->encode($k);
    like $serialized, qr/"7375"/, 'k tag value serializes as string in JSON';
};

# === from_event parsing ===

subtest 'from_event parses kind 7374 quote event' => sub {
    my $ev = make_event(
        pubkey  => $pubkey,
        kind    => 7374,
        content => 'encrypted-quote',
        tags    => [
            ['expiration', '1234567890'],
            ['mint', 'https://mint1'],
        ],
    );
    my $quote = Net::Nostr::Wallet->from_event($ev);
    is $quote->mint_url, 'https://mint1', 'mint_url parsed';
    is $quote->expiration, '1234567890', 'expiration parsed';
};

subtest 'from_event parses kind 7376 with redeemed e tags' => sub {
    my $ev = make_event(
        pubkey  => $pubkey,
        kind    => 7376,
        content => 'encrypted',
        tags    => [
            ['e', 'nutzap-1', 'wss://r', 'redeemed'],
            ['e', 'nutzap-2', '', 'redeemed'],
        ],
    );
    my $hist = Net::Nostr::Wallet->from_event($ev);
    is scalar @{$hist->redeemed_ids}, 2, 'redeemed IDs parsed from public tags';
    is $hist->redeemed_ids->[0], 'nutzap-1', 'first redeemed ID';
    is $hist->redeemed_ids->[1], 'nutzap-2', 'second redeemed ID';
};

subtest 'from_event kind 7376 ignores non-redeemed e tags' => sub {
    my $ev = make_event(
        pubkey  => $pubkey,
        kind    => 7376,
        content => 'encrypted',
        tags    => [
            ['e', 'created-id', '', 'created'],
            ['e', 'nutzap-id', 'wss://r', 'redeemed'],
            ['e', 'destroyed-id', '', 'destroyed'],
        ],
    );
    my $hist = Net::Nostr::Wallet->from_event($ev);
    is scalar @{$hist->redeemed_ids}, 1, 'only redeemed e tags collected';
    is $hist->redeemed_ids->[0], 'nutzap-id', 'non-redeemed e tags ignored';
};

subtest 'from_event kind 7376 with no public e tags' => sub {
    my $ev = make_event(
        pubkey  => $pubkey,
        kind    => 7376,
        content => 'encrypted',
        tags    => [],
    );
    my $hist = Net::Nostr::Wallet->from_event($ev);
    is $hist->redeemed_ids, [], 'empty redeemed_ids when no public tags';
};

subtest 'from_event returns undef for unrecognized kind' => sub {
    my $ev = make_event(pubkey => $pubkey, kind => 1, content => '', tags => []);
    ok !defined Net::Nostr::Wallet->from_event($ev), 'undef for kind 1';
};

subtest 'from_event parses kind 17375 wallet event' => sub {
    my $ev = make_event(pubkey => $pubkey, kind => 17375, content => 'enc', tags => []);
    my $w = Net::Nostr::Wallet->from_event($ev);
    ok defined $w, 'returns object for kind 17375';
};

subtest 'from_event parses kind 7375 token event' => sub {
    my $ev = make_event(pubkey => $pubkey, kind => 7375, content => 'enc', tags => []);
    my $t = Net::Nostr::Wallet->from_event($ev);
    ok defined $t, 'returns object for kind 7375';
};

# === validate ===

subtest 'validate kind 17375 accepts valid event' => sub {
    my $ev = Net::Nostr::Wallet->wallet_event(pubkey => $pubkey, content => 'enc');
    ok(Net::Nostr::Wallet->validate($ev)), 'valid wallet event';
};

subtest 'validate kind 7375 accepts valid event' => sub {
    my $ev = Net::Nostr::Wallet->token_event(pubkey => $pubkey, content => 'enc');
    ok(Net::Nostr::Wallet->validate($ev)), 'valid token event';
};

subtest 'validate kind 7376 accepts valid event' => sub {
    my $ev = Net::Nostr::Wallet->history_event(pubkey => $pubkey, content => 'enc');
    ok(Net::Nostr::Wallet->validate($ev)), 'valid history event (no public tags ok)';
};

subtest 'validate kind 7374 requires expiration and mint tags' => sub {
    my $ev = make_event(pubkey => $pubkey, kind => 7374, content => 'enc', tags => []);
    eval { Net::Nostr::Wallet->validate($ev) };
    like $@, qr/expiration/, 'croaks without expiration tag';

    my $ev2 = make_event(
        pubkey => $pubkey, kind => 7374, content => 'enc',
        tags => [['expiration', '123']],
    );
    eval { Net::Nostr::Wallet->validate($ev2) };
    like $@, qr/mint/, 'croaks without mint tag';

    my $ev3 = Net::Nostr::Wallet->quote_event(
        pubkey => $pubkey, content => 'enc', mint_url => 'https://m', expiration => 123,
    );
    ok(Net::Nostr::Wallet->validate($ev3)), 'valid quote event';
};

subtest 'validate rejects unrecognized kinds' => sub {
    my $ev = make_event(pubkey => $pubkey, kind => 1, content => '', tags => []);
    eval { Net::Nostr::Wallet->validate($ev) };
    like $@, qr/17375|7375|7376|7374/, 'croaks for unrecognized kind';
};

# === Fetch pattern from spec ===

subtest 'wallet fetch filter pattern from spec' => sub {
    # Spec: "kinds": [17375, 7375], "authors": ["<my-pubkey>"]
    use Net::Nostr::Filter;
    my $filter = Net::Nostr::Filter->new(
        kinds   => [17375, 7375],
        authors => [$pubkey],
    );
    ok $filter->matches(make_event(pubkey => $pubkey, kind => 17375, content => '', tags => [])),
        'filter matches wallet event';
    ok $filter->matches(make_event(pubkey => $pubkey, kind => 7375, content => '', tags => [])),
        'filter matches token event';
    ok !$filter->matches(make_event(pubkey => $pubkey, kind => 7376, content => '', tags => [])),
        'filter does not match history event';
    ok !$filter->matches(make_event(pubkey => 'cc' x 32, kind => 17375, content => '', tags => [])),
        'filter does not match other authors';
};

# === e tag markers: created, destroyed, redeemed ===

subtest 'history_content e_tag markers match spec' => sub {
    for my $marker (qw(created destroyed redeemed)) {
        my $plaintext = Net::Nostr::Wallet->history_content(
            direction => 'in',
            amount    => '1',
            e_tags    => [['eid', '', $marker]],
        );
        my $data = $json->decode($plaintext);
        my ($e) = grep { $_->[0] eq 'e' } @$data;
        is $e->[3], $marker, "e tag marker '$marker' preserved";
    }
};

# === amount is always string ===

subtest 'history_content amount is string' => sub {
    my $plaintext = Net::Nostr::Wallet->history_content(
        direction => 'in',
        amount    => 42,
        e_tags    => [['eid', '', 'created']],
    );
    my $data = $json->decode($plaintext);
    my ($amt) = grep { $_->[0] eq 'amount' } @$data;
    like $json->encode($amt), qr/"42"/, 'amount serializes as string in JSON';
};

# === End-to-end spending workflow from spec (lines 121-174) ===

subtest 'spending workflow: Alice spends 4 sats from [1,2,4,8]' => sub {
    # Step 1: Original token event with proofs [1,2,4,8] sats
    my $original_token = Net::Nostr::Wallet->token_content(
        mint   => 'https://stablenut.umint.cash',
        unit   => 'sat',
        proofs => [
            { id => '1', amount => 1 },
            { id => '2', amount => 2 },
            { id => '3', amount => 4 },
            { id => '4', amount => 8 },
        ],
    );
    my $original = Net::Nostr::Wallet->parse_token_content($original_token);
    is scalar @{$original->proofs}, 4, 'original has 4 proofs';

    # Step 2: MUST roll over unspent proofs into new token (minus spent proof id:3)
    my $rollover_token = Net::Nostr::Wallet->token_content(
        mint   => 'https://stablenut.umint.cash',
        unit   => 'sat',
        proofs => [
            { id => '1', amount => 1 },
            { id => '2', amount => 2 },
            { id => '4', amount => 8 },
        ],
        del => ['event-id-1'],  # SHOULD reference destroyed token
    );
    my $rollover = Net::Nostr::Wallet->parse_token_content($rollover_token);
    is scalar @{$rollover->proofs}, 3, 'rollover has 3 unspent proofs';
    is $rollover->del, ['event-id-1'], 'del references destroyed token';

    # Step 3: MUST delete the original token event with k:7375
    my $delete_ev = Net::Nostr::Wallet->delete_token(
        pubkey    => $pubkey,
        event_ids => [$eid1],
    );
    is $delete_ev->kind, 5, 'delete event is kind 5';
    my ($k) = grep { $_->[0] eq 'k' } @{$delete_ev->tags};
    is $k->[1], '7375', 'delete has k:7375 tag';

    # Step 4: SHOULD create history event recording the spend
    my $history_plain = Net::Nostr::Wallet->history_content(
        direction => 'out',
        amount    => '4',
        unit      => 'sat',
        e_tags    => [
            ['event-id-1', '', 'destroyed'],
            ['event-id-2', '', 'created'],
        ],
    );
    my $history = Net::Nostr::Wallet->parse_history_content($history_plain);
    is $history->direction, 'out', 'spend direction is out';
    is $history->amount, '4', 'spend amount is 4';
    is scalar @{$history->e_tags}, 2, 'two e tags in history';
    is $history->e_tags->[0][2], 'destroyed', 'old token destroyed';
    is $history->e_tags->[1][2], 'created', 'new token created';
};

# === Integration: encrypted content + public redeemed tags ===

subtest 'history event with encrypted content and public redeemed tags' => sub {
    # Encrypted content has created/destroyed e tags
    my $encrypted_content = Net::Nostr::Wallet->history_content(
        direction => 'in',
        amount    => '1',
        unit      => 'sat',
        e_tags    => [
            ['new-token-id', '', 'created'],
        ],
    );
    # Public tags have redeemed e tags (SHOULD be unencrypted per spec)
    my $ev = Net::Nostr::Wallet->history_event(
        pubkey       => $pubkey,
        content      => $encrypted_content,  # would be NIP-44 encrypted in practice
        redeemed_ids => [[$eid1, 'wss://relay1']],
    );

    # Verify public tags only contain redeemed
    my @pub_tags = @{$ev->tags};
    is scalar @pub_tags, 1, 'one public tag';
    is $pub_tags[0][3], 'redeemed', 'public tag has redeemed marker';

    # Verify encrypted content has created tag (not in public tags)
    my $content_data = $json->decode($ev->content);
    my @content_e = grep { $_->[0] eq 'e' } @$content_data;
    is $content_e[0][3], 'created', 'created tag stays in encrypted content';
};

# === Non-standard units ===

subtest 'token_content with non-standard units (usd, eur)' => sub {
    for my $unit (qw(usd eur)) {
        my $plaintext = Net::Nostr::Wallet->token_content(
            mint   => 'https://mint1',
            proofs => [{ id => 'a', amount => 100, secret => 's', C => 'c' }],
            unit   => $unit,
        );
        my $token = Net::Nostr::Wallet->parse_token_content($plaintext);
        is $token->unit, $unit, "unit '$unit' round-trips through token content";
    }
};

subtest 'history_content with non-standard units' => sub {
    for my $unit (qw(usd eur)) {
        my $plaintext = Net::Nostr::Wallet->history_content(
            direction => 'in',
            amount    => '100',
            unit      => $unit,
            e_tags    => [['eid', '', 'created']],
        );
        my $history = Net::Nostr::Wallet->parse_history_content($plaintext);
        is $history->unit, $unit, "unit '$unit' round-trips through history content";
    }
};

# === Relay hints in history_content e tags ===

subtest 'history_content e_tags with relay hints' => sub {
    my $plaintext = Net::Nostr::Wallet->history_content(
        direction => 'out',
        amount    => '4',
        e_tags    => [
            ['event-id-1', 'wss://relay.example.com', 'destroyed'],
            ['event-id-2', 'wss://relay2.example.com', 'created'],
        ],
    );
    my $data = $json->decode($plaintext);
    my @e = grep { $_->[0] eq 'e' } @$data;
    is $e[0][2], 'wss://relay.example.com', 'relay hint preserved in destroyed tag';
    is $e[1][2], 'wss://relay2.example.com', 'relay hint preserved in created tag';
};

###############################################################################
# Hex64 validation for event_ids in tags
###############################################################################

subtest 'rejects invalid hex64 in event_ids used for tags' => sub {
    eval { Net::Nostr::Wallet->delete_token(pubkey => $pubkey, event_ids => ['not-hex']) };
    like $@, qr/64-char lowercase hex/, 'delete_token croaks on non-hex event_id';

    eval { Net::Nostr::Wallet->delete_token(pubkey => $pubkey, event_ids => ['AABB' x 16]) };
    like $@, qr/64-char lowercase hex/, 'delete_token croaks on uppercase event_id';

    eval {
        Net::Nostr::Wallet->history_event(
            pubkey => $pubkey, content => 'enc',
            redeemed_ids => [['bad-id', 'wss://r']],
        );
    };
    like $@, qr/64-char lowercase hex/, 'history_event croaks on non-hex redeemed event_id';

    eval {
        Net::Nostr::Wallet->history_event(
            pubkey => $pubkey, content => 'enc',
            redeemed_ids => [['aa' x 31, '']],
        );
    };
    like $@, qr/64-char lowercase hex/, 'history_event croaks on too-short redeemed event_id';
};

done_testing;
