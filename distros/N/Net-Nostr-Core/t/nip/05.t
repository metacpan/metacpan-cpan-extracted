#!/usr/bin/perl

# NIP-05: Mapping Nostr keys to DNS-based internet identifiers
# https://github.com/nostr-protocol/nips/blob/master/05.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use AnyEvent;
use AnyEvent::Socket;
use JSON ();

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Identifier;

my $BOB_PUBKEY = 'b0635d6a9851d3aed0cd6c495b282167acf761729078d975fc341b22650b07b9';

###############################################################################
# Identifier parsing
###############################################################################

subtest 'parse splits identifier into local-part and domain' => sub {
    my ($local, $domain) = Net::Nostr::Identifier->parse('bob@example.com');
    is $local, 'bob', 'local-part is bob';
    is $domain, 'example.com', 'domain is example.com';
};

subtest 'parse accepts all valid local-part characters (a-z0-9-_.)' => sub {
    my ($local, $domain) = Net::Nostr::Identifier->parse('bob_smith-123.test@example.com');
    is $local, 'bob_smith-123.test', 'local-part with all valid chars';
    is $domain, 'example.com', 'domain extracted';
};

subtest 'parse accepts underscore root identifier' => sub {
    my ($local, $domain) = Net::Nostr::Identifier->parse('_@bob.com');
    is $local, '_', 'local-part is underscore';
    is $domain, 'bob.com', 'domain is bob.com';
};

subtest 'parse rejects uppercase characters in local-part' => sub {
    like dies { Net::Nostr::Identifier->parse('BOB@example.com') },
        qr/invalid/i, 'uppercase rejected';
};

subtest 'parse rejects missing @' => sub {
    like dies { Net::Nostr::Identifier->parse('bobexample.com') },
        qr/invalid/i, 'missing @ rejected';
};

subtest 'parse rejects multiple @' => sub {
    like dies { Net::Nostr::Identifier->parse('bob@foo@example.com') },
        qr/invalid/i, 'multiple @ rejected';
};

subtest 'parse rejects empty local-part' => sub {
    like dies { Net::Nostr::Identifier->parse('@example.com') },
        qr/invalid/i, 'empty local-part rejected';
};

subtest 'parse rejects empty domain' => sub {
    like dies { Net::Nostr::Identifier->parse('bob@') },
        qr/invalid/i, 'empty domain rejected';
};

subtest 'parse rejects special characters in local-part' => sub {
    like dies { Net::Nostr::Identifier->parse('bob!@example.com') },
        qr/invalid/i, 'exclamation rejected';
    like dies { Net::Nostr::Identifier->parse('bob @example.com') },
        qr/invalid/i, 'space rejected';
    like dies { Net::Nostr::Identifier->parse('bob+tag@example.com') },
        qr/invalid/i, 'plus rejected';
};

subtest 'parse rejects domain with URL-unsafe characters' => sub {
    # Domain is interpolated into https://<domain>/.well-known/nostr.json
    # so must not contain characters that alter URL structure
    like dies { Net::Nostr::Identifier->parse('bob@example.com/evil') },
        qr/invalid.*domain/i, 'slash would inject path';
    like dies { Net::Nostr::Identifier->parse('bob@example.com?x=1') },
        qr/invalid.*domain/i, 'question mark would inject query';
    like dies { Net::Nostr::Identifier->parse('bob@example.com#frag') },
        qr/invalid.*domain/i, 'hash would inject fragment';
    like dies { Net::Nostr::Identifier->parse('bob@example.com:8080') },
        qr/invalid.*domain/i, 'colon would inject port';
};

subtest 'parse rejects non-DNS domains' => sub {
    # NIP-05 is "Mapping Nostr keys to DNS-based internet identifiers"
    like dies { Net::Nostr::Identifier->parse('bob@[::1]') },
        qr/invalid.*domain/i, 'IPv6 literal rejected (DNS-based only)';
};

###############################################################################
# URL construction
###############################################################################

subtest 'url builds well-known URL from identifier' => sub {
    # From spec: client makes GET request to https://<domain>/.well-known/nostr.json?name=<local-part>
    my $url = Net::Nostr::Identifier->url('bob@example.com');
    is $url, 'https://example.com/.well-known/nostr.json?name=bob',
        'spec example URL';
};

