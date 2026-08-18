use Test2::V0;

use Mojo::ATProto::OAuth::DPoP qw//;
use Crypt::PK::ECC;
use MIME::Base64 qw/decode_base64url/;
use Mojo::JSON qw/decode_json/;

subtest 'proof() produces a well-formed, independently-verifiable DPoP JWT' => sub {
    my $key = Mojo::ATProto::OAuth::DPoP->generate_keypair;

    my $jwt = Mojo::ATProto::OAuth::DPoP->proof(
        key    => $key,
        method => 'post',
        url    => 'https://auth.example.com/oauth/par',
        nonce  => 'server-nonce-1',
    );

    my @parts = split(/\./, $jwt);
    is(scalar(@parts), 3, 'three-part compact JWS');

    my $header = decode_json(decode_base64url($parts[0]));
    is($header->{typ}, 'dpop+jwt', 'typ header');
    is($header->{alg}, 'ES256', 'alg header');
    is($header->{jwk}{kty}, 'EC', 'jwk header present with EC key type');
    is($header->{jwk}{crv}, 'P-256', 'jwk header curve is P-256');
    ok(!exists($header->{jwk}{d}), 'jwk header carries only the public key, never the private scalar');

    my $claims = decode_json(decode_base64url($parts[1]));
    is($claims->{htm}, 'POST', 'method uppercased');
    is($claims->{htu}, 'https://auth.example.com/oauth/par', 'target URL');
    is($claims->{nonce}, 'server-nonce-1', 'nonce carried through');
    ok(!exists($claims->{ath}), 'no access-token-hash claim when no access token given');
    ok(length($claims->{jti}), 'jti present');
    ok($claims->{exp} > $claims->{iat}, 'expiry after issued-at');

    # Verify the signature independently, using only the public key
    # material embedded in the JWT's own header - proves proof() didn't
    # just fabricate a plausible-looking but unverifiable token.
    my $pub = Crypt::PK::ECC->new;
    $pub->import_key($header->{jwk});
    my $signing_input = "$parts[0].$parts[1]";
    my $sig            = decode_base64url($parts[2]);
    ok($pub->verify_message_rfc7518($sig, $signing_input, 'SHA256'), 'signature verifies against the embedded public key');

    ok(!$pub->verify_message_rfc7518($sig, $signing_input . 'x', 'SHA256'), 'signature rejects a tampered signing input');
};

subtest 'proof() includes ath and iss only when given (resource-server calls)' => sub {
    my $key = Mojo::ATProto::OAuth::DPoP->generate_keypair;
    my $jwt = Mojo::ATProto::OAuth::DPoP->proof(
        key          => $key,
        method       => 'GET',
        url          => 'https://pds.example.com/xrpc/com.atproto.repo.getRecord',
        access_token => 'opaque-access-token',
        issuer       => 'https://auth.example.com',
    );
    my @parts  = split(/\./, $jwt);
    my $claims = decode_json(decode_base64url($parts[1]));

    is($claims->{iss}, 'https://auth.example.com', 'iss set for resource-server proofs');
    is($claims->{ath}, Mojo::ATProto::OAuth::DPoP->s256_challenge('opaque-access-token'), 'ath matches S256(access_token)');
};

subtest 'client_assertion() produces a verifiable RFC 7523 JWT with no leftover DPoP-only claims' => sub {
    my $key = Mojo::ATProto::OAuth::DPoP->generate_keypair;
    my $jwt = Mojo::ATProto::OAuth::DPoP->client_assertion(
        key       => $key,
        key_id    => 'key-1',
        client_id => 'https://pib.example.com/oauth/client-metadata.json',
        audience  => 'https://auth.example.com',
    );

    my @parts  = split(/\./, $jwt);
    my $header = decode_json(decode_base64url($parts[0]));
    my $claims = decode_json(decode_base64url($parts[1]));

    is($header->{kid}, 'key-1', 'kid header');
    is($claims->{iss}, 'https://pib.example.com/oauth/client-metadata.json', 'iss is the client_id');
    is($claims->{sub}, $claims->{iss}, 'sub matches iss');
    is($claims->{aud}, 'https://auth.example.com', 'aud is the auth server');
    ok(!exists($claims->{htm}), 'no htm claim (unlike a DPoP proof)');
    ok(!exists($claims->{ath}), 'no ath claim (unlike a DPoP proof)');

    my $pub = $key->export_key_jwk('public');
    my $pk  = Crypt::PK::ECC->new;
    $pk->import_key(decode_json($pub));
    ok($pk->verify_message_rfc7518(decode_base64url($parts[2]), "$parts[0].$parts[1]", 'SHA256'), 'signature verifies');
};

subtest 'export_private_pem / import_private_pem round-trip to the same key' => sub {
    my $key = Mojo::ATProto::OAuth::DPoP->generate_keypair;
    my $pem = Mojo::ATProto::OAuth::DPoP->export_private_pem($key);
    like($pem, qr/BEGIN (EC )?PRIVATE KEY/, 'looks like a PEM private key');

    my $key2 = Mojo::ATProto::OAuth::DPoP->import_private_pem($pem);
    my $jwt  = Mojo::ATProto::OAuth::DPoP->proof(key => $key2, method => 'POST', url => 'https://auth.example.com/x');
    my @parts = split(/\./, $jwt);

    my $pub = Crypt::PK::ECC->new;
    $pub->import_key(decode_json($key->export_key_jwk('public')));
    ok($pub->verify_message_rfc7518(decode_base64url($parts[2]), "$parts[0].$parts[1]", 'SHA256'),
        'key restored from PEM signs verifiably against the original public key');
};

subtest 'secure_random_base64 / s256_challenge' => sub {
    my $a = Mojo::ATProto::OAuth::DPoP->secure_random_base64(32);
    my $b = Mojo::ATProto::OAuth::DPoP->secure_random_base64(32);
    isnt($a, $b, 'two calls produce different random values');
    unlike($a, qr/[+\/=]/, 'base64url alphabet, no padding');

    is(
        Mojo::ATProto::OAuth::DPoP->s256_challenge('verifier-value'),
        Mojo::ATProto::OAuth::DPoP->s256_challenge('verifier-value'),
        'deterministic for the same input',
    );
};

done_testing;
