use strictures 2;
use Test2::V0 -no_srand => 1;
use lib 't/lib';
use TestFixtures qw(make_event);
use JSON ();

use Net::Nostr::WalletConnect;

my $wallet_pubkey = 'b889ff5b1513b641e2a139f661a661364979c5beee91842f8f0ef42ab558e9d4';
my $client_secret = '71a8c14c1407c113601079c4302dab36460f0ccd0ad506f1f2dc73b5100e4f3c';
my $client_pubkey = 'a' x 64;

# --- POD SYNOPSIS: parse_uri ---

subtest 'POD SYNOPSIS: parse_uri' => sub {
    my $conn = Net::Nostr::WalletConnect->parse_uri(
        "nostr+walletconnect://${wallet_pubkey}?relay=wss%3A%2F%2Frelay.damus.io&secret=${client_secret}"
    );
    ok $conn->wallet_pubkey, 'wallet_pubkey';
    ok $conn->secret, 'secret';
    ok $conn->relays->[0], 'relay';
};

# --- POD SYNOPSIS: create_uri ---

subtest 'POD SYNOPSIS: create_uri' => sub {
    my $uri = Net::Nostr::WalletConnect->create_uri(
        wallet_pubkey => $wallet_pubkey,
        relay         => 'wss://relay.damus.io',
        secret        => $client_secret,
        lud16         => 'alice@example.com',
    );
    like $uri, qr/^nostr\+walletconnect:\/\//, 'protocol prefix';
};

# --- POD SYNOPSIS: parse_info ---

subtest 'POD SYNOPSIS: parse_info' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 13194, pubkey => $wallet_pubkey,
        created_at => 1000,
        content => 'pay_invoice get_balance',
        tags => [['encryption', 'nip44_v2 nip04']],
        sig => '2' x 128,
    );
    my $info = Net::Nostr::WalletConnect->parse_info($event);
    ok scalar @{$info->capabilities}, 'capabilities';
    is $info->preferred_encryption, 'nip44_v2', 'preferred_encryption';
};

# --- POD SYNOPSIS: request ---

subtest 'POD SYNOPSIS: request' => sub {
    my $payload = Net::Nostr::WalletConnect->request(
        method => 'pay_invoice',
        params => { invoice => 'lnbc50n1...' },
    );
    ok $payload, 'payload is truthy';
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'pay_invoice', 'method in payload';
};

# --- POD SYNOPSIS: request_event ---

subtest 'POD SYNOPSIS: request_event' => sub {
    my $event = Net::Nostr::WalletConnect->request_event(
        method        => 'pay_invoice',
        params        => { invoice => 'lnbc50n1...' },
        pubkey        => $client_pubkey,
        wallet_pubkey => $wallet_pubkey,
        encryption    => 'nip44_v2',
    );
    is $event->kind, 23194, 'kind 23194';
};

# --- POD SYNOPSIS: parse_response ---

subtest 'POD SYNOPSIS: parse_response success' => sub {
    my $json = JSON->new->utf8->encode({
        result_type => 'pay_invoice', error => undef,
        result => { preimage => 'abc123' },
    });
    my $resp = Net::Nostr::WalletConnect->parse_response($json);
    ok !$resp->is_error, 'not error';
    is $resp->result->{preimage}, 'abc123', 'preimage';
};

subtest 'POD SYNOPSIS: parse_response error' => sub {
    my $json = JSON->new->utf8->encode({
        result_type => 'pay_invoice',
        error => { code => 'PAYMENT_FAILED', message => 'Timeout' },
        result => undef,
    });
    my $resp = Net::Nostr::WalletConnect->parse_response($json);
    ok $resp->is_error, 'is error';
    is $resp->error_code, 'PAYMENT_FAILED', 'error_code';
    is $resp->error_message, 'Timeout', 'error_message';
};

# --- POD SYNOPSIS: parse_notification ---

