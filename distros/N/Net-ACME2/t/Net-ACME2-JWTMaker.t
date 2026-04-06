#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::FailWarnings;

use JSON ();
use MIME::Base64 ();

use FindBin;
use lib "$FindBin::Bin/lib";

use Net::ACME2::AccountKey ();

use Test::Crypt ();

#----------------------------------------------------------------------
# Test keys (same as in Net-ACME2.t)
#----------------------------------------------------------------------

my $_RSA_KEY = <<END;
-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQCkOYWppsEFfKHqIntkpUjmuwnBH3sRYP00YRdIhrz6ypRpxX6H
c2Q0IrSprutu9/dUy0j9a96q3kRa9Qxsa7paQj7xtlTWx9qMHvhlrG3eLMIjXT0J
4+MSCw5LwViZenh0obBWcBbnNYNLaZ9o31DopeKcYOZBMogF6YqHdpIsFQIDAQAB
AoGAN7RjSFaN5qSN73Ne05bVEZ6kAmQBRLXXbWr5kNpTQ+ZvTSl2b8+OT7jt+xig
N3XY6WRDD+MFFoRqP0gbvLMV9HiZ4tJ/gTGOHesgyeemY/CBLRjP0mvHOpgADQuA
+VBZmWpiMRN8tu6xHzKwAxIAfXewpn764v6aXShqbQEGSEkCQQDSh9lbnpB/R9+N
psqL2+gyn/7bL1+A4MJwiPqjdK3J/Fhk1Yo/UC1266MzpKoK9r7MrnGc0XjvRpMp
JX8f4MTbAkEAx7FvmEuvsD9li7ylgnPW/SNAswI6P7SBOShHYR7NzT2+FVYd6VtM
vb1WrhO85QhKgXNjOLLxYW9Uo8s1fNGtzwJAbwK9BQeGT+cZJPsm4DpzpIYi/3Zq
WG2reWVxK9Fxdgk+nuTOgfYIEyXLJ4cTNrbHAuyU8ciuiRTgshiYgLmncwJAETZx
KQ51EVsVlKrpFUqI4H72Z7esb6tObC/Vn0B5etR0mwA2SdQN1FkKrKyU3qUNTwU0
K0H5Xm2rPQcaEC0+rwJAEuvRdNQuB9+vzOW4zVig6HS38bHyJ+qLkQCDWbbwrNlj
vcVkUrsg027gA5jRttaXMk8x9shFuHB9V5/pkBFwag==
-----END RSA PRIVATE KEY-----
END

my $_P256_KEY = <<END;
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIKDv8TBijBVbTYB7lfUnwLn4qjqWD0GD7XOXzdp0wb61oAoGCCqGSM49
AwEHoUQDQgAEBJIULcFadtIBc0TuNzT80UFcfkQ0U7+EPqEJNXamG1H4/z8xVgE7
3hoBfX4xbN2Hx2p26eNIptt+1jj2H/M44g==
-----END EC PRIVATE KEY-----
END

my $_P384_KEY = <<END;
-----BEGIN EC PRIVATE KEY-----
MIGkAgEBBDBqmQFgqovKRpzWs0JST9p/vtRQCHQi3r+6N2zoOorRv/JQoGMHZB+i
c4d7oLnMpx+gBwYFK4EEACKhZANiAATXy7Zwmz5s98iSrQ+Y6lZ56g8/1INa4GY2
LeDDedG+NvKKcj0P3uJV994RSyitrijBQvN2ccSuL67IHUQ3I4O7S7eKRNsU8R7K
3ljffUl1vtb6GnjPgSZgt2zugJCwlH8=
-----END EC PRIVATE KEY-----
END

#----------------------------------------------------------------------
# Helper: build a JWTMaker from a PEM key
#----------------------------------------------------------------------

sub _make_jwt_maker {
    my ($key_pem) = @_;

    my $acct_key = Net::ACME2::AccountKey->new($key_pem);

    my $class;
    if ($acct_key->get_type() eq 'rsa') {
        require Net::ACME2::JWTMaker::RSA;
        $class = 'Net::ACME2::JWTMaker::RSA';
    }
    else {
        require Net::ACME2::JWTMaker::ECC;
        $class = 'Net::ACME2::JWTMaker::ECC';
    }

    return $class->new(key => $acct_key);
}

#----------------------------------------------------------------------
# Tests: constructor
#----------------------------------------------------------------------

{
    require Net::ACME2::JWTMaker;

    dies_ok(
        sub { Net::ACME2::JWTMaker->new() },
        'constructor dies without key',
    );
}

#----------------------------------------------------------------------
# Tests: create_full_jws (RSA)
#----------------------------------------------------------------------

{
    my $maker = _make_jwt_maker($_RSA_KEY);
    isa_ok($maker, 'Net::ACME2::JWTMaker::RSA', 'RSA key yields RSA maker');

    my $jws = $maker->create_full_jws(
        payload => { foo => 'bar' },
    );

    ok($jws, 'create_full_jws returns something');

    my (undef, $header, $payload) = Test::Crypt::decode_acme2_jwt_extract_key($jws);

    is($header->{'alg'}, 'RS256', 'RSA full JWS has RS256 algorithm');
    ok($header->{'jwk'}, 'RSA full JWS includes jwk header');
    ok(!$header->{'kid'}, 'RSA full JWS has no kid header');

    is_deeply($payload, { foo => 'bar' }, 'RSA full JWS payload round-trips');
}

#----------------------------------------------------------------------
# Tests: create_key_id_jws (RSA)
#----------------------------------------------------------------------

