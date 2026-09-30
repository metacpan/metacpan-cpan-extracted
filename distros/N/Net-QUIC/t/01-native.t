use strict;
use warnings;

use Test2::V0;

use Net::QUIC;

my $version = Net::QUIC::ngtcp2_version();

like(
    $version,
    qr/\A\d+\.\d+\.\d+/,
    'linked ngtcp2 reports a version',
);

ok(
    Net::QUIC::ngtcp2_version_num() >= 0x011900,
    'linked ngtcp2 is at least 1.25.0',
);

is(
    Net::QUIC::crypto_backend(),
    'picotls',
    'Picotls is the QUIC TLS backend',
);

ok(
    Net::QUIC::_crypto_self_test(),
    'linked ngtcp2 crypto helper works',
);

done_testing;
