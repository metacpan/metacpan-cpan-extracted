#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 20;

use Net::IP::XS qw(ip_range_to_prefix
                   ip_iptobin
                   Error
                   Errno);

my $res;
my @res;

@res = ip_range_to_prefix('1', '1', 0);
is_deeply(\@res, [], 'No results on no version');
is(Error(), 'Cannot determine IP version',
    'Got correct error');
is(Errno(), 101, 'Got correct errno');

@res = ip_range_to_prefix('1', '1', 8);
is_deeply(\@res, [], 'No results on bad version');

@res = ip_range_to_prefix('10', '1', 4);
is_deeply(\@res, [], 'No results on different lengths');
is(Error(), 'IP addresses of different length',
    'Got correct error');
is(Errno(), 130, 'Got correct errno');

@res = ip_range_to_prefix('0' x 256, '1' x 256, 4);
ok(1, 'Call returned where bitstrings too long (IPv4)');

@res = ip_range_to_prefix('0' x 512, '1' x 512, 6);
ok(1, 'Call returned where bitstrings too long (IPv6)');

@res = ip_range_to_prefix(
    ip_iptobin('127.0.0.1', 4),
    ip_iptobin('127.0.0.255', 4),
    4
);
is_deeply(
    \@res,
    [
        '127.0.0.1/32',
        '127.0.0.2/31',
        '127.0.0.4/30',
        '127.0.0.8/29',
        '127.0.0.16/28',
        '127.0.0.32/27',
        '127.0.0.64/26',
        '127.0.0.128/25'
    ],
    'ip_range_to_prefix 1'
);

@res = ip_range_to_prefix(
    ip_iptobin('127.0.0.0', 4),
    ip_iptobin('127.0.0.255', 4),
    4
);

is_deeply(\@res, ['127.0.0.0/24'], 'ip_range_to_prefix 2');

@res = ip_range_to_prefix(
    ip_iptobin('127.0.0.0', 4),
    ip_iptobin('128.0.0.0', 4),
    4
);

is_deeply(\@res, ['127.0.0.0/8', '128.0.0.0/32'], 'ip_range_to_prefix 3');

@res = ip_range_to_prefix(
    ip_iptobin('0.0.0.0', 4),
    ip_iptobin('255.255.255.255', 4),
    4
);

is_deeply(\@res, ['0.0.0.0/0'], 'ip_range_to_prefix 4');

@res = ip_range_to_prefix(
    ip_iptobin('0.0.0.1', 4),
    ip_iptobin('255.255.255.255', 4),
    4
);

is_deeply(
    \@res, 
    [
        '0.0.0.1/32',
        '0.0.0.2/31',
        '0.0.0.4/30',
        '0.0.0.8/29',
        '0.0.0.16/28',
        '0.0.0.32/27',
        '0.0.0.64/26',
        '0.0.0.128/25',
        '0.0.1.0/24',
        '0.0.2.0/23',
        '0.0.4.0/22',
        '0.0.8.0/21',
        '0.0.16.0/20',
        '0.0.32.0/19',
        '0.0.64.0/18',
        '0.0.128.0/17',
        '0.1.0.0/16',
        '0.2.0.0/15',
        '0.4.0.0/14',
        '0.8.0.0/13',
        '0.16.0.0/12',
        '0.32.0.0/11',
        '0.64.0.0/10',
        '0.128.0.0/9',
        '1.0.0.0/8',
        '2.0.0.0/7',
        '4.0.0.0/6',
        '8.0.0.0/5',
        '16.0.0.0/4',
        '32.0.0.0/3',
        '64.0.0.0/2',
        '128.0.0.0/1' 
    ],
    'ip_range_to_prefix 5'
);

@res = ip_range_to_prefix(
    ip_iptobin('0.0.0.0', 4),
    ip_iptobin('255.255.255.254', 4),
    4
);

