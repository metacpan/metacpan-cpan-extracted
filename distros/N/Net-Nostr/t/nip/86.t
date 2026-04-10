use strictures 2;
use Test2::V0 -no_srand => 1;

use JSON ();
use MIME::Base64 qw(decode_base64);
use Digest::SHA qw(sha256_hex);

use lib 't/lib';
use TestFixtures qw(make_key_from_hex);

use Net::Nostr::RelayAdmin qw(
    encode_request
    decode_response
    request_with_auth
);

my $HEX64 = qr/\A[0-9a-f]{64}\z/;
my $JSON  = JSON->new->utf8;

###############################################################################
# NIP-86 spec: request format (lines 13-18)
###############################################################################

subtest 'spec: request format' => sub {
    my $body = encode_request(method => 'supportedmethods', params => []);
    my $data = $JSON->decode($body);
    ok(exists $data->{method}, 'request has method field');
    ok(exists $data->{params}, 'request has params field');
    is(ref $data->{params}, 'ARRAY', 'params is an array');
};

###############################################################################
# NIP-86 spec: response format (lines 20-27)
###############################################################################

subtest 'spec: success response' => sub {
    my $json = '{"result":["supportedmethods","banpubkey"]}';
    my $result = decode_response($json);
    is($result, ['supportedmethods', 'banpubkey'], 'result extracted');
};

subtest 'spec: error response' => sub {
    my $json = '{"result":null,"error":"permission denied"}';
    like(
        dies { decode_response($json) },
        qr/permission denied/,
        'error field causes croak'
    );
};

###############################################################################
# encode_request: all 19 methods (lines 31-90)
###############################################################################

subtest 'encode: supportedmethods' => sub {
    my $body = encode_request(method => 'supportedmethods', params => []);
    my $data = $JSON->decode($body);
    is($data->{method}, 'supportedmethods', 'method name');
    is($data->{params}, [], 'empty params');
};

subtest 'encode: banpubkey with reason' => sub {
    my $pk = 'aa' x 32;
    my $body = encode_request(method => 'banpubkey', params => [$pk, 'spammer']);
    my $data = $JSON->decode($body);
    is($data->{method}, 'banpubkey', 'method name');
    is($data->{params}, [$pk, 'spammer'], 'pubkey + reason');
};

subtest 'encode: banpubkey without reason' => sub {
    my $pk = 'aa' x 32;
    my $body = encode_request(method => 'banpubkey', params => [$pk]);
    my $data = $JSON->decode($body);
    is($data->{params}, [$pk], 'pubkey only');
};

subtest 'encode: unbanpubkey' => sub {
    my $pk = 'bb' x 32;
    my $body = encode_request(method => 'unbanpubkey', params => [$pk]);
    my $data = $JSON->decode($body);
    is($data->{method}, 'unbanpubkey', 'method name');
};

subtest 'encode: listbannedpubkeys' => sub {
    my $body = encode_request(method => 'listbannedpubkeys', params => []);
    my $data = $JSON->decode($body);
    is($data->{method}, 'listbannedpubkeys', 'method name');
    is($data->{params}, [], 'empty params');
};

subtest 'encode: allowpubkey' => sub {
    my $pk = 'cc' x 32;
    my $body = encode_request(method => 'allowpubkey', params => [$pk, 'trusted']);
    my $data = $JSON->decode($body);
    is($data->{method}, 'allowpubkey', 'method name');
    is($data->{params}, [$pk, 'trusted'], 'pubkey + reason');
};

subtest 'encode: unallowpubkey' => sub {
    my $pk = 'dd' x 32;
    my $body = encode_request(method => 'unallowpubkey', params => [$pk]);
    my $data = $JSON->decode($body);
    is($data->{method}, 'unallowpubkey', 'method name');
};

subtest 'encode: listallowedpubkeys' => sub {
    my $body = encode_request(method => 'listallowedpubkeys', params => []);
    my $data = $JSON->decode($body);
    is($data->{method}, 'listallowedpubkeys', 'method name');
};

subtest 'encode: listeventsneedingmoderation' => sub {
    my $body = encode_request(method => 'listeventsneedingmoderation', params => []);
    my $data = $JSON->decode($body);
    is($data->{method}, 'listeventsneedingmoderation', 'method name');
};

subtest 'encode: allowevent' => sub {
    my $id = 'ee' x 32;
    my $body = encode_request(method => 'allowevent', params => [$id, 'reviewed']);
    my $data = $JSON->decode($body);
    is($data->{method}, 'allowevent', 'method name');
    is($data->{params}, [$id, 'reviewed'], 'event id + reason');
};

subtest 'encode: banevent' => sub {
    my $id = 'ff' x 32;
    my $body = encode_request(method => 'banevent', params => [$id]);
    my $data = $JSON->decode($body);
    is($data->{method}, 'banevent', 'method name');
};