{
    my $maker = _make_jwt_maker($_RSA_KEY);

    my $jws = $maker->create_key_id_jws(
        payload => { action => 'test' },
        key_id  => 'https://acme.example/acct/123',
    );

    my $token_hr = JSON::decode_json($jws);
    my $header = JSON::decode_json(
        MIME::Base64::decode_base64url($token_hr->{'protected'})
    );

    is($header->{'alg'}, 'RS256', 'RSA kid JWS has RS256 algorithm');
    is(
        $header->{'kid'},
        'https://acme.example/acct/123',
        'RSA kid JWS includes the key_id',
    );
    ok(!$header->{'jwk'}, 'RSA kid JWS has no jwk header');
}

#----------------------------------------------------------------------
# Tests: create_full_jws (ECDSA P-256)
#----------------------------------------------------------------------

{
    my $maker = _make_jwt_maker($_P256_KEY);
    isa_ok($maker, 'Net::ACME2::JWTMaker::ECC', 'P-256 key yields ECC maker');

    my $jws = $maker->create_full_jws(
        payload => { hello => 'world' },
    );

    my (undef, $header, $payload) = Test::Crypt::decode_acme2_jwt_extract_key($jws);

    is($header->{'alg'}, 'ES256', 'P-256 full JWS has ES256 algorithm');
    ok($header->{'jwk'}, 'P-256 full JWS includes jwk header');
    is($header->{'jwk'}{'kty'}, 'EC', 'P-256 jwk is EC type');
    is($header->{'jwk'}{'crv'}, 'P-256', 'P-256 jwk has correct curve');

    is_deeply($payload, { hello => 'world' }, 'P-256 full JWS payload round-trips');
}

#----------------------------------------------------------------------
# Tests: create_full_jws (ECDSA P-384)
#----------------------------------------------------------------------

{
    my $maker = _make_jwt_maker($_P384_KEY);

    my $jws = $maker->create_full_jws(
        payload => { curve => '384' },
    );

    my (undef, $header, $payload) = Test::Crypt::decode_acme2_jwt_extract_key($jws);

    is($header->{'alg'}, 'ES384', 'P-384 full JWS has ES384 algorithm');
    ok($header->{'jwk'}, 'P-384 full JWS includes jwk header');
    is($header->{'jwk'}{'crv'}, 'P-384', 'P-384 jwk has correct curve');

    is_deeply($payload, { curve => '384' }, 'P-384 full JWS payload round-trips');
}

#----------------------------------------------------------------------
# Tests: create_key_id_jws (ECDSA P-256)
#----------------------------------------------------------------------

{
    my $maker = _make_jwt_maker($_P256_KEY);

    my $jws = $maker->create_key_id_jws(
        payload => { ecc => 'kid' },
        key_id  => 'https://acme.example/acct/456',
    );

    my $token_hr = JSON::decode_json($jws);
    my $header = JSON::decode_json(
        MIME::Base64::decode_base64url($token_hr->{'protected'})
    );

    is($header->{'alg'}, 'ES256', 'ECC kid JWS has ES256 algorithm');
    is(
        $header->{'kid'},
        'https://acme.example/acct/456',
        'ECC kid JWS includes the key_id',
    );
    ok(!$header->{'jwk'}, 'ECC kid JWS has no jwk header');
}

#----------------------------------------------------------------------
# Tests: payload encoding edge cases
#----------------------------------------------------------------------

{
    my $maker = _make_jwt_maker($_RSA_KEY);

    # String payload
    my $jws = $maker->create_full_jws(
        payload => 'plain-string',
    );

    my (undef, $header, $payload) = Test::Crypt::decode_acme2_jwt_extract_key($jws);
    is($payload, 'plain-string', 'string payload round-trips');

    # Array payload
    $jws = $maker->create_full_jws(
        payload => [1, 2, 3],
    );

    (undef, $header, $payload) = Test::Crypt::decode_acme2_jwt_extract_key($jws);
    is_deeply($payload, [1, 2, 3], 'array payload round-trips');

    # Empty-string payload (used by ACME POST-as-GET)
    $jws = $maker->create_full_jws(
        payload => '',
    );

    my $token_hr = JSON::decode_json($jws);
    my $raw_payload = MIME::Base64::decode_base64url($token_hr->{'payload'});
    is($raw_payload, '', 'empty-string payload encodes as empty');
}

#----------------------------------------------------------------------
# Tests: JWS structure is flattened JSON serialization (RFC 7515 A.7)
#----------------------------------------------------------------------

{
    my $maker = _make_jwt_maker($_RSA_KEY);

    my $jws = $maker->create_full_jws(
        payload => { test => 1 },
    );

    my $parsed = JSON::decode_json($jws);

    ok(exists $parsed->{'protected'}, 'JWS has "protected" field');
    ok(exists $parsed->{'payload'}, 'JWS has "payload" field');
    ok(exists $parsed->{'signature'}, 'JWS has "signature" field');

    # These should be base64url-encoded strings
    for my $field (qw(protected payload signature)) {
        ok(!ref($parsed->{$field}), "JWS '$field' is a scalar (base64url string)");
    }
}

#----------------------------------------------------------------------
# Tests: signature verification across all key types
#----------------------------------------------------------------------

for my $pair (
    ['RSA',   $_RSA_KEY],
    ['P-256', $_P256_KEY],
    ['P-384', $_P384_KEY],
) {
    my ($label, $key_pem) = @$pair;

    my $maker = _make_jwt_maker($key_pem);

    my $jws = $maker->create_full_jws(
        payload => { verify => $label },
    );

    lives_ok(
        sub { my @r = Test::Crypt::decode_acme2_jwt_extract_key($jws) },
        "$label: full JWS signature verifies",
    );
}

done_testing();
