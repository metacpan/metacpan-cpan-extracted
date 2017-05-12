#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 24;

use Net::IP::XS qw(ip_prefix_to_range Error Errno);

my $res = ip_prefix_to_range('a', 15, 0);
is($res, undef, 'Got undef on no version');
is(Error(), 'Cannot determine IP version',
    'Got correct error');
is(Errno(), 101, 'Got correct errno');

$res = ip_prefix_to_range('123.123.123.123.123', 16, 4);
is($res, undef, 'Got undef when unable to expand first address');

$res = ip_prefix_to_range('1.2.3.4', 16, 4);
is($res, undef, 'Got undef when address and prefix do not go together');

my @data = (
    [['0.0.0.0', 32, 4] => ['0.0.0.0', '0.0.0.0']],
    [['0.0.0.0', 31, 4] => ['0.0.0.0', '0.0.0.1']],
    [['0.0.0.0', 30, 4] => ['0.0.0.0', '0.0.0.3']],
    [['0.0.0.0', 29, 4] => ['0.0.0.0', '0.0.0.7']],
    [['0.0.0.0', 28, 4] => ['0.0.0.0', '0.0.0.15']],
    [['0.0.0.0', 27, 4] => ['0.0.0.0', '0.0.0.31']],
    [['1.2.3.0', 24, 4] => ['1.2.3.0', '1.2.3.255']],
    [['1.2.2.0', 23, 4] => ['1.2.2.0', '1.2.3.255']],
    [['1.2.0.0', 22, 4] => ['1.2.0.0', '1.2.3.255']],
    [['1.2.4.0', 22, 4] => ['1.2.4.0', '1.2.7.255']],
    [['1.2.0.0', 21, 4] => ['1.2.0.0', '1.2.7.255']],
    [['1.2.0.0', 20, 4] => ['1.2.0.0', '1.2.15.255']],
    [['100.100.16.0', 20, 4] => ['100.100.16.0', '100.100.31.255']],
    [['0.0.0.0', 1, 4] => ['0.0.0.0', '127.255.255.255']],
    [['0.0.0.0', 0, 4] => ['0.0.0.0', '255.255.255.255']],
    [['255.255.255.255', 32, 4] => ['255.255.255.255', '255.255.255.255']],
    [['1.0.0.0', 8, 4] => ['1.0.0.0', '1.255.255.255']],
    [[(join ':', ('0000') x 8), 0, 6] => [(join ':', ('0000') x 8),
                                          (join ':', ('ffff') x 8)]],
    [[(join ':', ('0000') x 8), 1, 6] => [(join ':', ('0000') x 8),
                                          (join ':', '7fff', ('ffff') x 7)]],
);

for my $entry (@data) {
    my ($args, $res) = @{$entry};
    my ($ip, $len, $ver) = @{$args};
    my @res_t = ip_prefix_to_range($ip, $len, $ver);
    is_deeply(\@res_t, $res, "Got correct results for $ip, $len, $ver");
}

1;
