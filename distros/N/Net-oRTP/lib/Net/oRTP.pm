package Net::oRTP;

################
#
# Net::oRTP: Perl interface to the oRTP C library
#
# Uses the oRTP library.
#
# Nicholas Humfrey
# njh@ecs.soton.ac.uk
#

use strict;
use XSLoader;
use Carp;

use vars qw/$VERSION/;

$VERSION="0.02";

# Number of Net::oRTP objects created
my $OBJCOUNT=0;


XSLoader::load('Net::oRTP', $VERSION);



sub new {
    my $class = shift;
    my ($mode) = @_;
    
    # Initialise the ortp library?
    if ($OBJCOUNT==0) {
	   	ortp_initialize();
    }
    $OBJCOUNT++;

    
	# Work out the multicast group to use
    croak "Missing mode parameter" unless defined $mode;
    
	# Convert mode name to mode enum
    my $mnum = undef;
    if    ($mode eq 'RECVONLY') { $mnum = 0; }
    elsif ($mode eq 'SENDONLY') { $mnum = 1; }
	elsif ($mode eq 'SENDRECV') { $mnum = 2; }
	else {
		croak "Invalid mode: $mode";
	}
	
	# Create new session
	my $session = rtp_session_new( $mnum );
	unless (defined $session) { 
		die "Failed to create RTP session";
	}

	# Store parameters
    my $self = {
    	'mode'	=> $mode,
    	'session' => $session
    };


    bless $self, $class;
	return $self;
}


sub set_blocking_mode {
    my $self=shift;
	my ($yesno) = @_;
	rtp_session_set_scheduling_mode( $self->{'session'}, $yesno );
	rtp_session_set_blocking_mode( $self->{'session'}, $yesno );
}

sub set_local_addr {
    my $self=shift;
	my ($addr, $port) = @_;

	return rtp_session_set_local_addr( $self->{'session'}, $addr, $port );
}

sub get_local_port {
    my $self=shift;
	my ($addr, $port) = @_;
	return rtp_session_get_local_port( $self->{'session'} );
}

sub set_remote_addr {
    my $self=shift;
	my ($addr, $port) = @_;
	return rtp_session_set_remote_addr( $self->{'session'}, $addr, $port );
}

sub get_jitter_compensation {
    my $self=shift;
	return rtp_session_get_jitter_compensation( $self->{'session'} );
}

sub set_jitter_compensation {
    my $self=shift;
	my ($milisec) = @_;
	return rtp_session_set_jitter_compensation( $self->{'session'}, $milisec );
}

sub set_adaptive_jitter_compensation {
    my $self=shift;
	my ($yesno) = @_;
	return rtp_session_enable_adaptive_jitter_compensation( $self->{'session'}, $yesno );
}

sub get_adaptive_jitter_compensation {
    my $self=shift;
	return rtp_session_adaptive_jitter_compensation_enabled( $self->{'session'} );
}

sub set_send_ssrc {
    my $self=shift;
	my ($ssrc) = @_;
	return rtp_session_set_ssrc( $self->{'session'}, $ssrc );
}

sub get_send_ssrc {
    my $self=shift;
	return rtp_session_get_send_ssrc( $self->{'session'} );
}

sub set_send_seq_number {
    my $self=shift;
	my ($seq) = @_;
	return rtp_session_set_seq_number( $self->{'session'}, $seq );
}

sub get_send_seq_number {
    my $self=shift;
	return rtp_session_get_send_seq_number( $self->{'session'} );
}

sub set_send_payload_type {
    my $self=shift;
	my ($pt) = @_;
	return rtp_session_set_send_payload_type( $self->{'session'}, $pt );
}

sub get_send_payload_type {
    my $self=shift;
	return rtp_session_get_send_payload_type( $self->{'session'} );
}

sub set_recv_payload_type {
    my $self=shift;
	my ($pt) = @_;
	return rtp_session_set_recv_payload_type( $self->{'session'}, $pt );
}

sub get_recv_payload_type {
    my $self=shift;
	return rtp_session_get_recv_payload_type( $self->{'session'} );
}

sub recv_with_ts {
    my $self=shift;
	my ($bytes, $userts) = @_;
	return rtp_session_recv_with_ts( $self->{'session'}, $bytes, $userts ) ;
}

sub send_with_ts {
    my $self=shift;
	my ($data, $userts) = @_;
	return rtp_session_send_with_ts( $self->{'session'}, $data, $userts );
}

sub flush_sockets {
    my $self=shift;
	return rtp_session_flush_sockets( $self->{'session'} );
}

sub reset {
    my $self=shift;
	return rtp_session_reset( $self->{'session'} );
}



sub DESTROY {
    my $self=shift;
    
    if (exists $self->{'session'}) {
    	rtp_session_destroy( $self->{'session'} );
    }

    # Decrement the number of Net::oRTP objects
    $OBJCOUNT--;
    if ($OBJCOUNT==0) {
    	ortp_shutdown();
    } elsif ($OBJCOUNT<0) {
    	warn "Warning: Net::oRTP object count is less than 0.";
    }
}



