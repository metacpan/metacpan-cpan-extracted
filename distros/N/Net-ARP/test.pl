#!/usr/bin/perl
#
# Perl ARP Extension test file
#
# Programmed by Bastian Ballmann
# Last update: 28.04.2020
#
# This program is free software; you can redistribute 
# it and/or modify it under the terms of the 
# GNU General Public License version 2 as published 
# by the Free Software Foundation.
#
# This program is distributed in the hope that it will 
# be useful, but WITHOUT ANY WARRANTY; without even 
# the implied warranty of MERCHANTABILITY or FITNESS 
# FOR A PARTICULAR PURPOSE. 
# See the GNU General Public License for more details. 

use ExtUtils::testlib;
use Net::ARP;

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

print "Sending ARP reply packet via dev $dev... ";

$ret = Net::ARP::send_packet($dev,                           # network interface
		      '127.0.0.1',                    # source ip
	              '127.0.0.1',                    # destination ip
		      'aa:bb:cc:aa:bb:cc',            # source mac
	              'ff:ff:ff:ff:ff:ff',            # destination mac
	              'reply');                       # ARP operation 

print $ret ? "ok\n" : "failed\n";

$mac = Net::ARP::get_mac($dev);
print "MAC $mac\n";

$mac = Net::ARP::arp_lookup($dev,"192.168.1.1");
print "192.168.1.1 has got mac $mac\n";

