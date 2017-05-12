package Net::Telnet::Netgear::Packet;
use strict;
use warnings;

sub new
{
    require Net::Telnet::Netgear::Packet::Native;
    Net::Telnet::Netgear::Packet::Native->new (splice (@_, 1));
}

sub from_string
{
    require Net::Telnet::Netgear::Packet::String;
    Net::Telnet::Netgear::Packet::String->new (splice (@_, 1));
}

sub from_base64
{
    require Net::Telnet::Netgear::Packet::String;
    Net::Telnet::Netgear::Packet::String->from_base64 (splice (@_, 1));
}

sub get_packet
{
    die "Method 'get_packet' not implemented in subclass";
}

1;

=encoding utf8

=head1 NAME

Net::Telnet::Netgear::Packet - generates "telnet enable packets" for Netgear routers

=head1 SYNOPSIS

    use Net::Telnet::Netgear::Packet;
    # From a string
    my $packet = Net::Telnet::Netgear::Packet->from_string ('...');
    # From a Base64-encoded string
    my $packet = Net::Telnet::Netgear::Packet->from_base64 ('Li4u');
    # From the MAC address of the router
    my $packet = Net::Telnet::Netgear::Packet->new (
        mac      => 'AA:BB:CC:DD:EE:FF',
        username => 'admin',  # optional
        password => 'hunter2' # optional
    );
    # Gets the packet as a string.
    my $string = $packet->get_packet;

=head1 DESCRIPTION

This module allows to generate "telnet enable packets" usable with Netgear routers to unlock the
telnet interface.

You can either provide a pre-generated packet from a string or you can let the module generate
it with the MAC address of the router. It's also possible to specify the username and password
that will be put in the packet.

This module is just a wrapper - the code which handles the packets
is in C<Net::Telnet::Netgear::Packet::Native> or C<Net::Telnet::Netgear::Packet::String>,
depending on which constructor you use.

=head1 METHODS

=head2 new

    my $packet = Net::Telnet::Netgear::Packet->new (%options);

Creates a C<Net::Telnet::Netgear::Packet::Native> instance.

C<%options> can be populated with the following items:

=over 4

=item * C<< mac => 'AA:BB:CC:DD:EE' >>

The MAC address of your router. I<This is required.>

=item * C<< username => 'admin' >>

Optional, the username which will be put in the packet.
Defaults to C<Gearguy> for compatibility reasons.

=item * C<< password => 'hunter2' >>

Optional, the password which will be put in the packet.
Defaults to C<Geardog> for compatibility reasons.

=back

B<NOTE:> the packet is generated each time L</"get_packet"> is called, so it's recommended
to store the returned value in a variable and use that instead of calling the method each time.

=head2 from_string

    my $packet = Net::Telnet::Netgear::Packet->from_string ('str');

Creates a C<Net::Telnet::Netgear::Packet::String> instance.

The string has to be 128 bytes, but this check is not enforced.

=head2 from_base64

    my $packet = Net::Telnet::Netgear::Packet->from_base64 ('...');

Creates a C<Net::Telnet::Netgear::Packet::String> instance.

The decoded string has to be 128 bytes, but this check is not enforced.

=head2 get_packet

    my $packet_str = $packet->get_packet;

Retrieves the generated packet (or the user provided one).

This method must be implemented by the subclasses, and dies if it isn't (or if it is called
directly on this class).

=head1 SEE ALSO

L<Net::Telnet::Netgear>, L<http://wiki.openwrt.org/toh/netgear/telnet.console>,
L<https://github.com/Robertof/perl-net-telnet-netgear>.

=head1 AUTHOR

Roberto Frenna (robertof AT cpan DOT org)

=head1 THANKS

See L<Net::Telnet::Netgear/"THANKS">.

=head1 LICENSE

Copyright (C) 2014-2015, Roberto Frenna.

This program is free software, you can redistribute it and/or modify it under the terms of the
Artistic License version 2.0.

=cut
