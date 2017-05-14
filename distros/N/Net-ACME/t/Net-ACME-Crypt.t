package t::Net::ACME::Crypt;

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

use Net::ACME::Crypt ();

if ( !caller ) {
    my $test_obj = __PACKAGE__->new();
    plan tests => $test_obj->expected_tests(1);
    $test_obj->runtests();
}

#----------------------------------------------------------------------

sub _KEY {
    return <<END;
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEAuZA++KaL/kv59vWGmCkgOv96/fS9eCpnrCktib0WqDqtBTx7
7cLD0AMh3hfeh+6bxWlXhoYJNHShifuvhX9Q45jLzNHq/XBA7om+G2QMtDjuUiOp
rWOyfrpfBNlndG0oIZhe08vxbHAcZFR9mkN/T6YDUO+ATSfshyKUgIxSTzlJMQF0
DPZ/imtkQ9B79JzwbH4D9uwXDtJOQdW2ibSgm0w9OjVTnIlz0pWTsmbiWOh2oc/+
MNlbMpDvEiBuGu2in/obGEVwETD/Vqths0Zieb0JQQZtGTHPb2Kig/pQ8k5MO2V7
ERMV/qQ8EGNLzHIP+8cjpD9oEwOueWkdKpBz0wIDAQABAoIBAFrAC7vpH5/vIkE/
1GJIAqY32bunXJ4PBwKwZL/vBMyjXYipCua9kKwDTCXkwIT0EaRbH13/4TKRM4ta
1n1QRYv5Zvo1U1o88tR18s5MgNYG3a64GDxe/KVzmhKyDCFpXO4JKZ8lJ13j+k6q
735pMjMOuqJzbujM9KUmKUAw3/Qz9p+EoPgKoXM7VSApGo4pLpoPBRgjIiBOrt7G
azA86bUHsaOBuItEjEOb7pNd1xMQnXnnMklxW3nyhJpXz5l2ZA1uAk7rWcoL0lMR
U3NqxV0MRZhxXUL66GgNT7c2VIgvyMnjB7TtQdzZmolUP83YMQEQrKsQSSU8rzMf
HxyiEQkCgYEA8a0rDkfiltKk0Yy55hrO7CKpzIR9K2WphdOzs13fDTbM4wqcOtZF
orMHONWt+r7EnE6V/lxCnwiyhEnGk6wAGPUSOgbTwy1M2hdSIUgNKqUR6I7f+DLF
ustR+ypVMIup5ihBZmOZvA5mKv6t1C3HMVLHtsgT1e8ne0jvB27wV4UCgYEAxI+0
Xi0z+Vk1SCRgT2SaBYIuo6Y4jp0Rb0niYtZm0RQmewcp4bHAu8m7NcA+jVrNsJhw
Weffd73+J3WC/wNIlJ6c5ZLTFyZRAk/giS9XVv+ecmBBzrK+QjFOY6FCLquJsILB
qjUpfQBv2Sac/kKtmDnyADIAdDMZ6gL0crDTQXcCgYAzRsuY1xWzbHP95f7XXJ7E
qUIfm4i3OXWzaEx7ZRJbSmJEVc76CNZzg8qne2bTicBLbb0TX93ewkimGsUgNeE7
alv4pdQuWCEzMLmDSDdK8gUPs6i/j342eMcnJD848pkUtTvTDpTiuqdgvfKBz0ix
JWAsXt0eigR1eu8EQ7yIxQKBgE963DAIjy+QRt849kikITOBBGLf35arJFWfxo64
qzJ3t2ef6et8+LX2SGDfr2txACMcQLHZ9J5ykMZb2fBL35lY2ZBq4jhGIhORQPW3
0tU231bYXUO7OvuA/HWEy0Ib0r0w4iZ1AKWu+4sO9gRJ6e/X3mb90PkrgJsDPtzx
azrZAoGAAionNpUU5btdqhX7H3EHUnwpvhUaq3YRpMdF7wtRdBOUelhFhNyr7MIa
ykZ2TU6LFaR/E3EdTCmAKu8Z6JvOf+gyYryJ8CYCQOFc7ZPILTc1YvGlP9175YfZ
cFzYacYxItcSjm+jhZBOyu24E/B/uMYlS04weqxKs0UOOeyEy04=
-----END RSA PRIVATE KEY-----
END
}

