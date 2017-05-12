#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 36;

use Net::IP::XS qw(:PROC);

for (qw(Error Errno ip_iptobin ip_bintoip ip_iplengths ip_bintoint 
        ip_inttobin ip_expand_address ip_is_ipv4 ip_is_ipv6 
        ip_get_version ip_get_mask ip_last_address_bin ip_splitprefix 
        ip_is_valid_mask ip_bincomp ip_binadd ip_get_prefix_length 
        ip_compress_v4_prefix ip_is_overlap ip_check_prefix 
        ip_range_to_prefix ip_get_embedded_ipv4 ip_aggregate 
        ip_prefix_to_range ip_reverse ip_normalize 
        ip_compress_address ip_iptype ip_auth ip_normal_range)) {
    ok(main->can($_), "Imported function $_ with PROC");
}

is($IP_NO_OVERLAP,      0, 'IP_NO_OVERLAP has correct value');
is($IP_PARTIAL_OVERLAP, 1, 'IP_PARTIAL_OVERLAP has correct value');
is($IP_A_IN_B_OVERLAP, -1, 'IP_A_IN_B_OVERLAP has correct value');
is($IP_B_IN_A_OVERLAP, -2, 'IP_B_IN_A_OVERLAP has correct value');
is($IP_IDENTICAL,      -3, 'IP_IDENTICAL has correct value');

1;
