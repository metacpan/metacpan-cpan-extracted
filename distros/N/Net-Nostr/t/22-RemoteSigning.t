use strictures 2;
use Test2::V0 -no_srand => 1;
use lib 't/lib';
use TestFixtures qw(make_event);
use JSON ();

use Net::Nostr::RemoteSigning;

my $remote_signer_pubkey = 'fa984bd7dbb282f07e16e7ae87b26a2a7b9b90b7246a44771f0cf5ae58018f52';
my $client_pubkey        = 'eff37350d839ce3707332348af4549a96051bd695d3223af4aabce4993531d86';

# --- POD SYNOPSIS: parse_bunker_uri ---

subtest 'POD SYNOPSIS: parse_bunker_uri' => sub {
    my $conn = Net::Nostr::RemoteSigning->parse_bunker_uri(
        "bunker://${remote_signer_pubkey}?relay=wss%3A%2F%2Frelay.example.com&secret=mysecret"
    );
    ok $conn->remote_signer_pubkey, 'remote_signer_pubkey';
    ok $conn->relays->[0], 'relay';
};

# --- POD SYNOPSIS: parse_nostrconnect_uri ---

subtest 'POD SYNOPSIS: parse_nostrconnect_uri' => sub {
    my $nc = Net::Nostr::RemoteSigning->parse_nostrconnect_uri(
        "nostrconnect://${client_pubkey}?relay=wss%3A%2F%2Frelay.example.com&secret=0s8j2djs&name=My+Client"
    );
    ok $nc->client_pubkey, 'client_pubkey';
    ok $nc->secret, 'secret';
};

# --- POD SYNOPSIS: request ---

subtest 'POD SYNOPSIS: request' => sub {
    my $payload = Net::Nostr::RemoteSigning->request(
        id     => 'req-1',
        method => 'sign_event',
        params => ['{}'],
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'sign_event', 'method';
};

# --- POD SYNOPSIS: request_event ---

subtest 'POD SYNOPSIS: request_event' => sub {
    my $event = Net::Nostr::RemoteSigning->request_event(
        id                   => 'req-1',
        method               => 'sign_event',
        params               => ['{}'],
        pubkey               => $client_pubkey,
        remote_signer_pubkey => $remote_signer_pubkey,
    );
    is $event->kind, 24133, 'kind 24133';
};

# --- POD SYNOPSIS: parse_response ---

subtest 'POD SYNOPSIS: parse_response' => sub {
    my $json = JSON->new->utf8->encode({ id => 'req-1', result => 'pong' });
    my $resp = Net::Nostr::RemoteSigning->parse_response($json);
    ok !$resp->is_auth_challenge, 'not auth challenge';
    ok !$resp->is_error, 'not error';
    is $resp->result, 'pong', 'result';
};

# --- POD SYNOPSIS: parse_permissions ---

subtest 'POD SYNOPSIS: parse_permissions' => sub {
    my @perms = Net::Nostr::RemoteSigning->parse_permissions(
        'nip44_encrypt,sign_event:4'
    );
    is scalar @perms, 2, 'two permissions';
};

# --- POD: create_bunker_uri ---

subtest 'POD create_bunker_uri' => sub {
    my $uri = Net::Nostr::RemoteSigning->create_bunker_uri(
        remote_signer_pubkey => $remote_signer_pubkey,
        relay                => 'wss://relay.example.com',
        secret               => 'mysecret',
    );
    like $uri, qr/^bunker:\/\//, 'protocol prefix';
};

# --- POD: create_nostrconnect_uri ---

subtest 'POD create_nostrconnect_uri' => sub {
    my $uri = Net::Nostr::RemoteSigning->create_nostrconnect_uri(
        client_pubkey => $client_pubkey,
        relay         => 'wss://relay.example.com',
        secret        => '0s8j2djs',
        perms         => 'nip44_encrypt,sign_event:4',
        name          => 'My Client',
        url           => 'https://app.example.com',
        image         => 'https://app.example.com/i.png',
    );
    like $uri, qr/^nostrconnect:\/\//, 'protocol prefix';
};

# --- POD: response ---

subtest 'POD response' => sub {
    my $json = Net::Nostr::RemoteSigning->response(
        id     => 'req-1',
        result => 'pong',
    );
    my $data = JSON->new->utf8->decode($json);
    is $data->{result}, 'pong', 'result';
};

# --- POD: response_event ---

subtest 'POD response_event' => sub {
    my $event = Net::Nostr::RemoteSigning->response_event(
        id            => 'req-1',
        result        => 'pong',
        pubkey        => $remote_signer_pubkey,
        client_pubkey => $client_pubkey,
    );
    is $event->kind, 24133, 'kind 24133';
};

# --- POD: parse_request ---

subtest 'POD parse_request' => sub {
    my $json = JSON->new->utf8->encode({ id => 'r1', method => 'ping', params => [] });
    my $req = Net::Nostr::RemoteSigning->parse_request($json);
    is $req->method, 'ping', 'method';
};

# --- POD: validate_request ---

subtest 'POD validate_request' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 24133, pubkey => $client_pubkey,
        created_at => 1000, content => '{}',
        tags => [['p', $remote_signer_pubkey]],
        sig => '2' x 128,
    );
    my $ok = eval { Net::Nostr::RemoteSigning->validate_request($event) };
    ok $ok, 'valid';
};

