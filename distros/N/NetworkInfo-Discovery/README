NetworkInfo/Discovery 
==========================

Note that this is alpha software.  Use at your own risk, and don't complain 
too loudly unless you are giving good advice.  There is much work to be done
with these modules, so check out the TODO or email me your comments, and lets
get cracking.


NetworkInfo::Discovery	is a toolset for the discovery of network information
			and topology.

NetworkInfo::Register	This module handles discovered interfaces, subnets,
			and gateways. It can save and restore the the things
			that we have discovered, and helps fill out unknown
			details.
			
NetworkInfo::Discovery::Host	represents all that we know about a 
				discovered host.

NetworkInfo::Discovery::Sniff	is a discovery module that sniffs the local
				segment to discover information about
				interfaces.
				
NetworkInfo::Discovery::Traceroute is a discovery module that maps the hops
				   from the local segment to other known
				   interfaces, helping to show us the topology.

NetworkInfo::Discovery::Scan	is a discovery module that scans ranges of
				ip addresses for open ports, and to detect
				new interfaces.

INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

SYSTEM REQUIREMENTS

So far we have only tested on the following setups.  I am looking for 
contributors, even if you just want to install and run the test scripts.

Perl 5.6.1, Solaris 7
perl 5.8.0, linux-pcc
perl 5.8.0, RedHat Linux 8.0
perl 5.6.0, RedHat Linux 7.2
perl 5.6.1, RedHat Linux 7.2
perl 5.6.0, RedHat Linux 7.3
perl 5.6.1, RedHat Linux 7.3

AVAILABILITY

This module can be found in CPAN at http://www.cpan.org/authors/id/T/TS/TSCANLAN/
or at http://they.gotdns.org:88/~tscanlan/perl/

DEPENDENCIES

This module requires these other modules and libraries:

  NetworkInfo::Discovery::Sniff
    Net-Pcap		0.04
    NetPacket		0.03

  NetworkInfo::Discovery::Traceroute
    Net-Traceroute	1.05

AUTHOR

Please send any questions, bugs, or contributions to
Tom Scanlan <tscanlan@they.gotdns.org>

COPYRIGHT AND LICENCE

Copyright (c) 2002 Thomas P. Scanlan IV.  All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
