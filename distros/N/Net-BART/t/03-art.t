#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'lib';
use Net::BART::Art qw(pfx_to_idx octet_to_idx idx_to_pfx prefix_decompose);

# pfx_to_idx
is(pfx_to_idx(0, 0), 1, '/0 maps to index 1');
is(pfx_to_idx(0, 1), 2, '0.../1 maps to index 2');
is(pfx_to_idx(128, 1), 3, '1.../1 maps to index 3');
is(pfx_to_idx(0b10100000, 3), 13, '160/3 = index 13');
# (160 >> 5) + 8 = 5 + 8 = 13

# octet_to_idx
is(octet_to_idx(0), 128, 'octet 0 -> idx 128');
is(octet_to_idx(1), 128, 'octet 1 -> idx 128 (LSB lost)');
is(octet_to_idx(2), 129, 'octet 2 -> idx 129');
is(octet_to_idx(254), 255, 'octet 254 -> idx 255');
is(octet_to_idx(255), 255, 'octet 255 -> idx 255');

# idx_to_pfx round-trip
for my $pfx_len (0 .. 7) {
    my $count = 1 << $pfx_len;
    for my $i (0 .. $count - 1) {
        my $octet = $i << (8 - $pfx_len);
        my $idx = pfx_to_idx($octet, $pfx_len);
        my ($got_octet, $got_len) = idx_to_pfx($idx);
        is($got_len, $pfx_len, "round-trip pfx_len for idx $idx");
        is($got_octet, $octet, "round-trip octet for idx $idx");
    }
}

# prefix_decompose
{
    my ($s, $lb) = prefix_decompose(0);
    is($s, 0, '/0: strides=0');
    is($lb, 0, '/0: lastbits=0');
}
{
    my ($s, $lb) = prefix_decompose(8);
    is($s, 1, '/8: strides=1');
    is($lb, 0, '/8: lastbits=0 (fringe)');
}
{
    my ($s, $lb) = prefix_decompose(12);
    is($s, 1, '/12: strides=1');
    is($lb, 4, '/12: lastbits=4');
}
{
    my ($s, $lb) = prefix_decompose(22);
    is($s, 2, '/22: strides=2');
    is($lb, 6, '/22: lastbits=6');
}
{
    my ($s, $lb) = prefix_decompose(24);
    is($s, 3, '/24: strides=3');
    is($lb, 0, '/24: lastbits=0 (fringe)');
}
{
    my ($s, $lb) = prefix_decompose(32);
    is($s, 4, '/32: strides=4');
    is($lb, 0, '/32: lastbits=0 (fringe)');
}

done_testing;