subtest 'url builds correct URL for root identifier' => sub {
    my $url = Net::Nostr::Identifier->url('_@bob.com');
    is $url, 'https://bob.com/.well-known/nostr.json?name=_',
        'root identifier URL';
};

###############################################################################
# Display name
###############################################################################

subtest 'display_name returns full identifier normally' => sub {
    is(Net::Nostr::Identifier->display_name('bob@example.com'), 'bob@example.com',
        'normal identifier unchanged');
};

subtest 'display_name shows just domain for root identifier _@domain' => sub {
    # From spec: "Clients may treat the identifier `_@domain` as the 'root' identifier,
    #  and choose to display it as just the <domain>"
    is(Net::Nostr::Identifier->display_name('_@bob.com'), 'bob.com',
        '_@bob.com displays as bob.com');
};

###############################################################################
# Response verification (spec examples)
###############################################################################

subtest 'verify_response matches pubkey from names mapping' => sub {
    # Spec example response
    my $response = {
        names => {
            bob => $BOB_PUBKEY,
        },
    };
    ok(Net::Nostr::Identifier->verify_response($response, 'bob', $BOB_PUBKEY),
        'pubkey matches names entry');
};

subtest 'verify_response with relays attribute (spec example)' => sub {
    # Spec example with recommended relays attribute
    my $response = {
        names => {
            bob => $BOB_PUBKEY,
        },
        relays => {
            $BOB_PUBKEY => ['wss://relay.example.com', 'wss://relay2.example.com'],
        },
    };
    ok(Net::Nostr::Identifier->verify_response($response, 'bob', $BOB_PUBKEY),
        'verification succeeds with relays present');
};

subtest 'verify_response rejects pubkey mismatch' => sub {
    my $response = {
        names => {
            bob => 'a' x 64,
        },
    };
    ok !Net::Nostr::Identifier->verify_response($response, 'bob', $BOB_PUBKEY),
        'different pubkey rejected';
};

subtest 'verify_response rejects missing name' => sub {
    my $response = {
        names => {
            alice => $BOB_PUBKEY,
        },
    };
    ok !Net::Nostr::Identifier->verify_response($response, 'bob', $BOB_PUBKEY),
        'name not in response rejected';
};

subtest 'verify_response rejects missing names key' => sub {
    my $response = {};
    ok !Net::Nostr::Identifier->verify_response($response, 'bob', $BOB_PUBKEY),
        'no names key rejected';
};

subtest 'verify_response rejects non-hashref names' => sub {
    my $response = { names => 'invalid' };
    ok !Net::Nostr::Identifier->verify_response($response, 'bob', $BOB_PUBKEY),
        'non-hashref names rejected';
};

subtest 'verify_response rejects non-object response' => sub {
    # "The result should be a JSON document object"
    ok !Net::Nostr::Identifier->verify_response([], 'bob', $BOB_PUBKEY),
        'JSON array rejected';
    ok !Net::Nostr::Identifier->verify_response('string', 'bob', $BOB_PUBKEY),
        'JSON string rejected';
    ok !Net::Nostr::Identifier->verify_response(undef, 'bob', $BOB_PUBKEY),
        'undef rejected';
};

subtest 'verify_response rejects short hex pubkey' => sub {
    my $short = 'abcd';
    my $response = { names => { bob => $short } };
    ok !Net::Nostr::Identifier->verify_response($response, 'bob', $short),
        'short hex pubkey rejected';
};

subtest 'verify_response rejects long hex pubkey' => sub {
    my $long = 'a' x 128;
    my $response = { names => { bob => $long } };
    ok !Net::Nostr::Identifier->verify_response($response, 'bob', $long),
        'long hex pubkey rejected';
};

