# $Id: Channel.pm,v 1.4 2003/09/11 19:57:31 davidb Exp $
#
# Copyright (C) 2003 Verisign, Inc.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
# USA

package Net::BEEP::Lite::Channel;

=head1 NAME

Net::BEEP::Lite::Channel - a class for holding BEEP channel variables.

=head1 DESCRIPTION

This is a class that basically just hold various channel related variables.  Most of the actual "action" methods are in C<Net::BEEP::Lite::Session>.

=cut

use Carp;
use strict;
use warnings;

use Net::BEEP::Lite::Message;

# some constants:
my $MAX_MSGNO = 2147483648;
my $MAX_SEQNO = 4294967296;

=head1 CONSTRUCTOR

=over 4

=item new( I<ARGS> )

This is the main constructor.  It takes a named parameter list as its
argument.  See the I<initialize> method for a list of valid parameter
names.

=back

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;

  my $self = {};
  bless $self, $class;

  $self->initialize(@_);

  $self;
}

=head1 METHODS

=over 4

=item initialize( I<ARGS> )

Initialize the object.  This is generally called by the constructor
and subclasses.  It takes the following named parameters:

=over 4

=item Number

The channel number.

=item Window

The local window to start with.  Default to 4096.

=item Profile

The profile implementation.

=back

=cut

sub initialize {
  my $self = shift;
  my %args = @_;

  # default a few things
  $self->{debug}         = 0;
  $self->{trace}         = 0;
  $self->{profile} 	 = undef;
  $self->{seqno}   	 = 0;
  $self->{peer_seqno}    = 0;
  $self->{msgno}   	 = 0;
  $self->{local_window}  = 4096;
  $self->{remote_window} = 4096;
  $self->{message} 	 = undef;
  $self->{ans_message}   = {};
  $self->{number}  	 = -1;

  for (keys %args) {
    my $val = $args{$_};

    /^number$/io and do {
      $self->{number} = $val;
      next;
    };
    /^window$/io and do {
      $self->local_window($val);
      next;
    };
    /^profile/io and do {
      $self->profile($val);
      next;
    };
    /^debug$/io and do {
      $self->{debug} = $val;
      next;
    };
    /^trace$/io and do {
      $self->{trace} = $val;
      next;
    };
  }
}

=item profile([$val])

Sets or returns the profile implementation object assoc. with this
channel (if any).

=cut

sub profile {
  my $self = shift;
  my $val  = shift;

  $self->{profile} = $val if $val;
  $self->{profile};
}

=item seqno()

Returns the current (sending) sequence number for this channel.  Note
that this is the sequence number for octets being sent to the peer.

=cut

sub seqno {
  my $self = shift;

  $self->{seqno};
}

=item update_seqno($length)

Adds length to the current sequence number.  This is done when frames
are written to the socket.

=cut

sub update_seqno {
  my $self   = shift;
  my $length = shift;

  $self->{seqno} += $length;
  $self->{seqno} %= $MAX_SEQNO;
  $self->{seqno};
}

=item peer_seqno([$val])

Returns (or sets and returns) the peer sequence number.  This is (or
should be) the sequence number of the octet seen from the peer on this
channel.  I.e., this should get updated when frames are read from the
socket.  This value is primarily used in calculating SEQ frames to
send back to the peer (as the ackno.).

=cut

# NOTE: the design of this module does not actually need this to
# operate: acknos may be calculated directly from the last received
# frame.  This exists so at some future point it can be used to detect
# channel corruption.
sub peer_seqno {
  my $self = shift;
  my $val = shift;

  $self->{peer_seqno} = $val if defined $val;
  $self->{peer_seqno};
}


=item msgno([$val])

Sets or returns the current message number for this channel.

=cut

sub msgno {
  my $self = shift;
  my $val = shift;

  $self->{msgno} = $val if $val;
  $self->{msgno};
}

=item next_msgno()

Returns the current message number, then increments it.

=cut

sub next_msgno {
  my $self = shift;

  my $n = $self->{msgno};
  $self->{msgno}++;

  $self->{msgno} %= $MAX_MSGNO;
  $n;
}

=item local_window([$val])

Sets or returns the size of the local (receiving) window.  This is
what gets published in sent SEQ frames for this window.

=cut

sub local_window {
  my $self = shift;
  my $val  = shift;

  $self->{local_window} = $val if defined $val;
  $self->{local_window};
}

=item remote_window([$val])

Sets or returns the size of the remove (sending) window.  This is what
is used to determine the max payload size on a frame that is about to
be sent.

=cut

sub remote_window {
  my $self = shift;
  my $val  = shift;

  $self->{remote_window} = $val if defined $val;
  $self->{remote_window};
}


=item message()

Returns the current message that is under construction by the recv_* method in C<Net::BEEP::Lite::Session>.

=cut

sub message {
  my $self = shift;
  my $val  = shift;

  $self->{message} = $val if $val;
  $self->{message};
}

=item message_add_frame($frame)

Adds (or create a new message with) the frame to the message under
construction.

=cut

sub message_add_frame {
  my $self  = shift;
  my $frame = shift;

  if (not $self->message()) {
    $self->message(new Net::BEEP::Lite::Message(Frame => $frame,
					      Debug => $self->{debug},
					      Trace => $self->{trace}));
  } else {
    $self->message()->add_frame($frame);
  }
}

=item clear_message()

Clears the message under construction. This is generally done when the
message is complete.

=cut

sub clear_message {
  my $self = shift;

  $self->{message} = undef;
}

=item ans_message($ans_number, [$val])

Returns or sets the ANS message under construction for the given ANS
number.

=cut

sub ans_message {
  my $self  = shift;
  my $ansno = shift;
  my $val   = shift;

  return undef if not defined $ansno;
  $self->{ans_message}->{$ansno} = $val if $val;
  $self->{ans_message}->{$ansno};
}

=item ans_message_add_frame($frame)

Adds a frame (or creates a new ANS message) for the ANS message under
construction with the frame's ANS number.

=cut

sub ans_message_add_frame {
  my $self  = shift;
  my $frame = shift;

  my $ansno = $frame->ansno();

  if (not $self->ans_message($ansno)) {
    $self->ans_message($ansno, new Net::BEEP::Lite::Message
		       (Frame => $frame,
			Debug => $self->{debug},
		        Trace => $self->{trace}));
  } else {
    $self->ans_message($ansno)->add_frame($frame);
  }
}

=item ans_clear_message($ans_number)

Clears the ANS message under construction with the given ANS number.
This is generally done when the message is complete.

=cut

sub ans_clear_message {
  my $self = shift;
  my $ansno = shift;

  $self->{ans_message}->{$ansno} = undef;
}

=item number()

Returns the channel number.

=cut

sub number {
  my $self = shift;

  $self->{number};
}

=pod

=back

=head1 SEE ALSO

=over 4

=item L<Net::BEEP::Lite::Session>

=item L<Net::BEEP::Lite::Message>

=back

=cut

1;
