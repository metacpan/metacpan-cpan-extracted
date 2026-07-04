use strictures 2;
use Test2::V0 -no_srand => 1;

use JSON ();
use MIME::Base64 qw(decode_base64);
use Digest::SHA qw(sha256_hex);

use lib 't/lib';
use TestFixtures qw(make_key_from_hex);

use Net::Nostr::Event;
use Net::Nostr::HttpAuth qw(
    create_auth_event
    create_auth_header
    parse_auth_header
    validate_auth_event
);

###############################################################################
# POD example: create Authorization header for GET
###############################################################################

subtest 'POD: create_auth_header GET' => sub {
    my $key = make_key_from_hex('01' x 32);
    my $header = create_auth_header(
        key    => $key,
        url    => 'https://api.example.com/data',
        method => 'GET',
    );
    like($header, qr/\ANostr /, 'header starts with Nostr scheme');
};

###############################################################################
# POD example: POST with payload hash
###############################################################################

subtest 'POD: create_auth_header POST with payload' => sub {
    my $key = make_key_from_hex('01' x 32);
    my $body = '{"name":"test"}';
    my $header = create_auth_header(
        key     => $key,
        url     => 'https://api.example.com/upload',
        method  => 'POST',
        payload => $body,
    );
    my ($scheme, $b64) = split / /, $header, 2;
    my $data = JSON->new->utf8->decode(decode_base64($b64));
    my @payload = grep { $_->[0] eq 'payload' } @{$data->{tags}};
    is($payload[0][1], sha256_hex($body), 'payload hash in header');
};

###############################################################################
# POD example: server parse and validate
###############################################################################

subtest 'POD: parse and validate' => sub {
    my $key = make_key_from_hex('01' x 32);
    my $header = create_auth_header(
        key    => $key,
        url    => 'https://api.example.com/data',
        method => 'GET',
    );
    my $event = parse_auth_header($header);
    is(
        dies { validate_auth_event($event, url => 'https://api.example.com/data', method => 'GET') },
        undef,
        'parsed event validates'
    );
};

###############################################################################
# POD example: create_auth_event
###############################################################################

subtest 'POD: create_auth_event' => sub {
    my $event = create_auth_event(
        pubkey => 'aa' x 32,
        url    => 'https://api.example.com/data',
        method => 'GET',
    );
    is($event->kind, 27235, 'kind 27235');
    is($event->content, '', 'empty content');
};

###############################################################################
# POD example: validate failure returns 401
###############################################################################

subtest 'POD: validate failure for 401' => sub {
    my $key = make_key_from_hex('01' x 32);
    my $header = create_auth_header(
        key    => $key,
        url    => 'https://example.com/api',
        method => 'GET',
    );
    my $event = parse_auth_header($header);
    my $err = dies { validate_auth_event($event, url => 'https://other.com', method => 'GET') };
    ok(defined $err, 'validation failure gives error for 401 response');
};

###############################################################################
# exports
###############################################################################

subtest 'exports: all functions available' => sub {
    ok(defined &create_auth_event, 'create_auth_event exported');
    ok(defined &create_auth_header, 'create_auth_header exported');
    ok(defined &parse_auth_header, 'parse_auth_header exported');
    ok(defined &validate_auth_event, 'validate_auth_event exported');
};

###############################################################################
# create_auth_event: validation
###############################################################################

subtest 'create_auth_event: requires pubkey' => sub {
    like(dies { create_auth_event(url => 'https://x.com', method => 'GET') },
        qr/pubkey.*required/i, 'missing pubkey rejected');
};

subtest 'create_auth_event: requires url' => sub {
    like(dies { create_auth_event(pubkey => 'aa' x 32, method => 'GET') },
        qr/url.*required/i, 'missing url rejected');
};

subtest 'create_auth_event: requires method' => sub {
    like(dies { create_auth_event(pubkey => 'aa' x 32, url => 'https://x.com') },
        qr/method.*required/i, 'missing method rejected');
};

subtest 'create_auth_event: rejects bad pubkey' => sub {
    like(dies { create_auth_event(pubkey => 'ZZZZ', url => 'https://x.com', method => 'GET') },
        qr/pubkey.*hex/i, 'non-hex pubkey rejected');
    like(dies { create_auth_event(pubkey => 'aa' x 31, url => 'https://x.com', method => 'GET') },
        qr/pubkey.*hex/i, 'short pubkey rejected');
    like(dies { create_auth_event(pubkey => 'AA' x 32, url => 'https://x.com', method => 'GET') },
        qr/pubkey.*hex/i, 'uppercase pubkey rejected');
};

