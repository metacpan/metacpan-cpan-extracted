use strict;
use warnings;

use Test::More tests => 3;

use NetPacket::Ethernet qw/ :types /;

is ETH_TYPE_PPPOES() => 0x8864, 'imports';

is NetPacket::Ethernet::ETH_TYPE_IP() => 0x0800, 'with namespace';

subtest "don't invert the mac ports" => sub {
    my $packet = NetPacket::Ethernet->decode(
        NetPacket::Ethernet::encode({
            src_mac => '001',
            dest_mac => '002',
            data => '',
        })
    );

    like $packet->{src_mac}, qr'001', 'src_mac';
    like $packet->{dest_mac}, qr'002', 'dest_mac';
};
