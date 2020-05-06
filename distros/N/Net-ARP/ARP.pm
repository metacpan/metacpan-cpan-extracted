#
# Perl ARP Extension
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

package Net::ARP;

use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use ARP ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '1.0.11';

require XSLoader;
XSLoader::load('Net::ARP', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

ARP - Perl extension for creating ARP packets

=head1 SYNOPSIS

  use Net::ARP;
  Net::ARP::send_packet('lo',                 # Device
                        '127.0.0.1',          # Source IP
	                '127.0.0.1',          # Destination IP
		        'aa:bb:cc:aa:bb:cc',  # Source MAC
	                'aa:bb:cc:aa:bb:cc',  # Destinaton MAC
	                'reply');             # ARP operation

$mac = Net::ARP::get_mac("enp3s0f1");

print "$mac\n";

$mac = Net::ARP::arp_lookup($dev,"192.168.1.1");

print "192.168.1.1 has got mac $mac\n";


=head2 IMPORTANT

Version 1.0 will break with the API of PRE-1.0 versions, 
because the return value of arp_lookup() and get_mac()
will no longer be passed as parameter, but returned!
I hope this decision is ok as long as we get a cleaner and more perlish API.


=head2 DESCRIPTION

This module can be used to create and send ARP packets and to
get the mac address of an ethernet interface or ip address.

=over

=item B<send_packet()>

  Net::ARP::send_packet('lo',                 # Device
                        '127.0.0.1',          # Source IP
	                '127.0.0.1',          # Destination IP
		        'aa:bb:cc:aa:bb:cc',  # Source MAC
	                'aa:bb:cc:aa:bb:cc',  # Destinaton MAC
	                'reply');             # ARP operation

  I think this is self documentating.
  ARP operation can be one of the following values:
  request, reply, revrequest, revreply, invrequest, invreply.

=item B<get_mac()>

  $mac = Net::ARP::get_mac("eth0");

  This gets the MAC address of the eth0 interface and stores 
  it in the variable $mac. The return value is "unknown" if
  the mac cannot be looked up.

=item B<arp_lookup()>

  $mac = Net::ARP::arp_lookup($dev,"192.168.1.1");

  This looks up the MAC address for the ip address 192.168.1.1
  and stores it in the variable $mac. The return value is 
  "unknown" if the mac cannot be looked up.

=back

=head1 SEE ALSO

 man -a arp

=head1 AUTHOR

 Bastian Ballmann [ balle@codekid.net ]
 http://www.codekid.net

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2020 by Bastian Ballmann

License: GPLv2


=cut
