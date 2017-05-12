package Net::RTP;

################
#
# Net::RTP: Pure Perl Real-time Transport Protocol (RFC3550)
#
# Nicholas J Humfrey
# njh@cpan.org
#

use Net::RTP::Packet;
use Socket;
use strict;
use Carp;



# Use whatever Superclass we can find first
# we would prefer to have a multicast socket...
BEGIN {
	my @superclasses = (
		'IO::Socket::Multicast6 0.02',
		'IO::Socket::Multicast 1.00',
		'IO::Socket::INET6 2.51',
		'IO::Socket::INET 1.20',
	);
	
	our $SUPER_CLASS = undef;
	foreach my $super (@superclasses) {
		eval "use $super";
		unless ($@) {
			($SUPER_CLASS) = ($super =~ /^([\w:]+)/);
			last;
		}
	}
	
	unless (defined $SUPER_CLASS) {
		die "Failed to load any of super classes.";
	}
	
	
	# Check to see if Socket6 is available
	our $HAVE_SOCKET6 = 0;
	eval "use Socket6 qw/ AF_INET6 unpack_sockaddr_in6 inet_ntop /;";
	$HAVE_SOCKET6=1 unless ($@);
}



use vars qw/$VERSION @ISA $SUPER_CLASS $HAVE_SOCKET6/;
@ISA = ($SUPER_CLASS);
$VERSION="0.09";




sub new {
    my $class = shift;
	unshift @_,(Proto => 'udp') unless @_;
	return $class->SUPER::new(@_);
}


sub configure {
	my($self,$arg) = @_;
	
	# Default to UDP instead of TCP
	$arg->{Proto} ||= 'udp';
	$arg->{ReuseAddr} ||= 1;
	my $result = $self->SUPER::configure($arg);

	
	if (defined $result) {	
		# Join group if it a multicast IP address
		my $group = $self->sockhost();
		if (_is_multicast_ip($group)) {
			if ($self->superclass() =~ /Multicast/) {
				#print "Joining group: $group\n";
				$self->mcast_add( $group ) || croak "Failed to join multicast group";
			} else {
				croak "Error: can't receive multicast without either ".
					  "IO::Socket::Multicast or IO::Socket::Multicast6 installed.";
			}
		} 
	}
	
	return $result;
}


sub _is_multicast_ip {
	my ($group) = @_;
	
	return 0 unless (defined $group);
	
	# IPv4 multicast address ?
	if ($group =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/) {
		return 1 if ($1 >= 224 and $1 <= 239);
		
	# IPv6 multicast address ?
	} elsif ($group =~ /^ff[0-9a-f]{2}\:/i) {
		return 1;
	}

	# Not an multicast IP
	return 0;
}


sub superclass {
	return $SUPER_CLASS;
}


sub recv {
	my $self=shift;
	my ($size) = @_;
	
	# Default read size
	$size = 2048 unless (defined $size);
	
	# Receive a binary packet
	my $data = undef;
	my $sockaddr_in = $self->SUPER::recv($data, $size);
	if (defined $data and $data ne '') {
	
		# Parse the packet
		my $packet = new Net::RTP::Packet( $data );
		
		# Store the source address
		if ($sockaddr_in ne '' and defined $packet)
		{
			if ($self->sockdomain() == &AF_INET) {
				my ($port,$addr) = unpack_sockaddr_in($sockaddr_in);
				$packet->{'source_ip'} = inet_ntoa($addr);
				$packet->{'source_port'} = $port;
				
			} elsif ($HAVE_SOCKET6) {
				eval {
					if ($self->sockdomain() == &AF_INET6) {
						my ($port,$addr) = unpack_sockaddr_in6($sockaddr_in);
						$packet->{'source_ip'} = inet_ntop(&AF_INET6, $addr);
						$packet->{'source_port'} = $port;
					}
				};
			}
			
			# Failed to decode socket address ?
			unless (defined $packet->{'source_ip'}) {
				warn "Failed to get socket address for family: ".$self->sockdomain();
			}
		}
		
		return $packet;
	}
	
	return undef;
}


sub send {
	my $self=shift;
	my ($packet) = @_;
	
	if (!defined $packet or ref($packet) ne 'Net::RTP::Packet') {
		croak "Net::RTP->send() takes a Net::RTP::Packet as its only argument";
	}
	
	# Build packet and send it
	my $data = $packet->encode();
	return $self->SUPER::send($data);
}


sub DESTROY {
    my $self=shift;
	return $self->SUPER::DESTROY(@_);
}



1;

__END__

=pod

=head1 NAME

Net::RTP - Send and receive RTP packets (RFC3550)

=head1 SYNOPSIS

  use Net::RTP;

  my $rtp = new Net::RTP( LocalPort=>5170, LocalAddr=>'233.122.227.171' );
  
  my $packet = $rtp->recv();
  print "Payload type: ".$packet->payload_type()."\n";
  

=head1 DESCRIPTION

The C<Net::RTP> module subclasses L<IO::Socket::Multicast6> to enable
you to manipulate multicast groups. The multicast additions are 
optional, so you may also send and recieve unicast packets.

=over

=item $rtp = new Net::RTP( [LocalAdrr=>$addr, LocalPort=>$port,...] )

The new() method is the constructor for the Net::RTP class. 
It takes the same arguments as L<IO::Socket::INET>, however 
the B<Proto> argument defaults to "udp", which is more appropriate for RTP.

The Net::RTP super-class used will depend on what is available on your system
it will try and use one of the following (in order of preference) :

	IO::Socket::Multicast6 (IPv4 and IPv6 unicast and multicast)
	IO::Socket::Multicast (IPv4 unicast and multicast)
	IO::Socket::INET6 (IPv4 and IPv6 unicast)
	IO::Socket::INET (IPv4 unicast)

If LocalAddr looks like a multicast address, then Net::RTP will automatically 
try and join that multicast group for you.


=item my $packet = $rtp->recv( [$size] )

Blocks and waits for an RTP packet to arrive on the UDP socket.
The read C<$size> defaults to 2048 which is usually big enough to read
an entire RTP packet (as it is advisable that packets are less than 
the Ethernet MTU).

Returns a C<Net::RTP::Packet> object or B<undef> if there is a problem.


=item $rtp->send( $packet )

Send a L<Net::RTP::Packet> from out of the RTP socket. 
The B<PeerPort> and B<PeerAddr> should be defined in order to send packets. 
Returns the number of bytes sent, or the undefined value if there is an error.

=item $rtp->superclass()

Returns the name of the super-class that Net::RTP chose to use.

=back


=head1 SEE ALSO

L<Net::RTP::Packet>

L<IO::Socket::Multicast6>

L<IO::Socket::INET6>

L<IO::Socket::Multicast>

L<IO::Socket::INET>

L<http://www.ietf.org/rfc/rfc3550.txt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-rtp@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you will automatically
be notified of progress on your bug as I make changes.

=head1 AUTHOR

Nicholas J Humfrey, njh@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 University of Southampton

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.005 or, at
your option, any later version of Perl 5 you may have available.


=cut
