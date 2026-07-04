use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Event;
use Net::Nostr::MintDiscovery;

my $PK = 'a' x 64;

###############################################################################
# Recommendation event (kind 38000)
###############################################################################

subtest 'recommendation: kind 38000' => sub {
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'my-rec',
        mint_kind  => '38173',
    );
    is($event->kind, 38000, 'kind is 38000');
    ok($event->is_addressable, 'addressable');
};

# Spec: k tag is the kind number of the event being recommended
subtest 'recommendation: k tag' => sub {
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'my-rec',
        mint_kind  => '38173',
    );
    my @k = grep { $_->[0] eq 'k' } @{$event->tags};
    is($k[0][1], '38173', 'k tag');
};

subtest 'recommendation: k tag for cashu' => sub {
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'my-rec',
        mint_kind  => '38172',
    );
    my @k = grep { $_->[0] eq 'k' } @{$event->tags};
    is($k[0][1], '38172', 'k tag for cashu');
};

# Spec: d tag identifier
subtest 'recommendation: d tag' => sub {
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'fed-abc',
        mint_kind  => '38173',
    );
    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'fed-abc', 'd tag');
};

# Spec: u tags (optional, repeated) URL or invite code
subtest 'recommendation: u tags' => sub {
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'my-rec',
        mint_kind  => '38173',
        urls       => [
            ['fed11abc..', 'fedimint'],
            ['https://cashu.example.com', 'cashu'],
        ],
    );
    my @u = grep { $_->[0] eq 'u' } @{$event->tags};
    is(scalar @u, 2, 'two u tags');
    is($u[0][1], 'fed11abc..', 'first u value');
    is($u[0][2], 'fedimint', 'first u type');
    is($u[1][1], 'https://cashu.example.com', 'second u value');
    is($u[1][2], 'cashu', 'second u type');
};

# Spec: a tags point to 38173/38172 events
subtest 'recommendation: a tags' => sub {
    my $mint_pk = 'b' x 64;
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'my-rec',
        mint_kind  => '38173',
        mint_refs  => [
            ["38173:${mint_pk}:fed-id", 'wss://relay1', 'fedimint'],
        ],
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][1], "38173:${mint_pk}:fed-id", 'a tag coord');
    is($a[0][2], 'wss://relay1', 'a tag relay');
    is($a[0][3], 'fedimint', 'a tag type');
};

# Spec: content can be used to give a review
subtest 'recommendation: content' => sub {
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'my-rec',
        mint_kind  => '38173',
        content    => 'I trust this mint with my life',
    );
    is($event->content, 'I trust this mint with my life', 'content');
};

subtest 'recommendation: content defaults to empty' => sub {
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'my-rec',
        mint_kind  => '38173',
    );
    is($event->content, '', 'empty content');
};

# Spec: first example shows u tag without type label ["u", <invite-code>]
subtest 'recommendation: u tag without type label' => sub {
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'my-rec',
        mint_kind  => '38173',
        urls       => [['fed11abc..']],
    );
    my @u = grep { $_->[0] eq 'u' } @{$event->tags};
    is(scalar @u, 1, 'one u tag');
    is($u[0][1], 'fed11abc..', 'u value');
    is(scalar @{$u[0]}, 2, 'no type element');
};

# Spec: first example shows a tag without type label ["a", coord, relay]
subtest 'recommendation: a tag without type label' => sub {
    my $mint_pk = 'b' x 64;
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'my-rec',
        mint_kind  => '38173',
        mint_refs  => [["38173:${mint_pk}:fed-id", 'wss://relay1']],
    );
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is($a[0][1], "38173:${mint_pk}:fed-id", 'a coord');
    is($a[0][2], 'wss://relay1', 'a relay');
    is(scalar @{$a[0]}, 3, 'no type element');
};

# Spec example: User A recommends some mints
subtest 'recommendation: spec example' => sub {
    my $fed_pk = 'b' x 64;
    my $cashu_pk = 'c' x 64;
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'my-recs',
        mint_kind  => '38173',
        urls       => [
            ['fed11abc..', 'fedimint'],
            ['https://cashu.example.com', 'cashu'],
        ],
        mint_refs  => [
            ["38173:${fed_pk}:fed-id", 'wss://relay1', 'fedimint'],
            ["38172:${cashu_pk}:cashu-id", 'wss://relay2', 'cashu'],
        ],
    );
    is($event->kind, 38000, 'kind');
    my @u = grep { $_->[0] eq 'u' } @{$event->tags};
    is(scalar @u, 2, 'u tag count');
    is($u[0][1], 'fed11abc..', 'first u value');
    is($u[0][2], 'fedimint', 'first u type');
    is($u[1][1], 'https://cashu.example.com', 'second u value');
    is($u[1][2], 'cashu', 'second u type');
    my @a = grep { $_->[0] eq 'a' } @{$event->tags};
    is(scalar @a, 2, 'a tag count');
    is($a[0][1], "38173:${fed_pk}:fed-id", 'first a coord');
    is($a[0][2], 'wss://relay1', 'first a relay');
    is($a[0][3], 'fedimint', 'first a type');
    is($a[1][1], "38172:${cashu_pk}:cashu-id", 'second a coord');
    is($a[1][2], 'wss://relay2', 'second a relay');
    is($a[1][3], 'cashu', 'second a type');
};

