#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Configuration
my %mutators     = (
    exit_on_destroy     => 1,
    packet_delay        => 5.001,
    packet_wait_timeout => 1.5,
    packet_send_mode    => 'tcp',
    packet              => 'test it off, test it off'
);
my @packet_impl  = qw/Net::Telnet::Netgear::Packet::Native Net::Telnet::Netgear::Packet::String/;

# 16 base tests + 2 per ::Packet implementation + 1 per mutator
plan tests => 16 + (2 * @packet_impl) + keys %mutators;

require_ok 'Net::Telnet::Netgear'
    || BAIL_OUT "Can't load Net::Telnet::Netgear";
require_ok 'Net::Telnet::Netgear::Packet'
    || BAIL_OUT "Can't load Net::Telnet::Netgear::Packet";
require_ok 'Net::Telnet::Netgear::Packet::Native'
    || BAIL_OUT "Can't load Net::Telnet::Netgear::Packet::Native";
require_ok 'Net::Telnet::Netgear::Packet::String'
    || BAIL_OUT "Can't load Net::Telnet::Netgear::Packet::String";

can_ok 'Net::Telnet::Netgear', 'new', 'open', 'fhopen', 'apply_netgear_defaults', keys %mutators;
can_ok 'Net::Telnet::Netgear::Packet', 'new', 'from_string', 'from_base64', 'get_packet';

foreach (@packet_impl)
{
    isa_ok $_, 'Net::Telnet::Netgear::Packet';
    can_ok $_, 'new', 'get_packet';
}

my $packet = Net::Telnet::Netgear::Packet->new (mac => "AA:BB:CC:DD:EE:FF");
isa_ok $packet, 'Net::Telnet::Netgear::Packet::Native';

$packet = Net::Telnet::Netgear::Packet->from_string ("xxx");
isa_ok $packet, 'Net::Telnet::Netgear::Packet::String';
is $packet->get_packet, 'xxx', 'pkt->from_string("xxx") == xxx';

$packet = Net::Telnet::Netgear::Packet->from_base64 ("eHh4");
isa_ok $packet, 'Net::Telnet::Netgear::Packet::String';
is $packet->get_packet, 'xxx', 'pkt->from_base64("eHh4") == xxx';

my $class = Net::Telnet::Netgear->new;
isa_ok $class, 'Net::Telnet';
isa_ok $class, 'Net::Telnet::Netgear';

# Trigger the argument parsing code of the constructor.
$class = Net::Telnet::Netgear->new (
    packet_instance => $packet
);
isa_ok $class, 'Net::Telnet';
isa_ok $class, 'Net::Telnet::Netgear';
is $class->packet, 'xxx', 'instance->packet == xxx';

# Test the mutators.
foreach my $mutator (keys %mutators)
{
    $class->$mutator ($mutators{$mutator});
    is $class->$mutator(), $mutators{$mutator}, 'mutator("val"); mutator() == "val" (mutator test)';
}
