# $Id: MgmtProfile.pm,v 1.10 2003/09/11 19:57:31 davidb Exp $
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

package Net::BEEP::Lite::MgmtProfile;

=head1 NAME

Net::BEEP::Lite::MgmtProfile

=head1 SYNOPSIS

  my $mgmt_profile
    = Net::BEEP::Lite::MgmtProfile->new(AllowMultipleChannels => 1)

  my $greeting_msg = $mgmt_profile->greeting_message($session);

  my $start_channel_msg
    = $mgmt_profile->start_channel_message($session,
          (URI        => "http://xml.resources.org/profiles/NULL/ECHO",
           ServerName => "localhost",
           StartData  => "echo this!"));


=head1 DESCRIPTION

This is a subclass of C<Net::BEEP::Lite::BaseProfile>.  It is the
special profile that deals with the BEEP channel management messages
that occur on channel zero.  User code is not expected to instantate
instances of this class on their own.  In general, this is created and
used solely by the C<Net::BEEP::Lite::Session> class and its subclasses.

Both server and client sessions use this, as it handles both sides of
the conversation.

This profile is designed to be shared between different sessions, just
as part of the general design principle for profiles.  However, within
this framework (and Perl in general) this is unlikely to be actually
true (due to forking, or even ithreads).

=cut

use Carp;
use strict;
use warnings;

use XML::LibXML;
use MIME::Base64;

use Net::BEEP::Lite::Message;
use base qw(Net::BEEP::Lite::BaseProfile);

=head1 CONSTRUCTOR

=over 4

=item new( I<ARGS> )

This is the main constructor for this class.  It takes named
parameters as arguments.  See the C<initialize> method of this class
and the superclass (C<Net::BEEP::Lite::BaseProfile>) for valid argument
names.

=back

=cut

sub new {
  my $this  = shift;
  my $class = ref($this) || $this;

  my $self = {};

  bless $self, $class;

  $self->SUPER::initialize(@_);
  $self->initialize(@_);

  $self->{parser} = XML::LibXML->new();

  $self;

}

=head1 METHODS

=over 4

=item initialize( I<ARGS> )

Initialize the object.  This takes the same arguments as the
constructor (Indeed, the constructor is just calling this method).
This method takes the following named parameters:

=over 4

=item AllowMultipleChannels

if false, attempts to start more than one data channel by the peer
will fail.  This is set to B<false> by default.

=back

=cut

sub initialize {
  my $self = shift;
  my %args = @_;

  # by default, we do not allow multiple channels
  $self->{allow_multiple} = 0;

  for (keys %args) {
    my $val = $args{$_};

    /^AllowMultipleChannels/io and do {
      $self->allow_multiple_channels($val);
      next;
    };
  }
}

=item allow_multiple_channels([value])

If an argument is given, it is used as the boolean value for whether
or not start channel requests should be allowed when there is already
an existing open channel.  It returns the current (possibly just set)
value.

=cut

sub allow_multiple_channels {
  my $self = shift;
  my $val  = shift;

  $self->{allow_multiple} = $val if defined $val;
  $self->{allow_multiple};
}

# This will parse the BEEP management channel message XML content.
sub _parse_message {
  my $self    = shift;
  my $message = shift;

  my $ct = $message->content_type();
  confess "invalid mangement channel content type ($ct)\n"
    if $ct ne "application/beep+xml";

  my $content = $message->content();

  # parse the content.
  my $doc = $self->{parser}->parse_string($content);

  $doc->documentElement();
}

=item MSG($session, $message)

Handle MSG type messages.  This method handles BEEP "<start>" and
"<close>" messages.  Returns $message.

=cut

