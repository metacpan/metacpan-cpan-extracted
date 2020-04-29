#
# Test get_mac function
#
# Programmed by Bastian Ballmann
# Last update: 27.04.2020

use Net::ARP;
use Test::More qw( no_plan );

$mac = Net::ARP::get_mac("enp3s0f1");
ok( $mac ne "unknown", "not unkown mac enp3s0f1 -> $mac" );