subtest 'public keys must be in hex format, lowercase' => sub {
    # "Keys must be returned in hex format, in lowercase.
    #  Keys in NIP-19 `npub` format are only meant to be used for display
    #  in client UIs, not in this NIP."
    my $response = {
        names => {
            bob => uc($BOB_PUBKEY),  # uppercase
        },
    };
    ok !Net::Nostr::Identifier->verify_response($response, 'bob', $BOB_PUBKEY),
        'uppercase pubkey in response rejected';

    # npub format must not be used
    my $npub_response = {
        names => {
            bob => 'npub1kc9e6dkqmljzf5kya8vd50a5rqxn89sxq0gfm2x4mfm32hn0v8qpp6hcc',
        },
    };
    ok !Net::Nostr::Identifier->verify_response($npub_response, 'bob', $BOB_PUBKEY),
        'npub format pubkey in response rejected';
};

###############################################################################
# Relay extraction
###############################################################################

subtest 'extract_relays returns relay list for pubkey' => sub {
    my $response = {
        names => { bob => $BOB_PUBKEY },
        relays => {
            $BOB_PUBKEY => ['wss://relay.example.com', 'wss://relay2.example.com'],
        },
    };
    my $relays = Net::Nostr::Identifier->extract_relays($response, $BOB_PUBKEY);
    is $relays, ['wss://relay.example.com', 'wss://relay2.example.com'],
        'relay list extracted for pubkey';
};

subtest 'extract_relays returns empty list when no relays key' => sub {
    my $response = { names => { bob => $BOB_PUBKEY } };
    my $relays = Net::Nostr::Identifier->extract_relays($response, $BOB_PUBKEY);
    is $relays, [], 'no relays key returns empty list';
};

subtest 'extract_relays returns empty list when pubkey not in relays' => sub {
    my $response = {
        names => { bob => $BOB_PUBKEY },
        relays => { ('a' x 64) => ['wss://other.com'] },
    };
    my $relays = Net::Nostr::Identifier->extract_relays($response, $BOB_PUBKEY);
    is $relays, [], 'pubkey not in relays returns empty list';
};

###############################################################################
# Spec example: kind 0 event with nip05 field
###############################################################################

subtest 'kind 0 event with nip05 field (spec example)' => sub {
    # From the spec:
    # {
    #   "pubkey": "b0635d6a9851d3aed0cd6c495b282167acf761729078d975fc341b22650b07b9",
    #   "kind": 0,
    #   "content": "{\"name\": \"bob\", \"nip05\": \"bob@example.com\"}"
    # }
    my $event = make_event(
        pubkey  => $BOB_PUBKEY,
        kind    => 0,
        content => '{"name": "bob", "nip05": "bob@example.com"}',
        sig     => 'a' x 128,
    );
    my $metadata = JSON::decode_json($event->content);
    is $metadata->{nip05}, 'bob@example.com', 'nip05 field extracted from kind 0 content';

    my $url = Net::Nostr::Identifier->url($metadata->{nip05});
    is $url, 'https://example.com/.well-known/nostr.json?name=bob',
        'constructed URL matches spec';
};

###############################################################################
# HTTP verification (with test server)
###############################################################################

# Helper: find a free port
my $find_port = sub {
    require IO::Socket::INET;
    my $sock = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1', LocalPort => 0,
        Proto => 'tcp', Listen => 1, ReuseAddr => 1,
    );
    my $port = $sock->sockport;
    close $sock;
    return $port;
};

# Helper: start a simple HTTP server that serves nostr.json responses
my $start_http_server = sub {
    my (%opts) = @_;
    my $port = $opts{port};
    my $response_body = $opts{body} // '{}';
    my $status = $opts{status} // '200 OK';
    my $headers = $opts{headers} // '';
    my $redirect = $opts{redirect};  # if set, return a redirect

    my $guard = tcp_server '127.0.0.1', $port, sub {
        my ($fh) = @_;
        my $buf = '';
        my $w; $w = AnyEvent->io(fh => $fh, poll => 'r', cb => sub {
            my $n = sysread $fh, $buf, 4096, length $buf;
            return unless $buf =~ /\r\n\r\n/;
            undef $w;

            my $resp;
            if ($redirect) {
                $resp = "HTTP/1.1 301 Moved Permanently\r\n"
                      . "Location: $redirect\r\n"
                      . "Content-Length: 0\r\n"
                      . "\r\n";
            } else {
                my $len = length $response_body;
                $resp = "HTTP/1.1 $status\r\n"
                      . "Content-Type: application/json\r\n"
                      . "Content-Length: $len\r\n"
                      . $headers
                      . "\r\n"
                      . $response_body;
            }
            syswrite $fh, $resp;
            close $fh;
        });
    };
    return $guard;
};