sub MSG {
  my $self    = shift;
  my $session = shift;
  my $message = shift;

  print STDERR "MgmtProfile->handling MSG: ", $message->content(), "\n"
    if $self->{debug};

  my $root = $self->_parse_message($message);
  my $name = $root->nodeName;

  # handle start message.
  if ($name eq "start") {

    # if we are not allowed to open multiple channels (in addition to
    # the management channel), don't.
    if ($session->num_open_channels() >= 1 and
	!$self->allow_multiple_channels()) {
      my $resp = $self->_error_message($message->msgno(),
				       550, "Channel creation not allowed.");
      $session->send_message($resp);
      return $message;
    }

    my $number      = $root->getAttribute("number");
    my $server_name = $root->getAttribute("serverName");

    my @profile_elements = $root->getElementsByTagName("profile");
    # for now, if there are multiple presented profiles, we just pick
    # the first one that we support (not the "best" one).
    my ($profile, $data, $encoded);
    for my $pe (@profile_elements) {
      my $uri = $pe->getAttribute("uri");
      $profile = $session->get_local_profile($uri);

      if ($profile) {
	my $encoding_attr = $pe->getAttribute("encoding") || "";
	$encoded = ($encoding_attr eq "base64");
	$data 	 = $pe->textContent;
	$data 	 = decode_base64($data) if $encoded;
	last;
      }
    }

    # if we don't support any of the profiles presented...
    if (not $profile) {
      # send the error response.
      my $resp = $self->_error_message
	($message->msgno(), 550, "all requested profiles are unsupported");
      $session->send_message($resp);
      return $message;
    }

    # set the server name, if we got it.
    $session->servername($server_name);

    # get the profile's input
    my ($resp_data, $encode);
    my @res = $profile->start_channel_request($session, $message, $data);

    if ($res[0] and $res[0] eq 'NUL') {
      # NUL means to do nothing at all.
      return $message;
    }
    elsif ($res[0] and $res[0] eq 'ERR') {
      # ERR means that the profile has refused the channel creation.
      my $resp = $self->_error_message($res[1], $res[2]);
      $session->send_message($resp);
      return $message;
    }
    elsif ($res[0] and $res[0] eq 'RPY') {
      # RPY means that the profile wants to send some response data
      # back along with creating the channel.
      $resp_data = $res[1];
      $encode 	 = $res[2] || 0;
      $resp_data = encode_base64($resp_data) if $encode;
    }
    # other responses or undef means to return a plain response.

    # IMPORTANT: add the channel to the session.
    $session->_add_channel($number, $profile);

    # return a "profile" response.
    $self->send_profile_message($session, $message->msgno(), $profile->uri(),
				$resp_data, $encode);

    return $message;
  }
  # handle close message.
  elsif ($name eq "close") {

    my $number = $root->getAttribute("number");
    my $code   = $root->getAttribute("code");

    my $resp = $self->_new_mgmt_message(Type 	=> 'RPY',
					Msgno 	=> $message->msgno(),
					Content => "<ok/>");

    $session->send_message($resp);

    # close the session if the channel number was zero.
    if ($number == 0) {
      # FIXME: I don't see any reason why I can't close the socket
      # immediately after sending the "ok", but beepcore-java will
      # throw an exception.

      # FIXME: what I really want to do is just wait for the other end
      # to close the socket (and only close)
      select(undef, undef, undef, 0.2);
      $session->close_session();
    } else {
      # IMPORTANT: otherwise, destroy the channel.
      $session->_del_channel($number);
    }
  }

  $message;
}

=item RPY($session, $message)

This method handles RPY type BEEP messages.  It handles "<greeting>",
"<ok>", and "<profile>" responses.  It returns $message.

=cut

sub RPY {
  my $self    = shift;
  my $session = shift;
  my $message = shift;

  print STDERR "MgmtProfile->handling RPY:\n", $message->content(), "\n"
    if $self->{debug};

  my $root = $self->_parse_message($message);
  my $name = $root->nodeName;

  # handle greeting message.
  if ($name eq "greeting") {

    my @profile_elements = $root->getElementsByTagName("profile");
    for my $pe (@profile_elements) {
      my $uri = $pe->getAttribute('uri');
      $session->add_remote_profile($uri);
    }

  }
  # handle ok message.
  elsif ($name eq "ok") {

    # This relies on the fact that send_close_channel_message will
    # stow the channel to be closed in the session.
    my $number = $session->{closing_channel_number};

    if ($number == 0) {
      # <ok /> received for close of channel zero means to close the
      # session.
      $session->close_session();
    } else {
      # we just close the requested channel.
      $session->_del_channel($number);
    }

  }
  # handle 'profile' message
  elsif ($name eq "profile") {

    # IMPORTANT: add the channel.  This relies on the fact that
    # send_start_channel_message will set the channel being started in
    # the session.
    $session->_add_channel($session->{starting_channel_number});

    # we probably don't need this check, since only client sessions
    # will get this (in this implementation, anyway).
    if ($session->can('selected_profile')) {
      my $uri = $root->getAttribute('uri');
      $session->selected_profile($uri);
    }

    # if there is any response data in the 
    my $encoding_attr = $root->getAttribute("encoding") || "";
    my $encoded = ($encoding_attr eq "base64");
    my $data = $root->textContent;
    $data = decode_base64($data) if $data and $encoded;

    $session->{start_channel_data} = $data if $data;
  }
  else {
    confess "unknown RPY encountered: ", $message->content(), "\n";
  }

  $message;
}

