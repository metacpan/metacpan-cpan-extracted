use strictures 2;
use Test2::V0 -no_srand => 1;
use lib 't/lib';
use TestFixtures qw(make_event);
use JSON ();

use Net::Nostr::RemoteSigning;

my $remote_signer_pubkey = 'fa984bd7dbb282f07e16e7ae87b26a2a7b9b90b7246a44771f0cf5ae58018f52';
my $client_pubkey        = 'eff37350d839ce3707332348af4549a96051bd695d3223af4aabce4993531d86';
my $relay1               = 'wss://relay1.example.com';
my $relay2               = 'wss://relay2.example2.com';

# ==========================================================================
# Bunker URI (remote-signer initiated connection)
# ==========================================================================

# Spec: "bunker://<remote-signer-pubkey>?relay=<wss://relay-to-connect-on>
# &relay=<wss://another-relay-to-connect-on>&secret=<optional-secret-value>"

subtest 'parse_bunker_uri: basic' => sub {
    my $uri = "bunker://${remote_signer_pubkey}?relay=wss%3A%2F%2Frelay1.example.com&secret=mysecret";
    my $conn = Net::Nostr::RemoteSigning->parse_bunker_uri($uri);
    is $conn->remote_signer_pubkey, $remote_signer_pubkey, 'remote_signer_pubkey';
    is $conn->relays, [$relay1], 'relay';
    is $conn->secret, 'mysecret', 'secret';
};

subtest 'parse_bunker_uri: multiple relays' => sub {
    my $uri = "bunker://${remote_signer_pubkey}?relay=wss%3A%2F%2Frelay1.example.com&relay=wss%3A%2F%2Frelay2.example2.com&secret=s";
    my $conn = Net::Nostr::RemoteSigning->parse_bunker_uri($uri);
    is $conn->relays, [$relay1, $relay2], 'multiple relays';
};

subtest 'parse_bunker_uri: optional secret' => sub {
    my $uri = "bunker://${remote_signer_pubkey}?relay=wss%3A%2F%2Frelay1.example.com";
    my $conn = Net::Nostr::RemoteSigning->parse_bunker_uri($uri);
    ok !defined $conn->secret, 'secret is optional';
};

subtest 'parse_bunker_uri: croaks on invalid protocol' => sub {
    eval { Net::Nostr::RemoteSigning->parse_bunker_uri("http://example.com") };
    like $@, qr/bunker:\/\//, 'croaks';
};

subtest 'parse_bunker_uri: croaks without relay' => sub {
    eval { Net::Nostr::RemoteSigning->parse_bunker_uri("bunker://${remote_signer_pubkey}?secret=s") };
    like $@, qr/relay/, 'croaks';
};

subtest 'create_bunker_uri: round-trip' => sub {
    my $uri = Net::Nostr::RemoteSigning->create_bunker_uri(
        remote_signer_pubkey => $remote_signer_pubkey,
        relay                => $relay1,
        secret               => 'mysecret',
    );
    like $uri, qr/^bunker:\/\//, 'protocol prefix';
    my $conn = Net::Nostr::RemoteSigning->parse_bunker_uri($uri);
    is $conn->remote_signer_pubkey, $remote_signer_pubkey, 'round-trip pubkey';
    is $conn->relays, [$relay1], 'round-trip relay';
    is $conn->secret, 'mysecret', 'round-trip secret';
};

subtest 'create_bunker_uri: without secret' => sub {
    my $uri = Net::Nostr::RemoteSigning->create_bunker_uri(
        remote_signer_pubkey => $remote_signer_pubkey,
        relay                => $relay1,
    );
    my $conn = Net::Nostr::RemoteSigning->parse_bunker_uri($uri);
    ok !defined $conn->secret, 'no secret';
};

# ==========================================================================
# Nostrconnect URI (client initiated connection)
# ==========================================================================

# Spec example: "nostrconnect://83f3b2ae...?relay=wss%3A%2F%2Frelay1.example.com
# &perms=nip44_encrypt%2Cnip44_decrypt%2Csign_event%3A13%2Csign_event%3A14
# %2Csign_event%3A1059&name=My+Client&secret=0s8j2djs
# &relay=wss%3A%2F%2Frelay2.example2.com"

subtest 'parse_nostrconnect_uri: spec example' => sub {
    my $uri = "nostrconnect://${client_pubkey}?relay=wss%3A%2F%2Frelay1.example.com&perms=nip44_encrypt%2Cnip44_decrypt%2Csign_event%3A13&name=My+Client&secret=0s8j2djs&relay=wss%3A%2F%2Frelay2.example2.com";
    my $conn = Net::Nostr::RemoteSigning->parse_nostrconnect_uri($uri);
    is $conn->client_pubkey, $client_pubkey, 'client_pubkey';
    is $conn->relays, [$relay1, $relay2], 'relays';
    is $conn->secret, '0s8j2djs', 'secret';
    is $conn->perms, 'nip44_encrypt,nip44_decrypt,sign_event:13', 'perms';
    is $conn->name, 'My Client', 'name';
};

