package t::Net::ACME::Utils;

use strict;
use warnings;

BEGIN {
    if ( $^V ge v5.10.1 ) {
        require autodie;
    }
}

use parent qw(
  Test::Class
);

use Test::More;
use Test::NoWarnings;
use Test::Deep;
use Test::Exception;

use MIME::Base64        ();

use Net::ACME::Utils ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(+1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub test_verify_token : Tests(3) {
    throws_ok(
        sub { Net::ACME::Utils::verify_token('invalid/token') },
        'Net::ACME::X::InvalidParameter',
        'invalid token exception',
    );
    my $err = $@;

    like( $err->to_string(), qr<invalid/token>, '… and the invalid token is in the message' );

    lives_ok(
        sub { Net::ACME::Utils::verify_token('valid_-token') },
        'valid token',
    );

    return;
}

sub test_get_jwk_data : Tests(1) {
    is_deeply(
        Net::ACME::Utils::get_jwk_data(_KEY()),
        {
            kty => 'RSA',
            e => 'AQAB',
            n => 'rj9dEQ06QEcx5CJRpsJLb3Hv3zr3sgxghCm6b-UOa6IKAl6U3073C0OYnRgimjlwpLt5mZQnPLliaXxzQ0QKf3K4GfksdN6BSSZRynDhUORvgLPd2McpHHyEW3mKXPjnyjeUDqAxlnX-W9nKjXreB0vZ0SbhvkRpmJKtTAtyQFMXaedmrrMfdR17GJphtamnQPb61wdnnT0h8d8JcSDHPcl3TKarkWTCR0Qkxsl05scODcOZuFVEF6QYhQnR7epSnykSMNEyiSDLayul22bdhcvugGQGPNJXwN0JomQjgsDwXmluixRqKP6pahh9AZhdmw_nrqFf_Or6tfBxyNX1Qw',
        },
        'structure as expected',
    );

    return;
}

sub _KEY {
    return <<END;
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEArj9dEQ06QEcx5CJRpsJLb3Hv3zr3sgxghCm6b+UOa6IKAl6U
3073C0OYnRgimjlwpLt5mZQnPLliaXxzQ0QKf3K4GfksdN6BSSZRynDhUORvgLPd
2McpHHyEW3mKXPjnyjeUDqAxlnX+W9nKjXreB0vZ0SbhvkRpmJKtTAtyQFMXaedm
rrMfdR17GJphtamnQPb61wdnnT0h8d8JcSDHPcl3TKarkWTCR0Qkxsl05scODcOZ
uFVEF6QYhQnR7epSnykSMNEyiSDLayul22bdhcvugGQGPNJXwN0JomQjgsDwXmlu
ixRqKP6pahh9AZhdmw/nrqFf/Or6tfBxyNX1QwIDAQABAoIBAGeTKpL0Nef3aeSd
scNaQtTf+SHMP2gKi2SEGVph4YyBKUn3Rq7mlVqQt6rJqefatOZ2ufVcZ2ZlG+Zw
H2OgkkznuB9YSeC+UkNVD9Ex//zBjLYINJqi6AES0uo8+M4C9mTxXITFHDS/to6K
iyhGHKxhnfwBDLa4m7whk/lb5HHu9w9NbTPOiygzDhJ6FOSAXGwb9HhR/0/tOEf8
EtTEQLSfijsjRj+xER3tWiqcKxLd9nE9JcNkE0blR7NPi94I2Ht0ov/7DOjL10vk
yELRs7hsk6bFEWAfQOFJks1uRFcF/ePU/P7A+xKVZOF3yAeTRiT1jX0tOCc1EJRr
+RTNV4ECgYEA2Uey2EJlHJ5r/nQcVUzbWSw6HrymSi0GytexvN6qx+4enzPhUwjX
DSxQr7efv0YmWQlBM9mP8e0DuszVAMAE08eHddalEEKQZQwgqfe5af8eZOi2ORs4
wvWHhHqqmNM8FFBnO87PS2iG9ICPZOYJzFJ8pfozwakp9EaxpDWcwlECgYEAzUyF
zaII/Z2wydxm3kliwzwjWGh1g/D79SBMnRSwKKCMR+0nBAfPE1jxkGWg9VMupKxF
DYTptaqBJcCs5bLEkZvL/nlcSLuwmYaTni6h69mHlHPzkEVsd76fLFCXsy8YokQW
HhpBiIDnouMyPDPgR5Np5IC0qTTwUK7T40GJZVMCgYEAyp27v0Ma+vcYie5IxZqo
KZ2+jQ8qmp0mal19lzylUU9SKu+8PSxPLi+XBmVbiIioFfs1XF6ThuyYv8dnEg39
8mdsgIyq3GDWOgR3KUijFJ8c/sirtNEXu2Yu+3FQSLcinWbk/ba7Q/yzbKm+Dj8d
//Uj27tYLE3Nm8eYvCJqjiECgYBSjj0YLdqTsf/PjNPI+5W9kMdd29O11Qhc0Do+
yHz2OWlv2wvfcQxyaUfqmxOY03RkP+ocv6ADr6bzeYGNdM/bBd2IXWEg1mjzs8xU
xcfTQcxlhCMjludBV+RGO7plEcFEL0D9pe1IaR28wMQItYuw/LSOcLs1d9ZTe5o1
PrtzhQKBgQC5af0s3w3TFP/x0do2e8hFIffzZ9yvFMXADJO/A2Dqf7XHbacVPTFP
yE9lohBoSgGms/b8XtrIRgVltsm2Ix1xGwpuywFMqyEZKi4tlZ3qDViNvoEgAGjE
xJpmKvnVPaSeykev88WqCwZ5xL7srvn9q9GJwWWUgpb9me952kVQjg==
-----END RSA PRIVATE KEY-----
END
}

sub test_get_jwk_thumbprint : Tests(1) {
    my $pem        = _KEY();

    my $jwk_data = Net::ACME::Utils::get_jwk_data($pem);

    is(
        Net::ACME::Utils::get_jwk_thumbprint($jwk_data),
        'xCY5xfEI-z-K6_1vHT2-wo2fItyITs5_5wTsVpYgfdg',
        'get_jwk_thumbprint()',
    );

    return;
}

1;
