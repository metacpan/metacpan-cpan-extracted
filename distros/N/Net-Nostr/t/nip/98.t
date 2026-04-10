use strictures 2;
use Test2::V0 -no_srand => 1;

use JSON ();
use MIME::Base64 qw(encode_base64 decode_base64);
use Digest::SHA qw(sha256_hex);

use lib 't/lib';
use TestFixtures qw(make_event make_key_from_hex);

use Net::Nostr::Event;
use Net::Nostr::HttpAuth qw(
    create_auth_event
    create_auth_header
    parse_auth_header
    validate_auth_event
);

my $TEST_KEY = make_key_from_hex('01' x 32);

# Helper: create a signed kind 27235 event for validation tests
sub make_signed_auth {
    my (%args) = @_;
    my $event = Net::Nostr::Event->new(
        pubkey     => $TEST_KEY->pubkey_hex,
        kind       => $args{kind} // 27235,
        content    => $args{content} // '',
        tags       => $args{tags} // [],
        created_at => $args{created_at} // time(),
    );
    $TEST_KEY->sign_event($event);
    return $event;
}

###############################################################################
# NIP-98 spec JSON example
###############################################################################

subtest 'NIP-98: spec JSON example' => sub {
    # Exact JSON from the spec
    my $spec_json = '{"id":"fe964e758903360f28d8424d092da8494ed207cba823110be3a57dfe4b578734","pubkey":"63fe6318dc58583cfe16810f86dd09e18bfd76aabc24a0081ce2856f330504ed","content":"","kind":27235,"created_at":1682327852,"tags":[["u","https://api.snort.social/api/v1/n5sp/list"],["method","GET"]],"sig":"5ed9d8ec958bc854f997bdc24ac337d005af372324747efe4a00e24f4c30437ff4dd8308684bed467d9d6be3e5a517bb43b1732cc7d33949a3aaf86705c22184"}';
    my $data = JSON->new->utf8->decode($spec_json);

    is($data->{kind}, 27235, 'kind is 27235');
    is($data->{content}, '', 'content is empty');

    my @u_tags = grep { $_->[0] eq 'u' } @{$data->{tags}};
    is(scalar @u_tags, 1, 'has one u tag');
    is($u_tags[0][1], 'https://api.snort.social/api/v1/n5sp/list', 'u tag is absolute URL');

    my @method_tags = grep { $_->[0] eq 'method' } @{$data->{tags}};
    is(scalar @method_tags, 1, 'has one method tag');
    is($method_tags[0][1], 'GET', 'method tag is GET');
};

###############################################################################
# NIP-98 spec: base64 Authorization header example
###############################################################################

subtest 'NIP-98: spec Authorization header example' => sub {
    my $spec_b64 = 'eyJpZCI6ImZlOTY0ZTc1ODkwMzM2MGYyOGQ4NDI0ZDA5MmRhODQ5NGVkMjA3Y2JhODIzMTEwYmUzYTU3ZGZlNGI1Nzg3MzQiLCJwdWJrZXkiOiI2M2ZlNjMxOGRjNTg1ODNjZmUxNjgxMGY4NmRkMDllMThiZmQ3NmFhYmMyNGEwMDgxY2UyODU2ZjMzMDUwNGVkIiwiY29udGVudCI6IiIsImtpbmQiOjI3MjM1LCJjcmVhdGVkX2F0IjoxNjgyMzI3ODUyLCJ0YWdzIjpbWyJ1IiwiaHR0cHM6Ly9hcGkuc25vcnQuc29jaWFsL2FwaS92MS9uNXNwL2xpc3QiXSxbIm1ldGhvZCIsIkdFVCJdXSwic2lnIjoiNWVkOWQ4ZWM5NThiYzg1NGY5OTdiZGMyNGFjMzM3ZDAwNWFmMzcyMzI0NzQ3ZWZlNGEwMGUyNGY0YzMwNDM3ZmY0ZGQ4MzA4Njg0YmVkNDY3ZDlkNmJlM2U1YTUxN2JiNDNiMTczMmNjN2QzMzk0OWEzYWFmODY3MDVjMjIxODQifQ';

    my $decoded = JSON->new->utf8->decode(decode_base64($spec_b64));
    is($decoded->{kind}, 27235, 'decoded kind is 27235');
    is($decoded->{pubkey}, '63fe6318dc58583cfe16810f86dd09e18bfd76aabc24a0081ce2856f330504ed', 'decoded pubkey matches');
    is($decoded->{tags}[0][1], 'https://api.snort.social/api/v1/n5sp/list', 'decoded u tag matches');
    is($decoded->{tags}[1][1], 'GET', 'decoded method matches');
};

###############################################################################
# create_auth_event: builds kind 27235 event
###############################################################################