# Spec: recommendation requires identifier
subtest 'recommendation: requires identifier' => sub {
    like(
        dies {
            Net::Nostr::MintDiscovery->recommendation(
                pubkey => $PK, mint_kind => '38173',
            )
        },
        qr/identifier/i,
        'requires identifier'
    );
};

# Spec: recommendation requires mint_kind
subtest 'recommendation: requires mint_kind' => sub {
    like(
        dies {
            Net::Nostr::MintDiscovery->recommendation(
                pubkey => $PK, identifier => 'x',
            )
        },
        qr/mint_kind/i,
        'requires mint_kind'
    );
};

###############################################################################
# Cashu Mint Information (kind 38172)
###############################################################################

subtest 'cashu_mint: kind 38172' => sub {
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $PK,
        identifier => 'mint-pubkey-abc',
    );
    is($event->kind, 38172, 'kind is 38172');
    ok($event->is_addressable, 'addressable');
};

# Spec: d tag SHOULD be the mint's pubkey
subtest 'cashu_mint: d tag' => sub {
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $PK,
        identifier => 'mint-pubkey-abc',
    );
    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'mint-pubkey-abc', 'd tag');
};

# Spec: u tag SHOULD be URL to cashu mint
subtest 'cashu_mint: u tag' => sub {
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $PK,
        identifier => 'mint-pubkey-abc',
        urls       => ['https://cashu.example.com'],
    );
    my @u = grep { $_->[0] eq 'u' } @{$event->tags};
    is($u[0][1], 'https://cashu.example.com', 'u tag');
};

# Spec: nuts tag lists supported NUTs
subtest 'cashu_mint: nuts tag' => sub {
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $PK,
        identifier => 'mint-pubkey-abc',
        nuts       => '1,2,3,4,5,6,7',
    );
    my @n = grep { $_->[0] eq 'nuts' } @{$event->tags};
    is($n[0][1], '1,2,3,4,5,6,7', 'nuts');
};

# Spec: n tag for network
subtest 'cashu_mint: n tag' => sub {
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $PK,
        identifier => 'mint-pubkey-abc',
        network    => 'mainnet',
    );
    my @n = grep { $_->[0] eq 'n' } @{$event->tags};
    is($n[0][1], 'mainnet', 'network');
};

# Spec: content is optional metadata JSON
subtest 'cashu_mint: content' => sub {
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $PK,
        identifier => 'mint-pubkey-abc',
        content    => '{"name":"My Mint"}',
    );
    is($event->content, '{"name":"My Mint"}', 'content');
};

subtest 'cashu_mint: content defaults to empty' => sub {
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $PK,
        identifier => 'mint-pubkey-abc',
    );
    is($event->content, '', 'empty content');
};

# Spec: cashu mint spec example
subtest 'cashu_mint: spec example' => sub {
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $PK,
        identifier => 'cashu-mint-pubkey',
        urls       => ['https://cashu.example.com'],
        nuts       => '1,2,3,4,5,6,7',
        network    => 'mainnet',
        content    => '<optional-kind:0-style-metadata>',
    );
    is($event->kind, 38172, 'kind');

    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'cashu-mint-pubkey', 'd');

    my @u = grep { $_->[0] eq 'u' } @{$event->tags};
    is($u[0][1], 'https://cashu.example.com', 'u');

    my @nuts = grep { $_->[0] eq 'nuts' } @{$event->tags};
    is($nuts[0][1], '1,2,3,4,5,6,7', 'nuts');

    my @n = grep { $_->[0] eq 'n' } @{$event->tags};
    is($n[0][1], 'mainnet', 'n');
};

# Spec: cashu_mint requires identifier
subtest 'cashu_mint: requires identifier' => sub {
    like(
        dies {
            Net::Nostr::MintDiscovery->cashu_mint(pubkey => $PK)
        },
        qr/identifier/i,
        'requires identifier'
    );
};

