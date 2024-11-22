#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 33;

use Net::IP::XS;

sub diag_error
{
    my $errno = $Net::IP::XS::ERRNO || 0;
    my $error = $Net::IP::XS::ERROR;

    if ($errno == 0 and not $error) {
        diag "No Net::IP::XS error recorded.";
    } else {
        $error ||= "undefined";
        diag "$errno: $error";
    }
}

for my $len (0..8) {
    my $ip = Net::IP::XS->new("0.0.0.0/$len");
    my $res = is($ip->short(), "0", "Correct short form (prefix length $len)");
    if (not $res) {
        diag_error();
    }
}
for my $len (9..16) {
    my $ip = Net::IP::XS->new("0.0.0.0/$len");
    my $res = is($ip->short(), "0.0", "Correct short form (prefix length $len)");
    if (not $res) {
        diag_error();
    }
}
for my $len (17..24) {
    my $ip = Net::IP::XS->new("0.0.0.0/$len");
    my $res = is($ip->short(), "0.0.0", "Correct short form (prefix length $len)");
    if (not $res) {
        diag_error();
    }
}
for my $len (25..32) {
    my $ip = Net::IP::XS->new("0.0.0.0/$len");
    my $res = is($ip->short(), "0.0.0.0", "Correct short form (prefix length $len)");
    if (not $res) {
        diag_error();
    }
}

1;
