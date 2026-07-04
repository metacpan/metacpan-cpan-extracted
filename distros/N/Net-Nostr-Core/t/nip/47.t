use strictures 2;
use Test2::V0 -no_srand => 1;
use lib 't/lib';
use TestFixtures qw(make_event);
use JSON ();

use Net::Nostr::WalletConnect;

my $wallet_pubkey = 'b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4';
my $client_secret = '71a8c14c1407c113601079c4302dab36460f0ccd0ad506f1f2dc73b5100e4f3c';
my $client_pubkey = 'a' x 64;
my $relay = 'wss://relay.damus.io';

# ==========================================================================
# Connection URI
# ==========================================================================

# Spec: "The wallet service generates this connection URI with protocol
# nostr+walletconnect:// and base path its 32-byte hex-encoded pubkey"

subtest 'parse_uri: spec example connection string' => sub {
    my $uri = "nostr+walletconnect://${wallet_pubkey}?relay=wss%3A%2F%2Frelay.damus.io&secret=${client_secret}";
    my $conn = Net::Nostr::WalletConnect->parse_uri($uri);
    is $conn->wallet_pubkey, $wallet_pubkey, 'wallet pubkey';
    is $conn->relays, [$relay], 'relay';
    is $conn->secret, $client_secret, 'secret';
    ok !defined $conn->lud16, 'lud16 not present';
};

# Spec: "lud16 Recommended. A lightning address"

subtest 'parse_uri: with lud16' => sub {
    my $uri = "nostr+walletconnect://${wallet_pubkey}?relay=wss%3A%2F%2Frelay.damus.io&secret=${client_secret}&lud16=alice%40example.com";
    my $conn = Net::Nostr::WalletConnect->parse_uri($uri);
    is $conn->lud16, 'alice@example.com', 'lud16 decoded';
};

# Spec: "relay Required. ... May be more than one."

subtest 'parse_uri: multiple relays' => sub {
    my $uri = "nostr+walletconnect://${wallet_pubkey}?relay=wss%3A%2F%2Frelay.damus.io&relay=wss%3A%2F%2Frelay2.example.com&secret=${client_secret}";
    my $conn = Net::Nostr::WalletConnect->parse_uri($uri);
    is $conn->relays, [$relay, 'wss://relay2.example.com'], 'multiple relays';
};

subtest 'parse_uri: croaks on invalid protocol' => sub {
    eval { Net::Nostr::WalletConnect->parse_uri("http://example.com") };
    like $@, qr/nostr\+walletconnect/, 'croaks';
};

subtest 'parse_uri: croaks without relay' => sub {
    eval { Net::Nostr::WalletConnect->parse_uri("nostr+walletconnect://${wallet_pubkey}?secret=${client_secret}") };
    like $@, qr/relay/, 'croaks';
};

subtest 'parse_uri: croaks without secret' => sub {
    eval { Net::Nostr::WalletConnect->parse_uri("nostr+walletconnect://${wallet_pubkey}?relay=wss%3A%2F%2Frelay.damus.io") };
    like $@, qr/secret/, 'croaks';
};

# Spec: "pubkey, which SHOULD be unique per client connection"

subtest 'create_uri: round-trip' => sub {
    my $uri = Net::Nostr::WalletConnect->create_uri(
        wallet_pubkey => $wallet_pubkey,
        relay         => $relay,
        secret        => $client_secret,
    );
    like $uri, qr/^nostr\+walletconnect:\/\//, 'protocol prefix';
    my $conn = Net::Nostr::WalletConnect->parse_uri($uri);
    is $conn->wallet_pubkey, $wallet_pubkey, 'round-trip wallet_pubkey';
    is $conn->secret, $client_secret, 'round-trip secret';
    is $conn->relays, [$relay], 'round-trip relay';
};

subtest 'create_uri: with lud16 and multiple relays' => sub {
    my $uri = Net::Nostr::WalletConnect->create_uri(
        wallet_pubkey => $wallet_pubkey,
        relay         => [$relay, 'wss://relay2.example.com'],
        secret        => $client_secret,
        lud16         => 'alice@example.com',
    );
    my $conn = Net::Nostr::WalletConnect->parse_uri($uri);
    is $conn->relays, [$relay, 'wss://relay2.example.com'], 'multiple relays';
    is $conn->lud16, 'alice@example.com', 'lud16';
};

