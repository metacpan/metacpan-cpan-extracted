use strictures 2;
use Test2::V0 -no_srand => 1;
use JSON ();

use lib 't/lib';
use TestFixtures qw(make_event make_key_from_hex);

use Net::Nostr::Zap qw(
    lud16_to_url
    encode_lnurl decode_lnurl
    bolt11_amount
    callback_url
    calculate_splits
);

###############################################################################
# Construction
###############################################################################

subtest 'new_request basic' => sub {
    my $zap = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://r.com'],
    );
    isa_ok $zap, 'Net::Nostr::Zap';
    is $zap->p, 'b' x 64, 'p accessor';
    is $zap->relays, ['wss://r.com'], 'relays accessor';
};

subtest 'new_receipt basic' => sub {
    my $zap = Net::Nostr::Zap->new_receipt(
        p           => 'b' x 64,
        bolt11      => 'lnbc1test',
        description => '{"kind":9734}',
    );
    isa_ok $zap, 'Net::Nostr::Zap';
    is $zap->p, 'b' x 64, 'p accessor';
    is $zap->bolt11, 'lnbc1test', 'bolt11 accessor';
};

###############################################################################
# to_event
###############################################################################

subtest 'request to_event passes through extra args' => sub {
    my $zap = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://r.com'],
    );
    my $event = $zap->to_event(pubkey => 'a' x 64, created_at => 1234567890);
    is $event->pubkey, 'a' x 64, 'pubkey passed through';
    is $event->created_at, 1234567890, 'created_at passed through';
};

subtest 'receipt to_event passes through extra args' => sub {
    my $zap = Net::Nostr::Zap->new_receipt(
        p           => 'b' x 64,
        bolt11      => 'lnbc1test',
        description => '{}',
    );
    my $event = $zap->to_event(pubkey => 'd' x 64, created_at => 9999);
    is $event->created_at, 9999, 'created_at passed through';
};

###############################################################################
# lud16_to_url
###############################################################################

subtest 'lud16_to_url POD examples' => sub {
    is lud16_to_url('alice@example.com'),
        'https://example.com/.well-known/lnurlp/alice',
        'basic lightning address';
    is lud16_to_url('bob@pay.domain.org'),
        'https://pay.domain.org/.well-known/lnurlp/bob',
        'subdomain lightning address';
};

subtest 'lud16_to_url lowercases username' => sub {
    is lud16_to_url('User@Example.COM'),
        'https://example.com/.well-known/lnurlp/user',
        'lowercased';
};

###############################################################################
# bolt11_amount edge cases
###############################################################################

subtest 'bolt11_amount with spec receipt invoice' => sub {
    my $bolt11 = 'lnbc10u1p3unwfusp5t9r3yymhpfqculx78u027lxspgxcr2n2987mx2j55nnfs95nxnzqpp5jmrh92pfld78spqs78v9euf2385t83uvpwk9ldrlvf6ch7tpascqhp5zvkrmemgth3tufcvflmzjzfvjt023nazlhljz2n9hattj4f8jq8qxqyjw5qcqpjrzjqtc4fc44feggv7065fqe5m4ytjarg3repr5j9el35xhmtfexc42yczarjuqqfzqqqqqqqqlgqqqqqqgq9q9qxpqysgq079nkq507a5tw7xgttmj4u990j7wfggtrasah5gd4ywfr2pjcn29383tphp4t48gquelz9z78p4cq7ml3nrrphw5w6eckhjwmhezhnqpy6gyf0';
    is bolt11_amount($bolt11), 1_000_000, 'spec example bolt11 = 1,000,000 millisats';
};

###############################################################################
# encode_lnurl / decode_lnurl
###############################################################################

subtest 'encode_lnurl produces lowercase bech32' => sub {
    my $encoded = encode_lnurl('https://example.com');
    is $encoded, lc($encoded), 'all lowercase';
    like $encoded, qr/^lnurl1/, 'lnurl prefix';
};

###############################################################################
# callback_url
###############################################################################

subtest 'callback_url with existing query params' => sub {
    my $event = make_event(
        kind    => 9734,
        pubkey  => 'a' x 64,
        content => '',
        tags    => [['p', 'b' x 64]],
    );
    my $url = callback_url('https://pay.test/cb?token=abc', amount => 1000, nostr => $event);
    like $url, qr{token=abc}, 'existing params preserved';
    like $url, qr{amount=1000}, 'amount added';
};