subtest 'verify succeeds with valid nostr.json response' => sub {
    my $port = $find_port->();
    my $body = JSON::encode_json({
        names => { bob => $BOB_PUBKEY },
    });
    my $guard = $start_http_server->(port => $port, body => $body);

    my $ident = Net::Nostr::Identifier->new(base_url => "http://127.0.0.1:$port");
    my $cv = AnyEvent->condvar;
    my ($ok, $relays, $err);

    $ident->verify(
        identifier => 'bob@example.com',
        pubkey     => $BOB_PUBKEY,
        on_success => sub { ($relays) = @_; $ok = 1; $cv->send },
        on_failure => sub { ($err) = @_; $ok = 0; $cv->send },
    );

    my $timer = AnyEvent->timer(after => 3, cb => sub { $err = 'timeout'; $cv->send });
    $cv->recv;

    ok $ok, 'verification succeeded';
    is $relays, [], 'no relays in response';
};

subtest 'verify returns relays when present' => sub {
    my $port = $find_port->();
    my $body = JSON::encode_json({
        names => { bob => $BOB_PUBKEY },
        relays => {
            $BOB_PUBKEY => ['wss://relay.example.com', 'wss://relay2.example.com'],
        },
    });
    my $guard = $start_http_server->(port => $port, body => $body);

    my $ident = Net::Nostr::Identifier->new(base_url => "http://127.0.0.1:$port");
    my $cv = AnyEvent->condvar;
    my ($ok, $relays, $err);

    $ident->verify(
        identifier => 'bob@example.com',
        pubkey     => $BOB_PUBKEY,
        on_success => sub { ($relays) = @_; $ok = 1; $cv->send },
        on_failure => sub { ($err) = @_; $ok = 0; $cv->send },
    );

    my $timer = AnyEvent->timer(after => 3, cb => sub { $err = 'timeout'; $cv->send });
    $cv->recv;

    ok $ok, 'verification succeeded';
    is $relays, ['wss://relay.example.com', 'wss://relay2.example.com'],
        'relays returned from response';
};

subtest 'verify fails when pubkey does not match' => sub {
    my $port = $find_port->();
    my $body = JSON::encode_json({
        names => { bob => 'a' x 64 },
    });
    my $guard = $start_http_server->(port => $port, body => $body);

    my $ident = Net::Nostr::Identifier->new(base_url => "http://127.0.0.1:$port");
    my $cv = AnyEvent->condvar;
    my ($ok, $err);

    $ident->verify(
        identifier => 'bob@example.com',
        pubkey     => $BOB_PUBKEY,
        on_success => sub { $ok = 1; $cv->send },
        on_failure => sub { ($err) = @_; $ok = 0; $cv->send },
    );

    my $timer = AnyEvent->timer(after => 3, cb => sub { $err = 'timeout'; $cv->send });
    $cv->recv;

    ok !$ok, 'verification failed';
    like $err, qr/pubkey/i, 'error mentions pubkey mismatch';
};

subtest 'verify fails on HTTP error' => sub {
    my $port = $find_port->();
    my $guard = $start_http_server->(port => $port, body => 'Not Found', status => '404 Not Found');

    my $ident = Net::Nostr::Identifier->new(base_url => "http://127.0.0.1:$port");
    my $cv = AnyEvent->condvar;
    my ($ok, $err);

    $ident->verify(
        identifier => 'bob@example.com',
        pubkey     => $BOB_PUBKEY,
        on_success => sub { $ok = 1; $cv->send },
        on_failure => sub { ($err) = @_; $ok = 0; $cv->send },
    );

    my $timer = AnyEvent->timer(after => 3, cb => sub { $err = 'timeout'; $cv->send });
    $cv->recv;

    ok !$ok, 'verification failed on HTTP error';
};

