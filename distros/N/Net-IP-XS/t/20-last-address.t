#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 9;

use Net::IP::XS qw(ip_last_address_bin Error Errno);

my $res = ip_last_address_bin('0' x 32, 0, 0);
is(Error(), 'Cannot determine IP version', 'Got correct error');
is(Errno(), 101, 'Got correct errno');

$res = ip_last_address_bin('0' x 32, 0, 4);
is($res, '1' x 32, 'ip_last_address_bin 1');

$res = ip_last_address_bin('0' x 32, 32, 4);
is($res, '0' x 32, 'ip_last_address_bin 2');

$res = ip_last_address_bin('0' x 35, 35, 4);
is($res, '0' x 32, 'ip_last_address_bin 3');

$res = ip_last_address_bin('0' x 35, -5, 4);
is($res, '0' x 32, 'ip_last_address_bin 4');

$res = ip_last_address_bin('11110000111100001111000011110000', 8, 4);
is($res, '11110000'.('1' x 24), 'ip_last_address_bin 5');

$res = ip_last_address_bin('0' x 128, 32, 6);
is($res, ('0' x 32).('1' x 96), 'ip_last_address_bin 6');

$res = ip_last_address_bin('0' x 500, 500, 6);
is($res, ('0' x 128), 'ip_last_address_bin 7');

1;
