use strict;
use warnings;

use Test::More tests => 2;

use NetPacket::Ethernet qw/ :types /;

is ETH_TYPE_PPPOES() => 0x8864, 'imports';

is NetPacket::Ethernet::ETH_TYPE_IP() => 0x0800, 'with namespace';