# ==========================================================================
# Info Event (kind 13194)
# ==========================================================================

# Spec: "The content should be a plaintext string with the supported
# capabilities space-separated"

subtest 'info_event: creates kind 13194 with capabilities' => sub {
    my $event = Net::Nostr::WalletConnect->info_event(
        pubkey       => $wallet_pubkey,
        capabilities => [qw(pay_invoice get_balance make_invoice lookup_invoice list_transactions get_info notifications)],
        encryption   => [qw(nip44_v2 nip04)],
        notifications => [qw(payment_received payment_sent)],
    );
    is $event->kind, 13194, 'kind 13194';
    is $event->content, 'pay_invoice get_balance make_invoice lookup_invoice list_transactions get_info notifications', 'capabilities in content';

    my @enc = grep { $_->[0] eq 'encryption' } @{$event->tags};
    is scalar @enc, 1, 'one encryption tag';
    is $enc[0][1], 'nip44_v2 nip04', 'encryption values';

    my @notif = grep { $_->[0] eq 'notifications' } @{$event->tags};
    is scalar @notif, 1, 'one notifications tag';
    is $notif[0][1], 'payment_received payment_sent', 'notification types';
};

# Spec example info event

subtest 'info_event: spec example' => sub {
    my $event = Net::Nostr::WalletConnect->info_event(
        pubkey       => 'c04ccd5c82fc1ea3499b9c6a5c0a7ab627fbe00a0116110d4c750faeaecba1e2',
        capabilities => [qw(pay_invoice pay_keysend get_balance get_info make_invoice lookup_invoice list_transactions multi_pay_invoice multi_pay_keysend sign_message notifications)],
        encryption   => [qw(nip44_v2 nip04)],
        notifications => [qw(payment_received payment_sent)],
    );
    is $event->kind, 13194, 'kind';
    like $event->content, qr/pay_invoice/, 'has pay_invoice';
    like $event->content, qr/notifications/, 'has notifications';
};

subtest 'parse_info: parses info event' => sub {
    my $event = make_event(
        id         => '1' x 64,
        kind       => 13194,
        pubkey     => $wallet_pubkey,
        created_at => 1713883677,
        content    => 'pay_invoice get_balance make_invoice lookup_invoice list_transactions get_info notifications',
        tags       => [
            ['encryption', 'nip44_v2 nip04'],
            ['notifications', 'payment_received payment_sent'],
        ],
        sig        => '2' x 128,
    );

    my $info = Net::Nostr::WalletConnect->parse_info($event);
    is $info->capabilities, [qw(pay_invoice get_balance make_invoice lookup_invoice list_transactions get_info notifications)], 'capabilities';
    is $info->encryption, [qw(nip44_v2 nip04)], 'encryption';
    is $info->notification_types, [qw(payment_received payment_sent)], 'notification types';
};

# Spec: "Absence of this tag implies that the wallet only supports nip04."

subtest 'parse_info: missing encryption tag implies nip04' => sub {
    my $event = make_event(
        id         => '3' x 64,
        kind       => 13194,
        pubkey     => $wallet_pubkey,
        created_at => 1000,
        content    => 'pay_invoice get_balance',
        tags       => [],
        sig        => '4' x 128,
    );

    my $info = Net::Nostr::WalletConnect->parse_info($event);
    is $info->encryption, ['nip04'], 'defaults to nip04';
};

subtest 'parse_info: supports_capability' => sub {
    my $event = make_event(
        id         => '5' x 64,
        kind       => 13194,
        pubkey     => $wallet_pubkey,
        created_at => 1000,
        content    => 'pay_invoice get_balance',
        tags       => [],
        sig        => '6' x 128,
    );

    my $info = Net::Nostr::WalletConnect->parse_info($event);
    ok $info->supports_capability('pay_invoice'), 'supports pay_invoice';
    ok $info->supports_capability('get_balance'), 'supports get_balance';
    ok !$info->supports_capability('make_invoice'), 'does not support make_invoice';
};