# --- POD: validate_response ---

subtest 'POD validate_response' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 24133, pubkey => $remote_signer_pubkey,
        created_at => 1000, content => '{}',
        tags => [['p', $client_pubkey]],
        sig => '2' x 128,
    );
    my $ok = eval { Net::Nostr::RemoteSigning->validate_response($event) };
    ok $ok, 'valid';
};

# --- POD: validate_connect_response ---

subtest 'POD validate_connect_response' => sub {
    my $json = JSON->new->utf8->encode({ id => 'c1', result => 'mysecret' });
    my $resp = Net::Nostr::RemoteSigning->parse_response($json);
    my $ok = Net::Nostr::RemoteSigning->validate_connect_response($resp, 'mysecret');
    ok $ok, 'valid';
};

# --- POD: parse_switch_relays ---

subtest 'POD parse_switch_relays' => sub {
    my $relays_json = JSON->new->utf8->encode(['wss://relay.example.com']);
    my $relays = Net::Nostr::RemoteSigning->parse_switch_relays($relays_json);
    is $relays, ['wss://relay.example.com'], 'parsed relays';
};

# --- POD: parse_nip05_metadata ---

subtest 'POD parse_nip05_metadata' => sub {
    my $json = JSON->new->utf8->encode({
        names => { '_' => $remote_signer_pubkey },
        nip46 => { relays => ['wss://relay.example.com'] },
    });
    my $meta = Net::Nostr::RemoteSigning->parse_nip05_metadata($json);
    is $meta->pubkey, $remote_signer_pubkey, 'pubkey';
};

# --- POD: parse_discovery_event ---

subtest 'POD parse_discovery_event' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 31990, pubkey => $remote_signer_pubkey,
        created_at => 1000, content => '',
        tags => [['k', '24133'], ['relay', 'wss://relay.example.com']],
        sig => '2' x 128,
    );
    my $disc = Net::Nostr::RemoteSigning->parse_discovery_event($event);
    is $disc->pubkey, $remote_signer_pubkey, 'pubkey';
};

# --- POD: discovery_event ---

subtest 'POD discovery_event' => sub {
    my $event = Net::Nostr::RemoteSigning->discovery_event(
        pubkey           => $remote_signer_pubkey,
        relays           => ['wss://relay.example.com'],
        nostrconnect_url => 'https://signer.example.com/<nostrconnect>',
    );
    is $event->kind, 31990, 'kind 31990';
};

