#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 20;

use Net::IP::XS qw(ip_compress_address Error Errno);

my $res = ip_compress_address('ZZZZ', 0);
is($res, undef, 'Got undef on bad IP address');
is(Error(), 'Cannot determine IP version for ZZZZ',
    'Got correct error');
is(Errno(), 101, 'Got correct errno');

$res = ip_compress_address('1.2.3.4', 4);
is($res, '1.2.3.4', 'Original IP address returned for IPv4');

my @data = (
    ['0000:0000:0000:0000:0000:0000:0000:0000' => '::'],
    ['2001:db8:0:1:1:1:1:1'                    => '2001:db8:0:1:1:1:1:1'],
    ['2001:db8:0:0:0:0:2:1'                    => '2001:db8::2:1'],
    ['2001:0:0:1:0:0:0:1'                      => '2001:0:0:1::1'],
    ['2001:db8:0:0:1:0:0:1'                    => '2001:db8::1:0:0:1'],
    ['ABCD:0000:EF01:0000:ABCD:0000:EF01:0000' => 'abcd:0:ef01:0:abcd:0:ef01:0'],
    ['ABCD:0000:0000:0000:ABCD:0000:EF01:0000' => 'abcd::abcd:0:ef01:0'],
    ['ABCD:0000:0000:0000::0000:EF01:0000'     => 'abcd::ef01:0'],
    ['ABCD:0000:0000:0000:0000:0000:EF01:0000' => 'abcd::ef01:0'],
    ['ABCD:0000:EF01:0000:0000:ABCD:0000:EF01' => 'abcd:0:ef01::abcd:0:ef01'],
    ['000F:000F:FF0F:FFFF:000F:FFFF:FFFF:FFFF' =>
        'f:f:ff0f:ffff:f:ffff:ffff:ffff'],
    ['FFFF:0000:0000:0000:0000:0000:0000:FFFF' =>
        'ffff::ffff'],
    ['FFFF:0:0000:0000:0:0000:0:FFFF'          =>
        'ffff::ffff'],
    ['FFFF:0:0000:FFFF:0:0000:0:FFFF'          =>
        'ffff:0:0:ffff::ffff'],
    ['a:b:c:d:a:b:c:d' => 'a:b:c:d:a:b:c:d'],
    ['a:b:c:d:a:b:c:d/128' => undef],
);

for my $entry (@data) {
    my ($arg, $res) = @{$entry};
    my $res_t = ip_compress_address($arg, 6);
    is($res_t, $res, "Got compressed address for $arg");
}

1;