subtest 'parse_info: supports_encryption' => sub {
    my $event = make_event(
        id         => '7' x 64,
        kind       => 13194,
        pubkey     => $wallet_pubkey,
        created_at => 1000,
        content    => 'pay_invoice',
        tags       => [['encryption', 'nip44_v2 nip04']],
        sig        => '8' x 128,
    );

    my $info = Net::Nostr::WalletConnect->parse_info($event);
    ok $info->supports_encryption('nip44_v2'), 'supports nip44_v2';
    ok $info->supports_encryption('nip04'), 'supports nip04';
    ok !$info->supports_encryption('nip99'), 'does not support nip99';
};

subtest 'parse_info: preferred_encryption prefers nip44_v2' => sub {
    my $event = make_event(
        id         => '9' x 64,
        kind       => 13194,
        pubkey     => $wallet_pubkey,
        created_at => 1000,
        content    => 'pay_invoice',
        tags       => [['encryption', 'nip44_v2 nip04']],
        sig        => 'a' x 128,
    );

    my $info = Net::Nostr::WalletConnect->parse_info($event);
    is $info->preferred_encryption, 'nip44_v2', 'prefers nip44_v2';
};

subtest 'parse_info: preferred_encryption falls back to nip04' => sub {
    my $event = make_event(
        id         => 'b' x 64,
        kind       => 13194,
        pubkey     => $wallet_pubkey,
        created_at => 1000,
        content    => 'pay_invoice',
        tags       => [],
        sig        => 'c' x 128,
    );

    my $info = Net::Nostr::WalletConnect->parse_info($event);
    is $info->preferred_encryption, 'nip04', 'falls back to nip04';
};

# ==========================================================================
# Request payloads
# ==========================================================================

# Spec: pay_invoice command

subtest 'request: pay_invoice' => sub {
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'pay_invoice',
        params => { invoice => 'lnbc50n1...' },
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'pay_invoice', 'method';
    is $data->{params}{invoice}, 'lnbc50n1...', 'invoice param';
};

subtest 'request: pay_invoice with optional amount and metadata' => sub {
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'pay_invoice',
        params => { invoice => 'lnbc50n1...', amount => 123, metadata => {} },
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{params}{amount}, 123, 'amount';
    is ref $data->{params}{metadata}, 'HASH', 'metadata is hash';
};

# Spec: pay_keysend command

subtest 'request: pay_keysend' => sub {
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'pay_keysend',
        params => {
            amount  => 123,
            pubkey  => '03' . ('a' x 62),
            preimage => '0123456789abcdef' x 4,
            tlv_records => [{ type => 5482373484, value => '0123456789abcdef' }],
        },
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'pay_keysend', 'method';
    is $data->{params}{amount}, 123, 'amount';
    is $data->{params}{pubkey}, '03' . ('a' x 62), 'pubkey';
};

# Spec: make_invoice command

subtest 'request: make_invoice' => sub {
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'make_invoice',
        params => { amount => 123, description => 'test invoice', expiry => 3600 },
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'make_invoice', 'method';
    is $data->{params}{amount}, 123, 'amount';
    is $data->{params}{description}, 'test invoice', 'description';
};

# Spec: lookup_invoice command

subtest 'request: lookup_invoice by payment_hash' => sub {
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'lookup_invoice',
        params => { payment_hash => '31afdf1' . ('0' x 57) },
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'lookup_invoice', 'method';
    ok $data->{params}{payment_hash}, 'payment_hash present';
};

subtest 'request: lookup_invoice by invoice' => sub {
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'lookup_invoice',
        params => { invoice => 'lnbc50n1...' },
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{params}{invoice}, 'lnbc50n1...', 'invoice param';
};

# Spec: list_transactions command

subtest 'request: list_transactions' => sub {
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'list_transactions',
        params => { from => 1693876973, until => 1703225078, limit => 10, offset => 0, unpaid => JSON::true, type => 'incoming' },
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'list_transactions', 'method';
    is $data->{params}{from}, 1693876973, 'from';
    is $data->{params}{until}, 1703225078, 'until';
    is $data->{params}{limit}, 10, 'limit';
    is $data->{params}{type}, 'incoming', 'type';
};

# Spec: get_balance command