# Spec: "relay (required)", "secret (required)"

subtest 'parse_nostrconnect_uri: croaks without relay' => sub {
    eval { Net::Nostr::RemoteSigning->parse_nostrconnect_uri("nostrconnect://${client_pubkey}?secret=s") };
    like $@, qr/relay/, 'croaks';
};

subtest 'parse_nostrconnect_uri: croaks without secret' => sub {
    eval { Net::Nostr::RemoteSigning->parse_nostrconnect_uri("nostrconnect://${client_pubkey}?relay=wss%3A%2F%2Frelay1.example.com") };
    like $@, qr/secret/, 'croaks';
};

subtest 'parse_nostrconnect_uri: croaks on invalid protocol' => sub {
    eval { Net::Nostr::RemoteSigning->parse_nostrconnect_uri("http://example.com") };
    like $@, qr/nostrconnect:\/\//, 'croaks';
};

# Spec: "url (optional) - the canonical url", "image (optional)"

subtest 'parse_nostrconnect_uri: optional fields' => sub {
    my $uri = "nostrconnect://${client_pubkey}?relay=wss%3A%2F%2Frelay1.example.com&secret=s&url=https%3A%2F%2Fapp.example.com&image=https%3A%2F%2Fapp.example.com%2Ficon.png";
    my $conn = Net::Nostr::RemoteSigning->parse_nostrconnect_uri($uri);
    is $conn->url, 'https://app.example.com', 'url';
    is $conn->image, 'https://app.example.com/icon.png', 'image';
};

subtest 'create_nostrconnect_uri: round-trip' => sub {
    my $uri = Net::Nostr::RemoteSigning->create_nostrconnect_uri(
        client_pubkey => $client_pubkey,
        relay         => [$relay1, $relay2],
        secret        => '0s8j2djs',
        perms         => 'nip44_encrypt,sign_event:13',
        name          => 'My Client',
        url           => 'https://app.example.com',
        image         => 'https://app.example.com/icon.png',
    );
    like $uri, qr/^nostrconnect:\/\//, 'protocol prefix';
    my $conn = Net::Nostr::RemoteSigning->parse_nostrconnect_uri($uri);
    is $conn->client_pubkey, $client_pubkey, 'round-trip pubkey';
    is $conn->relays, [$relay1, $relay2], 'round-trip relays';
    is $conn->secret, '0s8j2djs', 'round-trip secret';
    is $conn->perms, 'nip44_encrypt,sign_event:13', 'round-trip perms';
    is $conn->name, 'My Client', 'round-trip name';
};

# ==========================================================================
# Request payload
# ==========================================================================

# Spec: request content is JSON with "id" (random string), "method" (string),
# "params" (array of strings)

