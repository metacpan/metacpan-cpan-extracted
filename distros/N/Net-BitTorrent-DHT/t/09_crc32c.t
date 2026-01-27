use v5.40;
use lib 'lib', '../lib';
use Test2::V0;
use Net::BitTorrent::DHT::Security;
#
my $sec   = Net::BitTorrent::DHT::Security->new();
my @tests = (
    { input => '',                                            expected => 0x00000000, desc => 'empty string' },
    { input => '123456789',                                   expected => 0xE3069283, desc => '1-9 digits' },
    { input => 'The quick brown fox jumps over the lazy dog', expected => 0x22620404, desc => 'fox/dog sentence' },
    { input => pack( 'C*', 0x01, 0x0b, 0x1f, 0xee, 0x06 ),    expected => 0x7c237efd, desc => 'BEP 42 example input (seed 86)' },
);
for my $t (@tests) {
    my $got = $sec->_crc32c( $t->{input} );
    is( sprintf( '0x%08x', $got ), sprintf( '0x%08x', $t->{expected} ), 'CRC32c for ' . $t->{desc} );
}
#
done_testing;
