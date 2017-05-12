#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 21;

use Net::IP::XS qw(ip_is_ipv6 Error Errno);

my $res = ip_is_ipv6('123.123.123.123');
is($res, 0, 'ip_is_ipv6 invalid (IPv4 address)');

$res = ip_is_ipv6(':123.123.123.123');
is($res, 0, 'ip_is_ipv6 invalid (starts with :)');
is(Error(), "Invalid address :123.123.123.123 (starts with :)",
    'Got correct error');
is(Errno(), 109, 'Got correct errno');

$res = ip_is_ipv6('0000:');
is($res, 0, 'ip_is_ipv6 invalid (ends with :)');
is(Error(), "Invalid address 0000: (ends with :)",
    'Got correct error');
is(Errno(), 110, 'Got correct errno');

$res = ip_is_ipv6('0000::0000::0000');
is($res, 0, 'ip_is_ipv6 invalid (multiple ::)');
is(Error(), "Invalid address 0000::0000::0000 (More than one :: pattern)",
    'Got correct error');
is(Errno(), 111, 'Got correct errno');

$res = ip_is_ipv6('ABCDE::12345');
is($res, 0, 'ip_is_ipv6 invalid (parts too long)');
is(Errno(), 108, 'Correct errno');

$res = ip_is_ipv6('GGGG:FFFF');
is($res, 0, 'ip_is_ipv6 invalid (bad characters)');
is(Errno(), 108, 'Correct errno');

$res = ip_is_ipv6('1:2:3:4:5:6:7:8:9');
is($res, 0, 'ip_is_ipv6 invalid (too many colons 1)');

$res = ip_is_ipv6('1:2:3:4:5:6:7:8:9:0:1:2:3');
is($res, 0, 'ip_is_ipv6 invalid (too many colons 2)');

my @data = (
    ['1:2:3:4:5:6:7:8' => 1],
    ['1234::5678' => 1],
    ['1234:5678:9ABC:DEF0:1234:5678:9ABC:DEF0' => 1],
    ['::123.123.123.123' => 1],
    ['::' => 1]
);

for (@data) {
    my ($res, $res_exp) = @{$_};
    is(ip_is_ipv6($res), $res_exp, "$res");
}

1;