1;

__END__

=pod

=head1 NAME

Net::oRTP - Perl interface to the oRTP C library

=head1 SYNOPSIS

  use Net::oRTP;

  my $rtp = Net::oRTP->new( 'SENDONLY' );
  $rtp->set_remote_addr( '237.70.58.86', 5004 );
  $rtp->set_send_payload_type( 8 );
  
  while(1)
  {
     $payload = read_alaw_audio( 160 );
     $rtp->send_with_ts( $payload, $timestamp);
     $timestamp+=160;
  }

=head1 DESCRIPTION

Net::oRTP is a perl interface to the oRTP C library
- a RTP (Real-time Transport Protocol) stack.


=over 4

=item $rtp = new Net::oRTP( $mode )

The new() method is the constructor for the C<Net::oRTP> class.

The $mode parameter can be one of the following values:

	RECVONLY
	SENDONLY
	SENDRECV
	
Which sets the RTP session to Receive Only Mode, Send Only Mode and 
Send Receive modes respectively.


=item $rtp->set_blocking_mode( $yesno )

If $yesno is true, C<recv_with_ts()> will block until it is time for the 
packet to be received, according to the timestamp passed to the function. 
After this time, the function returns. For C<send_with_ts()>, it will block 
until it is time for the packet to be sent. If $yesno is false, then the two 
functions will return immediately.


=item $rtp->set_local_addr( $address, $port )

Specify the local addr to be use to listen for RTP packets or to send RTP 
packet from. In case where the RTP session is send-only, then it is not 
required to call this function: when calling C<set_remote_addr()>, 
if no local address has been set, then the default INADRR_ANY (0.0.0.0) 
IP address with a random port will be used. 
Calling C<set_local_addr()> is mandatory when the session is 
recv-only or duplex.


=item $rtp->get_local_port()

Returns the local port that the socket is bound to.


=item $rtp->set_remote_addr( $address, $port )

Sets the remote address of the RTP session, ie the destination address where 
RTP packet are sent. If the session is recv-only or duplex, it also sets 
the origin of incoming RTP packets. RTP packets that don't come from 
addr:port are discarded.


=item $rtp->get_jitter_compensation()

Gets the time interval for which packet are buffered instead of 
being delivered to the application.


=item $rtp->set_jitter_compensation( $milisec )

Sets the time interval for which packet are buffered instead of 
being delivered to the application.


=item $rtp->set_adaptive_jitter_compensation( $yesno )

Enable or disable adaptive jitter compensation.


=item $rtp->get_adaptive_jitter_compensation()

Gets the current state of adaptive jitter compensation.


=item $rtp->set_send_ssrc( $ssrc )

Sets the SSRC for the outgoing stream. If not done, a random ssrc is used.


=item $rtp->get_send_ssrc( $ssrc )

Gets the SSRC for the outgoing stream.


=item $rtp->set_send_seq_number( $seqnum )

Sets the initial sequence number of a freshly created session.


=item $rtp->get_send_seq_number( )

Returns the current sequence number of a session.


=item $rtp->set_send_payload_type( $payload_type )

Sets the payload type for outgoing packets in the session.


=item $rtp->get_send_payload_type( $payload_type )

Gets the payload type for outgoing packets in the session.


=item $rtp->set_recv_payload_type( $payload_type )

Sets the expected payload type for incoming packets.


=item $rtp->recv_with_ts( $bytes, $timestamp )

Tries to read $bytes bytes from the incoming RTP stream related to timestamp 
$timestamp. When blocking mode is on (see C<set_blocking_mode()> ), then the 
calling thread is suspended until the timestamp given as argument expires, 
whatever a received packet fits the query or not.

Important note: it is clear that the application cannot know the timestamp 
of the first packet of the incoming stream, because it can be random. 
The time timestamp given to the function is used relatively to first 
timestamp of the stream. In simple words, 0 is a good value to start 
calling this function.


=item $rtp->send_with_ts( $data, $timestamp )

Send a RTP datagram to the destination set by C<set_remote_addr()> 
containing $data with timestamp $timestamp. 
Refer to RFC3550 to know what it is.


=item $rtp->flush_sockets()

Flushes the sockets for all pending incoming packets.
This can be usefull if you did not listen to the stream for a while
and wishes to start to receive again. During the time no receive is made
packets get bufferised into the internal kernel socket structure.

=item $rtp->reset()

Reset the session: local and remote addresses are kept unchanged but the 
internal queue for ordering and buffering packets is flushed, the session 
is ready to be re-synchronised to another incoming stream.


=back


=head1 SEE ALSO

L<http://www.ietf.org/rfc/rfc3550.txt>

L<http://www.linphone.org/ortp/>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-net-ortp@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you will automatically
be notified of progress on your bug as I make changes.

=head1 AUTHOR

Nicholas Humfrey, njh@ecs.soton.ac.uk

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 University of Southampton

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

=cut