subtest 'POD SYNOPSIS: parse_notification' => sub {
    my $json = JSON->new->utf8->encode({
        notification_type => 'payment_received',
        notification => { type => 'incoming', amount => 50000 },
    });
    my $notif = Net::Nostr::WalletConnect->parse_notification($json);
    is $notif->notification_type, 'payment_received', 'type';
    is $notif->notification->{amount}, 50000, 'amount';
};

# --- POD: info_event ---

subtest 'POD info_event' => sub {
    my $event = Net::Nostr::WalletConnect->info_event(
        pubkey        => $wallet_pubkey,
        capabilities  => [qw(pay_invoice get_balance)],
        encryption    => [qw(nip44_v2 nip04)],
        notifications => [qw(payment_received)],
    );
    is $event->kind, 13194, 'kind 13194';
};

# --- POD: response_event ---

subtest 'POD response_event' => sub {
    my $event = Net::Nostr::WalletConnect->response_event(
        result_type   => 'pay_invoice',
        result        => { preimage => '...' },
        error         => undef,
        pubkey        => $wallet_pubkey,
        client_pubkey => $client_pubkey,
        request_id    => '3' x 64,
    );
    is $event->kind, 23195, 'kind 23195';
};

# --- POD: notification_event ---

subtest 'POD notification_event' => sub {
    my $event = Net::Nostr::WalletConnect->notification_event(
        notification_type => 'payment_received',
        notification      => { type => 'incoming', amount => 50000 },
        pubkey            => $wallet_pubkey,
        client_pubkey     => $client_pubkey,
        encryption        => 'nip44_v2',
    );
    is $event->kind, 23197, 'kind 23197';
};

# --- POD: validate_metadata ---

subtest 'POD validate_metadata' => sub {
    my $ok = Net::Nostr::WalletConnect->validate_metadata({ comment => 'hello' });
    ok $ok, 'valid';
};

# --- POD: validate_request ---

subtest 'POD validate_request' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 23194, pubkey => $client_pubkey,
        created_at => 1000, content => '{}',
        tags => [['p', $wallet_pubkey]],
        sig => '2' x 128,
    );
    my $ok = eval { Net::Nostr::WalletConnect->validate_request($event) };
    ok $ok, 'valid request';
};

# --- POD: validate_response ---

subtest 'POD validate_response' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 23195, pubkey => $wallet_pubkey,
        created_at => 1000, content => '{}',
        tags => [['p', $client_pubkey], ['e', '3' x 64]],
        sig => '2' x 128,
    );
    my $ok = eval { Net::Nostr::WalletConnect->validate_response($event) };
    ok $ok, 'valid response';
};

# --- POD: is_expired ---

subtest 'POD is_expired' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 23194, pubkey => $client_pubkey,
        created_at => 1000, content => '{}',
        tags => [['p', $wallet_pubkey], ['expiration', '1000']],
        sig => '2' x 128,
    );
    my $exp = Net::Nostr::WalletConnect->is_expired($event);
    ok $exp, 'expired';
};

# --- Validation: secret and wallet_pubkey must be 64-char hex ---

subtest 'parse_uri rejects non-hex secret' => sub {
    my $uri = "nostr+walletconnect://${wallet_pubkey}?relay=wss%3A%2F%2Frelay.damus.io&secret=not-valid-hex";
    ok !eval { Net::Nostr::WalletConnect->parse_uri($uri) }, 'croaks on bad secret';
    like $@, qr/secret/, 'error mentions secret';
};

subtest 'create_uri rejects non-hex wallet_pubkey' => sub {
    ok !eval { Net::Nostr::WalletConnect->create_uri(
        wallet_pubkey => 'not-hex',
        relay         => 'wss://r.com',
        secret        => $client_secret,
    ) }, 'croaks on bad wallet_pubkey';
    like $@, qr/wallet_pubkey/, 'error mentions wallet_pubkey';
};

subtest 'create_uri rejects non-hex secret' => sub {
    ok !eval { Net::Nostr::WalletConnect->create_uri(
        wallet_pubkey => $wallet_pubkey,
        relay         => 'wss://r.com',
        secret        => 'bad-secret',
    ) }, 'croaks on bad secret';
    like $@, qr/secret/, 'error mentions secret';
};