subtest 'encode: listbannedevents' => sub {
    my $body = encode_request(method => 'listbannedevents', params => []);
    my $data = $JSON->decode($body);
    is($data->{method}, 'listbannedevents', 'method name');
};

subtest 'encode: changerelayname' => sub {
    my $body = encode_request(method => 'changerelayname', params => ['My Relay']);
    my $data = $JSON->decode($body);
    is($data->{method}, 'changerelayname', 'method name');
    is($data->{params}, ['My Relay'], 'name param');
};

subtest 'encode: changerelaydescription' => sub {
    my $body = encode_request(method => 'changerelaydescription', params => ['A great relay']);
    my $data = $JSON->decode($body);
    is($data->{method}, 'changerelaydescription', 'method name');
};

subtest 'encode: changerelayicon' => sub {
    my $body = encode_request(method => 'changerelayicon', params => ['https://example.com/icon.png']);
    my $data = $JSON->decode($body);
    is($data->{method}, 'changerelayicon', 'method name');
    is($data->{params}, ['https://example.com/icon.png'], 'icon url param');
};

subtest 'encode: allowkind' => sub {
    my $body = encode_request(method => 'allowkind', params => [1]);
    my $data = $JSON->decode($body);
    is($data->{method}, 'allowkind', 'method name');
    is($data->{params}, [1], 'kind number');
};

subtest 'encode: disallowkind' => sub {
    my $body = encode_request(method => 'disallowkind', params => [30023]);
    my $data = $JSON->decode($body);
    is($data->{method}, 'disallowkind', 'method name');
    is($data->{params}, [30023], 'kind number');
};

subtest 'encode: listallowedkinds' => sub {
    my $body = encode_request(method => 'listallowedkinds', params => []);
    my $data = $JSON->decode($body);
    is($data->{method}, 'listallowedkinds', 'method name');
};

subtest 'encode: blockip' => sub {
    my $body = encode_request(method => 'blockip', params => ['192.168.1.1', 'abuse']);
    my $data = $JSON->decode($body);
    is($data->{method}, 'blockip', 'method name');
    is($data->{params}, ['192.168.1.1', 'abuse'], 'ip + reason');
};

subtest 'encode: unblockip' => sub {
    my $body = encode_request(method => 'unblockip', params => ['192.168.1.1']);
    my $data = $JSON->decode($body);
    is($data->{method}, 'unblockip', 'method name');
    is($data->{params}, ['192.168.1.1'], 'ip param');
};

subtest 'encode: listblockedips' => sub {
    my $body = encode_request(method => 'listblockedips', params => []);
    my $data = $JSON->decode($body);
    is($data->{method}, 'listblockedips', 'method name');
};

###############################################################################
# encode_request: params defaults to []
###############################################################################

subtest 'encode: params defaults to empty array' => sub {
    my $body = encode_request(method => 'supportedmethods');
    my $data = $JSON->decode($body);
    is($data->{params}, [], 'params defaults to []');
};

###############################################################################
# encode_request: validation
###############################################################################

subtest 'encode: missing method' => sub {
    like(
        dies { encode_request(params => []) },
        qr/method is required/,
        'missing method rejected'
    );
};

subtest 'encode: empty method' => sub {
    like(
        dies { encode_request(method => '') },
        qr/method is required/,
        'empty method rejected'
    );
};

subtest 'encode: params must be arrayref' => sub {
    like(
        dies { encode_request(method => 'supportedmethods', params => 'bad') },
        qr/params must be an array/i,
        'non-arrayref params rejected'
    );
};

subtest 'encode: banpubkey requires valid hex pubkey' => sub {
    like(
        dies { encode_request(method => 'banpubkey', params => ['not-hex']) },
        qr/must be 64-char lowercase hex/,
        'bad pubkey rejected'
    );
};

subtest 'encode: unbanpubkey requires valid hex pubkey' => sub {
    like(
        dies { encode_request(method => 'unbanpubkey', params => ['ZZ' x 32]) },
        qr/must be 64-char lowercase hex/,
        'uppercase hex rejected'
    );
};

subtest 'encode: allowpubkey requires valid hex pubkey' => sub {
    like(
        dies { encode_request(method => 'allowpubkey', params => []) },
        qr/requires a 64-char hex/,
        'missing pubkey rejected'
    );
};

subtest 'encode: unallowpubkey requires valid hex pubkey' => sub {
    like(
        dies { encode_request(method => 'unallowpubkey', params => ['short']) },
        qr/must be 64-char lowercase hex/,
        'short hex rejected'
    );
};

subtest 'encode: allowevent requires valid hex event id' => sub {
    like(
        dies { encode_request(method => 'allowevent', params => ['bad']) },
        qr/must be 64-char lowercase hex/,
        'bad event id rejected'
    );
};

