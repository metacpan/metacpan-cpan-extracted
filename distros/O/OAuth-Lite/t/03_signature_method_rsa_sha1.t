use Test::More tests => 5;

use OAuth::Lite::SignatureMethod::RSA_SHA1;

is(OAuth::Lite::SignatureMethod::RSA_SHA1->method_name, 'RSA-SHA1');
is(OAuth::Lite::SignatureMethod::RSA_SHA1->build_body_hash(qq{Hello World!}), q{Lve95gjOVATpfV8EL5X4nxwjKHE=});

my $public_key = <<__END_OF_PUBLIC__;
-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAN4jFZ1OxLALdJcirP0eQ0ydoZ8Dc3yc/UfWMRP5Jc3rN0zwKSelZkog
I/cDdg/aXuZwdHFwwI2rfqrptkughT3pPJqmMx8zAx1nx9CRpjhLfoFbem+wa9hc
TXHlr9JvRoRAAnbdjvHE5DT+niQzp2E/H9B4a9N3thDitC/VTSFXAgMBAAE=
-----END RSA PUBLIC KEY-----
__END_OF_PUBLIC__

my $private_key = <<__END_OF_PRIVATE__;
-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQDeIxWdTsSwC3SXIqz9HkNMnaGfA3N8nP1H1jET+SXN6zdM8Ckn
pWZKICP3A3YP2l7mcHRxcMCNq36q6bZLoIU96TyapjMfMwMdZ8fQkaY4S36BW3pv
sGvYXE1x5a/Sb0aEQAJ23Y7xxOQ0/p4kM6dhPx/QeGvTd7YQ4rQv1U0hVwIDAQAB
AoGAQHpwmLO3dd4tXn1LN0GkiUWsFyr6R66N+l8a6dBE/+uJpsSDPaXN9jA0IEwZ
5eod58e2lQMEcVrZLqUeK/+RDOfVlZSVcPY0eBG+u+rxmUwPVqh9ghsC7JfdmQA6
cQ14Rf/Rmlm7N3+tF83CrlBnwaNEhvHk6cJrMSSyKRF5xFECQQD7rd23/SsWqLOP
uSSy9jkdSKadsDDbJ0pHgOaRSJ3WNgJbEwLdSu6AQwy6vB0Ell4p9ixJD4MbCW46
IBrPyKapAkEA4fNhWcaBawvVAJf33jyHdGVExkQUpo6JHkitU06g5Af++sFRo8rT
aj+ZImGFvGwGGMfNoMt9d3ttdoNKW6yH/wJARoHW84yBXb+1TjZYCarhJUsNInAR
v9OqA44hCeKGFVTcJBeXXdd4KYafMlEw7/AQQUEt9unZmOFzd+U2na9gwQJAXYPR
YsqZfahj+97po30Bwta25CgBM/4CGhqSQcxlInt8uGOSWmvznCG+S1B5fUZoL5Fi
NY6C2xSmdUpZWB/MGQJAVxI4gD+kYTYvqPqU7UEu+d68aMttqJeZUbIYd4ydMWFB
CHT/dnHG/dX4b8GOOTFz1y9r2x3Org43CQOZvDy/HA==
-----END RSA PRIVATE KEY-----
__END_OF_PRIVATE__

my $invalid_public_key = <<__END_OF_INVALID__;
-----BEGIN RSA PUBLIC KEY-----
MIGJAoGBAMmsdxC0oP3E7yD9PX5vxUblyBEhUY9brNhJbJS55+8rxjBdo7iImoSd
lRxOVeest+mBRKqPrEgKYpsjiduIT0MiqHFdGR7DhYGtV1Sgn75+WoLj/S9t58wg
a5eBaoJl/UzNBxENLgWoI3TtdYiZoXFysMjqsFIqQKFo/fLCyZ3pAgMBAAE=
-----END RSA PUBLIC KEY-----
__END_OF_INVALID__

my $base = "hogehogehoge";
my $signer = OAuth::Lite::SignatureMethod::RSA_SHA1->new(
	consumer_secret => $private_key,
);

my $signature = $signer->sign($base);
my $expected = qq{rNZSaVtKK3Gkp6T9AwolAyMIng5xVr3TOYrTGGR8zAbUv4T4+oUQYecXf9dOBg0xrvNkkjKqJJda\nyFLYdqmK1d7JfGDzS5hzK65q2XghJjU7xlbgQQXKz0YPvk9KHSI9oO5XqlJPIGkrBNTRBn+iHeh8\npoNt4wYRZ/lICtjI/9I=};
is($signature, $expected);

my $verifier = OAuth::Lite::SignatureMethod::RSA_SHA1->new(
	consumer_secret => $public_key,
);

ok($verifier->verify($base, $signature));

my $invalid_verifier = OAuth::Lite::SignatureMethod::RSA_SHA1->new(
	consumer_secret => $invalid_public_key,
);

ok(!$invalid_verifier->verify($base, $signature));

