#!perl

use strict;
use warnings;

use Test::More 0.96;
use Test::Exception;

use Net::CIDR::Set;


my $set = Net::CIDR::Set->new;

throws_ok {
    $set->add("\x{0661}0.0.0.0/8");
} qr{^Can't decode \x{0661}0\.0\.0\.0/8 as an IPv4 or IPv6 address};

$set->add("10.0.0.0/8");

throws_ok {
    $set->add("1.1.1.1/09");
} qr{^Can't decode 1\.1\.1\.1/09 as an IPv4 (or IPv6 )?address};

throws_ok {
    $set->contains("10\n.0.0.0");
} qr{^Can't decode 10\n\.0\.0\.0 as an IPv4 or IPv6 address}s;

throws_ok {
    Net::CIDR::Set->new->add("::1/foo");
} qr{^Can't decode ::1/foo as an IPv4 or IPv6 address};


throws_ok {
    Net::CIDR::Set->new->add("::1/02");
} qr{^Can't decode ::1/02 as an IPv4 or IPv6 address};


done_testing;
