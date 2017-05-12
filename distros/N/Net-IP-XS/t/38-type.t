#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 10;

use Net::IP::XS qw(ip_iptype ip_iptobin ip_expand_address);

$Net::IP::XS::IPv4ranges{'1' x 32} = 'A' x 1024;

sub tbea { ip_iptobin(ip_expand_address($_[0], $_[1]), $_[1]) }

my @data = (
    [[tbea('1.2.3.4', 4), 4]        => 'PUBLIC'],
    [[tbea('0.255.255.255', 4), 4]  => 'PRIVATE'],
    [[tbea('127.0.0.1', 4), 4]      => 'PRIVATE'],
    [[tbea('192.0.2.128', 4), 4],   => 'RESERVED'],
    [[tbea('248.0.0.0', 4), 4]      => 'RESERVED'],
    [[tbea('0100::', 6), 6]         => 'RESERVED'],
    [[tbea('ff00::1234', 6), 6],    => 'MULTICAST'],
    [[tbea('::1', 6), 6],           => 'LOOPBACK'],
    [['1' x 32, 4]                  => 'A' x 255],
);

for my $entry (@data) {
    my ($arg, $res) = @{$entry};
    my ($ip, $version) = @{$arg};
    my $res_t = ip_iptype($ip, $version);
    is($res_t, $res, "Got correct type for $ip ($version)");
}

for (keys %Net::IP::XS::IPv6ranges) {
    delete $Net::IP::XS::IPv6ranges{$_};
}

my $res = ip_iptype(tbea('4000::', 6), 6);
is($res, undef, "Got undef on IPv6 address with no type");

1;
