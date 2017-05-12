package Net::SAP::Packet;

################
#
# Session Announcement Protocol Packet object
#
# Nicholas Humfrey
# njh@ecs.soton.ac.uk
#

use strict;
use Compress::Zlib;
use IO::Interface::Simple;
use Socket qw/ AF_INET /;
use Socket6 qw/ AF_INET6 inet_ntop inet_pton /;
use Carp;

use vars qw/$VERSION/;

$VERSION="0.10";



sub new {
    my $class = shift;
    my ($packet_data) = @_;
    
    # Set defaults
    my $self = {
    	'v'	=> 1,	# Version (1)
    	'a'	=> 0,	# Address type (0=v4, 1=v6)
    	't'	=> 0,	# Message Type (0=announce, 1=delete)
    	'e'	=> 0,	# Encrypted (0=no, 1=yes)
    	'c'	=> 0,	# Compressed (0=no, 1=yes)
    	'origin_address' => undef,	# No Origin
    	'msg_id_hash' => 0,       	# No Message Hash
    	'auth_len'	=> 0,
    	'auth_data'	=> '',
    	'payload_type'	=> 'application/sdp',
    	'payload'	=> '',
    };
	bless $self, $class;
    
    
    # Given packet data ?
    if (defined $packet_data) {
    	my $res = $self->parse( $packet_data );
    	
		# Unsuccessful ?
    	undef $self if ($res);
    }

	return $self;
}



sub parse {
	my $self = shift;
	my ($data) = @_;
	my $pos=0;
	
	
	# Don't even attempt if there isn't enough data
	if (length($data) < 10) {
		carp "data isn't big enough to be a whole SAP packet";
		return -1;
	}
	
	# grab the first 32bits of the packet
	my ($vartec, $auth_len, $id_hash) = unpack("CCn",substr($data,$pos,4)); $pos+=4;
	
 	$self->{'v'} = (($vartec & 0xE0) >> 5);	# Version (1)
 	$self->{'a'} = (($vartec & 0x10) >> 4);	# Address type (0=v4, 1=v6)
# 	$self->{'r'} = (($vartec & 0x08) >> 3);	# Reserved
 	$self->{'t'} = (($vartec & 0x04) >> 2);	# Message Type (0=announce, 1=delete)
 	$self->{'e'} = (($vartec & 0x02) >> 1);	# Encryped (0=no, 1=yes)
 	$self->{'c'} = (($vartec & 0x01) >> 0);	# Compressed (0=no, 1=yes)
 	
 	# Show warning if unsupported SAP packet version
 	if ($self->{'v'} != 0 and $self->{'v'} != 1) {
 		warn "Unsupported SAP packet version: $self->{'v'}.\n";
 		return -1;
 	}
 	
	
 	$self->{'auth_len'} = $auth_len;
 	$self->{'msg_id_hash'} = int($id_hash);
# 	$self->{'msg_id_hash'} = sprintf("0x%4.4X", $id_hash);
 	
 	
 	# Decide the origin address to a string
 	if ($self->{'a'} == 0) {
 		# IPv4 address
 		$self->{'origin_address'} = inet_ntop( AF_INET, substr($data,$pos,4) ); $pos+=4;
 	} else {
 		# IPv6 address
 		$self->{'origin_address'} = inet_ntop( AF_INET6, substr($data,$pos,16) ); $pos+=16;
 	}
 	
 	
 	# Get authentication data if it exists
 	if ($self->{'auth_len'}) {
 		$self->{'auth_data'} = substr($data,$pos,$self->{'auth_len'});
 		$pos+=$self->{'auth_len'};
 		warn "Net::SAP doesn't currently support encrypted SAP packets.";
 		return -1;
 	}
 	
 	
 	# Decompress the payload with zlib
 	my $payload = substr($data,$pos);
	if ($self->{'c'}) {
		my $inf = inflateInit();
		unless (defined $inf) {
			warn "Failed to initialize zlib to decompress SAP packet.";
			return -1;
		} else {
			$payload = $inf->inflate( $payload );
			unless (defined $payload) {
				warn "Failed to decompress SAP packet.";
				return -1;
			}
		}
	}


 	# Check the next three bytes, to see if it is the start of an SDP file
 	if ($payload =~ /^v=\d+/) {
  		$self->{'payload_type'} = 'application/sdp';
 		$self->{'payload'} = $payload;
	} else {
		my $index = index($payload, "\x00");
		if ($index==-1) {
			$self->{'payload_type'} = "unknown";
			$self->{'payload'} = $payload;
		} else {
			$self->{'payload_type'} = substr( $payload, 0, $index );
			$self->{'payload'} = substr( $payload, $index+1 );
 		}
 	}

	return 0;
}



