use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok 'Protocol::TLS::Constants', 'cipher_type', ':ciphers';
}

is_deeply
  [ cipher_type(TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256) ],
  [ 'ECDHE_ECDSA', 'AES_128_GCM', 'SHA256' ],
  "parse ok";

done_testing;

