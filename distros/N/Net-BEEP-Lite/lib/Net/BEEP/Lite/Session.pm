# $Id: Session.pm,v 1.13 2004/04/22 20:45:58 davidb Exp $
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


package Net::BEEP::Lite::Session;

=head1 NAME

Net::BEEP::Lite::Session

=head1 DESCRIPTION

This is a base class for BEEP sessions.  It handles core tasks common
to both server and client sessions.  This class isn't intended to be
used directly.  Instead, use one of its subclasses.

Note that in reality, this is really a TCP session.  It is not
abstracted away from the TCP transport for BEEP.  In the future it is
possible that it will be and a new TCPSession subclass will be
created.

=cut

use IO::Socket;

use Net::BEEP::Lite::Channel;
use Net::BEEP::Lite::MgmtProfile;

use Carp;
use strict;
use warnings;

=head1 CONSTRUCTOR

=over 4

=item new( I<ARGS> )

This is the main constructor.  It takes a named parameter list as its
argument.  See the C<initialize> method for a list of valid parameter
names.


=back

=cut

sub new {
  my $this  = shift;
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

=item Socket

the socket associated with this session.

=item NoGreeting

Do not send the greeting message.  This can be sent later with the
C<send_greeting> method.  This will be true if a socket isn't
supplied.

=item DefaultLocalWindow

Set the base local TCP window to a particular value.  This number
should be 4096 (the default) or higher.

=item IdleTimeout

The number of seconds to wait for a frame.  Zero (the default) means
to wait indefinitely.

=item Timeout

The number of seconds to wait for a frame body to be completely read.
This should ususally be non-zero to prevent framing errors from
locking the session forever.  The default is 30 seconds.

=back

It also takes the named parameters for C<Net::BEEP::Lite::MgmtProfile>.

=cut

sub initialize {
  my $self = shift;
  my %args = @_;

  # some defaults:

  $self->{debug} = 0;
  $self->{trace} = 0;

  # we assume the initiator role.  the listener subclass should set
  # this to 2.
  $self->{channelno_counter} = 1;

  # create our management profile.  FIXME: we may want to allow this
  # to be passed in (and only instantiate it once for all sessions.)
  $self->{mgmt_profile} = Net::BEEP::Lite::MgmtProfile->new(%args);

  # our local profiles.
  $self->{profiles} = {};
  # the remote profiles.
  $self->{remote_profiles} = {};

  # our channels.  basically, a hash of channel number to channel
  # object.
  $self->{channels} = {};

  # The default size of our local windows.  This should be at least
  # 4096.
  $self->{default_local_window} = 4096;

  # assign the management profile to channel zero.
  $self->_add_channel(0, $self->{mgmt_profile});
  $self->channel(0)->msgno(1); # start msgno at one because of
                               # greeting RPY.

  # our general received message queue;
  $self->{messages} = [];

  # our default idle timeout
  $self->{idle_timeout} = 0;
  # our default read timeout for frame bodies.
  $self->{timeout} = 60;

  for (keys %args) {
    my $val = $args{$_};

    /^socket/io and do {
      $self->{sock} = $val;
      next;
    };
    /^no.?greeting$/io and do {
      $self->{_no_greeting} = $val;
      next;
    };
    /^default.?local.?window$/io and do {
      $self->{default_local_window} = $val;
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
    /^idle.?timeout/io and do {
      $self->{idle_timeout} = $val;
      next;
    };
    /^timeout$/io and do {
      $self->{timeout} = $val;
      next;
    };
  }

  # set NoGreeting to true if the socket wasn't set or isn't 
  $self->{_no_greeting} = 1 if (! $self->{sock} or
				(ref($self->{sock}) and
				     !$self->{sock}->isa('IO::Socket')));
}

=item socket()

Returns the internal socket.

=cut

sub _socket {
  my $self = shift;

  $self->{sock};
}

=item _set_socket($socket)

Change the session's internal socket to the supplied socket.  Only use
this if you know what you are doing.

=cut

sub _set_socket {
  my $self   = shift;
  my $socket = shift;

  $self->{sock} = $socket;
}

=item _next_channel_number()

This returns the next channel number to request.

=cut

sub _next_channel_number {
  my $self = shift;

  my $res = $self->{channelno_counter};
  $self->{channelno_counter} += 2;
  $self->{channelno_counter} %= 2147483648;

  $res;
}

=item _add_channel($channel_number, [$profile, [$local_window_size]])

This is called by the management profile upon receiving a <start> or
<profile> message from the peer.  If $profile is provided, then this
will bind that profile to the channel.

=cut

sub _add_channel {
  my $self    = shift;
  my $number  = shift;
  my $profile = shift;
  my $window  = shift || $self->{default_local_window};

  $self->{channels}->{$number} = new Net::BEEP::Lite::Channel
    (Number  => $number,
     Profile => $profile,
     Window  => $window,
     Debug   => $self->{debug},
     Trace   => $self->{trace});
}

=item _del_channel($channel_number)

This is called by profiles when it needs to close a channel (either a
close request on the channel or a tuning reset (see
C<_del_all_channels>).

=cut

sub _del_channel {
  my $self   = shift;
  my $number = shift;

  delete $self->{channels}->{$number};
}

=item _del_all_channels()

Close (and destroy) all current channels.  This is most likely to be
done as part of a tuning reset.  You will have to re-add channel zero
after this.

=cut

sub _del_all_channels {
  my $self = shift;

  for my $n (keys %{$self->{channels}}) {
    $self->_del_channel($n);
  }
}

=item add_local_profile($profile)

This method will add a (local) profile to the session.  This will be
advertised in the greeting message.

=cut

sub add_local_profile {
  my $self = shift;
  my $p    = shift;

  $self->{profiles}->{$p->uri()} = $p;
}

=item get_local_profile($uri)

Returns the profile implementation associated with the given uri.

=cut

sub get_local_profile {
  my $self = shift;
  my $uri  = shift;

  $self->{profiles}->{$uri};
}

=item get_local_profile_uris()

Returns the list of profile URIs currently being advertised by this peer.

=cut

sub get_local_profile_uris {
  my $self = shift;
  keys %{$self->{profiles}};
}

=item del_local_profile($uri)

Removes a local profile.

=cut

sub del_local_profile {
  my $self = shift;
  my $uri  = shift;

  delete $self->{profiles}->{$uri};
}

=item add_remote_profile($uri)

This method is used internally when the remote peer advertises a
profile in the greeting message.

=cut

sub add_remote_profile {
  my $self = shift;
  my $uri  = shift;

  $self->{remote_profiles}->{$uri} = 1;
}

=item has_remote_profile($uri)

This method returns true if the remote profile advertised the given
profile uri, false otherwise.

=cut

sub has_remote_profile {
  my $self = shift;
  my $uri = shift;

  $self->{remote_profiles}->{$uri};
}

=item remote_profiles()

This method returns a list of the peer's advertised profiles.

=cut

sub remote_profiles {
  my $self = shift;

  keys %{$self->{remote_profiles}};
}

=item num_open_channels()

Return the number of open channels associated with this session.  This
does not include channel zero.

=cut

sub num_open_channels {
  my $self = shift;

  # return the number of open channels, not including channel zero.
  (scalar keys %{$self->{channels}})  - 1;
}

=item channel($channel_number)

Returns the C<Net::BEEP::Lite::Channel> object for the given channel
number.

=cut

sub channel {
  my $self = shift;
  my $chno = shift;

  $self->{channels}->{$chno};
}

=item servername([$val])

Returns or sets the session's server name.  This is normally set when
the first "<start>" message is encountered with a "serverName"
attribute.

=cut

sub servername {
  my $self = shift;
  my $name = shift;

  $self->{servername} = $name if $name;

  $self->{servername};
}

=item _tuning_reset([$send_greeting])

This does the full tuning reset: close all channels, delete pending
messages in the message queue, recreate channel zero, and (optionally)
re-send the greeting.  This defaults to sending the greeting.

This is normally called when a profile negotiates a security layer
(i.e., TLS or maybe SASL/DIGEST-MD5's encryption).

=cut

sub _tuning_reset {
  my $self 	    = shift;
  my $send_greeting = shift || 1;

  $self->_del_all_channels();
  $self->{messages} = [];
  $self->{remote_profiles} = {};
  $self->_add_channel(0, $self->{mgmt_profile});
  $self->send_greeting() if $send_greeting;
}

=item send_greeting()

Send the greeting message to the peer, and handle the greeting coming
from the peer.  It will advertise any profiles that have been
configured in the session.  Normally, this method is called as part of
the initialization process of the subclasses of this class.

=cut

sub send_greeting {
  my $self = shift;

  # send the greeting message.
  $self->{mgmt_profile}->send_greeting_message($self);

  # handle the remote greeting.
  my $peer_greeting = $self->_recv_message();
  $self->{mgmt_profile}->handle_message($self, $peer_greeting);
}

=item send_message($message)

This will send a BEEP message to the peer (over the channel specified
in the message).  This will handle possible fragmentation due to the
channel window size.

=cut

sub send_message {
  my $self    = shift;
  my $message = shift;

  my $chno = $message->channel_number();
  my $channel = $self->channel($chno);

  croak "send_message: message is on non-existent channel $chno"
    if not $channel;

  # New messages should never set msgno, and we will override it here
  # if it has.  Replies (RPY, ANS, ERR, NULL) should have the same
  # msgno and the MSG to which they are replying.
  if ($message->type() eq 'MSG') {
    carp "MSG messages should NOT have a pre-set message number"
      if defined $message->msgno();
    $message->msgno($channel->next_msgno());
  }
  else {
    if (not defined $message->msgno()) {
      carp "non-MSG message should have a pre-set message number";
      $message->msgno($channel->next_msgno());
    }
  }

  while ($message->has_more_frames()) {
    my $window = $channel->remote_window();

    # if there is no more space on this channel, switch to reading for
    # a bit while we wait for the channel to open.
    if ($window == 0) {
      $self->_read_for_seq($chno);

      $window = $channel->remote_window();
      next if $window == 0;
    }

    my $seqno = $channel->seqno();
    # calculate the next frame
    my $frame = $message->next_frame($seqno, $window);
    # actually send the frame.
    $self->_write_frame($frame);
    # update our current sequence number.
    $channel->update_seqno($frame->size());
    # and adjust the remote window.
    $channel->remote_window($window - $frame->size());
  }
}


=item _recv_message()

This will fetch the next message from the peer, returning a message
object.  It will handle reassembling a fragmented message.  It will
return the first complete message received on any (existing) channel.
It will discard frames on non-existent channels, issuing a warning.

This method will block.  It will return undef if it is not possible to
read from the socket, otherwise it will return the message.

=cut

sub _recv_message {
  my $self = shift;
  my %args = @_;

  # first try and return a message off the queue.
  my $message = $self->_dequeue_message();
  return $message if $message;

  # otherwise, we read one from the socket.

  # This handles interleaved frames for messages on different
  # channels, or ANS messages on the same (or different channels).
  # The channels have slots for building messages of both types.  The
  # first time we see a completing frame, we return that message.

  while (1) {
    # get the next frame from the socket (will block here).
    my $frame = $self->_recv_frame(%args);

    # our frame will have already gone through SEQ processing.  it
    # will also have been added to the appropriate message building
    # slot.

    next if $frame->type() eq 'SEQ';

    my $channel = $self->channel($frame->channel_number());

    # if we have a completing frame, we need to pull the complete
    # message from its build slot and clear it.

    if ($frame->completes()) {
      my $message;

      if ($frame->type() eq 'ANS') {
	$message = $channel->ans_message($frame->ansno());
	$channel->ans_clear_message($frame->ansno());
      }
      else {
	$message = $channel->message();
	$channel->clear_message();
      }

      return $message;
    }
  }
}

=item recv_message()

This will fetch the next message (on any defined channel other than
zero) from the peer, returning a message object.  It will handle
reassembling a fragmented message.  This will directly handle channel
zero messages, so this isn't all that useful for handling replies to
management channel messages.

=cut

sub recv_message {
  my $self  = shift;
  my %args = @_;

  my $message = undef;

  while (1) {
    $message = $self->_recv_message(%args);

    last if $message->channel_number() != 0;

    $self->{mgmt_profile}->handle_message($self, $message);
    return 0 if not $self->_is_connected();
  }
  $message;
}


=item close_session()

close the entire session.  Normally, this should only be called after
sending or receiving the "<ok>" message.  It can also be used in fatal
error situations.

=cut

sub close_session {
  my $self = shift;

  # we should have already sent or received the "ok" message by now
  # (unless we are aborting)
  $self->{sock}->close();
  $self->{sock} = undef;
  print STDERR "closed socket\n" if $self->{debug};
}

sub abort {
  my $self = shift;
  my $message = shift;

  print STDERR "aborting: $message\n" if $message && $self->{debug};
  confess "abort: $message\n" if $self->{trace};
  $self->close_session();

  die "aborted\n";
}


=item _read_for_seq([$channel_number])

Read frames from the socket until receiving a SEQ frame.  If
$channel_number is provided, then read until a SEQ frame on that
channel has been read.  Non SEQ frames read are place either in the
various message-building slots (see _recv_message), or place on the
general message queue.

=cut

sub _read_for_seq {
  my $self = shift;
  my $chno = shift;

  while (1) {
    my $frame = $self->_recv_frame();

    if (not $frame) {
      $self->abort("null frame detected");
      return;
    }

    # at this point, the SEQ has been processed.  This just determines
    # if we are done.
    if ($frame->type() eq 'SEQ') {
      return if not defined $chno;
      return if $chno == $frame->channel_number();
      next;
    }

    # for other frames, we need to make sure that we pull completed
    # messages off the build area and onto the queue.

    if ($frame->completes()) {

      my $channel = $self->channel($frame->channel_number());
      my $message;

      if ($frame->type() eq 'ANS') {
	$message = $channel->ans_message($frame->ansno());
	$channel->ans_clear_message($frame->ansno());
      }
      else {
	$message = $channel->message();
	$channel->clear_message();
      }

      $self->_queue_message($message);
    }
  }
}

=item _recv_frame()

This is an intermediate wrapper around C<_read_frame>.  Essentially,
it reads a frame from the socket, then does a little bit of post
processing, finally returning that frame.  The processing is: if it is
a SEQ frame, it updates the channels remote window size accordingly;
if it is some other frame, it adds it to the appropriate channel's
message building slot.

It returns undef if the socket could not be read from.  It returns 0
if the frame was on a non-existent channel.

=cut

sub _recv_frame {
  my $self = shift;
  my %args = @_;

  my $noseqs;
  if ($args{NoSEQ}) {
    $noseqs = 1;
  }

  my $frame = $self->_read_frame();

  # NOTE: this should never actually happen: _read_frame should
  # abort() instead of returning anything other than a valid frame.
  if (! $frame) {
    $self->abort("null frame received");
    return;
  }

  my $channel = $self->channel($frame->channel_number());

  if (not defined $channel) {
    $self->abort("frame received on non-existent channel " .
		 $frame->channel_number());
    return;
  }

  # handle SEQ frames independently.
  if ($frame->type() eq "SEQ") {
    # calculate new remote window: That is the advertise window
    # minus any bytes that we have already sent.
    my $new_window = $frame->window() -
      ($channel->seqno() - $frame->ackno());
    $channel->remote_window($new_window);
  }
  # assemble message from (possibly) multiple (sequential) frames.
  # the ANS collating case.
  elsif ($frame->type() eq 'ANS') {
    $channel->ans_message_add_frame($frame);
  }
  # the normal message collating case.
  else {
    $channel->message_add_frame($frame);
  }

  # track our last seen seqno from the peer in the channel.
  $channel->peer_seqno($frame->seqno() + $frame->size());

  # Emit a SEQ frame if we've actually read a frame with a payload.
  if ($frame->size() > 0 && !$noseqs) {
    # at the moment, we consider all frames to be "immediately"
    # consumed, so we just emit a constant for the window size.
    my $ackno = $channel->peer_seqno();

    $self->_send_seq($channel, $ackno);
  }

  $frame;
}

=item _send_seq($channel, $ackno)

Send a SEQ for $channel_number to the peer.  $ackno is the sequence
number to acknowledge.  Generally this is the seqno of the frame this
is responding to, plus the size of the payload of that frame.

=cut

sub _send_seq {
  my $self    = shift;
  my $channel = shift;
  my $seqno   = shift;

  my $seq_frame = new Net::BEEP::Lite::Frame
    (Type    => 'SEQ',
     Channel => $channel->number(),
     Ackno   => $seqno,
     Window  => $channel->local_window(),
     Debug   => $self->{debug},
     Trace   => $self->{trace});

  $self->_write_frame($seq_frame);
}

=item _read_frame()

This is an internal method for reading a single frame from the
internal socket.  It returns a C<Net::BEEP::Lite::Frame> object.

=cut

sub _read_frame {
  my $self = shift;

  my $sock = $self->{sock};

  my ($header, $read, $old_alarm_value);

  # set up an alarm handler for this method only.
  local $SIG{ALRM} = sub { die "alarm timeout\n"; };

  # read the header.
  eval {
    $old_alarm_value = alarm($self->{idle_timeout});
    $header = $sock->getline();
  };
  if ($@ and $@ =~ /^alarm timeout/io) {
    $self->abort("idle timeout");
    return;
  } elsif ($@) {
    die $@;
  }
  alarm($old_alarm_value);

  # FIXME: what does a null header mean?
  if (!$header) {
    $self->abort("null header detected (socket closed?)");
    return;
  }

  my $frame = Net::BEEP::Lite::Frame->new(Header => $header,
                                          Debug  => $self->{debug},
                                          Trace  => $self->{trace});

  # make sure the frame could be built \(i.e., known frame type, valid
  # frame headers...\)
  if (! $frame) {
    $self->abort("invalid frame header: '$header'");
    return;
  }

  # if we have no payload (SEQ, NUL), then we are done.
  return $frame if $frame->size() == 0 and ($frame->type() eq 'SEQ' or
                                            $frame->type() eq 'NUL');

  # read the payload.

  # FIXME: the following construct is not ideal. While the loop seems
  # necessary from a theoretical perspective (underlying read
  # operations are not guaranteed to return with all things read), it
  # is unknown if there is a real case where this read call would
  # return early and yet be able to continue.

  # Also note that a timer is set (and probably should always be set)
  # to (help) recover from cases where the frame size was incorrect
  # and too large.
  my $offset = 0;
  my $buffer;
  while (1) {
    eval {
      $old_alarm_value = alarm($self->{timeout});
      $read = $sock->read($buffer, $frame->size(), $offset);
    };
    if ($@ and $@ =~ /^alarm timeout/) {
      $self->abort("read operation timed out (invalid frame?)");
      return;
    } elsif ($@) {
      die $@;
    }
    alarm($old_alarm_value);
    last if ($read == 0 || $read == $frame->size());
    $offset += $read;
  }

  $frame->set_payload($buffer);

  # now read the trailer

  eval {
    $old_alarm_value = alarm($self->{timeout});
    $read = $sock->read($buffer, 5);
  };
  if ($@ and $@ =~ /^alarm timeout/) {
    $self->abort("read operation timed out (invalid frame?)");
    return;
  } elsif ($@) {
    die $@;
  }
  alarm($old_alarm_value);

  if ($buffer ne "END\r\n") {
    $self->abort("invalid frame trailer for '$buffer'");
    return;
  }

  print STDERR "_read_frame: read frame:\n", $frame->to_string, "\n"
    if $self->{trace};
  $frame;
}

=item _write_frame($frame)

This is an internal routine for writing a single frame to the
internally held socket.  $frame MUST be a C<Net::BEEP::Lite::Frame>
object.

=cut

sub _write_frame {
  my $self  = shift;
  my $frame = shift;

  my $sock = $self->{sock};

  $sock->print($frame->to_string());
  $sock->flush();

  print STDERR "_write_frame: wrote frame:\n", $frame->to_string(), "\n"
    if $self->{trace};
}

sub _queue_message {
  my $self    = shift;
  my $message = shift;

  push @{$self->{messages}}, $message;
}

sub _dequeue_message {
  my $self = shift;

  shift @{$self->{messages}};
}

sub _is_connected {
  my $self = shift;

  return ($self->{sock} && $self->{sock}->connected());
}


=pod

=back

=head1 SEE-ALSO

=over 4

=item L<Net::BEEP::Lite::ServerSession>

=item L<Net::BEEP::Lite::ClientSession>

=item L<Net::BEEP::Lite::Message>

=item L<Net::BEEP::Lite::Frame>

=back

=cut

1;
