#
# Perl ARP Extension makefile
#
# Programmed by Bastian Ballmann
# Last update: 27.04.2020
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

use ExtUtils::MakeMaker;
use Config;

BEGIN {
      eval { require Net::Pcap };

      if($@)
      {
          print "Module Net::Pcap is required for make test!\n";
      }
}

if($Config{'osname'} =~ /linux/i)
{
    $flags = "-DLINUX";
    $objects = "ARP.o send_packet_linux.o get_mac_linux.o arp_lookup_linux.o";
}
elsif($Config{'osname'} =~ /bsd|darwin/i)
{
    $flags = "-DBSD";
    $objects = "ARP.o send_packet_bsd.o get_mac_bsd.o arp_lookup_bsd.o";
}
else
{
    $flags = "-DBSD";
    $objects = "ARP.o get_mac_bsd.o arp_lookup_bsd.o";
}

WriteMakefile(
    NAME              => 'Net::ARP',
    VERSION           => '1.0.11',
    AUTHOR            => 'Bastian Ballmann',
    DEFINE            => $flags, 
    OBJECT            => $objects	      
);