subtest 'verify fails on invalid JSON response' => sub {
    my $port = $find_port->();
    my $guard = $start_http_server->(port => $port, body => 'not json{{{');

    my $ident = Net::Nostr::Identifier->new(base_url => "http://127.0.0.1:$port");
    my $cv = AnyEvent->condvar;
    my ($ok, $err);

    $ident->verify(
        identifier => 'bob@example.com',
        pubkey     => $BOB_PUBKEY,
        on_success => sub { $ok = 1; $cv->send },
        on_failure => sub { ($err) = @_; $ok = 0; $cv->send },
    );

    my $timer = AnyEvent->timer(after => 3, cb => sub { $err = 'timeout'; $cv->send });
    $cv->recv;

    ok !$ok, 'verification failed on invalid JSON';
};

###############################################################################
# Security: redirects MUST be ignored
###############################################################################

subtest 'fetcher ignores HTTP redirects' => sub {
    # "The /.well-known/nostr.json endpoint MUST NOT return any HTTP redirects."
    # "Fetchers MUST ignore any HTTP redirects given by the /.well-known/nostr.json endpoint."
    my $port = $find_port->();
    my $redirect_port = $find_port->();

    # Server that redirects
    my $guard1 = $start_http_server->(
        port => $port,
        redirect => "http://127.0.0.1:$redirect_port/.well-known/nostr.json?name=bob",
    );

    # Server at redirect target (should NOT be reached)
    my $body = JSON::encode_json({ names => { bob => $BOB_PUBKEY } });
    my $guard2 = $start_http_server->(port => $redirect_port, body => $body);

    my $ident = Net::Nostr::Identifier->new(base_url => "http://127.0.0.1:$port");
    my $cv = AnyEvent->condvar;
    my ($ok, $err);

    $ident->verify(
        identifier => 'bob@example.com',
        pubkey     => $BOB_PUBKEY,
        on_success => sub { $ok = 1; $cv->send },
        on_failure => sub { ($err) = @_; $ok = 0; $cv->send },
    );

    my $timer = AnyEvent->timer(after => 3, cb => sub { $err = 'timeout'; $cv->send });
    $cv->recv;

    ok !$ok, 'verification fails when server redirects';
    like $err, qr/redirect/i, 'error mentions redirect';
};

###############################################################################
# Lookup: find pubkey from identifier
###############################################################################

subtest 'lookup returns pubkey and relays for identifier' => sub {
    my $port = $find_port->();
    my $body = JSON::encode_json({
        names => { bob => $BOB_PUBKEY },
        relays => {
            $BOB_PUBKEY => ['wss://relay.example.com'],
        },
    });
    my $guard = $start_http_server->(port => $port, body => $body);

    my $ident = Net::Nostr::Identifier->new(base_url => "http://127.0.0.1:$port");
    my $cv = AnyEvent->condvar;
    my ($ok, $pubkey, $relays, $err);

    $ident->lookup(
        identifier => 'bob@example.com',
        on_success => sub { ($pubkey, $relays) = @_; $ok = 1; $cv->send },
        on_failure => sub { ($err) = @_; $ok = 0; $cv->send },
    );

    my $timer = AnyEvent->timer(after => 3, cb => sub { $err = 'timeout'; $cv->send });
    $cv->recv;

    ok $ok, 'lookup succeeded';
    is $pubkey, $BOB_PUBKEY, 'correct pubkey returned';
    is $relays, ['wss://relay.example.com'], 'relays returned';
};

subtest 'lookup fails when name not found' => sub {
    my $port = $find_port->();
    my $body = JSON::encode_json({
        names => { alice => 'a' x 64 },
    });
    my $guard = $start_http_server->(port => $port, body => $body);

    my $ident = Net::Nostr::Identifier->new(base_url => "http://127.0.0.1:$port");
    my $cv = AnyEvent->condvar;
    my ($ok, $err);

    $ident->lookup(
        identifier => 'bob@example.com',
        on_success => sub { $ok = 1; $cv->send },
        on_failure => sub { ($err) = @_; $ok = 0; $cv->send },
    );

    my $timer = AnyEvent->timer(after => 3, cb => sub { $err = 'timeout'; $cv->send });
    $cv->recv;

    ok !$ok, 'lookup failed for missing name';
};

