#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 36;

use Net::IP::XS;

my $str = "asdf";
my $obj = bless \$str, "Temporary";

for (qw(print size_str intip_str hexip hexmask prefix mask
        iptype reverse_ip last_bin last_int_str last_ip
        short find_prefixes)) {
    my $fn_name = "Net::IP::XS::$_";
    is(eval("$fn_name(\$obj)"), undef, 
        "Got undef on calling $_ on non-Net-IP-XS object");
    ok((not $@), "Did not die on calling $_");
    diag $@ if $@;
}

for (qw(binadd aggregate overlaps)) {
    my $fn_name = "Net::IP::XS::$_";
    is(eval("$fn_name(\$obj, \$obj)"), undef, 
        "Got undef on calling $_ on non-Net-IP-XS objects");
    ok((not $@), "Did not die on calling $_");
    diag $@ if $@;
}

is(Net::IP::XS::ip_add_num($obj, 100, undef), undef,
    'Got undef on calling ip_add_num on non-Net-IP-XS object');
is(Net::IP::XS::bincomp($obj, 'lt', $obj), undef,
    'Got undef on calling bincomp on non-Net-IP-XS objects');

1;
