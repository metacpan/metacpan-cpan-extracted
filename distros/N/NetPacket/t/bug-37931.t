use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use NetPacket::ICMP ':ALL';

ok ICMP_MASKREQ(), "ICMP_MASKRED defined";


__END__

=pod

Subject:  	NetPacket::ICMP has an export typo on ICMP_MASKREQ

I found a typo in NetPacket::ICMP:

> use constant ICMP_MASKREQ => 17;

This constant is exported and documented as ICMP_MASREQ, making
it unusable as an exported method.

=cut
