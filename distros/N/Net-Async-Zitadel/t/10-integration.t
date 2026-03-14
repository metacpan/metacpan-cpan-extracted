use strict;
use warnings;
use Test::More;

# Integration tests against a live Zitadel instance.
# Set ZITADEL_ISSUER, ZITADEL_TOKEN, ZITADEL_CLIENT_ID, ZITADEL_CLIENT_SECRET
# to run these tests.

BEGIN {
    plan skip_all => 'Set ZITADEL_ISSUER to run integration tests'
        unless $ENV{ZITADEL_ISSUER};
}

use IO::Async::Loop;
use Net::Async::Zitadel;

my $issuer        = $ENV{ZITADEL_ISSUER};
my $token         = $ENV{ZITADEL_TOKEN};
my $client_id     = $ENV{ZITADEL_CLIENT_ID};
my $client_secret = $ENV{ZITADEL_CLIENT_SECRET};

my $loop = IO::Async::Loop->new;
my $z = Net::Async::Zitadel->new(
    issuer   => $issuer,
    ($token ? (token => $token, base_url => $issuer) : ()),
);
$loop->add($z);

# --- OIDC discovery ---

subtest 'discovery document' => sub {
    my $doc = $z->oidc->discovery_f->get;
    ok ref $doc eq 'HASH', 'discovery returns hashref';
    ok $doc->{issuer},          'discovery has issuer';
    ok $doc->{jwks_uri},        'discovery has jwks_uri';
    ok $doc->{token_endpoint},  'discovery has token_endpoint';
    ok $doc->{userinfo_endpoint}, 'discovery has userinfo_endpoint';
};

subtest 'JWKS fetch' => sub {
    my $jwks = $z->oidc->jwks_f->get;
    ok ref $jwks eq 'HASH', 'JWKS returns hashref';
    ok ref $jwks->{keys} eq 'ARRAY', 'JWKS has keys array';
    ok scalar @{$jwks->{keys}} > 0, 'JWKS has at least one key';
};

# --- Token endpoint (client credentials) ---

SKIP: {
    skip 'ZITADEL_CLIENT_ID and ZITADEL_CLIENT_SECRET required', 3
        unless $client_id && $client_secret;

    subtest 'client credentials token' => sub {
        my $resp = $z->oidc->client_credentials_token_f(
            client_id     => $client_id,
            client_secret => $client_secret,
            scope         => 'openid',
        )->get;
        ok $resp->{access_token}, 'got access_token';
        ok $resp->{token_type},   'got token_type';

        # Verify the returned token
        my $claims = $z->oidc->verify_token_f(
            $resp->{access_token},
            verify_exp => 1,
        )->get;
        ok $claims->{sub}, 'verified token has sub';
        is $claims->{iss}, $issuer, 'verified token iss matches issuer';
    };
}

# --- Management API ---

SKIP: {
    skip 'ZITADEL_TOKEN required for Management API tests', 2
        unless $token;

    subtest 'list projects' => sub {
        my $resp = $z->management->list_projects_f->get;
        ok ref $resp eq 'HASH', 'list_projects returns hashref';
        ok exists $resp->{result} || exists $resp->{details}, 'has result or details';
    };

    subtest 'list orgs' => sub {
        my $resp = $z->management->list_orgs_f->get;
        ok ref $resp eq 'HASH', 'list_orgs returns hashref';
    };
}

done_testing;