subtest 'encode: banevent requires valid hex event id' => sub {
    like(
        dies { encode_request(method => 'banevent', params => []) },
        qr/requires a 64-char hex/,
        'missing event id rejected'
    );
};

subtest 'encode: allowkind requires non-negative integer' => sub {
    like(
        dies { encode_request(method => 'allowkind', params => []) },
        qr/requires a kind number/,
        'missing kind rejected'
    );
    like(
        dies { encode_request(method => 'allowkind', params => [-1]) },
        qr/must be a non-negative integer/,
        'negative kind rejected'
    );
    like(
        dies { encode_request(method => 'allowkind', params => ['abc']) },
        qr/must be a non-negative integer/,
        'non-numeric kind rejected'
    );
};

subtest 'encode: disallowkind requires non-negative integer' => sub {
    like(
        dies { encode_request(method => 'disallowkind', params => [1.5]) },
        qr/must be a non-negative integer/,
        'float kind rejected'
    );
};

subtest 'encode: changerelayname requires name' => sub {
    like(
        dies { encode_request(method => 'changerelayname', params => []) },
        qr/requires a string param/,
        'missing name rejected'
    );
};

subtest 'encode: changerelaydescription requires description' => sub {
    like(
        dies { encode_request(method => 'changerelaydescription', params => []) },
        qr/requires a string param/,
        'missing description rejected'
    );
};

subtest 'encode: changerelayicon requires url' => sub {
    like(
        dies { encode_request(method => 'changerelayicon', params => []) },
        qr/requires a string param/,
        'missing icon url rejected'
    );
};

subtest 'encode: blockip requires ip' => sub {
    like(
        dies { encode_request(method => 'blockip', params => []) },
        qr/requires an IP/,
        'missing ip rejected'
    );
};

subtest 'encode: unblockip requires ip' => sub {
    like(
        dies { encode_request(method => 'unblockip', params => []) },
        qr/requires an IP/,
        'missing ip rejected'
    );
};

###############################################################################
# encode_request: unknown methods pass through without param validation
###############################################################################

subtest 'encode: unknown method allowed' => sub {
    my $body = encode_request(method => 'custommethodxyz', params => ['anything']);
    my $data = $JSON->decode($body);
    is($data->{method}, 'custommethodxyz', 'unknown method passes through');
    is($data->{params}, ['anything'], 'params preserved');
};

###############################################################################
# decode_response
###############################################################################

subtest 'decode: result with object' => sub {
    my $json = '{"result":{"name":"My Relay"}}';
    my $result = decode_response($json);
    is($result, { name => 'My Relay' }, 'object result extracted');
};

subtest 'decode: result true (boolean)' => sub {
    my $json = '{"result":true}';
    my $result = decode_response($json);
    ok($result, 'true result is truthy');
};

subtest 'decode: result is array of objects' => sub {
    my $json = '{"result":[{"pubkey":"aa","reason":"spam"},{"pubkey":"bb"}]}';
    my $result = decode_response($json);
    is(scalar @$result, 2, 'two entries');
    is($result->[0]{pubkey}, 'aa', 'first pubkey');
    is($result->[0]{reason}, 'spam', 'first reason');
};

subtest 'decode: result is array of numbers' => sub {
    my $json = '{"result":[1,4,30023]}';
    my $result = decode_response($json);
    is($result, [1, 4, 30023], 'kind numbers extracted');
};

subtest 'decode: error takes precedence' => sub {
    my $json = '{"result":true,"error":"something went wrong"}';
    like(
        dies { decode_response($json) },
        qr/something went wrong/,
        'error field causes croak even when result present'
    );
};

subtest 'decode: missing result and no error' => sub {
    my $json = '{}';
    my $result = decode_response($json);
    is($result, undef, 'missing result returns undef');
};

subtest 'decode: invalid JSON' => sub {
    like(
        dies { decode_response('not json') },
        qr/invalid JSON/i,
        'malformed JSON rejected'
    );
};

subtest 'decode: undef input' => sub {
    like(
        dies { decode_response(undef) },
        qr/response is required/,
        'undef rejected'
    );
};

subtest 'decode: empty input' => sub {
    like(
        dies { decode_response('') },
        qr/response is required/,
        'empty string rejected'
    );
};

###############################################################################
# Authorization (spec lines 92-96)
###############################################################################

subtest 'auth: request_with_auth generates NIP-98 header' => sub {
    my $key = make_key_from_hex('01' x 32);
    my %req = request_with_auth(
        method    => 'supportedmethods',
        params    => [],
        key       => $key,
        relay_url => 'wss://relay.example.com',
    );

    ok(defined $req{body}, 'body present');
    ok(defined $req{authorization}, 'authorization present');
    is($req{content_type}, 'application/nostr+json+rpc', 'content type');

    # Verify body is valid JSON request
    my $data = $JSON->decode($req{body});
    is($data->{method}, 'supportedmethods', 'body has correct method');

    # Verify authorization is Nostr scheme
    like($req{authorization}, qr/\ANostr /, 'auth starts with Nostr');
};

