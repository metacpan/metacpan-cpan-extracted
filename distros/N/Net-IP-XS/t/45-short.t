#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 33;

use Net::IP::XS;

for my $len (0..8) {
    my $ip = Net::IP::XS->new("0.0.0.0/$len");
    is($ip->short(), "0", "Correct short form (prefix length $len)");
}
for my $len (9..16) {
    my $ip = Net::IP::XS->new("0.0.0.0/$len");
    is($ip->short(), "0.0", "Correct short form (prefix length $len)");
}
for my $len (17..24) {
    my $ip = Net::IP::XS->new("0.0.0.0/$len");
    is($ip->short(), "0.0.0", "Correct short form (prefix length $len)");
}
for my $len (25..32) {
    my $ip = Net::IP::XS->new("0.0.0.0/$len");
    is($ip->short(), "0.0.0.0", "Correct short form (prefix length $len)");
}

1;
