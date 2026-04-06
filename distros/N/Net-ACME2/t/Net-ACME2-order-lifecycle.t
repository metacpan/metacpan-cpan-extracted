#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::FailWarnings;

use Digest::MD5;
use HTTP::Status;
use URI;
use JSON;

use Crypt::Format ();

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::ACME2_Server;

#----------------------------------------------------------------------

{
    package MyCA;

    use parent qw( Net::ACME2 );

    use constant {
        HOST => 'acme.someca.net',
        DIRECTORY_PATH => '/acme-directory',
    };
}

my $_RSA_KEY  = <<END;
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

for my $test_case (
    [ rsa => $_RSA_KEY ],
    [ p256 => $_P256_KEY ],
) {
    my ($alg, $key_pem) = @$test_case;

    subtest "$alg: full order lifecycle" => sub {
        my $SERVER_OBJ = Test::ACME2_Server->new(
            ca_class => 'MyCA',
        );

        # Setup: create account
        my $acme;
        my $ok = eval {
            $acme = MyCA->new( key => $key_pem );
            $acme->create_account( termsOfServiceAgreed => 1 );
            1;
        };

        if (!$ok) {
            my $err = "$@";
            if ($err =~ /PKCS|marvin|disabled/i) {
                plan skip_all => "RSA signing unavailable with this crypto backend";
                return;
            }
            die $err;
        }

        ok( $acme->key_id(), 'account created with key_id' );

        # 1. create_order
        my $order = $acme->create_order(
            identifiers => [
                { type => 'dns', value => 'example.com' },
            ],
        );

        isa_ok( $order, 'Net::ACME2::Order', 'create_order() returns Order' );
        is( $order->status(), 'pending', 'new order is pending' );
        is( $order->finalize(), 'https://acme.someca.net/finalize/1', 'finalize URL present' );

        my @authz_urls = $order->authorizations();
        is( scalar @authz_urls, 1, 'one authorization URL' );

        # 2. get_authorization
        my $authz = $acme->get_authorization( $authz_urls[0] );

        isa_ok( $authz, 'Net::ACME2::Authorization', 'get_authorization() returns Authorization' );
        is( $authz->status(), 'pending', 'authorization is pending' );

        my $ident = $authz->identifier();
        is( $ident->{'type'}, 'dns', 'identifier type is dns' );
        is( $ident->{'value'}, 'example.com', 'identifier value is example.com' );

        # 3. challenges
        my @challenges = $authz->challenges();
        ok( scalar @challenges >= 1, 'at least one challenge' );

        my ($http_challenge) = grep { $_->type() eq 'http-01' } @challenges;
        ok( $http_challenge, 'http-01 challenge found' );
        isa_ok( $http_challenge, 'Net::ACME2::Challenge::http_01' );
        is( $http_challenge->token(), 'test-token-abc123', 'challenge token' );
        is( $http_challenge->status(), 'pending', 'challenge is pending' );

        # 4. make_key_authorization
        my $key_authz = $acme->make_key_authorization($http_challenge);
        like( $key_authz, qr/\Atest-token-abc123\./, 'key authorization starts with token' );

        # 5. http-01 path
        my $path = $http_challenge->get_path();
        is( $path, '/.well-known/acme-challenge/test-token-abc123', 'challenge path' );

        # 6. accept_challenge
        lives_ok(
            sub { $acme->accept_challenge($http_challenge) },
            'accept_challenge() succeeds',
        );

        # 7. poll_authorization
        my $authz_status = $acme->poll_authorization($authz);
        is( $authz_status, 'valid', 'authorization becomes valid after challenge accepted' );
        is( $authz->status(), 'valid', 'authorization object updated' );

        # 8. finalize_order (PEM CSR)
        my $fake_csr_pem = "-----BEGIN CERTIFICATE REQUEST-----\n"
            . MIME::Base64::encode("fake-csr-data-for-testing", "")
            . "\n-----END CERTIFICATE REQUEST-----\n";

        my $order_status = $acme->finalize_order($order, $fake_csr_pem);
        is( $order_status, 'valid', 'finalize_order() returns valid' );
        is( $order->status(), 'valid', 'order object updated to valid' );
        ok( $order->certificate(), 'certificate URL present after finalize' );

        # 9. get_certificate_chain
        my $cert_chain = $acme->get_certificate_chain($order);
        like( $cert_chain, qr/-----BEGIN CERTIFICATE-----/, 'certificate chain is PEM' );

        # 9b. get_certificate_chains (alternate chains)
        my $chains = $acme->get_certificate_chains($order);
        is( ref $chains, 'HASH', 'get_certificate_chains() returns hashref' );
        like( $chains->{'default'}, qr/-----BEGIN CERTIFICATE-----/, 'default chain is PEM' );
        is( $chains->{'default'}, $cert_chain, 'default chain matches get_certificate_chain()' );
        is( ref $chains->{'alternates'}, 'ARRAY', 'alternates is arrayref' );
        is( scalar @{ $chains->{'alternates'} }, 2, 'two alternate chains' );
        like( $chains->{'alternates'}[0], qr/ALTERNATE-CHAIN-1/, 'first alternate chain content' );
        like( $chains->{'alternates'}[1], qr/ALTERNATE-CHAIN-2/, 'second alternate chain content' );

        # 10. poll_order (after finalize)
        my $poll_status = $acme->poll_order($order);
        is( $poll_status, 'valid', 'poll_order() returns valid' );
    };
}

