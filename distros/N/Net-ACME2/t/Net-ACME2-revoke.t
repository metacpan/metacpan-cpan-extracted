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

# Use RSA key as "certificate key" when account uses P256 (just needs to be different)
my $_CERT_KEY = $_RSA_KEY;

my $FAKE_CERT_PEM = "-----BEGIN CERTIFICATE-----\n"
    . MIME::Base64::encode("fake-certificate-data-for-testing", "")
    . "\n-----END CERTIFICATE-----\n";

my $FAKE_CERT_DER = "fake-certificate-der-data";

#----------------------------------------------------------------------

for my $test_case (
    [ rsa => $_RSA_KEY ],
    [ p256 => $_P256_KEY ],
) {
    my ($alg, $key_pem) = @$test_case;

    subtest "$alg: revoke_certificate with PEM" => sub {
        my $SERVER_OBJ = Test::ACME2_Server->new(
            ca_class => 'MyCA',
        );

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

        lives_ok(
            sub { $acme->revoke_certificate($FAKE_CERT_PEM) },
            'revoke_certificate() with PEM succeeds',
        );
    };

    subtest "$alg: revoke_certificate with DER" => sub {
        my $SERVER_OBJ = Test::ACME2_Server->new(
            ca_class => 'MyCA',
        );

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

        lives_ok(
            sub { $acme->revoke_certificate($FAKE_CERT_DER) },
            'revoke_certificate() with DER succeeds',
        );
    };

    subtest "$alg: revoke_certificate with reason code" => sub {
        my $SERVER_OBJ = Test::ACME2_Server->new(
            ca_class => 'MyCA',
        );

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

        lives_ok(
            sub { $acme->revoke_certificate($FAKE_CERT_PEM, reason => 4) },
            'revoke_certificate() with reason code succeeds',
        );

        # Verify the server received the reason code
        is( $SERVER_OBJ->{'_last_revoke_reason'}, 4, 'reason code passed to server' );
    };
}

subtest 'revoke_certificate with certificate key' => sub {
    my $SERVER_OBJ = Test::ACME2_Server->new(
        ca_class => 'MyCA',
    );

    # We create an account with one key but revoke with a different key
    my $acme;
    my $ok = eval {
        $acme = MyCA->new( key => $_P256_KEY );
        $acme->create_account( termsOfServiceAgreed => 1 );
        1;
    };

    if (!$ok) {
        my $err = "$@";
        if ($err =~ /PKCS|marvin|disabled/i) {
            plan skip_all => "Signing unavailable with this crypto backend";
            return;
        }
        die $err;
    }

    lives_ok(
        sub { $acme->revoke_certificate($FAKE_CERT_PEM, key => $_CERT_KEY) },
        'revoke_certificate() with certificate key succeeds',
    );

    # The server should have seen the revoke signed by the cert key, not the account key
    ok( $SERVER_OBJ->{'_last_revoke_used_cert_key'}, 'revocation signed with certificate key' );
};

subtest 'revoke_certificate requires certificate argument' => sub {
    my $SERVER_OBJ = Test::ACME2_Server->new(
        ca_class => 'MyCA',
    );

    my $acme = MyCA->new( key => $_P256_KEY );
    $acme->create_account( termsOfServiceAgreed => 1 );

    throws_ok(
        sub { $acme->revoke_certificate() },
        qr/certificate/i,
        'revoke_certificate() dies without certificate',
    );
};

done_testing();