subtest 'create_auth_event: basic GET' => sub {
    my $event = create_auth_event(
        pubkey => 'aa' x 32,
        url    => 'https://api.example.com/data',
        method => 'GET',
    );
    is($event->kind, 27235, 'kind is 27235');
    is($event->content, '', 'content SHOULD be empty');

    my @u = grep { $_->[0] eq 'u' } @{$event->tags};
    is(scalar @u, 1, 'has u tag');
    is($u[0][1], 'https://api.example.com/data', 'u tag matches URL');

    my @m = grep { $_->[0] eq 'method' } @{$event->tags};
    is(scalar @m, 1, 'has method tag');
    is($m[0][1], 'GET', 'method tag matches');
};

subtest 'create_auth_event: POST with payload' => sub {
    my $body = '{"name":"test"}';
    my $event = create_auth_event(
        pubkey  => 'aa' x 32,
        url     => 'https://api.example.com/upload',
        method  => 'POST',
        payload => $body,
    );
    is($event->kind, 27235, 'kind is 27235');

    my @payload = grep { $_->[0] eq 'payload' } @{$event->tags};
    is(scalar @payload, 1, 'has payload tag');
    is($payload[0][1], sha256_hex($body), 'payload tag is SHA256 hex of body');
};

subtest 'create_auth_event: URL with query parameters' => sub {
    my $url = 'https://api.example.com/search?q=nostr&limit=10';
    my $event = create_auth_event(
        pubkey => 'aa' x 32,
        url    => $url,
        method => 'GET',
    );
    my @u = grep { $_->[0] eq 'u' } @{$event->tags};
    is($u[0][1], $url, 'u tag preserves query parameters');
};

subtest 'create_auth_event: various HTTP methods' => sub {
    for my $method (qw(GET POST PUT PATCH DELETE)) {
        my $event = create_auth_event(
            pubkey => 'aa' x 32,
            url    => 'https://example.com/api',
            method => $method,
        );
        my @m = grep { $_->[0] eq 'method' } @{$event->tags};
        is($m[0][1], $method, "method tag is $method");
    }
};

subtest 'create_auth_event: created_at defaults to now' => sub {
    my $before = time();
    my $event = create_auth_event(
        pubkey => 'aa' x 32,
        url    => 'https://example.com',
        method => 'GET',
    );
    my $after = time();
    ok($event->created_at >= $before && $event->created_at <= $after,
        'created_at is approximately now');
};

subtest 'create_auth_event: custom created_at' => sub {
    my $event = create_auth_event(
        pubkey     => 'aa' x 32,
        url        => 'https://example.com',
        method     => 'GET',
        created_at => 1682327852,
    );
    is($event->created_at, 1682327852, 'custom created_at used');
};

###############################################################################
# create_auth_event: validation
###############################################################################

subtest 'create_auth_event: missing pubkey' => sub {
    like(
        dies { create_auth_event(url => 'https://x.com', method => 'GET') },
        qr/pubkey is required/,
        'missing pubkey rejected'
    );
};

subtest 'create_auth_event: missing url' => sub {
    like(
        dies { create_auth_event(pubkey => 'aa' x 32, method => 'GET') },
        qr/url is required/,
        'missing url rejected'
    );
};

subtest 'create_auth_event: missing method' => sub {
    like(
        dies { create_auth_event(pubkey => 'aa' x 32, url => 'https://x.com') },
        qr/method is required/,
        'missing method rejected'
    );
};

###############################################################################
# create_auth_header: base64 encoding
###############################################################################

subtest 'create_auth_header: format' => sub {
    my $key = make_key_from_hex('01' x 32);
    my $header = create_auth_header(
        key    => $key,
        url    => 'https://api.example.com/data',
        method => 'GET',
    );
    like($header, qr/\ANostr [A-Za-z0-9+\/=]+\z/, 'header matches Nostr <base64> format');

    # Decode and verify the event inside
    my ($scheme, $b64) = split / /, $header, 2;
    is($scheme, 'Nostr', 'scheme is Nostr');

    my $json = decode_base64($b64);
    my $data = JSON->new->utf8->decode($json);
    is($data->{kind}, 27235, 'decoded kind is 27235');
    like($data->{sig}, qr/\A[0-9a-f]{128}\z/, 'event is signed');
};

subtest 'create_auth_header: with payload' => sub {
    my $key = make_key_from_hex('01' x 32);
    my $body = 'hello world';
    my $header = create_auth_header(
        key     => $key,
        url     => 'https://api.example.com/upload',
        method  => 'POST',
        payload => $body,
    );
    my ($scheme, $b64) = split / /, $header, 2;
    my $data = JSON->new->utf8->decode(decode_base64($b64));

    my @payload = grep { $_->[0] eq 'payload' } @{$data->{tags}};
    is($payload[0][1], sha256_hex($body), 'payload tag in header has correct hash');
};

