#
# Test get_mac function
#
# Programmed by Bastian Ballmann
# Last update: 31.01.2007

use Net::ARP;
use Test::More qw( no_plan );

$mac = Net::ARP::get_mac("strange_dev_value");
ok( $mac eq "unknown", "unkown mac on strange dev value -> $mac" );

