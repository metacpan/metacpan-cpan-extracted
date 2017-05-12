#!/usr/local/bin/perl

# Sys::HostAddr main.t
# $Id: test.pl,v 1.0 2010/10/06 10:32:25 jkister Exp $
# Copyright (c) 2010-2014 Jeremy Kister.
# Released under Perl's Artistic License.

BEGIN {
    #https://rt.cpan.org/Public/Bug/Display.html?id=82629
    $ENV{LC_ALL} = 'C';
};

use strict;
use Test::Simple tests => 6;

use Sys::HostAddr;

my $sysaddr = Sys::HostAddr->new( debug => 0 );

ok( $sysaddr->{class} eq 'Sys::HostAddr', "testing Sys::HostAddr v$Sys::HostAddr::VERSION on platform: $^O" );

my $main_ip = $sysaddr->main_ip();
ok( $main_ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/, "Main IP Address appears to be: $main_ip" );

my $first_ip = $sysaddr->first_ip();
ok( $first_ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/, "First IP Adddress is: $first_ip" );

# don't test public method, no good way for cpan auto installs
    
my $href = $sysaddr->ip();
my $info = "IP info:\n";
my $i = 0;
my $a = 0;
foreach my $interface ( keys %{$href} ){
    $i++ unless ($interface =~ /^lo\d*/);
    foreach my $aref ( @{$href->{$interface}} ){
        $info .= "$interface: $aref->{address}/$aref->{netmask}\n";
        $a++ unless($aref->{address} =~ /^127\./);
    }
}
ok( $i && $a, $info );

my $addrs;
my $addr_aref = $sysaddr->addresses();
foreach my $address ( @{$addr_aref} ){
    $addrs .= "Found IP address: $address\n";
}
ok( @{$addr_aref} > 0, $addrs ); # 127.0? + other - win32 doesnt include 127

my $ints;
my $int_aref = $sysaddr->interfaces();
foreach my $interface ( @{$int_aref} ){
    $ints .= "Found interface: $interface\n";
}
ok( @{$int_aref} > 0, $ints );