###############################################################################
# parse_auth_header: extract event from Authorization header
###############################################################################

subtest 'parse_auth_header: valid header' => sub {
    my $key = make_key_from_hex('01' x 32);
    my $header = create_auth_header(
        key    => $key,
        url    => 'https://example.com/api',
        method => 'GET',
    );
    my $event = parse_auth_header($header);
    isa_ok($event, 'Net::Nostr::Event');
    is($event->kind, 27235, 'parsed event kind is 27235');
};

subtest 'parse_auth_header: wrong scheme' => sub {
    like(
        dies { parse_auth_header('Bearer abc123') },
        qr/expected Nostr authorization scheme/i,
        'non-Nostr scheme rejected'
    );
};

subtest 'parse_auth_header: missing header' => sub {
    like(
        dies { parse_auth_header(undef) },
        qr/authorization header is required/i,
        'undef header rejected'
    );
    like(
        dies { parse_auth_header('') },
        qr/authorization header is required/i,
        'empty header rejected'
    );
};

subtest 'parse_auth_header: invalid base64' => sub {
    like(
        dies { parse_auth_header('Nostr !!!invalid!!!') },
        qr/./,
        'invalid base64 rejected'
    );
};

###############################################################################
# validate_auth_event: server-side validation (spec lines 40-48)
###############################################################################

subtest 'validate: kind MUST be 27235' => sub {
    my $event = make_signed_auth(kind => 1, tags => [
        ['u', 'https://example.com'],
        ['method', 'GET'],
    ]);
    like(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'GET') },
        qr/kind must be 27235/,
        'wrong kind rejected'
    );
};

subtest 'validate: created_at MUST be within time window' => sub {
    my $event = make_signed_auth(created_at => time() - 120, tags => [
        ['u', 'https://example.com'],
        ['method', 'GET'],
    ]);

    like(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'GET') },
        qr/created_at outside.*window/i,
        'old timestamp rejected (default 60s window)'
    );
};

subtest 'validate: created_at within custom time window' => sub {
    my $event = make_signed_auth(created_at => time() - 90, tags => [
        ['u', 'https://example.com'],
        ['method', 'GET'],
    ]);

    # Should fail with default 60s window
    like(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'GET') },
        qr/created_at outside.*window/i,
        'fails with default window'
    );

    # Should pass with 120s window
    is(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'GET', time_window => 120) },
        undef,
        'passes with larger window'
    );
};

subtest 'validate: future timestamp rejected' => sub {
    my $event = make_signed_auth(created_at => time() + 120, tags => [
        ['u', 'https://example.com'],
        ['method', 'GET'],
    ]);

    like(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'GET') },
        qr/created_at outside.*window/i,
        'future timestamp rejected'
    );
};

subtest 'validate: u tag MUST match absolute URL exactly' => sub {
    my $event = make_signed_auth(tags => [
        ['u', 'https://example.com/api'],
        ['method', 'GET'],
    ]);
    like(
        dies { validate_auth_event($event, url => 'https://example.com/other', method => 'GET') },
        qr/u tag.*does not match/i,
        'URL mismatch rejected'
    );
};

subtest 'validate: u tag matches with query parameters' => sub {
    my $url = 'https://example.com/search?q=nostr&limit=10';
    my $event = make_signed_auth(tags => [
        ['u', $url],
        ['method', 'GET'],
    ]);
    is(
        dies { validate_auth_event($event, url => $url, method => 'GET') },
        undef,
        'exact URL with query params passes'
    );
};

subtest 'validate: method tag MUST match HTTP method' => sub {
    my $event = make_signed_auth(tags => [
        ['u', 'https://example.com'],
        ['method', 'GET'],
    ]);
    like(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'POST') },
        qr/method tag.*does not match/i,
        'method mismatch rejected'
    );
};

subtest 'validate: missing u tag' => sub {
    my $event = make_signed_auth(tags => [
        ['method', 'GET'],
    ]);
    like(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'GET') },
        qr/missing.*u tag/i,
        'missing u tag rejected'
    );
};

subtest 'validate: missing method tag' => sub {
    my $event = make_signed_auth(tags => [
        ['u', 'https://example.com'],
    ]);
    like(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'GET') },
        qr/missing.*method tag/i,
        'missing method tag rejected'
    );
};

subtest 'validate: payload tag checked when present' => sub {
    my $body = '{"data":"test"}';
    my $event = make_signed_auth(tags => [
        ['u', 'https://example.com'],
        ['method', 'POST'],
        ['payload', sha256_hex($body)],
    ]);

    # Matching payload passes
    is(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'POST', payload => $body) },
        undef,
        'matching payload passes'
    );

    # Mismatched payload fails
    like(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'POST', payload => 'wrong body') },
        qr/payload.*does not match/i,
        'mismatched payload rejected'
    );
};

