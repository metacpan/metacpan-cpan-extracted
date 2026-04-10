use strictures 2;
use Test2::V0 -no_srand => 1;

use JSON ();
use MIME::Base64 qw(decode_base64);

use lib 't/lib';
use TestFixtures qw(make_key_from_hex);

use Net::Nostr::RelayAdmin qw(
    encode_request
    decode_response
    request_with_auth
);

###############################################################################
# POD example: encode a management request
###############################################################################

subtest 'POD: encode_request' => sub {
    my $body = encode_request(
        method => 'banpubkey',
        params => ['aa' x 32, 'spammer'],
    );
    my $data = JSON->new->utf8->decode($body);
    is($data->{method}, 'banpubkey', 'method is banpubkey');
    is($data->{params}[0], 'aa' x 32, 'pubkey in params');
    is($data->{params}[1], 'spammer', 'reason in params');
};

###############################################################################
# POD example: decode a response
###############################################################################

subtest 'POD: decode_response success' => sub {
    my $result = decode_response('{"result":true}');
    ok($result, 'result is true');
};

subtest 'POD: decode_response error' => sub {
    my $err = dies {
        decode_response('{"error":"not authorized"}');
    };
    like($err, qr/not authorized/, 'error message propagated');
};

###############################################################################
# POD example: request_with_auth
###############################################################################

subtest 'POD: request_with_auth' => sub {
    my $key = make_key_from_hex('01' x 32);
    my %req = request_with_auth(
        method    => 'supportedmethods',
        params    => [],
        key       => $key,
        relay_url => 'wss://relay.example.com',
    );
    ok(defined $req{body}, 'body present');
    like($req{authorization}, qr/\ANostr /, 'authorization header');
    is($req{content_type}, 'application/nostr+json+rpc', 'content type');
};

###############################################################################
# exports
###############################################################################

subtest 'exports: all functions available' => sub {
    ok(defined &encode_request, 'encode_request exported');
    ok(defined &decode_response, 'decode_response exported');
    ok(defined &request_with_auth, 'request_with_auth exported');
};

done_testing;