sub _crc16 {
	my ($data) = @_;
	my $crc = 0;
	
	for (my $i=0; $i<length($data); $i++) {
		$crc = $crc ^ ord(substr($data,$i,1)) << 8;
		for( my $b=0; $b<8; $b++ ) {
			if ($crc & 0x8000) {
				$crc = $crc << 1 ^ 0x1021;
			} else {
				$crc = $crc << 1;
			}
		}
	}
	
	return $crc & 0xFFFF;
}


sub generate {
	my $self = shift;

	# Set field of 8 bits
	my $vartec = 0;
	$vartec |= (($self->{'v'} & 0x7) << 5);	# Version (1)
	$vartec |= (($self->{'a'} & 0x1) << 4);	# Address type (0=v4, 1=v6)
#	$vartec |= (($self->{'r'} & 0x1) << 3);	# Reserved
	$vartec |= (($self->{'t'} & 0x1) << 2);	# Message Type (0=announce, 1=delete)
	$vartec |= (($self->{'e'} & 0x1) << 1);	# Encrypted (0=no, 1=yes)
	$vartec |= (($self->{'c'} & 0x1) << 0);	# Compressed (0=no, 1=yes)


	# Calculate hash for packet
	$self->{'msg_id_hash'} = _crc16( $self->{'payload'} );
	
	
	# Build packet header
	my $data = pack("CCn", $vartec, $self->{'auth_len'}, $self->{'msg_id_hash'});
	
	# Don't generate packet unless origin has been set
	if ($self->origin_address() eq '') {
		$self->_choose_origin_address();
		if ($self->origin_address() eq '') {
			croak("Failed to detect origin address: you must set an origin address before sending packets.");
		}
	}


	# Append the Originating Source address
 	if ($self->{'a'} == 0) {
 		# IPv4 address
 		$data .= inet_pton( AF_INET, $self->{'origin_address'} );
 	} else {
 		# IPv6 address
 		$data .= inet_pton( AF_INET6, $self->{'origin_address'} );
 	}
	

	# Append authentication data
	$data .= $self->{'auth_data'};
	
	# Assemble payload section
	my $payload = $self->{'payload_type'} . pack("x") . $self->{'payload'};

	
	# Compress the payload with zlib
	if ($self->{'c'}) {
		my $def = deflateInit();
		unless (defined $def) {
			warn "Failed to initialize zlib to compress SAP packet.";
			return undef;
		} else {
			$payload = $def->deflate( $payload );
			unless (defined $payload) {
				warn "Failed to compress SAP packet.";
				return undef;
			}
			$payload .= $def->flush();
		}
	}
	
	
	# Append payload to packet
	$data .= $payload;
	
	return $data;
}


## Find a public interface address for origin IP
#
sub _choose_origin_address {
	my $self = shift;
	
	# There isn't any support for IPv6 in IO::Interface
	# so we will just try and use a public v4 address
	my @interfaces = IO::Interface::Simple->interfaces;
	foreach my $if (@interfaces) {
		my $addr = $if->address();

		next if ($if->is_loopback());
		next unless (_addr_is_public( $addr ) );
		
		# Must be ok then: store it
		$self->origin_address($addr);
		$self->origin_address_type('ipv4');
		
		# Success
		return 1;
	}
	
	# Failure
	return 0;
}