subtest 'create_auth_event: tags structure' => sub {
    my $event = create_auth_event(
        pubkey => 'aa' x 32,
        url    => 'https://api.example.com/data',
        method => 'GET',
    );
    my @u_tags = grep { $_->[0] eq 'u' } @{$event->tags};
    my @m_tags = grep { $_->[0] eq 'method' } @{$event->tags};
    is scalar @u_tags, 1, 'exactly one u tag';
    is $u_tags[0][1], 'https://api.example.com/data', 'u tag value';
    is scalar @m_tags, 1, 'exactly one method tag';
    is $m_tags[0][1], 'GET', 'method tag value';
};

subtest 'create_auth_event: no payload tag without payload' => sub {
    my $event = create_auth_event(
        pubkey => 'aa' x 32,
        url    => 'https://api.example.com/',
        method => 'GET',
    );
    my @p_tags = grep { $_->[0] eq 'payload' } @{$event->tags};
    is scalar @p_tags, 0, 'no payload tag when payload not provided';
};

###############################################################################
# create_auth_header: validation
###############################################################################

subtest 'create_auth_header: requires key' => sub {
    like(dies { create_auth_header(url => 'https://x.com', method => 'GET') },
        qr/key.*required/i, 'missing key rejected');
};

subtest 'create_auth_header: requires url' => sub {
    my $key = make_key_from_hex('01' x 32);
    like(dies { create_auth_header(key => $key, method => 'GET') },
        qr/url.*required/i, 'missing url rejected');
};

subtest 'create_auth_header: requires method' => sub {
    my $key = make_key_from_hex('01' x 32);
    like(dies { create_auth_header(key => $key, url => 'https://x.com') },
        qr/method.*required/i, 'missing method rejected');
};

###############################################################################
# parse_auth_header: validation
###############################################################################

subtest 'parse_auth_header: rejects undef' => sub {
    like(dies { parse_auth_header(undef) },
        qr/required/i, 'undef rejected');
};

subtest 'parse_auth_header: rejects empty string' => sub {
    like(dies { parse_auth_header('') },
        qr/required/i, 'empty string rejected');
};

subtest 'parse_auth_header: rejects wrong scheme' => sub {
    like(dies { parse_auth_header('Bearer abc123') },
        qr/Nostr.*scheme/i, 'Bearer scheme rejected');
    like(dies { parse_auth_header('Basic abc123') },
        qr/Nostr.*scheme/i, 'Basic scheme rejected');
};

subtest 'parse_auth_header: rejects missing base64 data' => sub {
    like(dies { parse_auth_header('Nostr') },
        qr/base64/i, 'no data after scheme rejected');
    like(dies { parse_auth_header('Nostr ') },
        qr/base64/i, 'empty data after scheme rejected');
};

subtest 'parse_auth_header: rejects invalid JSON' => sub {
    use MIME::Base64 qw(encode_base64);
    my $b64 = encode_base64('not json at all', '');
    like(dies { parse_auth_header("Nostr $b64") },
        qr/JSON/i, 'invalid JSON rejected');
};

###############################################################################
# validate_auth_event: all error paths
###############################################################################

my $test_key = make_key_from_hex('01' x 32);

subtest 'validate_auth_event: rejects undef event' => sub {
    like(dies { validate_auth_event(undef, url => 'https://x.com', method => 'GET') },
        qr/event.*required/i, 'undef event rejected');
};

subtest 'validate_auth_event: requires url' => sub {
    my $event = _make_valid_auth_event();
    like(dies { validate_auth_event($event, method => 'GET') },
        qr/url.*required/i, 'missing url rejected');
};

subtest 'validate_auth_event: requires method' => sub {
    my $event = _make_valid_auth_event();
    like(dies { validate_auth_event($event, url => 'https://api.example.com/data') },
        qr/method.*required/i, 'missing method rejected');
};

subtest 'validate_auth_event: rejects wrong kind' => sub {
    my $event = _make_valid_auth_event(kind => 1);
    like(dies { validate_auth_event($event, url => 'https://api.example.com/data', method => 'GET') },
        qr/kind.*27235/i, 'wrong kind rejected');
};

subtest 'validate_auth_event: rejects stale created_at' => sub {
    my $event = _make_valid_auth_event(created_at => time() - 300);
    like(dies { validate_auth_event($event, url => 'https://api.example.com/data', method => 'GET') },
        qr/time.*window/i, 'stale event rejected');
};