###############################################################################
# new_request validation
###############################################################################

subtest 'new_request rejects missing p' => sub {
    like(dies { Net::Nostr::Zap->new_request(relays => ['wss://r.com']) },
        qr/p is required/, 'p is required');
};

subtest 'new_request rejects missing relays' => sub {
    like(dies { Net::Nostr::Zap->new_request(p => 'b' x 64) },
        qr/relays is required/, 'relays is required');
};

###############################################################################
# new_receipt validation
###############################################################################

subtest 'new_receipt rejects missing p' => sub {
    like(dies { Net::Nostr::Zap->new_receipt(bolt11 => 'lnbc1test', description => '{}') },
        qr/p is required/, 'p is required');
};

subtest 'new_receipt rejects missing bolt11' => sub {
    like(dies { Net::Nostr::Zap->new_receipt(p => 'b' x 64, description => '{}') },
        qr/bolt11 is required/, 'bolt11 is required');
};

subtest 'new_receipt rejects missing description' => sub {
    like(dies { Net::Nostr::Zap->new_receipt(p => 'b' x 64, bolt11 => 'lnbc1test') },
        qr/description is required/, 'description is required');
};

###############################################################################
# Round-trip tests
###############################################################################

subtest 'Round-trip: request to_event -> request_from_event' => sub {
    my $zap = Net::Nostr::Zap->new_request(
        p       => 'b' x 64,
        relays  => ['wss://r1.com', 'wss://r2.com'],
        amount  => '21000',
        lnurl   => 'lnurl1test',
        content => 'Great post!',
        e       => 'c' x 64,
        a       => '30023:' . ('d' x 64) . ':my-slug',
    );
    my $event = $zap->to_event(pubkey => 'a' x 64);
    my $parsed = Net::Nostr::Zap->request_from_event($event);

    is $parsed->p, 'b' x 64, 'p round-trips';
    is $parsed->relays, ['wss://r1.com', 'wss://r2.com'], 'relays round-trip';
    is $parsed->amount, '21000', 'amount round-trips';
    is $parsed->lnurl, 'lnurl1test', 'lnurl round-trips';
    is $parsed->e, 'c' x 64, 'e round-trips';
    is $parsed->a, '30023:' . ('d' x 64) . ':my-slug', 'a round-trips';
};

subtest 'Round-trip: receipt to_event -> receipt_from_event' => sub {
    my $zap = Net::Nostr::Zap->new_receipt(
        p           => 'b' x 64,
        bolt11      => 'lnbc10u1test',
        description => '{"kind":9734}',
        preimage    => 'f' x 64,
        e           => 'c' x 64,
    );
    my $event = $zap->to_event(pubkey => 'a' x 64);
    my $parsed = Net::Nostr::Zap->receipt_from_event($event);

    is $parsed->p, 'b' x 64, 'p round-trips';
    is $parsed->bolt11, 'lnbc10u1test', 'bolt11 round-trips';
    is $parsed->description, '{"kind":9734}', 'description round-trips';
    is $parsed->preimage, 'f' x 64, 'preimage round-trips';
    is $parsed->e, 'c' x 64, 'e round-trips';
};

###############################################################################
# from_event wrong kind
###############################################################################

subtest 'request_from_event rejects wrong kind' => sub {
    my $event = make_event(kind => 1, pubkey => 'a' x 64, content => '', tags => []);
    like(dies { Net::Nostr::Zap->request_from_event($event) },
        qr/kind 9734/, 'rejects non-9734 event');
};

subtest 'receipt_from_event rejects wrong kind' => sub {
    my $event = make_event(kind => 1, pubkey => 'a' x 64, content => '', tags => []);
    like(dies { Net::Nostr::Zap->receipt_from_event($event) },
        qr/kind 9735/, 'rejects non-9735 event');
};

###############################################################################
# encode/decode lnurl round-trip
###############################################################################

subtest 'decode_lnurl round-trips with encode_lnurl' => sub {
    my $url = 'https://example.com/.well-known/lnurlp/alice';
    my $encoded = encode_lnurl($url);
    my $decoded = decode_lnurl($encoded);
    is $decoded, $url, 'decode(encode(url)) == url';
};

done_testing;