## Returns true if IP is a global IPv4 address
#
sub _addr_is_public {
	my ($addr) = @_;
	
	# Check it looks like an IPv4 address
	return 0 unless (defined $addr);
	my ($a,$b,$c,$d) = ($addr =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/);
	return 0 unless (defined $a);
	
	# 10.0.0.0/8 is private address space
	return 0 if ($a==10);
	
	# 172.16.0.0/12 is private address space
	return 0 if ($a==172 and $b==16 and $c<=31 and $c>=16);

	# 192.168.0.0/16 is private address space
	return 0 if ($a==192 and $b==168);

	# 169.254.0.0/16 is link-local address space
	return 0 if ($a==169 and $b==254);

	# 127.0.0.0/8 is reserved/localhost
	return 0 if ($a==127);

	# 0.0.0.0/8 is reserved address space
	return 0 if ($a==0);

	# 1.0.0.0/8 is reserved address space
	return 0 if ($a==1);
	

	# Otherwise global
	return 1;
}

sub origin_address_type {
	my $self = shift;
	my ($value) = @_;
	
	if (defined $value) {
		if ($value =~ /ip6|ipv6/i) {
			$self->{'a'} = 1;
		} elsif ($value =~ /ip4|ipv4/i) {
			$self->{'a'} = 0;
		} else {
			carp "Invalid parameter for origin_address_type(): $value\n";
			carp "Should be 'ipv4' or 'ipv6'.";
		}
	}
	
	if ($self->{'a'}) 	{ return 'ipv6'; }
	else				{ return 'ipv4'; }
}


sub origin_address {
	my $self = shift;
	my ($value) = @_;
	
	if (defined $value) {
		## FIXME: should be some checking ?
		$self->{'origin_address'} = $value;
	}
	
	return $self->{'origin_address'};
}


sub compressed {
	my $self = shift;
	my ($value) = @_;
	
	if (defined $value) {
		if ($value =~ /1|yes|true/i) {
			$self->{'c'} = 1;
		} elsif ($value =~ /0|no|false/i) {
			$self->{'c'} = 0;
		} else {
			carp "Invalid parameter for compressed(): $value\n";
			carp "Should be '1' or '0'.";
		}
	}
			
	return $self->{'c'};
}

sub type {
	my $self = shift;
	my ($value) = @_;
	
	if (defined $value) {
		if ($value =~ /advert/i) {
			$self->{'t'} = 0;
		} elsif ($value =~ /delet/i) {
			$self->{'t'} = 1;
		} else {
			carp "Invalid parameter for type(): $value\n";
			carp "Should be 'advertisement' or 'deletion'.";
		}
	}

	if ($self->{'t'} == 0)		{ return 'advertisement'; }
	else						{ return 'deletion'; }
}

sub version {
	my $self = shift;
	return $self->{'v'};
}

sub message_id_hash {
	my $self = shift;
	return $self->{'msg_id_hash'};
}

sub encrypted {
	my $self = shift;
	return $self->{'e'};
}

sub encryption_key_length {
	my $self = shift;
	return $self->{'auth_len'};
}

sub encryption_key {
	my $self = shift;
	return $self->{'auth_data'};
}

sub payload_type {
	my $self = shift;
	my ($value) = @_;
	
	if (defined $value) {
		## FIXME: should be some checking ?
		$self->{'payload_type'} = $value;
	}
	
	return $self->{'payload_type'};
}

sub payload {
	my $self = shift;
	my ($value) = @_;

	if (defined $value) {
		## FIXME: should be some checking ?
		$self->{'payload'} = $value;
	}

	return $self->{'payload'};
}