subtest 'request: get_balance' => sub {
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'get_balance',
        params => {},
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'get_balance', 'method';
    is ref $data->{params}, 'HASH', 'params is hash';
};

# Spec: get_info command

subtest 'request: get_info' => sub {
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'get_info',
        params => {},
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'get_info', 'method';
};

# Spec: make_hold_invoice

subtest 'request: make_hold_invoice' => sub {
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'make_hold_invoice',
        params => { amount => 123, payment_hash => 'abc123' },
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'make_hold_invoice', 'method';
    is $data->{params}{payment_hash}, 'abc123', 'payment_hash';
};

# Spec: cancel_hold_invoice

subtest 'request: cancel_hold_invoice' => sub {
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'cancel_hold_invoice',
        params => { payment_hash => 'abc123' },
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'cancel_hold_invoice', 'method';
};

# Spec: settle_hold_invoice

subtest 'request: settle_hold_invoice' => sub {
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'settle_hold_invoice',
        params => { preimage => 'deadbeef' x 8 },
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'settle_hold_invoice', 'method';
};

# Spec: "method ... string" and "params ... object" are required

subtest 'request: croaks without method' => sub {
    eval { Net::Nostr::WalletConnect->request(params => {}) };
    like $@, qr/method/, 'croaks';
};

subtest 'request: croaks without params' => sub {
    eval { Net::Nostr::WalletConnect->request(method => 'get_info') };
    like $@, qr/params/, 'croaks';
};

# ==========================================================================
# Request Event (kind 23194)
# ==========================================================================

# Spec: "Both the request and response events SHOULD contain one p tag,
# containing the public key of the wallet service if this is a request"

subtest 'request_event: creates kind 23194 with p tag' => sub {
    my $event = Net::Nostr::WalletConnect->request_event(
        method        => 'pay_invoice',
        params        => { invoice => 'lnbc50n1...' },
        pubkey        => $client_pubkey,
        wallet_pubkey => $wallet_pubkey,
        encryption    => 'nip44_v2',
    );
    is $event->kind, 23194, 'kind 23194';

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is scalar @p, 1, 'one p tag';
    is $p[0][1], $wallet_pubkey, 'p tag is wallet pubkey';

    my @enc = grep { $_->[0] eq 'encryption' } @{$event->tags};
    is scalar @enc, 1, 'encryption tag';
    is $enc[0][1], 'nip44_v2', 'encryption value';
};

# Spec: "a request can have an expiration tag that has a unix timestamp"

subtest 'request_event: with expiration tag' => sub {
    my $event = Net::Nostr::WalletConnect->request_event(
        method        => 'pay_invoice',
        params        => { invoice => 'lnbc50n1...' },
        pubkey        => $client_pubkey,
        wallet_pubkey => $wallet_pubkey,
        encryption    => 'nip44_v2',
        expiration    => 1700000000,
    );
    my @exp = grep { $_->[0] eq 'expiration' } @{$event->tags};
    is scalar @exp, 1, 'expiration tag';
    is $exp[0][1], '1700000000', 'expiration value';
};

# Spec: "Absence of the encryption tag indicates use of nip04"

# Spec: request content is JSON with "method" (string) and "params" (object)

subtest 'request_event: content is valid JSON with method and params' => sub {
    my $event = Net::Nostr::WalletConnect->request_event(
        method        => 'pay_invoice',
        params        => { invoice => 'lnbc50n1...' },
        pubkey        => $client_pubkey,
        wallet_pubkey => $wallet_pubkey,
    );
    my $data = JSON->new->utf8->decode($event->content);
    is $data->{method}, 'pay_invoice', 'method in content';
    is $data->{params}{invoice}, 'lnbc50n1...', 'params in content';
};

subtest 'request_event: no encryption tag when not specified' => sub {
    my $event = Net::Nostr::WalletConnect->request_event(
        method        => 'get_balance',
        params        => {},
        pubkey        => $client_pubkey,
        wallet_pubkey => $wallet_pubkey,
    );
    my @enc = grep { $_->[0] eq 'encryption' } @{$event->tags};
    is scalar @enc, 0, 'no encryption tag implies nip04';
};

# ==========================================================================
# Response payloads
# ==========================================================================

# Spec: "result_type field MUST contain the name of the method"