# Test error cases
# Use P256 key for remaining tests to avoid CORSA 0.35+ PKCS#1 issues

subtest 'create_order without key_id fails' => sub {
    my $SERVER_OBJ = Test::ACME2_Server->new(
        ca_class => 'MyCA',
    );

    my $acme = MyCA->new( key => $_P256_KEY );

    # Don't create an account — key_id is not set
    throws_ok(
        sub {
            $acme->create_order(
                identifiers => [
                    { type => 'dns', value => 'example.com' },
                ],
            );
        },
        qr/key.?id/i,
        'create_order() dies without key_id',
    );
};

subtest 'make_key_authorization requires challenge object' => sub {
    my $SERVER_OBJ = Test::ACME2_Server->new(
        ca_class => 'MyCA',
    );

    my $acme = MyCA->new( key => $_P256_KEY );

    throws_ok(
        sub { $acme->make_key_authorization(undef) },
        qr/challenge/i,
        'make_key_authorization() dies without challenge',
    );
};

subtest 'finalize_order with DER CSR' => sub {
    my $SERVER_OBJ = Test::ACME2_Server->new(
        ca_class => 'MyCA',
    );

    my $acme = MyCA->new( key => $_P256_KEY );
    $acme->create_account( termsOfServiceAgreed => 1 );

    my $order = $acme->create_order(
        identifiers => [
            { type => 'dns', value => 'example.com' },
        ],
    );

    # DER CSR (doesn't start with -----)
    my $fake_csr_der = "fake-csr-der-data";

    lives_ok(
        sub { $acme->finalize_order($order, $fake_csr_der) },
        'finalize_order() accepts DER CSR',
    );
};

subtest 'deactivate_authorization' => sub {
    my $SERVER_OBJ = Test::ACME2_Server->new(
        ca_class => 'MyCA',
    );

    my $acme = MyCA->new( key => $_P256_KEY );
    $acme->create_account( termsOfServiceAgreed => 1 );

    my $order = $acme->create_order(
        identifiers => [
            { type => 'dns', value => 'example.com' },
        ],
    );

    my @authz_urls = $order->authorizations();
    my $authz = $acme->get_authorization( $authz_urls[0] );
    is( $authz->status(), 'pending', 'authorization starts as pending' );

    my $status = $acme->deactivate_authorization($authz);
    is( $status, 'deactivated', 'deactivate_authorization() returns deactivated' );
    is( $authz->status(), 'deactivated', 'authorization object updated to deactivated' );
};

subtest 'Order identifiers() returns copies' => sub {
    my $SERVER_OBJ = Test::ACME2_Server->new(
        ca_class => 'MyCA',
    );

    my $acme = MyCA->new( key => $_P256_KEY );
    $acme->create_account( termsOfServiceAgreed => 1 );

    my $order = $acme->create_order(
        identifiers => [
            { type => 'dns', value => 'example.com' },
        ],
    );

    my @idents = $order->identifiers();
    is( scalar @idents, 1, 'one identifier' );
    is( $idents[0]{'type'}, 'dns', 'identifier type' );
    is( $idents[0]{'value'}, 'example.com', 'identifier value' );

    # Modifying returned hash should not affect internal state
    $idents[0]{'value'} = 'hacked.com';
    my @idents2 = $order->identifiers();
    is( $idents2[0]{'value'}, 'example.com', 'identifiers() returns defensive copies' );
};

subtest 'retry_after exposed from poll responses' => sub {
    my $SERVER_OBJ = Test::ACME2_Server->new(
        ca_class => 'MyCA',
    );

    my $acme = MyCA->new( key => $_P256_KEY );
    $acme->create_account( termsOfServiceAgreed => 1 );

    my $order = $acme->create_order(
        identifiers => [
            { type => 'dns', value => 'example.com' },
        ],
    );

    my @authz_urls = $order->authorizations();
    my $authz = $acme->get_authorization( $authz_urls[0] );

    # Before polling, retry_after should be undef
    is( $order->retry_after(), undef, 'Order retry_after undef before poll' );
    is( $authz->retry_after(), undef, 'Authorization retry_after undef before poll' );

    # Set Retry-After on the mock server
    $SERVER_OBJ->set_retry_after( authz => 10, order => 30 );

    # Poll authorization — should pick up Retry-After
    $acme->poll_authorization($authz);
    is( $authz->retry_after(), 10, 'Authorization retry_after set from header' );

    # Poll order — should pick up Retry-After
    $acme->poll_order($order);
    is( $order->retry_after(), 30, 'Order retry_after set from header' );

    # retry_after_seconds() should parse delay-seconds
    is( $authz->retry_after_seconds(), 10, 'Authorization retry_after_seconds parses integer' );
    is( $order->retry_after_seconds(), 30, 'Order retry_after_seconds parses integer' );

    # Clear Retry-After and poll again — should become undef
    $SERVER_OBJ->set_retry_after( authz => undef, order => undef );

    $acme->poll_authorization($authz);
    is( $authz->retry_after(), undef, 'Authorization retry_after cleared when header absent' );
    is( $authz->retry_after_seconds(), undef, 'Authorization retry_after_seconds undef when header absent' );

    $acme->poll_order($order);
    is( $order->retry_after(), undef, 'Order retry_after cleared when header absent' );
    is( $order->retry_after_seconds(), undef, 'Order retry_after_seconds undef when header absent' );
};

done_testing();
