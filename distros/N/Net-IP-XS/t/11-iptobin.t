#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 21;

use Net::IP::XS qw(ip_iptobin Error Errno ip_bintoip);

my $str = ip_iptobin('000.000.000.000', 4);
is($str, undef, 'Got undef on bad IPv4 address (1)');

$str = ip_iptobin('300.300.300.300', 4);
is($str, undef, 'Got undef on bad IPv4 address (2)');

$str = ip_iptobin('300.300.300.300.300.300', 4);
is($str, undef, 'Got undef on bad IPv4 address (3)');

$str = ip_iptobin('0.0.0.0', 4);
is($str, '00000000000000000000000000000000',
    'ip_iptobin v4 (min)');

$str = ip_iptobin('127.1.2.122', 4);
is($str, '01111111000000010000001001111010',
    'ip_iptobin v4');

$str = ip_iptobin('255.255.255.255', 4);
is($str, '11111111111111111111111111111111',
    'ip_iptobin v4 (max)');

$str = ip_iptobin('1.2.3.400', 800);
is($str, undef, 'ip_iptobin invalid');

$str = ip_iptobin((join ':', (('0000') x 8)), 6);
is($str, '0' x 128,
    'ip_iptobin v6 (min)');

$str = ip_iptobin((join ':', (('ffff') x 8)), 6);
is($str, '1' x 128,
    'ip_iptobin v6 (max)');

$str = ip_iptobin('12341234123412341234123412341234',
6);
is($str, '0001001000110100' x 8,
    'ip_iptobin v6');

$str = ip_iptobin(
    'ff00:0000:0000:0000:0000:0000:0000:1234',
    6
);
is($str, '1111111100000000'.('0' x 96).'0001001000110100',
    'ip_iptobin v6');

$str = ip_iptobin('1234', 6);
is($str, undef, 'ip_iptobin invalid');
is(Error(), 'Bad IP address 1234', 'Correct error');
is(Errno(), 102, 'Correct errno');

$str = ip_iptobin(
    'A\CD:E<FG:A=DF:QWER:zx$v:qwer:asdf:zxcv',
    6
);
is($str, undef, 'ip_iptobin invalid');

$str = ip_iptobin(
    'ABCD:1234:A=DF:QWER:zx$v:qwer:asdf:zxcv',
    6
);
is($str, undef, 'ip_iptobin invalid');

$str = ip_iptobin(
    'ABCD:1234:A!DF:QWER:zx$v:qwer:asdf:zxcv',
    6
);
is($str, undef, 'ip_iptobin invalid');

# Make sure version is treated as 6 if it is not 4.

$str = ip_iptobin('1234', 800);
is($str, undef, 'ip_iptobin invalid');
is(Error(), 'Bad IP address 1234', 'Correct error');
is(Errno(), 102, 'Correct errno');

$str = ip_iptobin('ABCD', 4);
is($str, undef, 'ip_iptobin invalid');

1;
