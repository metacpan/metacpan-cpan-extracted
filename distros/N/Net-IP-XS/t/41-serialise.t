#!/usr/bin/env perl

use warnings;
use strict;

use Net::IP::XS;

use Storable qw(freeze thaw);
use File::Temp qw(tempfile);
my (undef, $ft) = tempfile();

use Test::More tests => 6;
use Scalar::Util qw(blessed);

{
    my $ip = Net::IP::XS->new('::/0');
    is($ip->size(), 
    '340282366920938463463374607431768211456', 
    "Got size for IP address");
    my $serial = freeze($ip);
    open my $fh, '>', $ft or die $!;
    print $fh $serial;
    close $fh;
    undef $ip;
    undef $serial;

    open $fh, '<', $ft or die $!;
    my $con = do { local $/; <$fh> };
    close $fh;
    $ip = thaw($con);
    is($ip->size(), 
    '340282366920938463463374607431768211456', 
    "Got size for IP address");
    undef $ip;
    ok(1, "Completed serial-deserial process for IPv6 without issues");
}

{
    my $ip = Net::IP::XS->new('0.0.0.0/0');
    is($ip->size(), 
       '4294967296',
       "Got size for IP address");
    my $serial = freeze($ip);
    open my $fh, '>', $ft or die $!;
    print $fh $serial;
    close $fh;
    undef $ip;
    undef $serial;

    open $fh, '<', $ft or die $!;
    my $con = do { local $/; <$fh> };
    close $fh;
    $ip = thaw($con);
    is($ip->size(), 
       '4294967296',
       "Got size for IP address");
    undef $ip;
    ok(1, "Completed serial-deserial process for IPv4 without issues");
}

1;
