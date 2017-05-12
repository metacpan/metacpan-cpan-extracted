
use strict;
use warnings;

use Test::More tests => 4;

use NetPacket::Ethernet;
use NetPacket::IP;
use NetPacket::TCP;

my $datagram = binarize( <<'END_DATAGRAM' );
00 21 85 9a 70 4d 00 80 64 54 ba 3a 08 00 45 00 
00 e4 2b 2d 40 00 74 06 0f 26 cc e8 f4 d6 0a 00 
00 02 00 50 82 60 eb 9d d5 71 11 5e 81 59 80 18 
fb 28 3d cf 00 00 01 01 08 0a 30 61 d4 65 05 8c 
40 76 48 54 54 50 2f 31 2e 31 20 32 30 30 20 4f 
4b 0d 0a 43 6f 6e 74 65 6e 74 2d 54 79 70 65 3a 
20 61 70 70 6c 69 63 61 74 69 6f 6e 2f 6a 73 6f 
6e 3b 20 63 68 61 72 73 65 74 3d 75 74 66 2d 38 
0d 0a 53 65 72 76 65 72 3a 20 4d 69 63 72 6f 73 
6f 66 74 2d 49 49 53 2f 37 2e 30 0d 0a 58 2d 50 
6f 77 65 72 65 64 2d 42 79 3a 20 41 53 50 2e 4e 
45 54 0d 0a 44 61 74 65 3a 20 46 72 69 2c 20 30 
37 20 4d 61 79 20 32 30 31 30 20 32 32 3a 35 38 
3a 32 35 20 47 4d 54 0d 0a 43 6f 6e 74 65 6e 74 
2d 4c 65 6e 67 74 68 3a 20 34 0d 0a 0d 0a 34 36 
32 34
END_DATAGRAM

my $eth = NetPacket::Ethernet->decode( $datagram );
my $ip = NetPacket::IP->decode( $eth->{data} );
my $tcp = NetPacket::TCP->decode( $ip->{data}, $ip );

like $tcp->{data} => qr/^HTTP.*4624$/ms, 'TCP payload';

# same thing, but with noise at the end of the Eth
# segment


$datagram = binarize( <<'END_DATAGRAM' );
00 21 85 9a 70 4d 00 80 64 54 ba 3a 08 00 
# IP
45 00 00 e4 2b 2d 40 00 74 06 0f 26 cc e8 f4 d6 
0a 00 00 02 
# TCP
00 50 82 60 eb 9d d5 71 11 5e 81 59 80 18 
fb 28 3d cf 00 00 01 01 08 0a 30 61 d4 65 05 8c 
40 76 48 54 54 50 2f 31 2e 31 20 32 30 30 20 4f 
4b 0d 0a 43 6f 6e 74 65 6e 74 2d 54 79 70 65 3a 
20 61 70 70 6c 69 63 61 74 69 6f 6e 2f 6a 73 6f 
6e 3b 20 63 68 61 72 73 65 74 3d 75 74 66 2d 38 
0d 0a 53 65 72 76 65 72 3a 20 4d 69 63 72 6f 73 
6f 66 74 2d 49 49 53 2f 37 2e 30 0d 0a 58 2d 50 
6f 77 65 72 65 64 2d 42 79 3a 20 41 53 50 2e 4e 
45 54 0d 0a 44 61 74 65 3a 20 46 72 69 2c 20 30 
37 20 4d 61 79 20 32 30 31 30 20 32 32 3a 35 38 
3a 32 35 20 47 4d 54 0d 0a 43 6f 6e 74 65 6e 74 
2d 4c 65 6e 67 74 68 3a 20 34 0d 0a 0d 0a 34 36 
32 34 de ad be ef
END_DATAGRAM

$eth = NetPacket::Ethernet->decode( $datagram );
$ip = NetPacket::IP->decode( $eth->{data} );
$tcp = NetPacket::TCP->decode( $ip->{data}, $ip );

like $tcp->{data} => qr/^HTTP.*4624$/ms, 'TCP payload';

is_deeply scalar $tcp->parse_tcp_options, {
    er => 93077622,
    ts => 811717733,
}, 'options';

$datagram = binarize( <<'END_DATAGRAM');
d3 55 00 50 85 cf 98 36 00 00 00 00 a0 02 16 d0
9b 76 00 00 02 04 05 b4 04 02 08 0a 85 82 12 6d
00 00 00 00 01 03 03 04
END_DATAGRAM

$tcp = NetPacket::TCP->decode( $datagram );

is_deeply scalar $tcp->parse_tcp_options, {
    er => 0,
    ts => 2239894125,
    mss => 1460,
    ws => 4,
    sack => 2,
}, 'options';

sub binarize {
    my $string = shift;

    $string =~ s/^\s*#.*?$//mg;   # remove comments

    return join '' => map { chr hex } split ' ', $string;
}