subtest 'parse_response: successful pay_invoice' => sub {
    my $json = JSON->new->utf8->encode({
        result_type => 'pay_invoice',
        error       => undef,
        result      => { preimage => '0123456789abcdef' x 4 },
    });
    my $resp = Net::Nostr::WalletConnect->parse_response($json);
    is $resp->result_type, 'pay_invoice', 'result_type';
    ok !$resp->is_error, 'not an error';
    is $resp->result->{preimage}, '0123456789abcdef' x 4, 'preimage';
};

# Spec: "error field MUST contain a message field ... and a code field"

subtest 'parse_response: error response' => sub {
    my $json = JSON->new->utf8->encode({
        result_type => 'pay_invoice',
        error       => { code => 'INSUFFICIENT_BALANCE', message => 'Not enough funds' },
        result      => undef,
    });
    my $resp = Net::Nostr::WalletConnect->parse_response($json);
    ok $resp->is_error, 'is an error';
    is $resp->error_code, 'INSUFFICIENT_BALANCE', 'error code';
    is $resp->error_message, 'Not enough funds', 'error message';
};

# Spec: "If the command was successful, the error field must be null"

subtest 'parse_response: successful get_balance' => sub {
    my $json = JSON->new->utf8->encode({
        result_type => 'get_balance',
        error       => undef,
        result      => { balance => 10000 },
    });
    my $resp = Net::Nostr::WalletConnect->parse_response($json);
    is $resp->result_type, 'get_balance', 'result_type';
    ok !$resp->is_error, 'not error';
    is $resp->result->{balance}, 10000, 'balance in msats';
};

subtest 'parse_response: get_info result' => sub {
    my $json = JSON->new->utf8->encode({
        result_type => 'get_info',
        error       => undef,
        result      => {
            alias        => 'my-node',
            color        => '#ff0000',
            pubkey       => $wallet_pubkey,
            network      => 'mainnet',
            block_height => 800000,
            block_hash   => 'f' x 64,
            methods      => [qw(pay_invoice get_balance)],
            notifications => [qw(payment_received)],
        },
    });
    my $resp = Net::Nostr::WalletConnect->parse_response($json);
    is $resp->result->{alias}, 'my-node', 'alias';
    is $resp->result->{network}, 'mainnet', 'network';
    is $resp->result->{methods}, [qw(pay_invoice get_balance)], 'methods';
};

subtest 'parse_response: list_transactions result' => sub {
    my $json = JSON->new->utf8->encode({
        result_type => 'list_transactions',
        error       => undef,
        result      => {
            transactions => [
                { type => 'incoming', state => 'settled', amount => 1000, payment_hash => 'abc', created_at => 1700000000 },
                { type => 'outgoing', state => 'settled', amount => 500, payment_hash => 'def', created_at => 1700000001 },
            ],
        },
    });
    my $resp = Net::Nostr::WalletConnect->parse_response($json);
    is scalar @{$resp->result->{transactions}}, 2, 'two transactions';
    is $resp->result->{transactions}[0]{type}, 'incoming', 'first is incoming';
};

subtest 'parse_response: pay_invoice with fees_paid' => sub {
    my $json = JSON->new->utf8->encode({
        result_type => 'pay_invoice',
        error       => undef,
        result      => { preimage => 'abc123', fees_paid => 100 },
    });
    my $resp = Net::Nostr::WalletConnect->parse_response($json);
    is $resp->result->{fees_paid}, 100, 'fees_paid';
};

# ==========================================================================
# Error codes
# ==========================================================================

# Spec error codes

subtest 'error codes: all spec error codes' => sub {
    my @codes = qw(
        RATE_LIMITED NOT_IMPLEMENTED INSUFFICIENT_BALANCE
        QUOTA_EXCEEDED RESTRICTED UNAUTHORIZED INTERNAL
        UNSUPPORTED_ENCRYPTION OTHER PAYMENT_FAILED NOT_FOUND
    );
    for my $code (@codes) {
        my $json = JSON->new->utf8->encode({
            result_type => 'pay_invoice',
            error       => { code => $code, message => "test $code" },
            result      => undef,
        });
        my $resp = Net::Nostr::WalletConnect->parse_response($json);
        is $resp->error_code, $code, "$code is preserved";
    }
};