subtest 'WalletConnect inner classes reject unknown arguments' => sub {
    ok !eval { Net::Nostr::WalletConnect::Connection->new(bogus => 'value') },
        'Connection rejects unknown args';
    like $@, qr/unknown.+bogus/i, 'Connection error mentions bogus';

    ok !eval { Net::Nostr::WalletConnect::Info->new(bogus => 'value') },
        'Info rejects unknown args';
    like $@, qr/unknown.+bogus/i, 'Info error mentions bogus';

    ok !eval { Net::Nostr::WalletConnect::Response->new(bogus => 'value') },
        'Response rejects unknown args';
    like $@, qr/unknown.+bogus/i, 'Response error mentions bogus';

    ok !eval { Net::Nostr::WalletConnect::Notification->new(bogus => 'value') },
        'Notification rejects unknown args';
    like $@, qr/unknown.+bogus/i, 'Notification error mentions bogus';
};

###############################################################################
# parse_info validation
###############################################################################

subtest 'parse_info rejects wrong event kind' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 1, pubkey => $wallet_pubkey,
        created_at => 1000,
        content => 'pay_invoice',
        tags => [],
        sig => '2' x 128,
    );
    ok !eval { Net::Nostr::WalletConnect->parse_info($event) }, 'croaks';
    like $@, qr/kind 13194/, 'error mentions kind';
};

###############################################################################
# parse_response validation
###############################################################################

subtest 'parse_response rejects missing result_type' => sub {
    my $json = JSON->new->utf8->encode({ result => { preimage => 'abc' } });
    ok !eval { Net::Nostr::WalletConnect->parse_response($json) }, 'croaks';
    like $@, qr/result_type is required/, 'error mentions result_type';
};

###############################################################################
# parse_notification validation
###############################################################################

subtest 'parse_notification rejects missing notification_type' => sub {
    my $json = JSON->new->utf8->encode({ notification => { amount => 50000 } });
    ok !eval { Net::Nostr::WalletConnect->parse_notification($json) }, 'croaks';
    like $@, qr/notification_type is required/, 'error mentions notification_type';
};

subtest 'parse_notification rejects missing notification' => sub {
    my $json = JSON->new->utf8->encode({ notification_type => 'payment_received' });
    ok !eval { Net::Nostr::WalletConnect->parse_notification($json) }, 'croaks';
    like $@, qr/notification is required/, 'error mentions notification';
};

###############################################################################
# Response constructor validation
###############################################################################

subtest 'WC Response constructor rejects missing result_type' => sub {
    ok !eval { Net::Nostr::WalletConnect::Response->new(result => { preimage => 'abc' }) },
        'croaks';
    like $@, qr/result_type is required/, 'error mentions result_type';
};

###############################################################################
# Notification constructor validation
###############################################################################

subtest 'WC Notification constructor rejects missing notification_type' => sub {
    ok !eval { Net::Nostr::WalletConnect::Notification->new(notification => { amount => 50000 }) },
        'croaks';
    like $@, qr/notification_type is required/, 'error mentions notification_type';
};

subtest 'WC Notification constructor rejects missing notification' => sub {
    ok !eval { Net::Nostr::WalletConnect::Notification->new(notification_type => 'payment_received') },
        'croaks';
    like $@, qr/notification is required/, 'error mentions notification';
};

###############################################################################
# Builder pubkey validation
###############################################################################

subtest 'WC request_event requires pubkey' => sub {
    ok !eval { Net::Nostr::WalletConnect->request_event(
        method => 'pay_invoice', params => { invoice => 'lnbc50n1...' },
        wallet_pubkey => $wallet_pubkey,
    ) }, 'croaks without pubkey';
    like $@, qr/requires 'pubkey'/, 'error mentions pubkey';
};