sub test_get_rsa_public_jwk : Tests(1) {
    my ($self) = @_;

    is_deeply(
        Net::ACME::Crypt::get_rsa_public_jwk( _KEY() ),
        {
            e => "AQAB",
            kty => "RSA",
            n => "uZA--KaL_kv59vWGmCkgOv96_fS9eCpnrCktib0WqDqtBTx77cLD0AMh3hfeh-6bxWlXhoYJNHShifuvhX9Q45jLzNHq_XBA7om-G2QMtDjuUiOprWOyfrpfBNlndG0oIZhe08vxbHAcZFR9mkN_T6YDUO-ATSfshyKUgIxSTzlJMQF0DPZ_imtkQ9B79JzwbH4D9uwXDtJOQdW2ibSgm0w9OjVTnIlz0pWTsmbiWOh2oc_-MNlbMpDvEiBuGu2in_obGEVwETD_Vqths0Zieb0JQQZtGTHPb2Kig_pQ8k5MO2V7ERMV_qQ8EGNLzHIP-8cjpD9oEwOueWkdKpBz0w",
        },
        'get_rsa_public_jwk() - PEM',
    );

    return;
}

sub test_get_rsa_jwk_thumbprint : Tests(1) {
    my ($self) = @_;

    is(
        Net::ACME::Crypt::get_rsa_jwk_thumbprint( _KEY() ),
        'pBHLu_XpB5-lyvs2mXRHvQl0lrdQdYSpzSCEYfQe4yA',
        'get_rsa_jwk_thumbprint() - PEM',
    );

    return;
}

sub test_create_rs256_jwt : Tests(3) {
    my $str = Net::ACME::Crypt::create_rs256_jwt(
        key => _KEY(),
        extra_headers => { foo => 123 },
        payload => 'Just the facts, ma’am.',
    );

    is(
        $str,
        'eyJhbGciOiJSUzI1NiIsImZvbyI6MTIzfQ.SnVzdCB0aGUgZmFjdHMsIG1h4oCZYW0u.B7aFWFZxNoWYaJR7294nNDU_H29z4pJd8lMaEOl3ZlGkSy06bQ5dq0-ywTRguWuSMjxhEZAHBswDu0QNDz3vctrBt2e6_isd0w5pZ6egweS15dcwLiY28fllY1GAH2PxbBxxu5mCQ2UXhohA3RU9JJq4OPlOe90zA6SaWxdJFJOT0hefchy8xvddxvn-vJxnJjJf-se1MagxuvsK7svpF6ztcqtt3iOWcKY1Z8MHw-PFKVcdqIHyE-pe_6ZzyzK_ZIuCxPqhWPyFXY4C3k3kjDsCHqDu1ayT9SxPFk9TEv7Lw1_1mOhCM_dua7KRcT0ol4dxTOINGXu65giq4SBv3w',
        'create_rs256_jwt()',
    );

    $str = Net::ACME::Crypt::create_rs256_jwt(
        key => _KEY(),
        extra_headers => { foo => 123 },
        payload => [ 'A list ...' ],
    );

    is(
        $str,
        'eyJhbGciOiJSUzI1NiIsImZvbyI6MTIzfQ.WyJBIGxpc3QgLi4uIl0.Ln_TQ_Pzsaq19ZxSchpYEv40M1v4_Fvm5GaTCQJcV345n7iLk66DegZD28RRJdtWMVQj7Amyg_rx95QVEo4nOvqGbgBQ1TjS1QoXiTnGBm-460o-EHMDVdCVDN7qDbxHoj7Wa0UtJEbidhi5MB6rVHeqSmXpJUegnd7HmW3x6CubOLqDFtSptqybouv_Ilw2k1eCZmJUi_JMdwsheKL5hw9TUh01jtgx69ewSdpg_YQKL6a8nGpUHEHXHW5fLeg89QyjczCGqJ03A_6NevFx8R_18D1aCV1N-2-rHjlw675Tq2WmTg1awDfuwEquX9jzzgYJj7ry1SxcV5GlxKsIKQ',
        'create_rs256_jwt() with an array payload',
    );

    $str = Net::ACME::Crypt::create_rs256_jwt(
        key => _KEY(),
        extra_headers => { foo => 123 },
        payload => { key => 'A thing ...' },
    );

    is(
        $str,
        'eyJhbGciOiJSUzI1NiIsImZvbyI6MTIzfQ.eyJrZXkiOiJBIHRoaW5nIC4uLiJ9.DTqBwNevEwJBuV54CfMnYJNv0rnCAP77DncLPYQ27452MmtATGq_Y1Cv8Qx1k2IWl5GPBY0Se9jEX4FhbCy2ToGgPp3qgBODyyfWpr6lXdxAH_a9tYBVUCNvVs68rLqWkhQNbgDVRz6Kyf9g6dffb8AwWfhWtjaxg70R45yIuXWU9Cyc2H0zvJ1gb-0tDsNflMVE84eFb4NiRSAG1nCzRzporl46rF2lVz8MtrXaNwCT9lkyy4DXh7YfV4ayu7gLR-XVpDrO6Pf39nKvH48pX3Owo2fatROf3xwzgvohD6NgMmaxA1TFbVUXPuid9tMLgkKfGjIClDn2Icx5XkyL-w',
        'create_rs256_jwt() with a hash payload',
    );

    return;
}

1;
