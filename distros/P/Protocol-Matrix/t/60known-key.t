#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Protocol::Matrix qw( signed_json signed_event_json );

use Crypt::NaCl::Sodium;
use MIME::Base64 qw( decode_base64 );

# The test vector key given by Matrix spec
my $signing_key_seed = decode_base64(
   "YJDBA9Xnr2sVqXD9Vj7XVUnmFZcZrlw8Md7kMW+3XA1"
);

my $sign = Crypt::NaCl::Sodium->sign;
my ( $pkey, $skey ) = $sign->keypair( $signing_key_seed );

# sign
{
   # See also
   #   https://github.com/matrix-org/python-signedjson/blob/master/tests/test_known_key.py

   my $signed = signed_json( {},
      secret_key => $skey,
      origin     => "name",
      key_id     => "ed25519:1",
   );
   is( $signed->{signatures}{"name"}{"ed25519:1"},
      "K8280/U9SSy9IVtjBuVeLr+HpOB4BQFWbg+UZaADMtTdGYI7Geitb76LTrr5QV/7Xg4ahLwYGYZzuHGZKM5ZAQ",
      'Signature of minimal empty object' );

   $signed = signed_json(
      { one => 1, two => "Two" },
      secret_key => $skey,
      origin     => "name",
      key_id     => "ed25519:1",
   );
   is( $signed->{signatures}{"name"}{"ed25519:1"},
      "KqmLSbO39/Bzb0QIYE82zqLwsA+PDzYIpIRA2sRQ4sL53+sN6/fpNSoqE7BP7vBZhG6kYdD13EIMJpvhJI+6Bw",
      'Signature of object with data' );
}

# sign_event
{
   # See also
   #   https://github.com/matrix-org/synapse/blob/develop/tests/crypto/test_event_signing.py

   my $signed = signed_event_json(
      {
         event_id         => "\$0:domain",
         origin           => "domain",
         origin_server_ts => 1000000,
         signatures       => {},
         type             => "X",
         unsigned         => { age_ts => "1000000" },
      },
      secret_key => $skey,
      origin     => "domain",
      key_id     => "ed25519:1",
   );

   is( $signed->{hashes}{"sha256"},
      "6tJjLpXtggfke8UxFhAKg82QVkJzvKOVOOSjUDK4ZSI",
      'SHA256 hash of minimal event' );

   is( $signed->{signatures}{"domain"}{"ed25519:1"},
      "2Wptgo4CwmLo/Y8B8qinxApKaCkBG2fjTWB7AbP5Uy+aIbygsSdLOFzvdDjww8zUVKCmI02eP9xtyJxc/cLiBA",
      'Signature of minimal event' );
}

done_testing;