subtest 'request: builds JSON payload' => sub {
    my $payload = Net::Nostr::RemoteSigning->request(
        id     => 'req-1',
        method => 'sign_event',
        params => ['{"kind":1,"content":"hello","tags":[],"created_at":1714078911}'],
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{id}, 'req-1', 'id';
    is $data->{method}, 'sign_event', 'method';
    is ref $data->{params}, 'ARRAY', 'params is array';
    is $data->{params}[0], '{"kind":1,"content":"hello","tags":[],"created_at":1714078911}', 'params[0]';
};

subtest 'request: auto-generates id if not provided' => sub {
    my $payload = Net::Nostr::RemoteSigning->request(
        method => 'ping',
        params => [],
    );
    my $data = JSON->new->utf8->decode($payload);
    ok defined $data->{id}, 'id auto-generated';
    ok length($data->{id}) > 0, 'id non-empty';
};

subtest 'request: croaks without method' => sub {
    eval { Net::Nostr::RemoteSigning->request(params => []) };
    like $@, qr/method/, 'croaks';
};

subtest 'request: croaks without params' => sub {
    eval { Net::Nostr::RemoteSigning->request(method => 'ping') };
    like $@, qr/params/, 'croaks';
};

# ==========================================================================
# Request payloads for each command
# ==========================================================================

# Spec: connect - [<remote-signer-pubkey>, <optional_secret>, <optional_requested_perms>]

subtest 'request: connect with secret and perms' => sub {
    my $payload = Net::Nostr::RemoteSigning->request(
        id     => 'c1',
        method => 'connect',
        params => [$remote_signer_pubkey, 'mysecret', 'nip44_encrypt,sign_event:4'],
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'connect', 'method';
    is $data->{params}[0], $remote_signer_pubkey, 'remote-signer-pubkey';
    is $data->{params}[1], 'mysecret', 'secret';
    is $data->{params}[2], 'nip44_encrypt,sign_event:4', 'perms';
};

# Spec: sign_event - [<{kind, content, tags, created_at}>]

subtest 'request: sign_event with spec example' => sub {
    my $event_json = JSON->new->utf8->canonical->encode({
        content    => "Hello, I'm signing remotely",
        kind       => 1,
        tags       => [],
        created_at => 1714078911,
    });
    my $payload = Net::Nostr::RemoteSigning->request(
        id     => 's1',
        method => 'sign_event',
        params => [$event_json],
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'sign_event', 'method';
    my $inner = JSON->new->utf8->decode($data->{params}[0]);
    is $inner->{kind}, 1, 'event kind';
    is $inner->{content}, "Hello, I'm signing remotely", 'event content';
};

# Spec: ping - []

subtest 'request: ping' => sub {
    my $payload = Net::Nostr::RemoteSigning->request(
        id     => 'p1',
        method => 'ping',
        params => [],
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'ping', 'method';
    is $data->{params}, [], 'empty params';
};

# Spec: get_public_key - []

subtest 'request: get_public_key' => sub {
    my $payload = Net::Nostr::RemoteSigning->request(
        id     => 'g1',
        method => 'get_public_key',
        params => [],
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'get_public_key', 'method';
};

# Spec: nip04_encrypt - [<third_party_pubkey>, <plaintext_to_encrypt>]

subtest 'request: nip04_encrypt' => sub {
    my $payload = Net::Nostr::RemoteSigning->request(
        id     => 'e1',
        method => 'nip04_encrypt',
        params => [$remote_signer_pubkey, 'hello world'],
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'nip04_encrypt', 'method';
    is $data->{params}[0], $remote_signer_pubkey, 'third_party_pubkey';
    is $data->{params}[1], 'hello world', 'plaintext';
};

# Spec: nip04_decrypt - [<third_party_pubkey>, <nip04_ciphertext_to_decrypt>]

subtest 'request: nip04_decrypt' => sub {
    my $payload = Net::Nostr::RemoteSigning->request(
        id     => 'd1',
        method => 'nip04_decrypt',
        params => [$remote_signer_pubkey, 'encrypted_text'],
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'nip04_decrypt', 'method';
    is $data->{params}[1], 'encrypted_text', 'ciphertext';
};

# Spec: nip44_encrypt - [<third_party_pubkey>, <plaintext_to_encrypt>]

subtest 'request: nip44_encrypt' => sub {
    my $payload = Net::Nostr::RemoteSigning->request(
        id     => 'ne1',
        method => 'nip44_encrypt',
        params => [$remote_signer_pubkey, 'hello nip44'],
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'nip44_encrypt', 'method';
};

# Spec: nip44_decrypt - [<third_party_pubkey>, <nip44_ciphertext_to_decrypt>]

subtest 'request: nip44_decrypt' => sub {
    my $payload = Net::Nostr::RemoteSigning->request(
        id     => 'nd1',
        method => 'nip44_decrypt',
        params => [$remote_signer_pubkey, 'nip44_ciphertext'],
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'nip44_decrypt', 'method';
};

# Spec: switch_relays - []

subtest 'request: switch_relays' => sub {
    my $payload = Net::Nostr::RemoteSigning->request(
        id     => 'sr1',
        method => 'switch_relays',
        params => [],
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{method}, 'switch_relays', 'method';
    is $data->{params}, [], 'empty params';
};

# ==========================================================================
# Request Event (kind 24133)
# ==========================================================================

# Spec: kind 24133, p-tags remote-signer-pubkey

subtest 'request_event: creates kind 24133 with p tag' => sub {
    my $event = Net::Nostr::RemoteSigning->request_event(
        id                   => 'req-1',
        method               => 'sign_event',
        params               => ['{}'],
        pubkey               => $client_pubkey,
        remote_signer_pubkey => $remote_signer_pubkey,
    );
    is $event->kind, 24133, 'kind 24133';

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is scalar @p, 1, 'one p tag';
    is $p[0][1], $remote_signer_pubkey, 'p tag is remote-signer-pubkey';
};

# Spec: content is JSON-RPC-like message

subtest 'request_event: content is valid JSON request' => sub {
    my $event = Net::Nostr::RemoteSigning->request_event(
        id                   => 'req-2',
        method               => 'ping',
        params               => [],
        pubkey               => $client_pubkey,
        remote_signer_pubkey => $remote_signer_pubkey,
    );
    my $data = JSON->new->utf8->decode($event->content);
    is $data->{id}, 'req-2', 'id in content';
    is $data->{method}, 'ping', 'method in content';
    is $data->{params}, [], 'params in content';
};

# ==========================================================================
# Response payload
# ==========================================================================

# Spec: response has id, result, and optional error

subtest 'response: builds JSON payload' => sub {
    my $payload = Net::Nostr::RemoteSigning->response(
        id     => 'req-1',
        result => 'pong',
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{id}, 'req-1', 'id';
    is $data->{result}, 'pong', 'result';
    ok !exists $data->{error}, 'no error field when not provided';
};

subtest 'response: with error' => sub {
    my $payload = Net::Nostr::RemoteSigning->response(
        id    => 'req-1',
        error => 'Permission denied',
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{id}, 'req-1', 'id';
    is $data->{error}, 'Permission denied', 'error';
};

subtest 'response: croaks without id' => sub {
    eval { Net::Nostr::RemoteSigning->response(result => 'ok') };
    like $@, qr/id/, 'croaks';
};

# ==========================================================================
# Response payloads for each command result
# ==========================================================================

# Spec: connect result is "ack" OR <required-secret-value>

subtest 'response: connect ack' => sub {
    my $payload = Net::Nostr::RemoteSigning->response(
        id     => 'c1',
        result => 'ack',
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{result}, 'ack', 'ack result';
};

subtest 'response: connect with secret' => sub {
    my $payload = Net::Nostr::RemoteSigning->response(
        id     => 'c1',
        result => '0s8j2djs',
    );
    my $data = JSON->new->utf8->decode($payload);
    is $data->{result}, '0s8j2djs', 'secret result';
};

# Spec: sign_event result is json_stringified(<signed_event>)

subtest 'response: sign_event result' => sub {
    my $signed = JSON->new->utf8->canonical->encode({
        id         => '1' x 64,
        pubkey     => $remote_signer_pubkey,
        kind       => 1,
        content    => "Hello, I'm signing remotely",
        tags       => [],
        created_at => 1714078911,
        sig        => '2' x 128,
    });
    my $payload = Net::Nostr::RemoteSigning->response(
        id     => 's1',
        result => $signed,
    );
    my $data = JSON->new->utf8->decode($payload);
    my $event = JSON->new->utf8->decode($data->{result});
    is $event->{kind}, 1, 'signed event kind';
    is $event->{pubkey}, $remote_signer_pubkey, 'signed event pubkey';
};

# Spec: ping result is "pong"

subtest 'response: ping pong' => sub {
    my $payload = Net::Nostr::RemoteSigning->response(id => 'p1', result => 'pong');
    my $data = JSON->new->utf8->decode($payload);
    is $data->{result}, 'pong', 'pong';
};

# Spec: get_public_key result is <user-pubkey>

subtest 'response: get_public_key' => sub {
    my $payload = Net::Nostr::RemoteSigning->response(id => 'g1', result => $remote_signer_pubkey);
    my $data = JSON->new->utf8->decode($payload);
    is $data->{result}, $remote_signer_pubkey, 'user-pubkey';
};

# Spec: switch_relays result is ["relay-url", ...] OR null

subtest 'response: switch_relays with relays' => sub {
    my $relays_json = JSON->new->utf8->encode([$relay1, $relay2]);
    my $payload = Net::Nostr::RemoteSigning->response(id => 'sr1', result => $relays_json);
    my $data = JSON->new->utf8->decode($payload);
    my $relays = JSON->new->utf8->decode($data->{result});
    is $relays, [$relay1, $relay2], 'relay list';
};

subtest 'response: switch_relays null' => sub {
    my $payload = Net::Nostr::RemoteSigning->response(id => 'sr1', result => undef);
    my $data = JSON->new->utf8->decode($payload);
    ok !defined $data->{result}, 'null result';
};

# ==========================================================================
# Response Event (kind 24133)
# ==========================================================================

# Spec: response is also kind 24133, p-tags client-pubkey

subtest 'response_event: creates kind 24133 with p tag' => sub {
    my $event = Net::Nostr::RemoteSigning->response_event(
        id            => 'req-1',
        result        => 'pong',
        pubkey        => $remote_signer_pubkey,
        client_pubkey => $client_pubkey,
    );
    is $event->kind, 24133, 'kind 24133';

    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is scalar @p, 1, 'one p tag';
    is $p[0][1], $client_pubkey, 'p tag is client-pubkey';
};

subtest 'response_event: content is valid JSON response' => sub {
    my $event = Net::Nostr::RemoteSigning->response_event(
        id            => 'req-2',
        result        => 'pong',
        pubkey        => $remote_signer_pubkey,
        client_pubkey => $client_pubkey,
    );
    my $data = JSON->new->utf8->decode($event->content);
    is $data->{id}, 'req-2', 'id in content';
    is $data->{result}, 'pong', 'result in content';
};

subtest 'response_event: error response' => sub {
    my $event = Net::Nostr::RemoteSigning->response_event(
        id            => 'req-3',
        error         => 'Not allowed',
        pubkey        => $remote_signer_pubkey,
        client_pubkey => $client_pubkey,
    );
    my $data = JSON->new->utf8->decode($event->content);
    is $data->{error}, 'Not allowed', 'error in content';
};

# ==========================================================================
# Parse request/response
# ==========================================================================

subtest 'parse_request: parses JSON payload' => sub {
    my $json = JSON->new->utf8->encode({
        id     => 'req-1',
        method => 'sign_event',
        params => ['{}'],
    });
    my $req = Net::Nostr::RemoteSigning->parse_request($json);
    is $req->id, 'req-1', 'id';
    is $req->method, 'sign_event', 'method';
    is $req->params, ['{}'], 'params';
};

subtest 'parse_response: parses success response' => sub {
    my $json = JSON->new->utf8->encode({
        id     => 'req-1',
        result => 'pong',
    });
    my $resp = Net::Nostr::RemoteSigning->parse_response($json);
    is $resp->id, 'req-1', 'id';
    is $resp->result, 'pong', 'result';
    ok !$resp->is_error, 'not an error';
};

subtest 'parse_response: parses error response' => sub {
    my $json = JSON->new->utf8->encode({
        id    => 'req-1',
        error => 'Forbidden',
    });
    my $resp = Net::Nostr::RemoteSigning->parse_response($json);
    ok $resp->is_error, 'is error';
    is $resp->error, 'Forbidden', 'error message';
};

# ==========================================================================
# Auth Challenges
# ==========================================================================

# Spec: auth challenge has result "auth_url" and error is URL to display

subtest 'parse_response: auth challenge' => sub {
    my $json = JSON->new->utf8->encode({
        id     => 'req-1',
        result => 'auth_url',
        error  => 'https://example.com/auth?token=abc123',
    });
    my $resp = Net::Nostr::RemoteSigning->parse_response($json);
    ok $resp->is_auth_challenge, 'is auth challenge';
    is $resp->auth_url, 'https://example.com/auth?token=abc123', 'auth URL';
};

subtest 'parse_response: not auth challenge when result is not auth_url' => sub {
    my $json = JSON->new->utf8->encode({
        id     => 'req-1',
        result => 'pong',
    });
    my $resp = Net::Nostr::RemoteSigning->parse_response($json);
    ok !$resp->is_auth_challenge, 'not auth challenge';
};

# ==========================================================================
# Spec example flow
# ==========================================================================

# Spec example: remote-signer-pubkey and user-pubkey are same, client-pubkey
# is different

subtest 'spec example: signing flow request event' => sub {
    my $event_json = JSON->new->utf8->canonical->encode({
        content    => "Hello, I'm signing remotely",
        kind       => 1,
        tags       => [],
        created_at => 1714078911,
    });
    my $event = Net::Nostr::RemoteSigning->request_event(
        id                   => 'spec-example',
        method               => 'sign_event',
        params               => [$event_json],
        pubkey               => $client_pubkey,
        remote_signer_pubkey => $remote_signer_pubkey,
    );
    is $event->kind, 24133, 'kind';
    is $event->pubkey, $client_pubkey, 'pubkey is client-pubkey';
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is $p[0][1], $remote_signer_pubkey, 'p-tags remote-signer-pubkey';

    my $data = JSON->new->utf8->decode($event->content);
    is $data->{method}, 'sign_event', 'method';
    my $inner = JSON->new->utf8->decode($data->{params}[0]);
    is $inner->{content}, "Hello, I'm signing remotely", 'event content';
    is $inner->{kind}, 1, 'event kind';
    is $inner->{created_at}, 1714078911, 'event created_at';
};

subtest 'spec example: signing flow response event' => sub {
    my $signed = JSON->new->utf8->canonical->encode({
        id         => '1' x 64,
        pubkey     => $remote_signer_pubkey,
        kind       => 1,
        content    => "Hello, I'm signing remotely",
        tags       => [],
        created_at => 1714078911,
        sig        => '2' x 128,
    });
    my $event = Net::Nostr::RemoteSigning->response_event(
        id            => 'spec-example',
        result        => $signed,
        pubkey        => $remote_signer_pubkey,
        client_pubkey => $client_pubkey,
    );
    is $event->kind, 24133, 'kind';
    is $event->pubkey, $remote_signer_pubkey, 'pubkey is remote-signer-pubkey';
    my @p = grep { $_->[0] eq 'p' } @{$event->tags};
    is $p[0][1], $client_pubkey, 'p-tags client-pubkey';
};

# ==========================================================================
# Permissions parsing
# ==========================================================================

# Spec: "permissions are a comma-separated list of method[:params]"

subtest 'parse_permissions: basic' => sub {
    my @perms = Net::Nostr::RemoteSigning->parse_permissions('nip44_encrypt,sign_event:4');
    is scalar @perms, 2, 'two permissions';
    is $perms[0]{method}, 'nip44_encrypt', 'first method';
    ok !defined $perms[0]{param}, 'no param for first';
    is $perms[1]{method}, 'sign_event', 'second method';
    is $perms[1]{param}, '4', 'second param is kind 4';
};

subtest 'parse_permissions: multiple sign_event kinds' => sub {
    my @perms = Net::Nostr::RemoteSigning->parse_permissions('sign_event:13,sign_event:14,sign_event:1059');
    is scalar @perms, 3, 'three permissions';
    is $perms[0]{param}, '13', 'kind 13';
    is $perms[1]{param}, '14', 'kind 14';
    is $perms[2]{param}, '1059', 'kind 1059';
};

subtest 'parse_permissions: empty string' => sub {
    my @perms = Net::Nostr::RemoteSigning->parse_permissions('');
    is scalar @perms, 0, 'no permissions';
};

# ==========================================================================
# Validate events
# ==========================================================================

subtest 'validate_request: valid event' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 24133, pubkey => $client_pubkey,
        created_at => 1000, content => '{}',
        tags => [['p', $remote_signer_pubkey]],
        sig => '2' x 128,
    );
    my $ok = eval { Net::Nostr::RemoteSigning->validate_request($event) };
    ok $ok, 'valid';
};

subtest 'validate_request: wrong kind' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 1, pubkey => $client_pubkey,
        created_at => 1000, content => '{}',
        tags => [['p', $remote_signer_pubkey]],
        sig => '2' x 128,
    );
    eval { Net::Nostr::RemoteSigning->validate_request($event) };
    like $@, qr/24133/, 'croaks on wrong kind';
};

subtest 'validate_request: missing p tag' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 24133, pubkey => $client_pubkey,
        created_at => 1000, content => '{}',
        tags => [],
        sig => '2' x 128,
    );
    eval { Net::Nostr::RemoteSigning->validate_request($event) };
    like $@, qr/p tag/, 'croaks without p tag';
};

subtest 'validate_response: valid event' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 24133, pubkey => $remote_signer_pubkey,
        created_at => 1000, content => '{}',
        tags => [['p', $client_pubkey]],
        sig => '2' x 128,
    );
    my $ok = eval { Net::Nostr::RemoteSigning->validate_response($event) };
    ok $ok, 'valid';
};

subtest 'validate_response: wrong kind' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 1, pubkey => $remote_signer_pubkey,
        created_at => 1000, content => '{}',
        tags => [['p', $client_pubkey]],
        sig => '2' x 128,
    );
    eval { Net::Nostr::RemoteSigning->validate_response($event) };
    like $@, qr/24133/, 'croaks on wrong kind';
};

# ==========================================================================
# NIP-89 remote signer discovery
# ==========================================================================

# Spec: "remote-signer MAY publish a NIP-89 kind: 31990 event with k tag
# of 24133, which MAY also include one or more relay tags"

subtest 'discovery_event: creates kind 31990 with k tag' => sub {
    my $event = Net::Nostr::RemoteSigning->discovery_event(
        pubkey => $remote_signer_pubkey,
        relays => [$relay1, $relay2],
        nostrconnect_url => 'https://signer.example.com/<nostrconnect>',
    );
    is $event->kind, 31990, 'kind 31990';

    my @k = grep { $_->[0] eq 'k' } @{$event->tags};
    is scalar @k, 1, 'one k tag';
    is $k[0][1], '24133', 'k tag value';

    my @relays = grep { $_->[0] eq 'relay' } @{$event->tags};
    is scalar @relays, 2, 'two relay tags';
    is $relays[0][1], $relay1, 'first relay';

    my @nc = grep { $_->[0] eq 'nostrconnect_url' } @{$event->tags};
    is $nc[0][1], 'https://signer.example.com/<nostrconnect>', 'nostrconnect_url';
};

subtest 'discovery_event: without optional fields' => sub {
    my $event = Net::Nostr::RemoteSigning->discovery_event(
        pubkey => $remote_signer_pubkey,
    );
    is $event->kind, 31990, 'kind 31990';

    my @k = grep { $_->[0] eq 'k' } @{$event->tags};
    is $k[0][1], '24133', 'k tag';

    my @relays = grep { $_->[0] eq 'relay' } @{$event->tags};
    is scalar @relays, 0, 'no relay tags';
};

# ==========================================================================
# Secret handling
# ==========================================================================

# Spec: "Optional secret can be used for single successfully established
# connection only, remote-signer SHOULD ignore new attempts to establish
# connection with old secret."

# Spec: "secret value MUST be provided to avoid connection spoofing,
# client MUST validate the secret returned by connect response"

subtest 'validate_connect_response: validates secret' => sub {
    my $json = JSON->new->utf8->encode({
        id     => 'c1',
        result => 'mysecret',
    });
    my $resp = Net::Nostr::RemoteSigning->parse_response($json);
    my $ok = Net::Nostr::RemoteSigning->validate_connect_response($resp, 'mysecret');
    ok $ok, 'valid secret';
};

subtest 'validate_connect_response: rejects wrong secret' => sub {
    my $json = JSON->new->utf8->encode({
        id     => 'c1',
        result => 'wrong',
    });
    my $resp = Net::Nostr::RemoteSigning->parse_response($json);
    eval { Net::Nostr::RemoteSigning->validate_connect_response($resp, 'mysecret') };
    like $@, qr/secret/, 'croaks on wrong secret';
};

subtest 'validate_connect_response: accepts ack for bunker-initiated' => sub {
    my $json = JSON->new->utf8->encode({
        id     => 'c1',
        result => 'ack',
    });
    my $resp = Net::Nostr::RemoteSigning->parse_response($json);
    my $ok = Net::Nostr::RemoteSigning->validate_connect_response($resp);
    ok $ok, 'ack accepted without expected secret';
};

# ==========================================================================
# Pubkey format validation
# ==========================================================================

# Spec: "All pubkeys specified in this NIP are in hex format."

subtest 'parse_bunker_uri: croaks on invalid hex pubkey' => sub {
    eval { Net::Nostr::RemoteSigning->parse_bunker_uri("bunker://ZZZZ?relay=wss%3A%2F%2Frelay.example.com") };
    like $@, qr/bunker:\/\//, 'croaks on non-hex pubkey';
};

subtest 'parse_bunker_uri: croaks on short pubkey' => sub {
    eval { Net::Nostr::RemoteSigning->parse_bunker_uri("bunker://abcd?relay=wss%3A%2F%2Frelay.example.com") };
    like $@, qr/bunker:\/\//, 'croaks on short pubkey';
};

subtest 'parse_nostrconnect_uri: croaks on invalid hex pubkey' => sub {
    eval { Net::Nostr::RemoteSigning->parse_nostrconnect_uri("nostrconnect://notahexpubkey?relay=wss%3A%2F%2Frelay.example.com&secret=s") };
    like $@, qr/nostrconnect:\/\//, 'croaks on non-hex pubkey';
};

# ==========================================================================
# switch_relays response parsing
# ==========================================================================

# Spec: switch_relays result is ["relay-url", ...] OR null

subtest 'parse_switch_relays: parses relay list' => sub {
    my $relays_json = JSON->new->utf8->encode([$relay1, $relay2]);
    my $relays = Net::Nostr::RemoteSigning->parse_switch_relays($relays_json);
    is $relays, [$relay1, $relay2], 'parsed relay list';
};

subtest 'parse_switch_relays: returns undef for null' => sub {
    my $relays = Net::Nostr::RemoteSigning->parse_switch_relays(undef);
    ok !defined $relays, 'undef for null';
};

subtest 'parse_switch_relays: returns undef for "null" string' => sub {
    my $relays = Net::Nostr::RemoteSigning->parse_switch_relays('null');
    ok !defined $relays, 'undef for "null"';
};

# ==========================================================================
# NIP-05 metadata parsing
# ==========================================================================

# Spec: "With NIP-05, a request to <remote-signer>/.well-known/nostr.json?name=_
# MAY return this: { names: { _: <pubkey> }, nip46: { relays: [...],
# nostrconnect_url: "..." } }"

subtest 'parse_nip05_metadata: full response' => sub {
    my $json = JSON->new->utf8->encode({
        names => { '_' => $remote_signer_pubkey },
        nip46 => {
            relays => [$relay1, $relay2],
            nostrconnect_url => 'https://signer.example.com/<nostrconnect>',
        },
    });
    my $meta = Net::Nostr::RemoteSigning->parse_nip05_metadata($json);
    is $meta->pubkey, $remote_signer_pubkey, 'pubkey from names._';
    is $meta->relays, [$relay1, $relay2], 'relays';
    is $meta->nostrconnect_url, 'https://signer.example.com/<nostrconnect>', 'nostrconnect_url';
};

subtest 'parse_nip05_metadata: without nip46 field' => sub {
    my $json = JSON->new->utf8->encode({
        names => { '_' => $remote_signer_pubkey },
    });
    my $meta = Net::Nostr::RemoteSigning->parse_nip05_metadata($json);
    is $meta->pubkey, $remote_signer_pubkey, 'pubkey';
    is $meta->relays, [], 'empty relays';
    ok !defined $meta->nostrconnect_url, 'no nostrconnect_url';
};

subtest 'parse_nip05_metadata: croaks without names._' => sub {
    my $json = JSON->new->utf8->encode({ names => { 'alice' => $remote_signer_pubkey } });
    eval { Net::Nostr::RemoteSigning->parse_nip05_metadata($json) };
    like $@, qr/names/, 'croaks';
};

# ==========================================================================
# NIP-89 discovery event parsing
# ==========================================================================

# Spec: "remote-signer MAY publish a NIP-89 kind: 31990 event with k tag
# of 24133"

subtest 'parse_discovery_event: parses kind 31990' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 31990, pubkey => $remote_signer_pubkey,
        created_at => 1000, content => '',
        tags => [
            ['k', '24133'],
            ['relay', $relay1],
            ['relay', $relay2],
            ['nostrconnect_url', 'https://signer.example.com/<nostrconnect>'],
        ],
        sig => '2' x 128,
    );
    my $disc = Net::Nostr::RemoteSigning->parse_discovery_event($event);
    is $disc->pubkey, $remote_signer_pubkey, 'pubkey';
    is $disc->relays, [$relay1, $relay2], 'relays';
    is $disc->nostrconnect_url, 'https://signer.example.com/<nostrconnect>', 'nostrconnect_url';
};

subtest 'parse_discovery_event: without optional tags' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 31990, pubkey => $remote_signer_pubkey,
        created_at => 1000, content => '',
        tags => [['k', '24133']],
        sig => '2' x 128,
    );
    my $disc = Net::Nostr::RemoteSigning->parse_discovery_event($event);
    is $disc->pubkey, $remote_signer_pubkey, 'pubkey';
    is $disc->relays, [], 'empty relays';
    ok !defined $disc->nostrconnect_url, 'no nostrconnect_url';
};