subtest 'RemoteSigning inner classes reject unknown arguments' => sub {
    ok !eval { Net::Nostr::RemoteSigning::BunkerConnection->new(bogus => 'value') },
        'BunkerConnection rejects unknown args';
    like $@, qr/unknown.+bogus/i, 'BunkerConnection error mentions bogus';

    ok !eval { Net::Nostr::RemoteSigning::NostrConnect->new(bogus => 'value') },
        'NostrConnect rejects unknown args';
    like $@, qr/unknown.+bogus/i, 'NostrConnect error mentions bogus';

    ok !eval { Net::Nostr::RemoteSigning::Nip05Metadata->new(bogus => 'value') },
        'Nip05Metadata rejects unknown args';
    like $@, qr/unknown.+bogus/i, 'Nip05Metadata error mentions bogus';

    ok !eval { Net::Nostr::RemoteSigning::Discovery->new(bogus => 'value') },
        'Discovery rejects unknown args';
    like $@, qr/unknown.+bogus/i, 'Discovery error mentions bogus';

    ok !eval { Net::Nostr::RemoteSigning::Request->new(bogus => 'value') },
        'Request rejects unknown args';
    like $@, qr/unknown.+bogus/i, 'Request error mentions bogus';

    ok !eval { Net::Nostr::RemoteSigning::Response->new(bogus => 'value') },
        'Response rejects unknown args';
    like $@, qr/unknown.+bogus/i, 'Response error mentions bogus';
};

###############################################################################
# parse_request validation
###############################################################################

subtest 'parse_request rejects missing id' => sub {
    my $json = JSON->new->utf8->encode({ method => 'ping', params => [] });
    ok !eval { Net::Nostr::RemoteSigning->parse_request($json) }, 'croaks';
    like $@, qr/id is required/, 'error mentions id';
};

subtest 'parse_request rejects missing method' => sub {
    my $json = JSON->new->utf8->encode({ id => 'r1', params => [] });
    ok !eval { Net::Nostr::RemoteSigning->parse_request($json) }, 'croaks';
    like $@, qr/method is required/, 'error mentions method';
};

subtest 'parse_request rejects missing params' => sub {
    my $json = JSON->new->utf8->encode({ id => 'r1', method => 'ping' });
    ok !eval { Net::Nostr::RemoteSigning->parse_request($json) }, 'croaks';
    like $@, qr/params is required/, 'error mentions params';
};

subtest 'parse_request rejects non-arrayref params' => sub {
    my $json = JSON->new->utf8->encode({ id => 'r1', method => 'ping', params => 'bad' });
    ok !eval { Net::Nostr::RemoteSigning->parse_request($json) }, 'croaks';
    like $@, qr/params must be an arrayref/, 'error mentions arrayref';
};

###############################################################################
# parse_response validation
###############################################################################

subtest 'parse_response rejects missing id' => sub {
    my $json = JSON->new->utf8->encode({ result => 'pong' });
    ok !eval { Net::Nostr::RemoteSigning->parse_response($json) }, 'croaks';
    like $@, qr/id is required/, 'error mentions id';
};

###############################################################################
# Request constructor validation
###############################################################################

subtest 'Request constructor rejects missing id' => sub {
    ok !eval { Net::Nostr::RemoteSigning::Request->new(method => 'ping', params => []) },
        'croaks';
    like $@, qr/id is required/, 'error mentions id';
};

subtest 'Request constructor rejects missing method' => sub {
    ok !eval { Net::Nostr::RemoteSigning::Request->new(id => 'r1', params => []) },
        'croaks';
    like $@, qr/method is required/, 'error mentions method';
};

subtest 'Request constructor rejects missing params' => sub {
    ok !eval { Net::Nostr::RemoteSigning::Request->new(id => 'r1', method => 'ping') },
        'croaks';
    like $@, qr/params is required/, 'error mentions params';
};

