package Net::RTP::Packet;

################
#
# Net::RTP::Packet: Pure Perl RTP Packet object (RFC3550)
#
# Nicholas J Humfrey, njh@cpan.org
#

use strict;
use Carp;

use vars qw/$VERSION/;
$VERSION="0.05";


# Seed a random number for old versions of perl
if ($] < 5.004) {
	srand(time ^ ($$ + ($$ << 15)));
}


sub new {
    my $class = shift;
	my ($bindata) = @_;

	# Store parameters
    my $self = {
		version => 2,
		padding => 0,
		extension => 0,
		marker => 0,
		payload_type => 0,
		seq_num => 0,
		timestamp => 0,
		ssrc => 0,
		csrc => [],
		payload => '',
		size => undef,
		source_ip => undef,
		source_port => undef,
    };
    bless $self, $class;


	# Decode binary packet?
	if (defined $bindata) {
		$self->decode( $bindata );
	} else {
		# Randomise sequence, timestamp and SSRC
		$self->{'seq_num'} = int(rand(2**16));
		$self->{'timestamp'} = int(rand(2**32));
		$self->{'ssrc'} = int(rand(2**32));
	}
	
	return $self;
}


sub version {
	my $self = shift;
	my ($version) = @_;
	$self->{'version'} = $version if (defined $version);
	return $self->{'version'};
}

sub padding {
	my $self = shift;
	my ($padding) = @_;
	$self->{'padding'} = $padding if (defined $padding);
	return $self->{'padding'};
}

sub extension {
	my $self = shift;
	return $self->{'extension'};
}

sub marker {
	my $self = shift;
	my ($marker) = @_;
	$self->{'marker'} = $marker if (defined $marker);
	return $self->{'marker'};
}

sub payload_type {
	my $self = shift;
	my ($payload_type) = @_;
	$self->{'payload_type'} = $payload_type if (defined $payload_type);
	return $self->{'payload_type'};
}

sub seq_num {
	my $self = shift;
	my ($seq_num) = @_;
	$self->{'seq_num'} = $seq_num if (defined $seq_num);
	return $self->{'seq_num'};
}

sub seq_num_increment {
	my $self = shift;

	my ($value) = @_;
	$value = 1 unless (defined $value);
	$self->{'seq_num'} += $value;

	return $self->{'seq_num'};
}
	
sub timestamp {
	my $self = shift;
	my ($timestamp) = @_;
	$self->{'timestamp'} = $timestamp if (defined $timestamp);
	return $self->{'timestamp'};
}

sub timestamp_increment {
	my $self = shift;

	my ($value) = @_;
	$value = 1 unless (defined $value);
	$self->{'timestamp'} += $value;

	return $self->{'timestamp'};
}

sub ssrc {
	my $self = shift;
	my ($ssrc) = @_;
	$self->{'ssrc'} = $ssrc if (defined $ssrc);
	return $self->{'ssrc'};
}

sub csrc {
	my $self = shift;
	my ($csrc) = @_;
	if (defined $csrc) {
		if (ref($csrc) ne 'ARRAY') {
			carp "CSRC should be an ARRAYREF";
		} else {
			$self->{'csrc'} = $csrc ;
		}
	}
	return $self->{'csrc'};
}

sub payload {
	my $self = shift;
	my ($payload) = @_;
	$self->{'payload'} = $payload if (defined $payload);
	return $self->{'payload'};
}

sub payload_size {
	my $self = shift;
	return length($self->{'payload'});
}

sub source_ip {
	my $self = shift;
	return $self->{'source_ip'};
}

sub source_port {
	my $self = shift;
	return $self->{'source_port'};
}

sub size {
	my $self = shift;
	
	# Encode the packet if the size isn't known
	unless (defined $self->{'size'}) {
		# Not very efficient, but sure to work
		$self->encode();
	}
	
	return $self->{'size'};
}

sub decode {
	my $self = shift;
	my ($bindata) = @_;
	
	# Store the size of the packet we are decoding
	$self->{'size'} = length( $bindata );

	# Decode the binary header (network endian)
	my ($vpxcc, $mpt, $seq_num, $timestamp, $ssrc) = unpack( 'CCnNN', $bindata );
	$bindata = substr( $bindata, 12 );
	
	# We only know how to parse version 2 of RTP
	$self->{'version'} = ($vpxcc & 0xC0) >> 6;
	if ($self->{'version'} != 2) {
		carp "Warning: unsupported RTP packet version ($self->{'version'})";
		return 0;
	}
	
	# Extract from the bit fields
	$self->{'padding'} = ($vpxcc & 0x20) >> 5;
	$self->{'extension'} = ($vpxcc & 0x10) >> 4;
	my $csrc_count = ($vpxcc & 0x0F) >> 0;
	$self->{'marker'} = ($mpt & 0x80) >> 7;
	$self->{'payload_type'} = ($mpt & 0x7F) >> 0;
	$self->{'seq_num'} = $seq_num;
	$self->{'timestamp'} = $timestamp;
	$self->{'ssrc'} = $ssrc;

	
	# Process CSRC list
	for(my $c=0; $c<$csrc_count; $c++) {
		my $csrc = unpack('N', $bindata );
		$bindata = substr( $bindata, 4 );
		
		# Append it on to the list
		push( @{$self->{'csrc'}}, $csrc );
	}
	
	# Ignore any header extention
	if ($self->{'extension'}) {
		my ($foo, $len) = unpack('nn', $bindata );
		$bindata = substr( $bindata, ($len+1)*4 );
	}
	
	# Ignore padding on end of packet
	if ($self->{'padding'}) {
		$self->{'padding'} = unpack('C', substr( $bindata, -1, 1 ));
	}
	
	# Whats left is the payload
	my $len = length( $bindata ) - $self->{'padding'};
	$self->{'payload'} = substr($bindata,0,$len);
	
	# Undefine the source IP and port
	# (it is unknown and set elsewhere)
	$self->{'source_ip'} = undef;
	$self->{'source_port'} = undef;
	
	# Success
	return 1;
}


