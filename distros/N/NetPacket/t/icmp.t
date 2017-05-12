use strict;
use warnings;

use Test::More tests => 2;                      # last test to print

use NetPacket::Ethernet;
use NetPacket::IP;
use NetPacket::ICMP;

my $datagram = binarize( <<'END_DATAGRAM' );
00 00 00 00 00 00 00 00 00 00 00 00 08 00 45 00 
00 54 00 00 40 00 40 01 3c a7 7f 00 00 01 7f 00 
00 01 08 00 d8 2f b6 6f 00 00 f8 11 c9 45 ba 05 
03 00 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 
16 17 18 19 1a 1b 1c 1d 1e 1f 20 21 22 23 24 25 
26 27 28 29 2a 2b 2c 2d 2e 2f 30 31 32 33 34 35 
36 37
END_DATAGRAM

my $eth = NetPacket::Ethernet->decode( $datagram );
my $ip = NetPacket::IP->decode( $eth->{data} );
my $icmp = NetPacket::ICMP->decode( $ip->{data} );

is $icmp->{cksum} => 55343, 'ICMP checksum';

# recompute the checksum
$icmp->checksum;

is $icmp->{cksum} => 55343, 'recomputed ICMP checksum';

sub binarize {
    my $string = shift;

    return join '' => map { chr hex } split ' ', $string;
}

