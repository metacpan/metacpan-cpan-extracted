use Test2::V0;

use Mojo::ATProto::OAuth::ClientMetadata qw//;
use Mojo::ATProto::OAuth::DPoP           qw//;

subtest 'public client metadata document' => sub {
    my $doc = Mojo::ATProto::OAuth::ClientMetadata->build(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        scopes       => ['atproto', 'transition:generic'],
    );

    is($doc->{client_id}, 'https://pib.example.com/oauth/client-metadata.json');
    is($doc->{redirect_uris}, ['https://pib.example.com/oauth/callback']);
    is($doc->{scope}, 'atproto transition:generic');
    is($doc->{token_endpoint_auth_method}, 'none');
    ok(!exists($doc->{jwks}), 'no jwks on a public client doc');
    ok(!exists($doc->{token_endpoint_auth_signing_alg}), 'no signing alg declared for a public client');
    ok($doc->{dpop_bound_access_tokens}, 'dpop_bound_access_tokens is true');
    is($doc->{grant_types}, ['authorization_code', 'refresh_token']);
    is($doc->{response_types}, ['code']);
};

subtest 'confidential client metadata document' => sub {
    my $key = Mojo::ATProto::OAuth::DPoP->generate_keypair;
    my $doc = Mojo::ATProto::OAuth::ClientMetadata->build(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        scopes       => ['atproto'],
        private_key  => $key,
        key_id       => 'key-1',
    );

    is($doc->{token_endpoint_auth_method}, 'private_key_jwt');
    is($doc->{token_endpoint_auth_signing_alg}, 'ES256');
    is(scalar(@{$doc->{jwks}{keys}}), 1, 'one public key exposed');
    is($doc->{jwks}{keys}[0]{kid}, 'key-1');
    ok(!exists($doc->{jwks}{keys}[0]{d}), 'jwks never leaks the private scalar');
};

subtest 'public_jwks on a public client is empty' => sub {
    my $jwks = Mojo::ATProto::OAuth::ClientMetadata->public_jwks(
        client_id    => 'https://pib.example.com/oauth/client-metadata.json',
        callback_url => 'https://pib.example.com/oauth/callback',
        scopes       => ['atproto'],
    );
    is($jwks, {keys => []});
};

done_testing;
