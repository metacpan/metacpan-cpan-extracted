use Test::More tests => 12;

use strict;
use warnings;

use Net::IP::AddrRanges;

BEGIN {
    *_pack = \&Net::IP::AddrRanges::_pack;
    *_unpack = \&Net::IP::AddrRanges::_unpack;
    *_incr = \&Net::IP::AddrRanges::_incr;
    *_decr = \&Net::IP::AddrRanges::_decr;
}

is((_unpack _decr _pack '66.249.89.99'), '66.249.89.98', 'decr_ipv4');
is((_unpack       _pack '66.249.89.99'), '66.249.89.99', 'pack_ipv4');
is((_unpack _incr _pack '66.249.89.99'), '66.249.89.100', 'incr_ipv4');

is((_unpack _incr _pack '66.249.89.255'), '66.249.90.0', 'incr_ipv4_2');
is((_unpack _decr _pack '66.249.89.0'), '66.249.88.255', 'decr_ipv4_2');

is((_unpack _decr _pack '2001:0db8:0000:0000:1234:0000:0000:9abc'), '2001:db8::1234:0:0:9abb', 'decr_ipv6');
is((_unpack       _pack '2001:0db8:0000:0000:1234:0000:0000:9abc'), '2001:db8::1234:0:0:9abc', 'pack_ipv6');
is((_unpack _incr _pack '2001:0db8:0000:0000:1234:0000:0000:9abc'), '2001:db8::1234:0:0:9abd', 'incr_ipv6');

is((_unpack _incr _pack '2001:0db8:0000:0000:1234:0000:0000:ffff'), '2001:db8::1234:0:1:0', 'incr_ipv6_2');
is((_unpack _decr _pack '2001:0db8:0000:0000:1234:0000:9abc:0000'), '2001:db8::1234:0:9abb:ffff', 'decr_ipv6_2');

is((_unpack _pack '0000:0000:0000:0000:1234:0000:0000:9abc'), '::1234:0:0:9abc', 'pack_ipv6_2');
is((_unpack _pack '1234:1234:0000:1234:0000:0000:0000:0000'), '1234:1234:0:1234::', 'pack_ipv6_3');

