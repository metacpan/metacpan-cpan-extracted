#!/usr/bin/perl

use strict;
use warnings;

use NetAddr::MAC;


# Object-oriented usage
my $obj = NetAddr::MAC->new('00:11:33:aa:bb:cc');
print "Original: ", $obj->original, "\n";
print "OUI: ", $obj->oui, "\n";
print "EUI48: ", ($obj->is_eui48 ? 'yes' : 'no'), "\n";
print "EUI64: ", ($obj->is_eui64 ? 'yes' : 'no'), "\n";
print "Unicast: ", ($obj->is_unicast ? 'yes' : 'no'), "\n";
print "Multicast: ", ($obj->is_multicast ? 'yes' : 'no'), "\n";
print "Broadcast: ", ($obj->is_broadcast ? 'yes' : 'no'), "\n";
print "Local: ", ($obj->is_local ? 'yes' : 'no'), "\n";
print "Universal: ", ($obj->is_universal ? 'yes' : 'no'), "\n";
print "Basic: ", $obj->as_basic, "\n";
print "BPR: ", $obj->as_bpr, "\n";
print "Cisco: ", $obj->as_cisco, "\n";
print "IEEE: ", $obj->as_ieee, "\n";
print "IPv6 Suffix: ", $obj->as_ipv6_suffix, "\n";
print "Microsoft: ", $obj->as_microsoft, "\n";
print "SingleDash: ", $obj->as_singledash, "\n";
print "Sun: ", $obj->as_sun, "\n";
print "TokenRing: ", $obj->as_tokenring, "\n";

# Functional usage
use NetAddr::MAC qw(:all);
my $mac = '00.11.22.33.44.55';
print "\nFunctional checks for $mac\n";
print "EUI48: ", (mac_is_eui48($mac) ? 'yes' : 'no'), "\n";
print "EUI64: ", (mac_is_eui64($mac) ? 'yes' : 'no'), "\n";
print "Unicast: ", (mac_is_unicast($mac) ? 'yes' : 'no'), "\n";
print "Multicast: ", (mac_is_multicast($mac) ? 'yes' : 'no'), "\n";
print "Broadcast: ", (mac_is_broadcast($mac) ? 'yes' : 'no'), "\n";
print "Local: ", (mac_is_local($mac) ? 'yes' : 'no'), "\n";
print "Universal: ", (mac_is_universal($mac) ? 'yes' : 'no'), "\n";
print "Basic: ", mac_as_basic($mac), "\n";
print "Cisco: ", mac_as_cisco($mac), "\n";
print "IEEE: ", mac_as_ieee($mac), "\n";
print "IPv6 Suffix: ", mac_as_ipv6_suffix($mac), "\n";
print "Microsoft: ", mac_as_microsoft($mac), "\n";
print "SingleDash: ", mac_as_singledash($mac), "\n";
print "Sun: ", mac_as_sun($mac), "\n";
print "TokenRing: ", mac_as_tokenring($mac), "\n";

# Error handling
my $bad = NetAddr::MAC->new('notamac');
if (!$bad) {
	print "\nError: $NetAddr::MAC::errstr\n";
}

# Random MAC generation
my $rand_mac = NetAddr::MAC->random(oui => '00:16:3e');
print "\nRandom MAC (EUI-48, OUI 00:16:3e): ", $rand_mac->as_ieee, "\n";
my $rand_mac64 = NetAddr::MAC->random(oui => '00:16:3e:12', eui64 => 1);
print "Random MAC (EUI-64, OUI 00:16:3e:12): ", $rand_mac64->as_ieee, "\n";