is_deeply(
    \@res,
    [
        '0.0.0.0/1',
        '128.0.0.0/2',
        '192.0.0.0/3',
        '224.0.0.0/4',
        '240.0.0.0/5',
        '248.0.0.0/6',
        '252.0.0.0/7',
        '254.0.0.0/8',
        '255.0.0.0/9',
        '255.128.0.0/10',
        '255.192.0.0/11',
        '255.224.0.0/12',
        '255.240.0.0/13',
        '255.248.0.0/14',
        '255.252.0.0/15',
        '255.254.0.0/16',
        '255.255.0.0/17',
        '255.255.128.0/18',
        '255.255.192.0/19',
        '255.255.224.0/20',
        '255.255.240.0/21',
        '255.255.248.0/22',
        '255.255.252.0/23',
        '255.255.254.0/24',
        '255.255.255.0/25',
        '255.255.255.128/26',
        '255.255.255.192/27',
        '255.255.255.224/28',
        '255.255.255.240/29',
        '255.255.255.248/30',
        '255.255.255.252/31',
        '255.255.255.254/32'
    ],
    'ip_range_to_prefix 6'
);


# 2000::, 2020::
@res = ip_range_to_prefix(
    '00100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
    '00100000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',
    6
);

is_deeply(
    \@res,
    [
        '2000:0000:0000:0000:0000:0000:0000:0000/11',
        '2020:0000:0000:0000:0000:0000:0000:0000/128'
    ],
    'ip_range_to_prefix 7'
);

@res = ip_range_to_prefix(
    ip_iptobin('AAAA:0000:0000:0000:0000:0000:0000:0000', 6),
    ip_iptobin('AAAA:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF', 6),
    6
);

is_deeply(\@res, ['aaaa:0000:0000:0000:0000:0000:0000:0000/16'], 
    'ip_range_to_prefix 8');

@res = ip_range_to_prefix(
    ip_iptobin('0000:0000:0000:0000:0000:0000:0000:0000', 6),
    ip_iptobin('FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF', 6),
    6
);

is_deeply(\@res, ['0000:0000:0000:0000:0000:0000:0000:0000/0'], 
    'ip_range_to_prefix 9');

@res = ip_range_to_prefix(
    ip_iptobin('0000:0000:0000:0000:0000:0000:0000:0000', 6),
    ip_iptobin('FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFE', 6),
    6
);