sub encode {
	my $self = shift;
	my $bindata = '';
	
	my $csrc_count = scalar(@{$self->{'csrc'}});
	my $pad = 0; $pad = 1 if ($self->{'padding'});
	
	my $vpxcc = 0;
	$vpxcc |= ($self->{'version'} << 6) & 0xC0;
	$vpxcc |= ($pad << 5) & 0x20;
	$vpxcc |= ($self->{'extension'} << 4) & 0x10;
	$vpxcc |= ($csrc_count & 0x0F);
	$bindata .= pack('C', $vpxcc);
	
	my $mpt = 0;
	$mpt |= ($self->{'marker'} << 7) & 0x80;
	$mpt |= ($self->{'payload_type'} & 0x7F);
	$bindata .= pack('C', $mpt);
	
	$bindata .= pack('n', $self->{'seq_num'});
	$bindata .= pack('N', $self->{'timestamp'});
	$bindata .= pack('N', $self->{'ssrc'});
	
	# Append list of CSRC
	foreach( @{$self->{'csrc'}} ) {
		$bindata .= pack('N', $_);
	}

	# Append the payload
	$bindata .= $self->{'payload'};
	
	# Append the padding
	if ($self->{'padding'}) {
		for(my $p=0; $p<($self->{'padding'}-1); $p++) {
			$bindata .= pack('C', 0);
		}
		$bindata .= pack('C', $self->{'padding'});
	}
	
	# Store the size of the encoded packet
	$self->{'size'} = length( $bindata );
	
	return $bindata;
}


1;

__END__

=pod

=head1 NAME

Net::RTP::Packet - RTP Packet object (RFC3550)

=head1 SYNOPSIS

  use Net::RTP::Packet;
  
  my $packet = new Net::RTP::Packet();
  $packet->payload_type( 10 );
  $packet->seq_num( 6789 );
  $packet->timestamp( 76303 );
  $packet->payload( $audio );
  $binary = $packet->encode();

=head1 DESCRIPTION

Net::RTP::Packet implements RTP packet header encoding and decoding.

=over

=item $packet = new Net::RTP::Packet( [$binary] )

The new() method is the constructor for the C<Net::RTP::Packet> class.
The RTP version number is initialized to 2. The sequence number, timestamp 
and SSRC are all randomized.

The C<$binary> parameter is optional, and is passed to C<decode()> if present.


=item $packet->version( [$value] )

Get or set the version number of the RTP packet.
Only version 2 is currently supported.

=item $packet->padding( [$value] )

Get or set the number of bytes of padding at the
end of the RTP packet.

=item $packet->extension()

Returns true if there was an RTP header extension present in the packet.
It isn't currently possible to get the data of that extension.

=item $packet->marker( [$value] )

Get or set the value of the marker flag in the header.
If true, it usually means that this RTP packet is the start of a 
frame boundary.

=item $packet->payload_type( [$value] )

Get or set the payload type of the packet.
See C<http://www.iana.org/assignments/rtp-parameters> for 
the Payload Type values.

=item $packet->seq_num( [$value] )

Get or set the sequence number of the packet.
The sequence number increments by one for each RTP data packet
sent, and may be used by the receiver to detect packet loss and to
restore packet sequence.

=item $packet->seq_num_increment( [$amount] )

Increment the packet's sequence number by C<$amount>. If no amount is specified, 
then the sequence number is incremented by 1. 
Returns the packet's new sequence number if successful.

=item $packet->timestamp( [$value] )

Get or set the timestamp of the packet.
The timestamp reflects the sampling instant of the first octet in
the RTP data packet.

=item $packet->timestamp_increment( [$amount] )

Increment the packet's timestamp by C<$amount>. If no amount is specified, 
then the timestamp is incremented by 1. 
Returns the packet's new timestamp if successful.

=item $packet->ssrc( [$value] )

Get or set the 32-bit source identifier of the packet.

=item $packet->csrc( [$value] )

Get or set an ARRAYREF of contributing source identifiers for the packet.

=item $packet->payload( [$value] )

Get or set the payload data for the packet.

=item $packet->payload_size()

Return the length (in bytes) of the packet's payload.

=item $packet->source_ip()

Return the source IP address of the packet (as an ASCII string).
If the source IP is not known, the value is undefined.

=item $packet->source_port()

Return the source port of the packet (as an ASCII string).
If the source port is not known, the value is undefined.

=item $packet->size()

Return the length (in bytes) of the binary RTP packet.

Note: The size of the packet is only calculated during encode() and decode().

=item $packet->decode( $binary )

Decodes binary RTP packet header into the packet object.

=item $data = $packet->endcode()

Encode a packet object into a binary RTP packet.

=back

=head1 SEE ALSO

L<Net::RTP>

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
