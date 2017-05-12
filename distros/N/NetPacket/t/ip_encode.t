use strict;
use warnings;

use Test::More tests => 2;

use NetPacket::IP;
use NetPacket::Ethernet;

my $datagram  =  join '', map { chr } split ':', join ':' => <DATA>;

my $eth = NetPacket::Ethernet->decode( $datagram );

my $ip = NetPacket::IP->decode( $eth->{data} );

is $ip->{flags} => 2;

my $q = NetPacket::IP->decode( $ip->encode );

is $q->{flags} => $ip->{flags};

__DATA__
0:25:209:6:219:108:0:19:163:164:237:251:8:0:69:0:0:46
174:1:64:0:56:6:248:228:96:6:121:42:192:168:2:11:0:80
17:185:251:228:155:131:197:211:72:2:80:16:30:230:61:189
0:0:0:0:0:0:0:0
