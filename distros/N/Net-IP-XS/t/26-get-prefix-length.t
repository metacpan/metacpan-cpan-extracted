#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 17;

use Net::IP::XS qw(ip_get_prefix_length
                   ip_iptobin
                   Error
                   Errno);

my $res = ip_get_prefix_length('1', '11');
is($res, undef, 'Got undef on different lengths');
is(Error(), 'IP addresses of different length', 'Got correct error');
is(Errno(), 130, 'Got correct errno');

my @data = (
    [ qw(127.0.0.0 127.0.0.0       4 0) ],
    [ qw(127.0.0.0 127.0.0.1       4 1) ],
    [ qw(127.0.0.0 127.0.0.2       4 0) ],
    [ qw(127.0.0.0 127.0.0.3       4 2) ],
    [ qw(127.0.0.0 127.0.0.4       4 0) ],
    [ qw(127.0.0.0 127.0.0.5       4 1) ],
    [ qw(127.0.0.0 127.0.0.6       4 0) ],
    [ qw(127.0.0.0 127.0.0.7       4 3) ],
    [ qw(127.0.0.0 127.0.0.255     4 8) ],
    [ qw(127.0.0.0 127.0.255.255   4 16) ],
    [ qw(127.0.0.0 127.255.255.255 4 24) ],
    [ qw(0.0.0.0   255.255.255.255 4 32) ],
    [ (join ':', ('0000') x 8),
      (join ':', (('0000') x 7, 'ffff')),
      6, 16 ],
    [ (join ':', ('0000') x 8),
      (join ':', ('ffff') x 8),
      6, 128 ],
);

for (@data) {
    my ($addr1, $addr2, $version, $len_exp) = @{$_};
    my $len = ip_get_prefix_length(ip_iptobin($addr1, $version),
                                   ip_iptobin($addr2, $version));
    is($len, $len_exp, "$addr1 - $addr2");
}

1;
