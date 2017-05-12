# $Id: ClientSession.pm,v 1.7 2004/04/22 20:45:13 davidb Exp $
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

package Net::BEEP::Lite::ClientSession;

=head1 NAME

Net::BEEP::Lite::ClientSession

=head1 SYNOPSIS

 my $c_session = Net::BEEP::Lite::ClientSession->new(Socket => $sock);

 my $channel_num = $c_session->start_channel('http://some/profile/url',
                                             (ServerName => "some.host.org"));

 my $resp = $c_session->send_and_recv_message(ContentType => "text/plain",
                                              Content => "hello!");

 $c_session->close_channel($channel_num);
 $c_session->close_channel(0); # close session.

=head1 DESCRIPTION

This is the session subclass that handles the pure "client" case.
This models the case of a process sending individual messages and
dealing with individual replies on its own.  In general, "clients" do
not advertise any profiles, so it is impossible for the peer to open
any new channels.

=cut

use Carp;

use Net::BEEP::Lite::Session;

use strict;
use warnings;

our(@ISA);

@ISA = qw(Net::BEEP::Lite::Session);

=head1 CONSTRUCTOR

=over 4

=item new( I<ARGS> )

This is the main constructor for this class.  It takes a named
parameter list.  It accepts all parameters defined by the
C<initialize> method (see below) and its superclass constructor (see
C<Net::BEEP::Lite::Session>).

This constructor will attempt to establish a valid BEEP session (i.e.,
it will send and process the greeting message.) if it is passed an
actual socket in the constructor.  If not (or if NoGreeting is set to
true), it is up to the calling code to send the greeting.

=back

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

This will initialize the object.  It is generally called from the
constructor.  At the moment it does not define any new named
parameters in addition to those supported by the superclass.

=cut

sub initialize {
  my $self = shift;
  my %args = @_;

#   for (keys %args) {
#     my $val = $args{$_};
#   }

  # as a client session, we assume that we are the initiator.
  $self->{channelno_counter} = 1;

  # we keep track of the "current" channel for the client.  This is
  # the last channel successfully opened.
  $self->{current_channel} = 0;
}

=item start_channel( I<ARGS> )

Sends a start channel request to the peer.  The named arguments are:

=over 4

=item URI

The URI of the BEEP profile to use this channel.  This is mandatory.

=item ServerName

The "server name" to present to the server.  Essentially this is the
name the client thinks the server is.  It is optional.

=item StartData

Data to piggyback with the start channel request.  This is optional.

=item Encoding

Set this to true of the StartData value is base64 encoded.

=back

This returns the channel number started, or dies on failure.

See the C<start_channel_message> method in
C<Net::BEEP::Lite::MgmtProfile>.

=cut

sub start_channel {
  my $self = shift;
  my %args = @_;

  my ($chno, $start_msg)
    = $self->{mgmt_profile}->send_start_channel_message($self, %args);
  my $resp = $self->_recv_message();

  # FIXME: should we die here? probably not.
  croak "unable to start channel: ", $resp->content(), "\n"
    if $resp->type() eq 'ERR';

  $self->{mgmt_profile}->handle_message($self, $resp);

  $self->current_channel($chno);

  $chno;
}

=item close_channel($channel_number, [$code, $content, $lang])

Sends a "close" message for the given channel.  See the
C<close_channel_message> in C<Net::BEEP::Lite:MgmtProfile> for more
information.

=cut

sub close_channel {
  my $self    = shift;
  my $chno    = shift;
  my $code    = shift;
  my $content = shift;
  my $lang    = shift;

  my $msg = $self->{mgmt_profile}->send_close_channel_message($self,
							      $chno,
							      $code,
							      $content,
							      $lang);
  my $resp = $self->_recv_message();

  # FIXME: should we die here? probably not.
  croak "unable to close channel: ", $resp->content(), "\n"
    if $resp->type() eq 'ERR';

  $self->{mgmt_profile}->handle_message($self, $resp);
}

=item new_message( I<ARGS> )

This is a convenience method for creating new messages.  It accepts
the following named parameters:

=over 4

=item Type

One of "MSG", "RPY", etc.  Defaults to "MSG".

=item Channel

The channel number to use.  This defaults to the "current channel",
which is the last successfully opened channel.

=item Content

The message content.

=item Content-Type (or ContentType, or contenttype)

The MIME content type.  This defaults to 'application/octet-stream'.

=back

=cut

sub new_message {
  my $self = shift;
  my %args = @_;

  $args{Type} = "MSG" if not $args{Type};
  $args{Channel} = $self->current_channel() if not $args{Channel};

  Net::BEEP::Lite::Message->new(%args);
}

=item send_and_recv_message( I<ARGS> )

This is a convenience method for send and message and receiving the
response to it all in one step.  This takes the same named parameters
as the C<new_message> method.

Note: currently this will have trouble with multiple channels.

=cut

sub send_and_recv_message {
  my $self = shift;

  my $message = $self->new_message(@_);

  $self->send_message($message);
  my $resp = $self->recv_message();

  $resp;
}

=item selected_profile([$uri])

Returns the profile selected from the last successful start channel.

=cut

sub selected_profile {
  my $self = shift;
  my $uri = shift;

  $self->{selected_profile} = $uri if $uri;

  $self->{selected_profile};
}

=item current_channel([$channel_number])

Returns the current channel number.

=cut

sub current_channel {
  my $self = shift;
  my $chno = shift;

  $self->{current_channel} = $chno if $chno;

  $self->{current_channel};
}

=pod

=back

=head1 SEE ALSO

=over 4

=item L<Net::BEEP::Lite::Session>

=back

=cut

1;