subtest 'parse_discovery_event: croaks on wrong kind' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 1, pubkey => $remote_signer_pubkey,
        created_at => 1000, content => '',
        tags => [['k', '24133']],
        sig => '2' x 128,
    );
    eval { Net::Nostr::RemoteSigning->parse_discovery_event($event) };
    like $@, qr/31990/, 'croaks on wrong kind';
};

subtest 'parse_discovery_event: croaks without k tag 24133' => sub {
    my $event = make_event(
        id => '1' x 64, kind => 31990, pubkey => $remote_signer_pubkey,
        created_at => 1000, content => '',
        tags => [['k', '1']],
        sig => '2' x 128,
    );
    eval { Net::Nostr::RemoteSigning->parse_discovery_event($event) };
    like $@, qr/24133/, 'croaks without k tag 24133';
};

# ==========================================================================
# Hex64 validation for pubkey parameters used in tags and URIs
# ==========================================================================

subtest 'hex64 validation rejects invalid pubkeys' => sub {
    # request_event remote_signer_pubkey
    eval {
        Net::Nostr::RemoteSigning->request_event(
            method => 'ping', params => [],
            pubkey => $client_pubkey,
            remote_signer_pubkey => 'INVALID',
        );
    };
    like $@, qr/remote_signer_pubkey must be 64-char lowercase hex/, 'request_event rejects bad remote_signer_pubkey';

    eval {
        Net::Nostr::RemoteSigning->request_event(
            method => 'ping', params => [],
            pubkey => $client_pubkey,
            remote_signer_pubkey => 'AB' x 32,
        );
    };
    like $@, qr/remote_signer_pubkey must be 64-char lowercase hex/, 'request_event rejects uppercase remote_signer_pubkey';

    # response_event client_pubkey
    eval {
        Net::Nostr::RemoteSigning->response_event(
            id => 'r1', result => 'ok',
            pubkey => $remote_signer_pubkey,
            client_pubkey => 'short',
        );
    };
    like $@, qr/client_pubkey must be 64-char lowercase hex/, 'response_event rejects bad client_pubkey';

    # create_bunker_uri
    eval {
        Net::Nostr::RemoteSigning->create_bunker_uri(
            remote_signer_pubkey => 'NOTHEX',
            relay => 'wss://relay.example.com',
        );
    };
    like $@, qr/remote_signer_pubkey must be 64-char lowercase hex/, 'create_bunker_uri rejects bad pubkey';

    # create_nostrconnect_uri
    eval {
        Net::Nostr::RemoteSigning->create_nostrconnect_uri(
            client_pubkey => 'ZZ' x 32,
            relay => 'wss://relay.example.com',
            secret => 's',
        );
    };
    like $@, qr/client_pubkey must be 64-char lowercase hex/, 'create_nostrconnect_uri rejects bad pubkey';
};