sub DESTROY {
    my $self=shift;
    
}


1;

__END__

=pod

=head1 NAME

Net::SAP::Packet - A SAP Packet

=head1 SYNOPSIS

  use Net::SAP::Packet;

  my $packet = new Net::SAP::Packet();

  $packet->type( 'advertisement' );
  $packet->compressed( 0 );
  $packet->payload( $sdp_data );


=head1 DESCRIPTION

The C<Net::SAP::Packet> class represents a single SAP Packet. 
It provides methods for getting and setting the properties of the packet. 

=head2 METHODS

=over 4

=item B<new( [$binary_data] )>

Creates a new C<Net::SAP::Packet> object with default values for all 
the properties. Takes an optional parameter which is passed straight 
to C<parse()> if given.


=item B<parse( $binary_data )>

Parses a binary packet (as received from the network) and stores 
its data in the object. Returns non-zero if the binary data is 
invalid.


=item B<generate()>

Generates a binary packet from the properties stored in the perl 
object. Returned undefined if there is a problem creating the 
packet. This method also calculates the message id hash field 
for the packet and compresses it if the C<compressed()> field is set.


=item B<origin_address_type()>

Get or Set the family of the origin address (either ipv4 or ipv6).

Example:

	$type = $packet->origin_address_type();
	$packet->origin_address_type( 'ipv6' );
  

=item B<origin_address()>

Get or Set the origin address (IPv4 or IPv6 address of the host 
sending the packet). Be sure to also set the address type using 
C<origin_address_type()>.

Example:

	$origin = $packet->origin_address();
	$packet->origin_address( '152.78.104.83' );
  

=item B<compressed()>

Get or Set wether the packet was, or should be compressed. 
Note that the payload of the SAP packet should be no more than 
1024 bytes. So compression should be used is the raw data is more 
than that.

Example:

	$compressed = $packet->compressed();
	$packet->compressed( 1 );
  
  
=item B<type()>

Get or Set the packet type - advertisement or deletion. A delete packet 
is used to instruct clients that a previously advertised session is now
no longer valid.

Example:

	$type = $packet->type();
	$packet->type( 'advertisement' );
	$packet->type( 'deletion' );
  
  
=item B<version()>

Get the SAP version number of a received packet. Usually 1 or 0.
See the end of RFC2974 for a description of the difference between 
packet versions. All packets created using C<Net::SAP> are version 1.


=item B<message_id_hash()>

Get the Message ID Hash for the packet. The hash for a new packet 
is calculated when calling C<generate()>. 
The hash is a 16-bit unsigned integer (0 to 65535).


=item B<encrypted()>

Gets whether a packet is encrypted or not. Note that C<Net::SAP> 
can't currently encrypt or de-crypt packets.


=item B<encryption_key_length()>

Gets the length of the packet's encryption key. Note that C<Net::SAP> 
can't currently encrypt or decrypt packets.


=item B<encryption_key()>

Gets the encryption key for a packet. Returns undefined value if there is
no encryption key for the packet. Note that C<Net::SAP> can't currently 
encrypt or de-crypt packets.
  
  
=item B<payload_type()>

Get or Set the packet's payload type. This field should be a MIME type.
The default MIME type for packets is 'application/sdp'.

Example:

	$mime = $packet->payload_type();
	$packet->payload_type( 'application/sdp' );
  
  
=item B<payload()>

Get or Set the packet's payload.

Example:

	$payload = $packet->payload();
	$packet->payload( $sdp_data );


=back

=head1 SEE ALSO

L<Net::SAP>, L<Net::SDP>, perl(1)

L<http://www.ietf.org/rfc/rfc2974.txt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-sap@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you will automatically
be notified of progress on your bug as I make changes.


=head1 AUTHOR

Nicholas Humfrey, njh@ecs.soton.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2006 University of Southampton

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.005 or,
at your option, any later version of Perl 5 you may have available.

=cut
