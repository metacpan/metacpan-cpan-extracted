#!/usr/bin/env perl
use strict;
use warnings;
use Net::Telnet::Netgear;
use Test::More;

plan skip_all => 'Digest::SHA required for this test!'
    unless eval 'use Digest::SHA; 1';

# Configuration
my @packet_tests = (
    {
        # The method of Net::Telnet::Netgear::Packet to call
        method => 'from_string',
        # The parameters to pass to that method
        params => [ 'Hello world' ],
        # In addition, the params to pass to the constructor of Net::Telnet::Netgear
        constr => [ packet_content => 'Hello world' ],
        # The SHA-1 hash of the expected packet.
        expect => '7b502c3a1f48c8609ae212cdfb639dee39673f5e'
    },
    {
        method => 'from_base64',
        params => [ 'U2hoLCBJJ20gYSBzZWNyZXQgc3RyaW5nIQ==' ],
        constr => [ packet_base64 => 'U2hoLCBJJ20gYSBzZWNyZXQgc3RyaW5nIQ==' ],
        expect => '8d2b98c122639e5cfcbfca3486c683874da00039'
    },
    {
        method => 'new',
        params => [ mac => 'AA:BB:CC:DD:EE:FF' ],
        constr => [ packet_mac => 'AA:BB:CC:DD:EE:FF' ],
        expect => 'bce8be8764099fbb4012acbaec12e811c0b2ba88'
    },
    {
        method => 'new',
        params => [
            mac      => 'AA:BB:CC:DD:EE:FF',
            username => '123456abc',
            password => 'cba654321'
        ],
        constr => [
            packet_mac      => 'AA:BB:CC:DD:EE:FF',
            packet_username => '123456abc',
            packet_password => 'cba654321'
        ],
        expect => 'e6165958232ef674f53c3e0d53f144e54df0ad02'
    },
    {
        method => 'new',
        params => [
            mac      => 'AA:BB:CC:DD:EE:FF',
            username => 'admin',
            password => 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
        ],
        constr => [
            packet_mac      => 'AA:BB:CC:DD:EE:FF',
            packet_username => 'admin',
            packet_password => 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
        ],
        expect => 'b8ee6e186dcffa63f2bea38a0a0e0cc81af8186a'
    }
);

plan tests => 2 * @packet_tests;

foreach my $conf (@packet_tests)
{
    # Create the packet instance.
    my $method = $conf->{method};
    my $packet = Net::Telnet::Netgear::Packet->$method (@{$conf->{params}});
    is $conf->{expect}, Digest::SHA::sha1_hex ($packet->get_packet),
        "packet generated by $method is as expected";
    # Now repeat the test, using Net::Telnet::Netgear->new.
    my $inst = Net::Telnet::Netgear->new (@{$conf->{constr}});
    is $conf->{expect}, Digest::SHA::sha1_hex ($inst->packet),
        'packet generated by the constructor is as expected';
}
