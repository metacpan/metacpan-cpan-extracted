#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 32;

use Net::IP::XS qw(ip_reverse Error Errno);

my $res = ip_reverse('ASDF', 0, 0);
is($res, undef, 'Got undef on no version and bad address');
is(Error(), 'Cannot determine IP version for ASDF',
    'Got correct error');
is(Errno(), 101, 'Got correct errno');

my @data = (
    [['A.B.C.D', 6, 4] => undef],
    [['0.0.0.0', -1, 4] => undef],
    [['0.0.0.0', 33, 4] => undef],
    [['0.0.0.0', 32, 4] => '0.0.0.0.in-addr.arpa.'],
    [['1.2.3.4', 32, 4] => '4.3.2.1.in-addr.arpa.'],
    [['1.2.3.4', 24, 4] => '3.2.1.in-addr.arpa.'],
    [['1.2.3.4', 16, 4] => '2.1.in-addr.arpa.'],
    [['1.2.3.4', 8, 4] => '1.in-addr.arpa.'],
    [['1.2.3.4', 0, 4] => 'in-addr.arpa.'],
    [['123.234.234.231', 32, 4] => '231.234.234.123.in-addr.arpa.'],
    [['255.255.255.255', 32, 4] => '255.255.255.255.in-addr.arpa.'],
    [['100.0', 32, 4] => '0.0.0.100.in-addr.arpa.'],
    [['A:B:C:D::', -1, 6] => undef],
    [['A:B:C:D::', 129, 6] => undef],
    [['ZXCVCCCCC', 56, 6] => undef],
    [['A:B:C:D::', 0, 6] => 'ip6.arpa.'],
    [['A:B:C:D::', 4, 6] => '0.ip6.arpa.'],
    [['A:B:C:D::', 8, 6] => '0.0.ip6.arpa.'],
    [['A:B:C:D::', 12, 6] => '0.0.0.ip6.arpa.'],
    [['A:B:C:D::', 16, 6] => 'a.0.0.0.ip6.arpa.'],
    [['A:B:C:D::', 20, 6] => '0.a.0.0.0.ip6.arpa.'],
    [['A:B:C:D::', 24, 6] => '0.0.a.0.0.0.ip6.arpa.'],
    [['A:B:C:D::', 28, 6] => '0.0.0.a.0.0.0.ip6.arpa.'],
    [['A:B:C:D::', 32, 6] => 'b.0.0.0.a.0.0.0.ip6.arpa.'],
    [['A:B:C:D::', 36, 6] => '0.b.0.0.0.a.0.0.0.ip6.arpa.'],
    [['A:B:C:D::', 40, 6] => '0.0.b.0.0.0.a.0.0.0.ip6.arpa.'],
    [['A:B:C:D::', 44, 6] => '0.0.0.b.0.0.0.a.0.0.0.ip6.arpa.'],
    [['A:B:C:D::', 48, 6] => 'c.0.0.0.b.0.0.0.a.0.0.0.ip6.arpa.'],
    [['0::0',128,6] => '0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa.'],
);

for my $entry (@data) {
    my ($args, $res) = @{$entry};
    my ($ip, $len, $ver) = @{$args};
    my $res_t = ip_reverse($ip, $len, $ver);
    for ($ip, $len, $ver) {
        defined $_ or $_ = undef;
    }
    is($res_t, $res, "Got reverse domain for $ip, $len, $ver");
}

1;
