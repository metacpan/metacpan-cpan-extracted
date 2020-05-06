#
# Test get_mac function
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

$mac = Net::ARP::get_mac($dev);
ok( $mac ne "unknown", "not unkown mac $dev -> $mac" );