# ==========================================================================
# Response Event (kind 23195)
# ==========================================================================

# Spec: response SHOULD contain p tag with client pubkey and e tag with request id

subtest 'response_event: creates kind 23195 with p and e tags' => sub {
    my $event = Net::Nostr::WalletConnect->response_event(
        result_type   => 'pay_invoice',
        result        => { preimage => 'abc123' },
        pubkey        => $wallet_pubkey,
        client_pubkey => $client_pubkey,
        request_id    => 'f' x 64,
    );
    is $event->kind, 23195, 'kind 23195';

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is $p[0][1], $client_pubkey, 'p tag is client pubkey';

    my @e = grep { $_->[0] eq 'e' } @{$event->tags};
    is $e[0][1], 'f' x 64, 'e tag is request id';
};

subtest 'response_event: error response' => sub {
    my $event = Net::Nostr::WalletConnect->response_event(
        result_type   => 'pay_invoice',
        error         => { code => 'PAYMENT_FAILED', message => 'Timeout' },
        pubkey        => $wallet_pubkey,
        client_pubkey => $client_pubkey,
        request_id    => 'f' x 64,
    );
    is $event->kind, 23195, 'kind 23195';
    # content is unencrypted JSON (encryption handled separately)
    my $data = JSON->new->utf8->decode($event->content);
    is $data->{error}{code}, 'PAYMENT_FAILED', 'error code in content';
};

# ==========================================================================
# Notification payloads
# ==========================================================================

# Spec: payment_received notification

subtest 'parse_notification: payment_received' => sub {
    my $json = JSON->new->utf8->encode({
        notification_type => 'payment_received',
        notification      => {
            type         => 'incoming',
            state        => 'settled',
            invoice      => 'lnbc50n1...',
            preimage     => 'abc123',
            payment_hash => 'def456',
            amount       => 50000,
            fees_paid    => 0,
            created_at   => 1700000000,
            settled_at   => 1700000001,
        },
    });
    my $notif = Net::Nostr::WalletConnect->parse_notification($json);
    is $notif->notification_type, 'payment_received', 'type';
    is $notif->notification->{type}, 'incoming', 'incoming';
    is $notif->notification->{amount}, 50000, 'amount';
    is $notif->notification->{settled_at}, 1700000001, 'settled_at';
};

# Spec: payment_sent notification

subtest 'parse_notification: payment_sent' => sub {
    my $json = JSON->new->utf8->encode({
        notification_type => 'payment_sent',
        notification      => {
            type         => 'outgoing',
            state        => 'settled',
            invoice      => 'lnbc50n1...',
            preimage     => 'abc123',
            payment_hash => 'def456',
            amount       => 50000,
            fees_paid    => 100,
            created_at   => 1700000000,
            settled_at   => 1700000001,
        },
    });
    my $notif = Net::Nostr::WalletConnect->parse_notification($json);
    is $notif->notification_type, 'payment_sent', 'type';
    is $notif->notification->{type}, 'outgoing', 'outgoing';
    is $notif->notification->{fees_paid}, 100, 'fees_paid';
};

# Spec: hold_invoice_accepted notification

subtest 'parse_notification: hold_invoice_accepted' => sub {
    my $json = JSON->new->utf8->encode({
        notification_type => 'hold_invoice_accepted',
        notification      => {
            type           => 'incoming',
            state          => 'accepted',
            invoice        => 'lnbc50n1...',
            payment_hash   => 'def456',
            amount         => 50000,
            created_at     => 1700000000,
            expires_at     => 1700003600,
            settle_deadline => 850000,
        },
    });
    my $notif = Net::Nostr::WalletConnect->parse_notification($json);
    is $notif->notification_type, 'hold_invoice_accepted', 'type';
    is $notif->notification->{state}, 'accepted', 'state';
    is $notif->notification->{settle_deadline}, 850000, 'settle_deadline';
};

# ==========================================================================
# Notification Event (kind 23197)
# ==========================================================================

# Spec: "notification event is a kind 23197 event SHOULD contain one p tag"