=item ERR($session, $message)

This method handles ERR type messages.  Currently, it doesn't really
do anything with them.  It returns $message.

=cut

sub ERR {
  my $self    = shift;
  my $session = shift;
  my $message = shift;

  print STDERR "got an error: ", $message->content(), "\n"
    if $self->{debug};
  return $message;
}

=item greeting_message(@profile_uris)

This method returns a formatted C<Net::BEEP::Lite::Message> containing a
valid "<greeting>" message.  It will advertise the profiles in
@profile_uris..

=cut

sub greeting_message {
  my $self    	   = shift;
  my @profile_list = @_;

  my $greeting_el = XML::LibXML::Element->new("greeting");
  for my $uri (@profile_list) {
    my $profile_el = XML::LibXML::Element->new("profile");
    $profile_el->setAttribute("uri", $uri);
    $greeting_el->appendChild($profile_el);
  }

  my $msg = $self->_new_mgmt_message
    (Type    => 'RPY',
     Msgno   => 0,
     Content => $greeting_el->toString());

  $msg;
}

=item send_greeting_message($session)

Format and send the greeting message to the peer.  It uses the session
to determine was profiles to advertise.

=cut

sub send_greeting_message {
  my $self    = shift;
  my $session = shift;

  my @profile_list = $session->get_local_profile_uris();
  my $msg = $self->greeting_message(@profile_list);

  $session->send_message($msg);

  $msg;
}

=item start_channel_message( I<ARGS> )

This method will return a formatted "<start>" message.  It accepts a
named parameter list.  The following named parameters are accepted:

=over 4

=item Channel

The channel number to request.  This is usually assigned by the
session.  It is required.

=item URI

The profile URI to request.  Currently this only allows one URI.  This
is required.

=item ServerName

The "server name" to present to the server.  Essentially this is the
name the client thinks the server is.  It is optional.

=item StartData

Data to piggyback with the start channel request.  This is optional.

=item Encoding

Set this to true of the StartData value is base64 encoded.

=back

=cut

sub start_channel_message {
  my $self    = shift;
  my %args    = @_;

  my ($number, $uri, $encoding, $servername, $data);
  # get the optional args
  for (keys %args) {
    my $val = $args{$_};
    /^Channel$/i and do {
      $number = $val;
      next;
    };
    /^URI/i and do {
      $uri = $val;
      next;
    };
    /^encoding$/i and do {
      $encoding = $val;
      next;
    };
    /^server.?name$/i and do {
      $servername = $val;
      next;
    };
    /^start.?data$/i and do {
      $data = $val;
      next;
    };
  }

  croak "start_channel_message(): missing required parameter 'Channel'\n"
    if not $number;
  croak "start_channel_message(): missing required parameter 'URI'\n"
    if not $uri;

  my $start_el = XML::LibXML::Element->new("start");

  $start_el->setAttribute("number", $number);
  $start_el->setAttribute("serverName", $servername) if $servername;

  my $profile_el = XML::LibXML::Element->new("profile");
  $profile_el->setAttribute('uri', $uri);
  $start_el->appendChild($profile_el);

  # FIXME: should be able to pass in a Node or string as data.
  if ($data) {
    if (!ref($data)) {
      my $cdata = XML::LibXML::CDATASection->new($data);
      $profile_el->appendChild($cdata);
    } elsif ($data->isa('XML::LibXML::CDATASection')) {
      $profile_el->appendChild($data);
    }
    $profile_el->setAttribute("encoding", "base64") if $encoding;
  }

  my $msg = $self->_new_mgmt_message(Type    => 'MSG',
				     Content => $start_el->toString());
  $msg;
}