###############################################################################
# Fedimint Information (kind 38173)
###############################################################################

subtest 'fedimint: kind 38173' => sub {
    my $event = Net::Nostr::MintDiscovery->fedimint(
        pubkey     => $PK,
        identifier => 'federation-id-abc',
    );
    is($event->kind, 38173, 'kind is 38173');
    ok($event->is_addressable, 'addressable');
};

# Spec: d tag SHOULD be the federation id
subtest 'fedimint: d tag' => sub {
    my $event = Net::Nostr::MintDiscovery->fedimint(
        pubkey     => $PK,
        identifier => 'federation-id-abc',
    );
    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'federation-id-abc', 'd tag');
};

# Spec: u tags list invite codes (repeated)
subtest 'fedimint: u tags' => sub {
    my $event = Net::Nostr::MintDiscovery->fedimint(
        pubkey     => $PK,
        identifier => 'federation-id-abc',
        urls       => ['fed11abc..', 'fed11xyz..'],
    );
    my @u = grep { $_->[0] eq 'u' } @{$event->tags};
    is(scalar @u, 2, 'two u tags');
    is($u[0][1], 'fed11abc..', 'first invite');
    is($u[1][1], 'fed11xyz..', 'second invite');
};

# Spec: modules tag
subtest 'fedimint: modules tag' => sub {
    my $event = Net::Nostr::MintDiscovery->fedimint(
        pubkey     => $PK,
        identifier => 'federation-id-abc',
        modules    => 'lightning,wallet,mint',
    );
    my @m = grep { $_->[0] eq 'modules' } @{$event->tags};
    is($m[0][1], 'lightning,wallet,mint', 'modules');
};

# Spec: n tag for network
subtest 'fedimint: n tag' => sub {
    my $event = Net::Nostr::MintDiscovery->fedimint(
        pubkey     => $PK,
        identifier => 'federation-id-abc',
        network    => 'signet',
    );
    my @n = grep { $_->[0] eq 'n' } @{$event->tags};
    is($n[0][1], 'signet', 'network');
};

# Spec: content is optional metadata JSON
subtest 'fedimint: content' => sub {
    my $event = Net::Nostr::MintDiscovery->fedimint(
        pubkey     => $PK,
        identifier => 'federation-id-abc',
        content    => '{"name":"My Federation"}',
    );
    is($event->content, '{"name":"My Federation"}', 'content');
};

subtest 'fedimint: content defaults to empty' => sub {
    my $event = Net::Nostr::MintDiscovery->fedimint(
        pubkey     => $PK,
        identifier => 'federation-id-abc',
    );
    is($event->content, '', 'empty content');
};

# Spec: fedimint spec example
subtest 'fedimint: spec example' => sub {
    my $event = Net::Nostr::MintDiscovery->fedimint(
        pubkey     => $PK,
        identifier => 'federation-id',
        urls       => ['fed11abc..', 'fed11xyz..'],
        modules    => 'lightning,wallet,mint',
        network    => 'signet',
        content    => '<optional-kind:0-style-metadata>',
    );
    is($event->kind, 38173, 'kind');

    my @d = grep { $_->[0] eq 'd' } @{$event->tags};
    is($d[0][1], 'federation-id', 'd');

    my @u = grep { $_->[0] eq 'u' } @{$event->tags};
    is(scalar @u, 2, 'u count');
    is($u[0][1], 'fed11abc..', 'first u');
    is($u[1][1], 'fed11xyz..', 'second u');

    my @m = grep { $_->[0] eq 'modules' } @{$event->tags};
    is($m[0][1], 'lightning,wallet,mint', 'modules');

    my @n = grep { $_->[0] eq 'n' } @{$event->tags};
    is($n[0][1], 'signet', 'n');
};

# Spec: fedimint requires identifier
subtest 'fedimint: requires identifier' => sub {
    like(
        dies {
            Net::Nostr::MintDiscovery->fedimint(pubkey => $PK)
        },
        qr/identifier/i,
        'requires identifier'
    );
};

###############################################################################
# from_event: round-trip parsing
###############################################################################

