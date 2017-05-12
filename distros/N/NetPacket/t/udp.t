use strict;
use warnings;

use Test::More tests => 8;

use NetPacket::Ethernet;
use NetPacket::IP;
use NetPacket::UDP qw/ udp_strip /;

my $datagram = binarize( <<'END_DATAGRAM' );
00 90 d0 23 ed 2a 00 1c bf ca a3 d5 08 00 45 00 
00 30 00 00 40 00 40 11 30 5a 0a 00 00 a5 84 b1 
7b 0d eb 11 0d 96 00 1c 42 7f 00 01 00 00 21 12 
a4 42 fd 95 e8 83 8a 05 28 45 6a 8e f1 e2
END_DATAGRAM

my $eth = NetPacket::Ethernet->decode( $datagram );
my $ip = NetPacket::IP->decode( $eth->{data} );
my $udp = NetPacket::UDP->decode( $ip->{data}, $ip );

is unpack( "H*", $udp->{data} ) 
    => '000100002112a442fd95e8838a0528456a8ef1e2', 'UDP payload (STUN)';

is $udp->{src_port} => 60177, 'src_port';
is $udp->{dest_port} => 3478, 'dest_port';
is $udp->{len} => 28, 'len';
is $udp->{cksum} => 17023, 'cksum';

is $udp->{src_port} => 60177, 'src_port';
is $udp->{dest_port} => 3478, 'dest_port';

is unpack( "H*", udp_strip($udp->encode($ip)) ) => 
    '000100002112a442fd95e8838a0528456a8ef1e2', 'udp_strip()';


sub binarize {
    my $string = shift;

    $string =~ s/^\s*#.*?$//mg;   # remove comments

    return join '' => map { chr hex } split ' ', $string;
}