=item send_start_channel_message($session, I<ARGS>)

In addition to the session, the parameters are the same as the named
parameters for the C<start_channel_message> method.  The 'Channel'
parameter may (and usually is) omitted.  This method returns the
channel number requested, and the message itself

=cut

sub send_start_channel_message {
  my $self    = shift;
  my $session = shift;
  my %args    = @_;

  $args{Channel} = $session->_next_channel_number()
    if not $args{Channel};

  $session->{starting_channel_number} = $args{Channel};

  my $msg = $self->start_channel_message(%args);

  $session->send_message($msg);

  ($args{Channel}, $msg);
}

=item close_channel_message($channel_number, [$code, $content, $lang])

This method will return a formatted "<close>" message.  $channel_number
is required.  $code will default to '200'.  $content is optional.
$lang is also optional, and is only meaningful if there is content.

=cut

sub close_channel_message {
  my $self    = shift;
  my $chno    = shift;
  my $code    = shift || 200;
  my $content = shift;
  my $lang    = shift;

  my $close_el = XML::LibXML::Element->new("close");
  $close_el->setAttribute("number", $chno);
  $close_el->setAttribute("code", $code);
  $close_el->setAttribute("xml:lang", $lang) if $lang;
  $close_el->appendText($content) if $content;


  $self->_new_mgmt_message(Type    => 'MSG',
			   Content => $close_el->toString());
}

=item send_close_channel_message($session, $channel_number,
                                 [$code, $content, $lang])

This method will format and send a "<close>" message.  Except for the
addition of the $session parameter, the parameters are the same as
C<close_channel_message>.

=cut

sub send_close_channel_message {
  my $self    = shift;
  my $session = shift;
  my $chno    = shift;

  my $msg = $self->close_channel_message($chno, @_);

  $session->{closing_channel_number} = $chno;

  $session->send_message($msg);

  $msg;
}

=item profile_message($uri, [$content, [$encoded]])

Generate a "<profile>" message content for $uri.  If $content is
provided, include it as text content contained within the <profile>
element.  If $encoded is set to true, set the 'encoding' attribute to
'base64'.

=cut

sub profile_message {
  my $self    = shift;
  my $msgno   = shift;
  my $uri     = shift;
  my $content = shift;
  my $encoded = shift;

  my $profile_el = XML::LibXML::Element->new("profile");
  $profile_el->setAttribute("uri", $uri);

  if ($content) {
    if (!ref($content)) {
      $profile_el->appendText($content);
    } elsif ($content->isa('XML::LibXML::Node')) {
      $profile_el->appendChild($content);
    }
  }
  $self->_new_mgmt_message(Type    => 'RPY',
			   Msgno   => $msgno,
			   Content => $profile_el->toString());
}

=item send_profile_message($session, $uri, [$content, [$encoded]])

Generate and send a "<profile>" message to the peer.  Except for the
$session paramter, the parameters are the same as for the
C<profile_message> method.

=cut

sub send_profile_message {
  my $self    = shift;
  my $session = shift;

  my $msg = $self->profile_message(@_);

  $session->send_message($msg);

  $msg;
}


# A convenience wrapper around the process of creating a new
# management BEEP message.
sub _new_mgmt_message {
  my $self    = shift;
  my %args    = @_;

  $args{Content_Type} = "application/beep+xml";
  $args{Channel}      = 0;

  Net::BEEP::Lite::Message->new(%args);
}

# create a new BEEP management error message.
sub _error_message {
  my $self    = shift;
  my $msgno   = shift;
  my $code    = shift;
  my $content = shift;

  my $error_el = XML::LibXML::Element->new("error");
  $error_el->setAttribute("code", $code);
  $error_el->appendText($content) if $content;

  $self->_new_mgmt_message(Type    => 'ERR',
			   Msgno   => $msgno,
			   Content => $error_el->toString());
}

=pod

=back

=head1 SEE ALSO

L<Net::BEEP::Lite::BaseProfile>, L<Net::BEEP::Lite::Session>, and
L<Net::BEEP::Lite::Message>

=cut

1;