subtest 'Request constructor rejects non-arrayref params' => sub {
    ok !eval { Net::Nostr::RemoteSigning::Request->new(id => 'r1', method => 'ping', params => 'bad') },
        'croaks';
    like $@, qr/params must be an arrayref/, 'error mentions arrayref';
};

###############################################################################
# Response constructor validation
###############################################################################

subtest 'Response constructor rejects missing id' => sub {
    ok !eval { Net::Nostr::RemoteSigning::Response->new(result => 'pong') },
        'croaks';
    like $@, qr/id is required/, 'error mentions id';
};

###############################################################################
# Builder pubkey validation
###############################################################################

subtest 'request_event requires pubkey' => sub {
    ok !eval { Net::Nostr::RemoteSigning->request_event(
        method => 'ping', params => [],
        remote_signer_pubkey => $remote_signer_pubkey,
    ) }, 'croaks without pubkey';
    like $@, qr/requires 'pubkey'/, 'error mentions pubkey';
};

subtest 'response_event requires pubkey' => sub {
    ok !eval { Net::Nostr::RemoteSigning->response_event(
        id => 'r1', result => 'pong',
    ) }, 'croaks without pubkey';
    like $@, qr/requires 'pubkey'/, 'error mentions pubkey';
};

subtest 'discovery_event requires pubkey' => sub {
    ok !eval { Net::Nostr::RemoteSigning->discovery_event(
        relays => ['wss://relay.example.com'],
    ) }, 'croaks without pubkey';
    like $@, qr/requires 'pubkey'/, 'error mentions pubkey';
};

subtest 'request_event rejects bad pubkey' => sub {
    ok !eval { Net::Nostr::RemoteSigning->request_event(
        method => 'ping', params => [],
        remote_signer_pubkey => $remote_signer_pubkey,
        pubkey => 'bad',
    ) }, 'croaks on bad pubkey';
    like $@, qr/pubkey must be 64-char/, 'error mentions format';
};

###############################################################################
# Defensive copying: caller/accessor mutation must not affect internal state
###############################################################################

subtest 'RS BunkerConnection: accessor mutation of relays does not affect object' => sub {
    my $conn = Net::Nostr::RemoteSigning::BunkerConnection->new(
        remote_signer_pubkey => 'a' x 64,
        relays => ['wss://relay1.example.com'],
    );
    push @{$conn->relays}, 'wss://relay2.example.com';
    is scalar @{$conn->relays}, 1, 'relays unaffected';
};

subtest 'RS NostrConnect: accessor mutation of relays does not affect object' => sub {
    my $nc = Net::Nostr::RemoteSigning::NostrConnect->new(
        client_pubkey => 'a' x 64,
        relays => ['wss://relay1.example.com'],
        secret => 'mysecret',
    );
    push @{$nc->relays}, 'wss://relay2.example.com';
    is scalar @{$nc->relays}, 1, 'relays unaffected';
};

subtest 'RS Nip05Metadata: accessor mutation of relays does not affect object' => sub {
    my $meta = Net::Nostr::RemoteSigning::Nip05Metadata->new(
        pubkey => 'a' x 64,
        relays => ['wss://relay1.example.com'],
    );
    push @{$meta->relays}, 'wss://relay2.example.com';
    is scalar @{$meta->relays}, 1, 'relays unaffected';
};

subtest 'RS Discovery: accessor mutation of relays does not affect object' => sub {
    my $disc = Net::Nostr::RemoteSigning::Discovery->new(
        pubkey => 'a' x 64,
        relays => ['wss://relay1.example.com'],
    );
    push @{$disc->relays}, 'wss://relay2.example.com';
    is scalar @{$disc->relays}, 1, 'relays unaffected';
};

subtest 'RS Request: accessor mutation of params does not affect object' => sub {
    my $req = Net::Nostr::RemoteSigning::Request->new(
        id => 'r1', method => 'ping', params => ['arg1'],
    );
    push @{$req->params}, 'arg2';
    is scalar @{$req->params}, 1, 'params unaffected';
};

done_testing;