subtest 'lookup ignores redirects' => sub {
    my $port = $find_port->();
    my $guard = $start_http_server->(
        port => $port,
        redirect => 'http://evil.com/.well-known/nostr.json?name=bob',
    );

    my $ident = Net::Nostr::Identifier->new(base_url => "http://127.0.0.1:$port");
    my $cv = AnyEvent->condvar;
    my ($ok, $err);

    $ident->lookup(
        identifier => 'bob@example.com',
        on_success => sub { $ok = 1; $cv->send },
        on_failure => sub { ($err) = @_; $ok = 0; $cv->send },
    );

    my $timer = AnyEvent->timer(after => 3, cb => sub { $err = 'timeout'; $cv->send });
    $cv->recv;

    ok !$ok, 'lookup fails on redirect';
};

subtest 'lookup rejects short hex pubkey from server' => sub {
    my $port = $find_port->();
    my $body = JSON::encode_json({
        names => { bob => 'abcd' },
    });
    my $guard = $start_http_server->(port => $port, body => $body);

    my $ident = Net::Nostr::Identifier->new(base_url => "http://127.0.0.1:$port");
    my $cv = AnyEvent->condvar;
    my ($ok, $err);

    $ident->lookup(
        identifier => 'bob@example.com',
        on_success => sub { $ok = 1; $cv->send },
        on_failure => sub { ($err) = @_; $ok = 0; $cv->send },
    );

    my $timer = AnyEvent->timer(after => 3, cb => sub { $err = 'timeout'; $cv->send });
    $cv->recv;

    ok !$ok, 'lookup rejects short hex pubkey';
    like $err, qr/invalid pubkey/i, 'error mentions invalid format';
};

subtest 'lookup rejects non-hex pubkey from server' => sub {
    # "Keys must be returned in hex format, in lowercase"
    my $port = $find_port->();
    my $body = JSON::encode_json({
        names => { bob => 'npub1kc9e6dkqmljzf5kya8vd50a5rqxn89sxq0gfm2x4mfm32hn0v8qpp6hcc' },
    });
    my $guard = $start_http_server->(port => $port, body => $body);

    my $ident = Net::Nostr::Identifier->new(base_url => "http://127.0.0.1:$port");
    my $cv = AnyEvent->condvar;
    my ($ok, $err);

    $ident->lookup(
        identifier => 'bob@example.com',
        on_success => sub { $ok = 1; $cv->send },
        on_failure => sub { ($err) = @_; $ok = 0; $cv->send },
    );

    my $timer = AnyEvent->timer(after => 3, cb => sub { $err = 'timeout'; $cv->send });
    $cv->recv;

    ok !$ok, 'lookup rejects npub-format pubkey';
    like $err, qr/invalid pubkey/i, 'error mentions invalid format';
};

###############################################################################
# Edge cases
###############################################################################

subtest 'response with multiple names' => sub {
    # Static servers may serve multiple names in one file
    my $response = {
        names => {
            bob   => $BOB_PUBKEY,
            alice => 'a' x 64,
        },
    };
    ok(Net::Nostr::Identifier->verify_response($response, 'bob', $BOB_PUBKEY),
        'bob matches in multi-name response');
    ok(!Net::Nostr::Identifier->verify_response($response, 'bob', 'a' x 64),
        'bob does not match alice pubkey');
    ok(Net::Nostr::Identifier->verify_response($response, 'alice', 'a' x 64),
        'alice matches her pubkey');
};

subtest 'relays served for any name in same reply' => sub {
    # "Web servers which serve /.well-known/nostr.json files dynamically based on
    #  the query string SHOULD also serve the relays data for any name they serve"
    my $response = {
        names => {
            bob   => $BOB_PUBKEY,
            alice => 'a' x 64,
        },
        relays => {
            $BOB_PUBKEY => ['wss://relay1.com'],
            ('a' x 64)  => ['wss://relay2.com'],
        },
    };
    is(Net::Nostr::Identifier->extract_relays($response, $BOB_PUBKEY),
        ['wss://relay1.com'], 'bob relays extracted');
    is(Net::Nostr::Identifier->extract_relays($response, 'a' x 64),
        ['wss://relay2.com'], 'alice relays extracted');
};

done_testing;
