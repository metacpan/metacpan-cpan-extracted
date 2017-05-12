# $Id: ServerSession.pm,v 1.6 2003/09/11 19:57:31 davidb Exp $
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

package Net::BEEP::Lite::ServerSession;

=head1 NAME

Net::BEEP::Lite::ServerSession

=head1 SYNOPSIS

  my $s_session = Net::BEEP::Lite::Session( Socket                => $sock
                                          AllowMultipleChannels => 1 );
  $s_session->add_local_profile($my_profile);

  $s_session->process_messages();

=head1 DESCRIPTION

This is the session subclass that handles the pure "server" case.
This models the case of a process of fetching messages from the
internal socket, and handing those messages to the profile
implementation associated with the channel on which the message was
received.  That is, it only reacts to messages appearing on the
socket.

Note that at the moment, handling multiple channels is very weak, so
is it B<not> recommended that you use that feature.

=cut

use Carp;

use Net::BEEP::Lite::Session;

use strict;
use warnings;

our(@ISA);

@ISA = qw(Net::BEEP::Lite::Session);

=head1 CONSTRUCTOR

This is the main constructor.  It accepts a named parameter list.  In
addition to the parameters accepted by the superclass
(C<Net::BEEP::Lite::Session>), the same parameters as the C<initialize>
method.

This constructor will attempt to establish a valid BEEP session (i.e.,
it will send and process the greeting message.) if it is passed an
actual socket in the constructor.  If not (or if NoGreeting is set to
true), it is up to the calling code to send the greeting.

=cut

sub new {
  my $this = shift;
  my $class = ref($this) || $this;

  my $self = {};
  bless $self, $class;

  $self->SUPER::initialize(@_);
  $self->initialize(@_);

  $self->send_greeting() unless $self->{_no_greeting};

  $self;
}

=head1 METHODS

=over 4

=item initialize( I<ARGS> )

This will initialize the internal state of this object.  This is
normally called by the constructor.  It accepts a named parameter list
with the following parameters:

=over 4

=item

Profiles -- a list (or scalar) of profile implementations to advertise
and support.

=back

=cut

sub initialize {
  my $self = shift;
  my %args = @_;

  for (keys %args) {
    my $val = $args{$_};

    /^Profiles?/io and do {
      if (ref($val) eq "ARRAY") {
	for my $p (@$val) {
	  $self->add_local_profile($p);
	}
      } elsif (ref($val) eq "SCALAR") {
	$self->add_local_profile($val);
      }
      next;
    };
  }

  croak "At least one profile must be specified"
    if not $self->get_local_profile_uris();

  # as a server session, we assume that we are the listener.
  $self->{channelno_counter} = 2;
}

=item process_message()

Pull a single message from the internal socket (this will block if
there is nothing to read), and hand it off to the apropriate profile
implementation.

Note: this relies on the C<recv_message> method, and thus doesn't
handle multiple channels.  This method may go away in future versions.

=cut

sub process_message {
  my $self = shift;

  my $message = $self->recv_message();
  return 0 if not $message;

  # print STDERR "processing a message:", ref($message), "\n";

  #  call appropriate method of profile assoc. with channel.
  my $channel = $self->channel($message->channel_number());
  my $profile = $channel->profile();

  if (not $profile) {
    warn "message received on channel without profile\n";
    return 1;
  }

  # print STDERR "handling a message.\n";
  $profile->handle_message($self, $message);
}

=item process_message()

Process messages until the session closes.  This the the main routine
for server sessions.

=cut

sub process_messages {
  my $self = shift;

  while (1) {
    my $res = $self->process_message();
    last if (not $self->_is_connected());
    last if (not $res);
  }
}

=item reply_message( I<ARGS> )

This is a convenience methods for profiles to create responses to
received messages.  It takes the same named parameters as the
C<Net::BEEP::Lite::Message> constructor, with the addition of "Message",
containing a reference to another message object.  At minimum, the
"Message" and "Payload" parameters should be set.

=cut

sub reply_message {
  my $self = shift;
  my %args = @_;

  my $message;

  for (keys %args) {
    my $val = $args{$_};

    /^Message$/i and do {
      $message = $val;
      next;
    };
  }

  # some base defaults not based on the source message.
  $args{Type} = 'RPY' if not $args{Type};
  $args{Session} = $self;

  if ($message) {
    $args{Channel} = $message->channel_number();
    $args{Msgno}   = $message->msgno();
  }

  Net::BEEP::Lite::Message->new(%args);
}

=pod

=back

=head1 SEE ALSO

=over 4

=item L<Net::BEEP::Lite::Session>

=back

=cut

1;
