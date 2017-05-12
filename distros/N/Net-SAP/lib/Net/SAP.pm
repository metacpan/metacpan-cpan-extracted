package Net::SAP;

################
#
# SAP: Session Announcement Protocol (RFC2974)
#
# Nicholas J Humfrey
# njh@cpan.org
#

use strict;
use Carp;

use Net::SAP::Packet;
use Socket qw/ unpack_sockaddr_in /;
use Socket6 qw/ inet_ntop inet_pton unpack_sockaddr_in6 /;
use IO::Socket::Multicast6;

use vars qw/$VERSION/;
our $VERSION="0.10";



# User friendly names for multicast groups
my %groups = (
	'ipv4'=>		'224.2.127.254',
	'ipv4-local'=>	'239.255.255.255',
	'ipv4-org'=>	'239.195.255.255',
	'ipv4-global'=>	'224.2.127.254',
	
	'ipv6-node'=>	'FF01::2:7FFE',
	'ipv6-link'=>	'FF02::2:7FFE',
	'ipv6-site'=>	'FF05::2:7FFE',
	'ipv6-org'=>	'FF08::2:7FFE',
	'ipv6-global'=>	'FF0E::2:7FFE',
);

my $SAP_PORT = 9875;



sub new {
    my $class = shift;
    my ($group) = @_;
    
    
	# Work out the multicast group to use
    croak "Missing group parameter" unless defined $group;
    if (exists $groups{$group}) {
    	$group = $groups{$group};
    }


	# Store parameters
    my $self = {
    	'group'	=> $group,
    	'port'	=> $SAP_PORT
    };
    
    
    # Create Multicast Socket
	$self->{'socket'} = new IO::Socket::Multicast6(
			LocalAddr => $self->{'group'},
			LocalPort => $SAP_PORT )
	|| return undef;
	
	# Set the TTL for transmitted packets
	$self->{'socket'}->mcast_ttl( 127 );
	
	# Join the multicast group
	$self->{'socket'}->mcast_add( $self->{'group'} ) ||
	die "Failed to join multicast group: $!";
	

    bless $self, $class;
	return $self;
}


#
# Returns the multicast group the socket is bound to
#
sub group {
	my $self = shift;
	return $self->{'group'};
}


#
# Sets the TTL for packets sent
#
sub ttl {
	my $self = shift;
	my ($ttl) = @_;
	
	# Set new TTL if specified
	if (defined $ttl) {
		return undef if ($ttl<0 or $ttl>127);
		$self->{'socket'}->mcast_ttl($ttl);
	}

	return $self->{'socket'}->mcast_ttl();
}


#
# Blocks until a valid SAP packet is received
#
sub receive {
	my $self = shift;
	my $sap_packet = undef;
	
	
	while(!defined $sap_packet) {
	
		# Receive a packet
		my $data = undef;
		my $from = $self->{'socket'}->recv( $data, 1500 );
		die "Failed to receive packet: $!" unless (defined $from);
		next unless (defined $data and length($data));
		
		# Create new packet object from the data we received
		$sap_packet = new Net::SAP::Packet( $data );
		next unless (defined $sap_packet);
		
		# Correct the origin on Stupid packets !
		if ($sap_packet->origin_address() eq '' or
		    $sap_packet->origin_address() eq '0.0.0.0' or
			$sap_packet->origin_address() eq '1.2.3.4' )
		{
			if (sockaddr_family($from)==AF_INET) {
				my ($from_port, $from_ip) = unpack_sockaddr_in( $from );
				$from = inet_ntop( AF_INET, $from_ip );
			} elsif (sockaddr_family($from)==AF_INET6) {
				my ($from_port, $from_ip) = unpack_sockaddr_in6( $from );
				$from = inet_ntop( AF_INET6, $from_ip );
			} else {
				warn "Unknown address family (family=".sockaddr_family($from).")\n";
			}
			$sap_packet->origin_address( $from );
		}
	}

	return $sap_packet;
}


sub send {
	my $self = shift;
	my ($packet) = @_;
	
	croak "Missing data to send." unless defined $packet;


	# If it isn't a packet object, turn it into one	
	if (ref $packet eq 'Net::SDP') {
		my $data = $packet->generate();
		$packet = new Net::SAP::Packet();
		$packet->payload( $data );
	}
	elsif (ref $packet ne 'Net::SAP::Packet') {
		my $data = $packet;
		$packet = new Net::SAP::Packet();
		$packet->payload( $data );
	}

	
	# Assemble and send the packet
	my $data = $packet->generate();
	if (!defined $data) {
		warn "Failed to create binary packet.";
		return -1;
	} elsif (length $data > 1024) {
		warn "Packet is more than 1024 bytes, not sending.";
		return -1;
	} else {
		return $self->{'socket'}->mcast_send( $data, $self->{'group'}, $self->{'port'} );
	}
}


sub close {
	my $self=shift;
	
	# Close the multicast socket
	$self->{'socket'}->close();
	undef $self->{'socket'};
	
}


sub DESTROY {
    my $self=shift;
    
    if (exists $self->{'socket'} and defined $self->{'socket'}) {
    	$self->close();
    }
}


1;

__END__

=pod

=head1 NAME

Net::SAP - Session Announcement Protocol (rfc2974)

=head1 SYNOPSIS

  use Net::SAP;

  my $sap = Net::SAP->new( 'ipv6-global' );

  my $packet = $sap->receive();

  $sap->close();


=head1 DESCRIPTION

Net::SAP allows receiving and sending of SAP (RFC2974) 
multicast packets over IPv4 and IPv6.

=head2 METHODS

=over 4

=item $sap = Net::SAP->new( $group )

The new() method is the constructor for the C<Net::SAP> class.
You must specify the SAP multicast group you want to join:

	ipv4-local
	ipv4-org
	ipv4-global
	ipv6-node
	ipv6-link
	ipv6-site
	ipv6-org
	ipv6-global

Alternatively you may pass the address of the multicast group 
directly. When the C<Net::SAP> object is created, it joins the 
multicast group, ready to start receiving or sending packets.


=item $packet = $sap->receive()

This method blocks until a valid SAP packet has been received.
The packet is parsed, decompressed and returned as a 
C<Net::SAP::Packet> object.


=item $sap->send( $data )

This method sends out SAP packet on the multicast group that the
C<Net::SAP> object to bound to. The $data parameter can either be 
a C<Net::SAP::Packet> object, a C<Net::SDP> object or raw SDP data.

Passing a C<Net::SAP::Packet> object gives the greatest control 
over what is sent. Otherwise default values will be used.

If no origin_address has been set, then it is set to the IP address 
of the first network interface.

Packets greater than 1024 bytes will not be sent. This method 
returns 0 if packet was sent successfully.


=item $group = $sap->group()

Returns the address of the multicast group that the socket is bound to.


=item $ttl = $sap->ttl( [$value] )

Gets or sets the TTL of outgoing packets.

=item $sap->close()

Leave the SAP multicast group and close the socket.

=back

=head1 TODO

=over

=item add automatic detection of IPv6 origin address

=item add method of choosing the network interface to use for multicast

=item Packet decryption and validation

=back

=head1 SEE ALSO

L<Net::SAP::Packet>, L<Net::SDP>, perl(1)

L<http://www.ietf.org/rfc/rfc2974.txt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-sap@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you will automatically
be notified of progress on your bug as I make changes.

=head1 AUTHOR

Nicholas J Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2006 University of Southampton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut
