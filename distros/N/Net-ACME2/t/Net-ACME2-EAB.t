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
use MIME::Base64 ();

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::ACME2_Server;

#----------------------------------------------------------------------

{
    package MyEABCA;

    use parent qw( Net::ACME2 );

    use constant {
        HOST => 'acme.eabca.net',
        DIRECTORY_PATH => '/acme-directory',
    };
}

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

# Known EAB credentials for testing
my $EAB_KID     = 'test-eab-key-id-001';
my $EAB_MAC_KEY = 'dGVzdC1obWFjLWtleS0xMjM0NTY3ODkw';  # base64url-encoded

my @alg_key = (
    [ rsa  => $_RSA_KEY ],
    [ p256 => $_P256_KEY ],
);

#----------------------------------------------------------------------
# Test: create_account with EAB succeeds
#----------------------------------------------------------------------

for my $t (@alg_key) {
    my ($alg, $key_pem) = @$t;

    lives_ok(
        sub {
            my $SERVER_OBJ = Test::ACME2_Server->new(
                ca_class => 'MyEABCA',
                eab_credentials => { $EAB_KID => $EAB_MAC_KEY },
            );

            my $acme = MyEABCA->new( key => $key_pem );

            my $created = $acme->create_account(
                termsOfServiceAgreed => 1,
                externalAccountBinding => {
                    kid     => $EAB_KID,
                    mac_key => $EAB_MAC_KEY,
                },
            );

            is( $created, 1, "[$alg] EAB account created" );

            my $key_id = $acme->key_id();
            ok( $key_id, "[$alg] key_id is set after EAB account creation" );

            # Second call should return 0 (account exists)
            $created = $acme->create_account(
                termsOfServiceAgreed => 1,
                externalAccountBinding => {
                    kid     => $EAB_KID,
                    mac_key => $EAB_MAC_KEY,
                },
            );

            is( $created, 0, "[$alg] EAB account already exists" );
        },
        "[$alg] EAB account creation - no errors",
    );
}

#----------------------------------------------------------------------
# Test: EAB with explicit HS384 algorithm
#----------------------------------------------------------------------

lives_ok(
    sub {
        my $SERVER_OBJ = Test::ACME2_Server->new(
            ca_class => 'MyEABCA',
            eab_credentials => { $EAB_KID => $EAB_MAC_KEY },
        );

        my $acme = MyEABCA->new( key => $_RSA_KEY );

        my $created = $acme->create_account(
            termsOfServiceAgreed => 1,
            externalAccountBinding => {
                kid       => $EAB_KID,
                mac_key   => $EAB_MAC_KEY,
                algorithm => 'HS384',
            },
        );

        is( $created, 1, 'EAB with HS384 creates account' );
    },
    'EAB with HS384 - no errors',
);

#----------------------------------------------------------------------
# Test: server requires EAB but client omits it
#----------------------------------------------------------------------

throws_ok(
    sub {
        my $SERVER_OBJ = Test::ACME2_Server->new(
            ca_class => 'MyEABCA',
            eab_credentials => { $EAB_KID => $EAB_MAC_KEY },
        );

        my $acme = MyEABCA->new( key => $_RSA_KEY );

        $acme->create_account(
            termsOfServiceAgreed => 1,
        );
    },
    qr/externalAccountBinding/,
    'Server rejects missing EAB',
);

#----------------------------------------------------------------------
# Test: EAB with wrong MAC key fails
#----------------------------------------------------------------------

throws_ok(
    sub {
        my $SERVER_OBJ = Test::ACME2_Server->new(
            ca_class => 'MyEABCA',
            eab_credentials => { $EAB_KID => $EAB_MAC_KEY },
        );

        my $acme = MyEABCA->new( key => $_RSA_KEY );

        $acme->create_account(
            termsOfServiceAgreed => 1,
            externalAccountBinding => {
                kid     => $EAB_KID,
                mac_key => 'd3Jvbmcta2V5LXZhbHVlLWhlcmU',  # wrong key
            },
        );
    },
    qr/HMAC verification failed/,
    'Wrong MAC key is rejected',
);

#----------------------------------------------------------------------
# Test: EAB with unknown kid fails
#----------------------------------------------------------------------

throws_ok(
    sub {
        my $SERVER_OBJ = Test::ACME2_Server->new(
            ca_class => 'MyEABCA',
            eab_credentials => { $EAB_KID => $EAB_MAC_KEY },
        );

        my $acme = MyEABCA->new( key => $_RSA_KEY );

        $acme->create_account(
            termsOfServiceAgreed => 1,
            externalAccountBinding => {
                kid     => 'unknown-kid',
                mac_key => $EAB_MAC_KEY,
            },
        );
    },
    qr/Unknown EAB kid/,
    'Unknown EAB kid is rejected',
);

#----------------------------------------------------------------------
# Test: missing required EAB fields
#----------------------------------------------------------------------

throws_ok(
    sub {
        my $acme = MyEABCA->new( key => $_RSA_KEY );

        $acme->create_account(
            termsOfServiceAgreed => 1,
            externalAccountBinding => {
                mac_key => $EAB_MAC_KEY,
            },
        );
    },
    qr/EAB requires "kid"/,
    'Missing kid is caught',
);

throws_ok(
    sub {
        my $acme = MyEABCA->new( key => $_RSA_KEY );

        $acme->create_account(
            termsOfServiceAgreed => 1,
            externalAccountBinding => {
                kid => $EAB_KID,
            },
        );
    },
    qr/EAB requires "mac_key"/,
    'Missing mac_key is caught',
);

#----------------------------------------------------------------------
# Test: unsupported algorithm
#----------------------------------------------------------------------

throws_ok(
    sub {
        my $acme = MyEABCA->new( key => $_RSA_KEY );

        $acme->create_account(
            termsOfServiceAgreed => 1,
            externalAccountBinding => {
                kid       => $EAB_KID,
                mac_key   => $EAB_MAC_KEY,
                algorithm => 'RS256',
            },
        );
    },
    qr/Unsupported EAB algorithm/,
    'Unsupported algorithm is caught',
);

done_testing();