subtest 'from_event: recommendation round-trip' => sub {
    my $mint_pk = 'b' x 64;
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'my-rec',
        mint_kind  => '38173',
        urls       => [
            ['fed11abc..', 'fedimint'],
        ],
        mint_refs  => [
            ["38173:${mint_pk}:fed-id", 'wss://relay1', 'fedimint'],
        ],
        content    => 'Great mint',
    );
    my $parsed = Net::Nostr::MintDiscovery->from_event($event);
    is($parsed->identifier, 'my-rec', 'identifier');
    is($parsed->mint_kind, '38173', 'mint_kind');
    is(scalar @{$parsed->urls}, 1, 'urls');
    is($parsed->urls->[0][0], 'fed11abc..', 'url value');
    is($parsed->urls->[0][1], 'fedimint', 'url type');
    is(scalar @{$parsed->mint_refs}, 1, 'mint_refs count');
    is($parsed->mint_refs->[0][0], "38173:${mint_pk}:fed-id", 'mint_ref coord');
    is($parsed->mint_refs->[0][1], 'wss://relay1', 'mint_ref relay');
    is($parsed->mint_refs->[0][2], 'fedimint', 'mint_ref type');
    is($parsed->description, 'Great mint', 'description');
};

subtest 'from_event: cashu_mint round-trip' => sub {
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $PK,
        identifier => 'mint-pk',
        urls       => ['https://cashu.example.com'],
        nuts       => '1,2,3',
        network    => 'mainnet',
        content    => '{"name":"Mint"}',
    );
    my $parsed = Net::Nostr::MintDiscovery->from_event($event);
    is($parsed->identifier, 'mint-pk', 'identifier');
    is($parsed->urls->[0], 'https://cashu.example.com', 'url');
    is($parsed->nuts, '1,2,3', 'nuts');
    is($parsed->network, 'mainnet', 'network');
    is($parsed->description, '{"name":"Mint"}', 'description');
};

subtest 'from_event: fedimint round-trip' => sub {
    my $event = Net::Nostr::MintDiscovery->fedimint(
        pubkey     => $PK,
        identifier => 'fed-id',
        urls       => ['fed11abc..', 'fed11xyz..'],
        modules    => 'lightning,wallet',
        network    => 'testnet',
    );
    my $parsed = Net::Nostr::MintDiscovery->from_event($event);
    is($parsed->identifier, 'fed-id', 'identifier');
    is(scalar @{$parsed->urls}, 2, 'urls count');
    is($parsed->urls->[0], 'fed11abc..', 'first url');
    is($parsed->urls->[1], 'fed11xyz..', 'second url');
    is($parsed->modules, 'lightning,wallet', 'modules');
    is($parsed->network, 'testnet', 'network');
};

subtest 'from_event: returns undef for wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    is(Net::Nostr::MintDiscovery->from_event($event), undef, 'undef for kind 1');
};

###############################################################################
# validate
###############################################################################

subtest 'validate: valid recommendation' => sub {
    my $event = Net::Nostr::MintDiscovery->recommendation(
        pubkey     => $PK,
        identifier => 'x',
        mint_kind  => '38173',
    );
    ok(Net::Nostr::MintDiscovery->validate($event), 'valid');
};

subtest 'validate: valid cashu_mint' => sub {
    my $event = Net::Nostr::MintDiscovery->cashu_mint(
        pubkey     => $PK,
        identifier => 'x',
    );
    ok(Net::Nostr::MintDiscovery->validate($event), 'valid');
};

subtest 'validate: valid fedimint' => sub {
    my $event = Net::Nostr::MintDiscovery->fedimint(
        pubkey     => $PK,
        identifier => 'x',
    );
    ok(Net::Nostr::MintDiscovery->validate($event), 'valid');
};

subtest 'validate: rejects wrong kind' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 1, content => '', tags => [],
    );
    like(
        dies { Net::Nostr::MintDiscovery->validate($event) },
        qr/kind/i,
        'rejects wrong kind'
    );
};

subtest 'validate: recommendation requires d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 38000, content => '',
        tags => [['k', '38173']],
    );
    like(
        dies { Net::Nostr::MintDiscovery->validate($event) },
        qr/d.*tag/i,
        'rejects missing d tag'
    );
};

subtest 'validate: recommendation requires k tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 38000, content => '',
        tags => [['d', 'x']],
    );
    like(
        dies { Net::Nostr::MintDiscovery->validate($event) },
        qr/k.*tag/i,
        'rejects missing k tag'
    );
};

subtest 'validate: cashu_mint requires d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 38172, content => '',
        tags => [],
    );
    like(
        dies { Net::Nostr::MintDiscovery->validate($event) },
        qr/d.*tag/i,
        'rejects missing d tag'
    );
};

subtest 'validate: fedimint requires d tag' => sub {
    my $event = Net::Nostr::Event->new(
        pubkey => $PK, kind => 38173, content => '',
        tags => [],
    );
    like(
        dies { Net::Nostr::MintDiscovery->validate($event) },
        qr/d.*tag/i,
        'rejects missing d tag'
    );
};

###############################################################################
# Constructor: unknown args rejected
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::MintDiscovery->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

done_testing;