is_deeply(\@res, [
          '0000:0000:0000:0000:0000:0000:0000:0000/1',
          '8000:0000:0000:0000:0000:0000:0000:0000/2',
          'c000:0000:0000:0000:0000:0000:0000:0000/3',
          'e000:0000:0000:0000:0000:0000:0000:0000/4',
          'f000:0000:0000:0000:0000:0000:0000:0000/5',
          'f800:0000:0000:0000:0000:0000:0000:0000/6',
          'fc00:0000:0000:0000:0000:0000:0000:0000/7',
          'fe00:0000:0000:0000:0000:0000:0000:0000/8',
          'ff00:0000:0000:0000:0000:0000:0000:0000/9',
          'ff80:0000:0000:0000:0000:0000:0000:0000/10',
          'ffc0:0000:0000:0000:0000:0000:0000:0000/11',
          'ffe0:0000:0000:0000:0000:0000:0000:0000/12',
          'fff0:0000:0000:0000:0000:0000:0000:0000/13',
          'fff8:0000:0000:0000:0000:0000:0000:0000/14',
          'fffc:0000:0000:0000:0000:0000:0000:0000/15',
          'fffe:0000:0000:0000:0000:0000:0000:0000/16',
          'ffff:0000:0000:0000:0000:0000:0000:0000/17',
          'ffff:8000:0000:0000:0000:0000:0000:0000/18',
          'ffff:c000:0000:0000:0000:0000:0000:0000/19',
          'ffff:e000:0000:0000:0000:0000:0000:0000/20',
          'ffff:f000:0000:0000:0000:0000:0000:0000/21',
          'ffff:f800:0000:0000:0000:0000:0000:0000/22',
          'ffff:fc00:0000:0000:0000:0000:0000:0000/23',
          'ffff:fe00:0000:0000:0000:0000:0000:0000/24',
          'ffff:ff00:0000:0000:0000:0000:0000:0000/25',
          'ffff:ff80:0000:0000:0000:0000:0000:0000/26',
          'ffff:ffc0:0000:0000:0000:0000:0000:0000/27',
          'ffff:ffe0:0000:0000:0000:0000:0000:0000/28',
          'ffff:fff0:0000:0000:0000:0000:0000:0000/29',
          'ffff:fff8:0000:0000:0000:0000:0000:0000/30',
          'ffff:fffc:0000:0000:0000:0000:0000:0000/31',
          'ffff:fffe:0000:0000:0000:0000:0000:0000/32',
          'ffff:ffff:0000:0000:0000:0000:0000:0000/33',
          'ffff:ffff:8000:0000:0000:0000:0000:0000/34',
          'ffff:ffff:c000:0000:0000:0000:0000:0000/35',
          'ffff:ffff:e000:0000:0000:0000:0000:0000/36',
          'ffff:ffff:f000:0000:0000:0000:0000:0000/37',
          'ffff:ffff:f800:0000:0000:0000:0000:0000/38',
          'ffff:ffff:fc00:0000:0000:0000:0000:0000/39',
          'ffff:ffff:fe00:0000:0000:0000:0000:0000/40',
          'ffff:ffff:ff00:0000:0000:0000:0000:0000/41',
          'ffff:ffff:ff80:0000:0000:0000:0000:0000/42',
          'ffff:ffff:ffc0:0000:0000:0000:0000:0000/43',
          'ffff:ffff:ffe0:0000:0000:0000:0000:0000/44',
          'ffff:ffff:fff0:0000:0000:0000:0000:0000/45',
          'ffff:ffff:fff8:0000:0000:0000:0000:0000/46',
          'ffff:ffff:fffc:0000:0000:0000:0000:0000/47',
          'ffff:ffff:fffe:0000:0000:0000:0000:0000/48',
          'ffff:ffff:ffff:0000:0000:0000:0000:0000/49',
          'ffff:ffff:ffff:8000:0000:0000:0000:0000/50',
          'ffff:ffff:ffff:c000:0000:0000:0000:0000/51',
          'ffff:ffff:ffff:e000:0000:0000:0000:0000/52',
          'ffff:ffff:ffff:f000:0000:0000:0000:0000/53',
          'ffff:ffff:ffff:f800:0000:0000:0000:0000/54',
          'ffff:ffff:ffff:fc00:0000:0000:0000:0000/55',
          'ffff:ffff:ffff:fe00:0000:0000:0000:0000/56',
          'ffff:ffff:ffff:ff00:0000:0000:0000:0000/57',
          'ffff:ffff:ffff:ff80:0000:0000:0000:0000/58',
          'ffff:ffff:ffff:ffc0:0000:0000:0000:0000/59',
          'ffff:ffff:ffff:ffe0:0000:0000:0000:0000/60',
          'ffff:ffff:ffff:fff0:0000:0000:0000:0000/61',
          'ffff:ffff:ffff:fff8:0000:0000:0000:0000/62',
          'ffff:ffff:ffff:fffc:0000:0000:0000:0000/63',
          'ffff:ffff:ffff:fffe:0000:0000:0000:0000/64',
          'ffff:ffff:ffff:ffff:0000:0000:0000:0000/65',
          'ffff:ffff:ffff:ffff:8000:0000:0000:0000/66',
          'ffff:ffff:ffff:ffff:c000:0000:0000:0000/67',
          'ffff:ffff:ffff:ffff:e000:0000:0000:0000/68',
          'ffff:ffff:ffff:ffff:f000:0000:0000:0000/69',
          'ffff:ffff:ffff:ffff:f800:0000:0000:0000/70',
          'ffff:ffff:ffff:ffff:fc00:0000:0000:0000/71',
          'ffff:ffff:ffff:ffff:fe00:0000:0000:0000/72',
          'ffff:ffff:ffff:ffff:ff00:0000:0000:0000/73',
          'ffff:ffff:ffff:ffff:ff80:0000:0000:0000/74',
          'ffff:ffff:ffff:ffff:ffc0:0000:0000:0000/75',
          'ffff:ffff:ffff:ffff:ffe0:0000:0000:0000/76',
          'ffff:ffff:ffff:ffff:fff0:0000:0000:0000/77',
          'ffff:ffff:ffff:ffff:fff8:0000:0000:0000/78',
          'ffff:ffff:ffff:ffff:fffc:0000:0000:0000/79',
          'ffff:ffff:ffff:ffff:fffe:0000:0000:0000/80',
          'ffff:ffff:ffff:ffff:ffff:0000:0000:0000/81',
          'ffff:ffff:ffff:ffff:ffff:8000:0000:0000/82',
          'ffff:ffff:ffff:ffff:ffff:c000:0000:0000/83',
          'ffff:ffff:ffff:ffff:ffff:e000:0000:0000/84',
          'ffff:ffff:ffff:ffff:ffff:f000:0000:0000/85',
          'ffff:ffff:ffff:ffff:ffff:f800:0000:0000/86',
          'ffff:ffff:ffff:ffff:ffff:fc00:0000:0000/87',
          'ffff:ffff:ffff:ffff:ffff:fe00:0000:0000/88',
          'ffff:ffff:ffff:ffff:ffff:ff00:0000:0000/89',
          'ffff:ffff:ffff:ffff:ffff:ff80:0000:0000/90',
          'ffff:ffff:ffff:ffff:ffff:ffc0:0000:0000/91',
          'ffff:ffff:ffff:ffff:ffff:ffe0:0000:0000/92',
          'ffff:ffff:ffff:ffff:ffff:fff0:0000:0000/93',
          'ffff:ffff:ffff:ffff:ffff:fff8:0000:0000/94',
          'ffff:ffff:ffff:ffff:ffff:fffc:0000:0000/95',
          'ffff:ffff:ffff:ffff:ffff:fffe:0000:0000/96',
          'ffff:ffff:ffff:ffff:ffff:ffff:0000:0000/97',
          'ffff:ffff:ffff:ffff:ffff:ffff:8000:0000/98',
          'ffff:ffff:ffff:ffff:ffff:ffff:c000:0000/99',
          'ffff:ffff:ffff:ffff:ffff:ffff:e000:0000/100',
          'ffff:ffff:ffff:ffff:ffff:ffff:f000:0000/101',
          'ffff:ffff:ffff:ffff:ffff:ffff:f800:0000/102',
          'ffff:ffff:ffff:ffff:ffff:ffff:fc00:0000/103',
          'ffff:ffff:ffff:ffff:ffff:ffff:fe00:0000/104',
          'ffff:ffff:ffff:ffff:ffff:ffff:ff00:0000/105',
          'ffff:ffff:ffff:ffff:ffff:ffff:ff80:0000/106',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffc0:0000/107',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffe0:0000/108',
          'ffff:ffff:ffff:ffff:ffff:ffff:fff0:0000/109',
          'ffff:ffff:ffff:ffff:ffff:ffff:fff8:0000/110',
          'ffff:ffff:ffff:ffff:ffff:ffff:fffc:0000/111',
          'ffff:ffff:ffff:ffff:ffff:ffff:fffe:0000/112',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:0000/113',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:8000/114',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:c000/115',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:e000/116',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:f000/117',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:f800/118',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:fc00/119',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:fe00/120',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff00/121',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ff80/122',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffc0/123',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffe0/124',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:fff0/125',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:fff8/126',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffc/127',
          'ffff:ffff:ffff:ffff:ffff:ffff:ffff:fffe/128'
        ], 'ip_range_to_prefix 10');

@res = ip_range_to_prefix(
    ip_iptobin('FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF', 6),
    ip_iptobin('FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF:FFFF', 6),
    6
);

is_deeply(\@res, 
          [ 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff/128' ],
          'ip_range_to_prefix 11');

1;
