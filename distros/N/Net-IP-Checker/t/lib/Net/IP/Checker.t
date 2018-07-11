use strict;
use warnings;
use Test::More qw[no_plan];

BEGIN { use_ok( 'Net::IP::Checker', qw(:ALL) ); }
can_ok( 'Net::IP::Checker', qw(ip_is_ipv4 ip_is_ipv6 ip_get_version) );

ok ip_is_ipv4('0.0.0.0'),          "0.0.0.0 is valid IPv4";
ok ip_is_ipv4('127.0.0.1'),        "127.0.0.1 is valid IPv4";
ok ip_is_ipv4('172.16.0.216'),     "172.16.0.216 is valid IPv4";
is ip_get_version('172.16.0.216'), 4, '172.16.0.216 is IPv4';

ok ip_is_ipv6('dead:beef:89ab:cdef:0123:4567:89ab:cdef'),
  "is dead:beef:89ab:cdef:0123:4567:89ab:cdef valid IPv6";
is ip_get_version('dead:beef:89ab:cdef:0123:4567:89ab:cdef'), 6, 'IPv6';
ok ip_is_ipv6('::ff00:192.0.0.1'), '::ff00:192.0.0.1 is valid IPv6';
ok ip_is_ipv6('::2:3:4:5:6:7:8'),  '::2:3:4:5:6:7:8 is valid IPv6';

my $invalid_ipv4_samples = {
    'empty-string'   => '',
    'empty-hash'     => {},
    'empty-array'    => [],
    'subnet'         => '127.0.0.0/24',
    'invalid-octet'  => '256.1.1.1',
    'negative-octet' => '1.1.-1.1',
    'extra-octets'   => '1.2.3.4.5',
    'lack-of-octets' => '1.2.3',
    'missed-number'  => '1.2..4',
    'tail-dot'       => '1.2.3.4.',
    'head-dot'       => '.1.2.3.4',
    'just-dot'       => '.'
};

while ( my ( $key, $value ) = each(%$invalid_ipv4_samples) ) {
    ok !ip_is_ipv4($value), "IPv4 invalid when $key";
}

my $invalid_ipv6_samples = {
    'empty-string'         => '',
    'empty-hash'           => {},
    'empty-array'          => [],
    'subnet'               => '2001:db8:1234:c000::/50',
    'invalid-ipv4-mapping' => '::256.1.1.1',
    'invalid-ipv6'         => '$1:2:3:4:5:6:7:8',
    'invalid-ipv6-2'       => '::1.2.3.4:5678',
    'invalid-ipv6-3'       => '1:2:3:4:5:6:7:8::',
    'negative-octet'       => '1.1.-1.1',
    'extra-colon'          => '1:::1',
    'lack-of-octets'       => '::1.2.3',
    'lack-of-octets-2'     => '1:2::3.4.5',
    'lack-of-octets-3'     => '::ffff:2.3.4',
    'missed-number'        => '1.2..4',
    'tail-dot'             => '::1.2.3.4.',
    'dot-after-colon'      => '::.1.2.3.4',
    'dot-before-colon'     => '.::1.2.3.4',
    'invalid-hex'          => '2001::765G',
    'just-colon'           => ':',
    'just-dot'             => '.',
};

while ( my ( $key, $value ) = each(%$invalid_ipv6_samples) ) {
    ok !ip_is_ipv6($value), "IPv6 invalid when $key";
}