subtest 'validate: payload tag ignored when no body provided' => sub {
    my $event = make_signed_auth(tags => [
        ['u', 'https://example.com'],
        ['method', 'POST'],
        ['payload', 'aa' x 32],
    ]);
    # Server doesn't provide payload to check -- should pass
    is(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'POST') },
        undef,
        'payload tag not checked when server provides no body'
    );
};

subtest 'validate: valid event passes' => sub {
    my $event = make_signed_auth(tags => [
        ['u', 'https://example.com/api/v1/data'],
        ['method', 'GET'],
    ]);

    is(
        dies { validate_auth_event($event, url => 'https://example.com/api/v1/data', method => 'GET') },
        undef,
        'valid event passes all checks'
    );
};

###############################################################################
# validate_auth_event: argument validation
###############################################################################

subtest 'validate: missing event' => sub {
    like(
        dies { validate_auth_event(undef, url => 'https://x.com', method => 'GET') },
        qr/event is required/,
        'undef event rejected'
    );
};

subtest 'validate: missing url' => sub {
    my $event = make_event(kind => 27235, content => '', created_at => time(), tags => [
        ['u', 'https://example.com'],
        ['method', 'GET'],
    ]);
    like(
        dies { validate_auth_event($event, method => 'GET') },
        qr/url is required/,
        'missing url rejected'
    );
};

subtest 'validate: missing method' => sub {
    my $event = make_event(kind => 27235, content => '', created_at => time(), tags => [
        ['u', 'https://example.com'],
        ['method', 'GET'],
    ]);
    like(
        dies { validate_auth_event($event, url => 'https://example.com') },
        qr/method is required/,
        'missing method rejected'
    );
};

###############################################################################
# validate_auth_event: cryptographic verification (NIP-01 requirement)
###############################################################################

subtest 'validate: event signature MUST be verified' => sub {
    # Unsigned event should fail validation even with correct tags
    my $event = make_event(kind => 27235, content => '', created_at => time(), tags => [
        ['u', 'https://example.com'],
        ['method', 'GET'],
    ]);
    like(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'GET') },
        qr/sig|signature/i,
        'unsigned event rejected'
    );
};

subtest 'validate: tampered event ID rejected' => sub {
    my $key = make_key_from_hex('01' x 32);
    my $header = create_auth_header(
        key    => $key,
        url    => 'https://example.com',
        method => 'GET',
    );
    my $event = parse_auth_header($header);

    # Tamper with the ID
    $event->{id} = 'ff' x 32;
    like(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'GET') },
        qr/id|hash/i,
        'tampered event ID rejected'
    );
};

subtest 'validate: tampered signature rejected' => sub {
    my $key = make_key_from_hex('01' x 32);
    my $header = create_auth_header(
        key    => $key,
        url    => 'https://example.com',
        method => 'GET',
    );
    my $event = parse_auth_header($header);

    # Tamper with the signature
    $event->{sig} = 'ff' x 64;
    like(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'GET') },
        qr/sig|signature/i,
        'tampered signature rejected'
    );
};

###############################################################################
# round-trip: create header, parse, validate
###############################################################################

subtest 'round-trip: create -> parse -> validate' => sub {
    my $key = make_key_from_hex('01' x 32);
    my $url = 'https://api.example.com/upload?format=json';
    my $body = 'file contents here';

    my $header = create_auth_header(
        key     => $key,
        url     => $url,
        method  => 'POST',
        payload => $body,
    );

    my $event = parse_auth_header($header);
    is($event->kind, 27235, 'parsed kind is 27235');

    is(
        dies { validate_auth_event($event, url => $url, method => 'POST', payload => $body) },
        undef,
        'round-trip validates successfully'
    );
};

###############################################################################
# content SHOULD be empty
###############################################################################

subtest 'create_auth_event: content is empty string' => sub {
    my $event = create_auth_event(
        pubkey => 'aa' x 32,
        url    => 'https://example.com',
        method => 'GET',
    );
    is($event->content, '', 'content is empty string');
};

###############################################################################
# method case sensitivity
###############################################################################

subtest 'validate: method comparison is exact' => sub {
    my $event = make_signed_auth(tags => [
        ['u', 'https://example.com'],
        ['method', 'GET'],
    ]);

    # Lowercase should fail
    like(
        dies { validate_auth_event($event, url => 'https://example.com', method => 'get') },
        qr/method tag.*does not match/i,
        'lowercase method does not match uppercase tag'
    );
};

done_testing;