subtest 'notification_event: creates kind 23197 with p tag' => sub {
    my $event = Net::Nostr::WalletConnect->notification_event(
        notification_type => 'payment_received',
        notification      => { type => 'incoming', amount => 50000, payment_hash => 'abc' },
        pubkey            => $wallet_pubkey,
        client_pubkey     => $client_pubkey,
    );
    is $event->kind, 23197, 'kind 23197';

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is $p[0][1], $client_pubkey, 'p tag is client pubkey';
};

# Spec: "If a wallet service supports both nip04 and nip44, it should publish
# two notification events for each notification - kind 23196 encrypted with
# NIP-04, and kind 23197 encrypted with NIP-44."

subtest 'notification_event: kind 23196 for nip04 backwards compat' => sub {
    my $event = Net::Nostr::WalletConnect->notification_event(
        notification_type => 'payment_received',
        notification      => { type => 'incoming', amount => 50000 },
        pubkey            => $wallet_pubkey,
        client_pubkey     => $client_pubkey,
        encryption        => 'nip04',
    );
    is $event->kind, 23196, 'kind 23196 for nip04';

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is $p[0][1], $client_pubkey, 'p tag is client pubkey';
};

# ==========================================================================
# Metadata
# ==========================================================================

# Spec: "Metadata MAY be stored ... MUST be no more than 4096 characters"

subtest 'validate_metadata: accepts valid metadata' => sub {
    my $ok = Net::Nostr::WalletConnect->validate_metadata({ comment => 'hello' });
    ok $ok, 'valid metadata';
};

subtest 'validate_metadata: rejects metadata over 4096 chars' => sub {
    my $big = { comment => 'x' x 5000 };
    eval { Net::Nostr::WalletConnect->validate_metadata($big) };
    like $@, qr/4096/, 'croaks on oversized metadata';
};

# ==========================================================================
# Validation
# ==========================================================================

subtest 'validate: request event kind' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 1, pubkey => $client_pubkey,
        created_at => 1000, content => '{}', tags => [], sig => '2' x 128,
    );
    eval { Net::Nostr::WalletConnect->validate_request($event) };
    like $@, qr/23194/, 'croaks on wrong kind';
};

subtest 'validate: request event must have p tag' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 23194, pubkey => $client_pubkey,
        created_at => 1000, content => '{}', tags => [], sig => '2' x 128,
    );
    eval { Net::Nostr::WalletConnect->validate_request($event) };
    like $@, qr/p tag/, 'croaks without p tag';
};

subtest 'validate: response event kind' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 1, pubkey => $wallet_pubkey,
        created_at => 1000, content => '{}', tags => [], sig => '2' x 128,
    );
    eval { Net::Nostr::WalletConnect->validate_response($event) };
    like $@, qr/23195/, 'croaks on wrong kind';
};

subtest 'validate: response event should have p and e tags' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 23195, pubkey => $wallet_pubkey,
        created_at => 1000, content => '{}',
        tags => [['p', $client_pubkey], ['e', '3' x 64]],
        sig => '2' x 128,
    );
    ok eval { Net::Nostr::WalletConnect->validate_response($event) }, 'valid response';
};

# Spec: "If the request is received after this timestamp, it should be ignored"

subtest 'is_expired: checks expiration tag' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 23194, pubkey => $client_pubkey,
        created_at => 1000, content => '{}',
        tags => [['p', $wallet_pubkey], ['expiration', '1000']],
        sig => '2' x 128,
    );
    my $exp = Net::Nostr::WalletConnect->is_expired($event);
    ok $exp, 'expired event';
};

subtest 'is_expired: not expired if no expiration tag' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 23194, pubkey => $client_pubkey,
        created_at => 1000, content => '{}',
        tags => [['p', $wallet_pubkey]],
        sig => '2' x 128,
    );
    my $exp = Net::Nostr::WalletConnect->is_expired($event);
    ok !$exp, 'not expired';
};

subtest 'is_expired: not expired if timestamp in future' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 23194, pubkey => $client_pubkey,
        created_at => 1000, content => '{}',
        tags => [['p', $wallet_pubkey], ['expiration', '' . (time() + 86400)]],
        sig => '2' x 128,
    );
    my $exp = Net::Nostr::WalletConnect->is_expired($event);
    ok !$exp, 'future expiration';
};

done_testing;