subtest 'validate_auth_event: rejects future created_at' => sub {
    my $event = _make_valid_auth_event(created_at => time() + 300);
    like(dies { validate_auth_event($event, url => 'https://api.example.com/data', method => 'GET') },
        qr/time.*window/i, 'future event rejected');
};

subtest 'validate_auth_event: custom time_window' => sub {
    my $event = _make_valid_auth_event(created_at => time() - 90);
    # Default window (60s) would reject
    like(dies { validate_auth_event($event, url => 'https://api.example.com/data', method => 'GET') },
        qr/time.*window/i, 'rejected with default window');
    # Custom window (120s) should accept
    ok(lives { validate_auth_event($event, url => 'https://api.example.com/data', method => 'GET', time_window => 120) },
        'accepted with wider window');
};

subtest 'validate_auth_event: rejects missing u tag' => sub {
    my $event = _make_valid_auth_event(tags => [['method', 'GET']]);
    like(dies { validate_auth_event($event, url => 'https://api.example.com/data', method => 'GET') },
        qr/missing u tag/i, 'missing u tag rejected');
};

subtest 'validate_auth_event: rejects url mismatch' => sub {
    my $event = _make_valid_auth_event();
    like(dies { validate_auth_event($event, url => 'https://other.com/', method => 'GET') },
        qr/u tag.*match/i, 'url mismatch rejected');
};

subtest 'validate_auth_event: rejects missing method tag' => sub {
    my $event = _make_valid_auth_event(tags => [['u', 'https://api.example.com/data']]);
    like(dies { validate_auth_event($event, url => 'https://api.example.com/data', method => 'GET') },
        qr/missing method tag/i, 'missing method tag rejected');
};

subtest 'validate_auth_event: rejects method mismatch' => sub {
    my $event = _make_valid_auth_event();
    like(dies { validate_auth_event($event, url => 'https://api.example.com/data', method => 'POST') },
        qr/method.*match/i, 'method mismatch rejected');
};

subtest 'validate_auth_event: payload hash mismatch' => sub {
    my $event = _make_valid_auth_event(
        tags => [
            ['u', 'https://api.example.com/data'],
            ['method', 'POST'],
            ['payload', sha256_hex('original body')],
        ],
    );
    like(dies { validate_auth_event($event,
        url => 'https://api.example.com/data', method => 'POST',
        payload => 'different body') },
        qr/payload.*match/i, 'payload mismatch rejected');
};

subtest 'validate_auth_event: payload tag without server payload is ignored' => sub {
    my $event = _make_valid_auth_event(
        tags => [
            ['u', 'https://api.example.com/data'],
            ['method', 'GET'],
            ['payload', sha256_hex('some body')],
        ],
    );
    # When server doesn't provide payload opt, the check is skipped (MAY)
    ok(lives { validate_auth_event($event,
        url => 'https://api.example.com/data', method => 'GET') },
        'payload tag ignored when server has no payload');
};

###############################################################################
# Round-trip: create -> sign -> parse -> validate
###############################################################################

subtest 'round-trip: header survives create -> parse -> validate' => sub {
    my $url    = 'https://api.example.com/data?q=1';
    my $method = 'GET';
    my $header = create_auth_header(
        key    => $test_key,
        url    => $url,
        method => $method,
    );
    my $event = parse_auth_header($header);
    ok(lives { validate_auth_event($event, url => $url, method => $method) },
        'round-trip validates');
    is($event->kind, 27235, 'kind preserved');
    is($event->content, '', 'content is empty');
};

subtest 'round-trip: POST with payload' => sub {
    my $url    = 'https://api.example.com/upload';
    my $method = 'POST';
    my $body   = '{"data":"value"}';
    my $header = create_auth_header(
        key     => $test_key,
        url     => $url,
        method  => $method,
        payload => $body,
    );
    my $event = parse_auth_header($header);
    ok(lives { validate_auth_event($event,
        url => $url, method => $method, payload => $body) },
        'round-trip with payload validates');
};

# Helper: make a valid signed auth event for validation tests
sub _make_valid_auth_event {
    my %overrides = @_;
    my $tags = $overrides{tags} // [
        ['u', 'https://api.example.com/data'],
        ['method', 'GET'],
    ];
    my $event = Net::Nostr::Event->new(
        pubkey     => $test_key->pubkey_hex,
        kind       => $overrides{kind} // 27235,
        content    => '',
        tags       => $tags,
        created_at => $overrides{created_at} // time(),
    );
    $test_key->sign_event($event);
    return $event;
}

done_testing;
