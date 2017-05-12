package Net::Wake;

use strict;
use IO::Socket;

use vars qw($VERSION);
$VERSION = '0.02';

=head1 NAME

Net::Wake - A package to send packets to power on computers.

=head1 SYNOPSIS

To send a wake-on-lan packet via UDP:
Net::Wake::by_udp('255.255.255.255', '00:00:87:A0:8A:D2');

Or directly from the command line:

perl -MNet::Wake -e "Net::Wake::by_udp(undef,'00:00:87:A0:8A:D2')"


=head1 DESCRIPTION

This package sends wake-on-lan (AKA magic) packets to turn on machines that
are wake-on-lan capable.

For now there is only one function in this package:
Net::Wake::by_udp([$host], $mac_address, [$port]);

You can omit the colons in the $mac_address, but not leading zeros.

Generally speaking, you should use a broadcast address for $host.
Using the host's last known IP address is usually not sufficient
since the IP address may no longer be in the ARP cache.
A $host value of '255.255.255.255' is implied if $host is undef.
If you wish to send a magic packet to a remote subnet,
you can use a variation of '192.168.0.255', given that you know
the subnet mask to generate the proper broadcast address.

=head1 SEE ALSO

  http://gsd.di.uminho.pt/jpo/software/wakeonlan/mini-howto/

=head1 COPYRIGHT

Copyright 1999-2003 Clinton Wong

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

sub by_udp {
  my ($host, $mac_addr, $port) = @_;

  # use the discard service if $port not passed in
  if (! defined $host) { $host = '255.255.255.255' }
  if (! defined $port || $port !~ /^\d+$/ ) { $port = 9 }

  my $sock = new IO::Socket::INET(Proto=>'udp') || return undef;

  my $ip_addr = inet_aton($host);
  my $sock_addr = sockaddr_in($port, $ip_addr);
  $mac_addr =~ s/://g;
  my $packet = pack('C6H*', 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, $mac_addr x 16);

  setsockopt($sock, SOL_SOCKET, SO_BROADCAST, 1);
  send($sock, $packet, 0, $sock_addr);
  close ($sock);

  return 1;
}

1;