subtest 'auth: payload tag is required (spec line 94)' => sub {
    my $key = make_key_from_hex('01' x 32);
    my %req = request_with_auth(
        method    => 'banpubkey',
        params    => ['aa' x 32],
        key       => $key,
        relay_url => 'wss://relay.example.com',
    );

    # Decode the NIP-98 event from the auth header
    my ($scheme, $b64) = split / /, $req{authorization}, 2;
    my $event_data = $JSON->decode(decode_base64($b64));
    my @payload_tags = grep { $_->[0] eq 'payload' } @{$event_data->{tags}};
    is(scalar @payload_tags, 1, 'payload tag present in auth event');

    # Payload tag should be SHA256 of the request body
    is($payload_tags[0][1], sha256_hex($req{body}), 'payload tag is SHA256 of body');
};

subtest 'auth: u tag is the relay URL (spec line 94)' => sub {
    my $key = make_key_from_hex('01' x 32);
    my %req = request_with_auth(
        method    => 'listbannedpubkeys',
        params    => [],
        key       => $key,
        relay_url => 'wss://relay.example.com',
    );

    my ($scheme, $b64) = split / /, $req{authorization}, 2;
    my $event_data = $JSON->decode(decode_base64($b64));
    my @u_tags = grep { $_->[0] eq 'u' } @{$event_data->{tags}};
    is($u_tags[0][1], 'wss://relay.example.com', 'u tag is relay URL');
};

subtest 'auth: method tag is POST' => sub {
    my $key = make_key_from_hex('01' x 32);
    my %req = request_with_auth(
        method    => 'supportedmethods',
        params    => [],
        key       => $key,
        relay_url => 'wss://relay.example.com',
    );

    my ($scheme, $b64) = split / /, $req{authorization}, 2;
    my $event_data = $JSON->decode(decode_base64($b64));
    my @method_tags = grep { $_->[0] eq 'method' } @{$event_data->{tags}};
    is($method_tags[0][1], 'POST', 'HTTP method is POST');
};

subtest 'auth: event kind is 27235' => sub {
    my $key = make_key_from_hex('01' x 32);
    my %req = request_with_auth(
        method    => 'supportedmethods',
        params    => [],
        key       => $key,
        relay_url => 'wss://relay.example.com',
    );

    my ($scheme, $b64) = split / /, $req{authorization}, 2;
    my $event_data = $JSON->decode(decode_base64($b64));
    is($event_data->{kind}, 27235, 'auth event kind is 27235');
};

subtest 'auth: event is signed' => sub {
    my $key = make_key_from_hex('01' x 32);
    my %req = request_with_auth(
        method    => 'supportedmethods',
        params    => [],
        key       => $key,
        relay_url => 'wss://relay.example.com',
    );

    my ($scheme, $b64) = split / /, $req{authorization}, 2;
    my $event_data = $JSON->decode(decode_base64($b64));
    like($event_data->{sig}, qr/\A[0-9a-f]{128}\z/, 'event has valid signature');
};

###############################################################################
# request_with_auth: validation
###############################################################################

subtest 'auth: missing key' => sub {
    like(
        dies { request_with_auth(method => 'supportedmethods', relay_url => 'wss://x') },
        qr/key is required/,
        'missing key rejected'
    );
};

subtest 'auth: missing relay_url' => sub {
    my $key = make_key_from_hex('01' x 32);
    like(
        dies { request_with_auth(method => 'supportedmethods', key => $key) },
        qr/relay_url is required/,
        'missing relay_url rejected'
    );
};

###############################################################################
# spec line 96: 401 for invalid/missing auth (informational — library provides
# the tools, server implements the response)
###############################################################################

subtest 'spec: 401 note is documented' => sub {
    # This is a server-side concern. The library provides request_with_auth
    # for clients and NIP-98 validate_auth_event for servers.
    # Just verify the round-trip works with NIP-98 validation.
    my $key = make_key_from_hex('01' x 32);
    my %req = request_with_auth(
        method    => 'supportedmethods',
        params    => [],
        key       => $key,
        relay_url => 'wss://relay.example.com',
    );

    require Net::Nostr::HttpAuth;
    my $event = Net::Nostr::HttpAuth::parse_auth_header($req{authorization});
    is(
        dies {
            Net::Nostr::HttpAuth::validate_auth_event($event,
                url     => 'wss://relay.example.com',
                method  => 'POST',
                payload => $req{body},
            )
        },
        undef,
        'auth header validates with NIP-98'
    );
};

done_testing;
