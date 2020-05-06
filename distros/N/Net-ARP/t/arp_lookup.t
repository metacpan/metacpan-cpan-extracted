#
# Test arp_lookup function
#
# Programmed by Bastian Ballmann
# Last update: 27.04.2020

use Net::ARP;
use Test::More qw( no_plan );

BEGIN
{
    eval{ require Net::Pcap; };
              
    if($@ =~ /^Can\'t\slocate/)
    {
        $dev = "enp3s0f1";
    }
    else
    {
   	import Net::Pcap;
        $dev = Net::Pcap::lookupdev(\$errbuf);
    }
}

$mac = Net::ARP::arp_lookup("strange_dev_value","127.0.0.1");
ok( $mac eq "unknown", "unkown mac on strange dev value -> $mac" );

$mac = Net::ARP::arp_lookup("$fu","127.0.0.1");
ok( $mac eq "unknown", "unkown mac on strange dev value 2 -> $mac" );

$mac = Net::ARP::arp_lookup($dev,"this_is_not_an_ip_address");
ok( $mac eq "unknown", "unkown mac on strange ip value -> $mac" );

#Net::ARP::arp_lookup($dev,"192.168.1.1","fu");
#ok( $mac eq "unknown", "unkown mac on strange mac value" );
