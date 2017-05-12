# $Id: BaseProfile.pm,v 1.7 2003/09/11 19:57:31 davidb Exp $
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

package Net::BEEP::Lite::BaseProfile;

=head1 NAME

Net::BEEP::Lite::BaseProfile

=head1 SYNOPIS

  $profile = Net::BEEP::Lite::BaseProfile->new();

  my $uri = $profile->uri();

  if ($message->isa('Net::BEEP::Lite::Message') {
    $profile->handle_message($session, $message);
  }

=head1 DESCRIPTION

"Net::BEEP::Lite::BaseProfile" is the base class Net::BEEP::Lite profiles
should inherit from/implement.  It is not intended to be instantiated
on its own.  This class provides the basic structure of profile.

In general, subclasses only need to override the constructor (for
additional initialization parameters, if any) and the various message
handler methods (MSG(), RPY(), etc.).

Note that in general BEEP "client" applications generally do not need
to create profiles (although they may if they wish).  "Server"
applications generally do need to create profiles.

Normally profiles are designed to be shared between Sessions. This
primarily means that no session or channel base state is stored in the
profile object itself.  Designers of profiles need not stick to this
constraint, however.  In this framework, most often each Session is in
a different process and thus not actually shared amongst Sessions.

=cut

use Carp;

use strict;
use warnings;

=head1 CONSTRUCTOR

=over 4

=item new( I<ARGS> )

This constructor currently has no valid arguments.

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

This method initializes the object.  The arguments are named value
pairs, although currently none are defined.  Users of this class do
not call this method, as it is invoked by the constructor.
Subclasses, however, should invoke this in their constructors. (i.e.,
as $self->SUPER::initialize(@_)).

=cut

sub initialize {
  my $self  = shift;
  my %args = @_;

  $self->{debug} = 0;
  $self->{trace} = 0;

  for (keys %args) {
    my $val = $args{$_};
    /^debug/io and do {
      $self->{debug} = $val;
      next;
    };
    /^trace/io and do {
      $self->{trace} = $val;
      next;
    };
  }
}

=item uri([$va])

This returns the profile\'s identifying URI (e.g.,
http://iana.org/beep/SASL/PLAIN).  If passed an optional value, it
sets that to the profile's URI.

=cut

sub uri {
  my $self = shift;
  my $val  = shift;

  $self->{uri} = $val if $val;
  $self->{uri} || confess "profile has no URI!\n";
}

=item handle_message($session, $message)

Handle a BEEP message based on its type.  This just invokes the
profile's various handler functions (MSG(), ERR(), etc.).  Returns
whatever the handler method returns (generally the original message).

=cut

sub handle_message {
  my $self    = shift;
  my $session = shift;
  my $message = shift;

  if ($message->type() eq "MSG") {
    $self->MSG($session, $message);
  } elsif ($message->type() eq "RPY") {
    $self->RPY($session, $message);
  } elsif ($message->type() eq "ERR") {
    $self->ERR($session, $message);
  } elsif ($message->type() eq "ANS") {
    $self->ANS($session, $message);
  } elsif ($message->type() eq "NUL") {
    $self->NUL($session, $message);
  } else {
    croak $message->type(), " is unknown";
  }
}

=item start_channel_request($session, $message, $data)

Handle a start channel request.  This is a place for profiles to
control what happens when a start channel request for this profile is
handled by the management profile.  $session is the session the
request was received by, $message is the original request, and $data
is the data contained within the <start> element, extracted and
decoded from base64 (if necessary).

This method must return one of the following responses:

=over 4

=item undef

This means that the caller (the management profile) will return a
normal <profile> response with no included data and start the channel
This is what the base version of this method will return.

=item ('RPY', $content, [$encode])

This means that the caller should return a <profile> response with the
included content.  If $encode is true, it should base64 encode the
content first.

=item ('ERR', $code, $content)

This means that the caller should return this error instead of
starting the channel.

=item 'NUL'

This means that the caller should do nothing (don't send a response,
don't start the channel), this routine has handled the start channel
request.

=back

If not overridden, this routine will return undef, and will stow the
data in $session->{start_channel_data}, if there was any.

=cut

sub start_channel_request {
  my $self    = shift;
  my $session = shift;
  my $message = shift;
  my $data    = shift;

  $session->{start_channel_data} = $data if $data;

  return undef;
}

=item MSG($session, $message)

Handle MSG type messages.  This should be overridden by the subclass.
Subclasses should have this method return the original method.  This
version will simply croak if invoked.

=cut

sub MSG {
  my $self    = shift;
  my $session = shift;
  my $message = shift;

  croak "MSG handling not implemented\n";
}

=item RPY($session, $message)

Handle RPY type messages.  This should be overridden by the subclass.
Subclasses should have this method return the original method.  This
version will simply croak if invoked.

=cut

sub RPY {
  my $self    = shift;
  my $session = shift;
  my $message = shift;

  croak "RPY handling not implemented\n";
}

=item ERR($session, $message)

Handle ERR type messages.  This should be overridden by the subclass.
Subclasses should have this method return the original method.  This
version will simply croak if invoked.

=cut

sub ERR {
  my $self    = shift;
  my $session = shift;
  my $message = shift;

  croak "ERR handling not implemented\n";
}

=item ANS($session, $message)

Handle ANS type messages.  This should be overridden by the subclass.
Subclasses should have this method return the original method.  This
version will simply croak if invoked.

=cut

sub ANS {
  my $self    = shift;
  my $session = shift;
  my $message = shift;

  croak "ANS handling not implemented\n";
}

=item NUL($message)

Handle NUL type messages.  This should be overridden by the subclass.
Subclasses should have this method return the original method.  This
version will simply croak if invoked.

=cut

sub NUL {
  my $self    = shift;
  my $session = shift;
  my $message = shift;

  croak "NUL handling not implemented\n";
}

=pod

=back

=head1 SEE ALSO

=over 4

=item L<Net::BEEP::Lite::Message>

=item L<Net::BEEP::Lite::MgmtProfile>

=back

=cut

1;