###############################################################################
# URI parsers: pubkey case normalization
###############################################################################

subtest 'parse_bunker_uri: mixed-case pubkey is lowercased' => sub {
    my $upper = uc($remote_signer_pubkey);
    my $uri = "bunker://${upper}?relay=wss%3A%2F%2Frelay1.example.com&secret=s";
    my $conn = Net::Nostr::RemoteSigning->parse_bunker_uri($uri);
    is $conn->remote_signer_pubkey, $remote_signer_pubkey, 'pubkey lowercased';
};

subtest 'parse_nostrconnect_uri: mixed-case pubkey is lowercased' => sub {
    my $upper = uc($client_pubkey);
    my $uri = "nostrconnect://${upper}?relay=wss%3A%2F%2Frelay1.example.com&secret=s";
    my $nc = Net::Nostr::RemoteSigning->parse_nostrconnect_uri($uri);
    is $nc->client_pubkey, $client_pubkey, 'pubkey lowercased';
};

###############################################################################
# parse_discovery_event: short tags are safely skipped
###############################################################################

subtest 'parse_discovery_event: short tags are skipped' => sub {
    my $event = Net::Nostr::Event->new(
        kind    => 31990,
        pubkey  => $remote_signer_pubkey,
        content => '',
        tags    => [
            ['k', '24133'],
            ['relay'],               # too short, skipped
            [],                      # empty, skipped
            ['relay', 'wss://relay1.example.com'],
            ['nostrconnect_url'],    # too short, skipped
        ],
    );
    my $disc = Net::Nostr::RemoteSigning->parse_discovery_event($event);
    is $disc->relays, ['wss://relay1.example.com'], 'short relay tag skipped';
    is $disc->nostrconnect_url, undef, 'short nostrconnect_url tag skipped';
};

done_testing;