subtest 'WC response_event requires pubkey' => sub {
    ok !eval { Net::Nostr::WalletConnect->response_event(
        result_type => 'pay_invoice', result => { preimage => 'abc' },
    ) }, 'croaks without pubkey';
    like $@, qr/requires 'pubkey'/, 'error mentions pubkey';
};

subtest 'WC notification_event requires pubkey' => sub {
    ok !eval { Net::Nostr::WalletConnect->notification_event(
        notification_type => 'payment_received',
        notification => { amount => 50000 },
    ) }, 'croaks without pubkey';
    like $@, qr/requires 'pubkey'/, 'error mentions pubkey';
};

subtest 'WC request_event rejects bad pubkey' => sub {
    ok !eval { Net::Nostr::WalletConnect->request_event(
        method => 'pay_invoice', params => { invoice => 'lnbc50n1...' },
        wallet_pubkey => $wallet_pubkey,
        pubkey => 'bad',
    ) }, 'croaks on bad pubkey';
    like $@, qr/pubkey must be 64-char/, 'error mentions format';
};

###############################################################################
# Defensive copying: caller/accessor mutation must not affect internal state
###############################################################################

subtest 'WC Connection: caller mutation of relays does not affect object' => sub {
    my @relays = ('wss://relay1.example.com');
    my $conn = Net::Nostr::WalletConnect::Connection->new(
        wallet_pubkey => 'a' x 64, relays => \@relays, secret => 'b' x 64,
    );
    push @relays, 'wss://relay2.example.com';
    is scalar @{$conn->relays}, 1, 'relays unaffected';
};

subtest 'WC Connection: accessor mutation of relays does not affect object' => sub {
    my $conn = Net::Nostr::WalletConnect::Connection->new(
        wallet_pubkey => 'a' x 64,
        relays => ['wss://relay1.example.com'],
        secret => 'b' x 64,
    );
    my $got = $conn->relays;
    push @$got, 'wss://relay2.example.com';
    is scalar @{$conn->relays}, 1, 'relays unaffected';
};

subtest 'WC Info: accessor mutation of capabilities does not affect object' => sub {
    my $info = Net::Nostr::WalletConnect::Info->new(
        capabilities => [qw(pay_invoice)], encryption => [qw(nip44_v2)],
        notification_types => [qw(payment_received)],
    );
    push @{$info->capabilities}, 'get_balance';
    is scalar @{$info->capabilities}, 1, 'capabilities unaffected';
};

subtest 'WC Info: accessor mutation of encryption does not affect object' => sub {
    my $info = Net::Nostr::WalletConnect::Info->new(
        capabilities => [qw(pay_invoice)], encryption => [qw(nip44_v2)],
        notification_types => [],
    );
    push @{$info->encryption}, 'nip04';
    is scalar @{$info->encryption}, 1, 'encryption unaffected';
};

subtest 'WC Info: accessor mutation of notification_types does not affect object' => sub {
    my $info = Net::Nostr::WalletConnect::Info->new(
        capabilities => [qw(pay_invoice)], encryption => [qw(nip44_v2)],
        notification_types => [qw(payment_received)],
    );
    push @{$info->notification_types}, 'payment_sent';
    is scalar @{$info->notification_types}, 1, 'notification_types unaffected';
};

###############################################################################
# parse_uri lowercases pubkey from URI
###############################################################################

subtest 'parse_uri lowercases pubkey from URI' => sub {
    my $uc_pubkey = uc($wallet_pubkey);
    my $uri = "nostr+walletconnect://${uc_pubkey}?relay=" . _uri_encode('wss://relay.damus.io') . "&secret=$client_secret";
    my $conn = Net::Nostr::WalletConnect->parse_uri($uri);
    is($conn->wallet_pubkey, $wallet_pubkey, 'parsed pubkey is lowercase');
};

sub _uri_encode {
    my ($str) = @_;
    $str =~ s/([^A-Za-z0-9\-_.~])/sprintf("%%%02X", ord($1))/ge;
    return $str;
}

done_testing;
