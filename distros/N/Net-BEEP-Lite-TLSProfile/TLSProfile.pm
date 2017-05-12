# $Id: TLSProfile.pm,v 1.1 2003/09/11 23:25:51 davidb Exp $
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

package Net::BEEP::Lite::TLSProfile;

=head1 NAME

Net::BEEP::Lite::TLSProfile - A TLS tuning profile for Net::BEEP::Lite.

=head1 SYNOPSIS

  use Net::BEEP::Lite;
  use Net::BEEP::Lite::TLSProfile;

  my $c_session = Net::BEEP::Lite::beep_connect(Host => localhost,
                                              Port => 12345) ||
    die "could not connect to beep peer: $!";

  if ($c_session->has_remote_profile($Net::BEEP::Lite::TLSProfile::URI)) {
    my $tls_profile = new Net::BEEP::Lite::TLSProfile(SSL_verify_mode => 0x01);

    $tls_profile->start_TLS($c_session) || die "could not establish TLS";

    print "peer certificate info: ", $session->{peer_certificate}, "\n";
  }

  ---

  use Net::BEEP::Lite;
  use Net::BEEP::Lite::TLSProfile;

  my $other_profile = ...;

  my $tls_profile = Net::BEEP::Lite::TLSProfile
      (Server        => 1,
       Callback      => sub { my $session = shift;
                              $session->add_local_profile($other_profile); },
       SSL_cert_file => 'my_cert.pem',
       SSL_key_file  => 'my_key.pem',
       SSL_ca_file   => 'my_ca.pem',
       SSL_passwd_db => sub { "some-passwd" });

  Net::BEEP::Lite::beep_listen(Port     => 12345,
                               Method   => 'fork',
                               Profiles => [ $tls_profile ]);

=head1 ABSTRACT

<Net::BEEP::Lite::TLSProfile> is a TLS profile for BEEP as defined by
RFC 3080 for use with the C<Net::BEEP::Lite> module.

=head1 DESCRIPTION

This is a TLS profile for BEEP as defined by RFC 3080 for use with the
C<Net::BEEP::Lite> module.  It can be use for both the initiator and
listener roles.  This module relies heavily on the C<IO::Socket::SSL>
module for the TLS implementation.

=cut

use Carp;
use strict;
use warnings;

use XML::LibXML;
use IO::Socket::SSL;

use Net::BEEP::Lite::Message;

use base qw(Net::BEEP::Lite::BaseProfile);

our($URI, $errstr, $VERSION);

$URI = 'http://iana.org/beep/TLS';

$VERSION = '0.01';

=head1 CONSTRUCTOR

=over 4

=item new( I<ARGS> )

This is the main constructor.  It takes a named parameter lists as its
argument.  See the C<initialize> method of a list of valid parameters.
It also takes the named parameters of C<Net::BEEP::Lite::BaseProfile>.

=back

=cut

sub new {
  my $this = shift;
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

Initialze this profile.  This is generally called by the constructor.
It takes the following named parameters:

=over 4

=item Server

Set this to true when this profile is being used by a BEEP peer in the
Listener role.  This will tell the underlying TLS negotation that it
is the server.  If this isn't set correctly, the TLS negotiation will
fail.

=item Callback

If this is set to a sub reference, this subroutine will be called upon
a successful TLS negotiation.  It will be passed a reference to the
session as its first and only argument.  For example, this might be
used to change the local profiles offered.

=item SSL_*

These are parameters that are understood by C<IO::Socket::SSL::new>.
You will probably want to use a few of them: SSL_cert_file,
SSL_key_file, and SSL_verify_mode are typical.

=back

=cut

sub initialize {
  my $self = shift;
  my %args = @_;

  $self->{uri} 	     = $URI;
  $self->{_callback} = 0;
  $self->{_ssl_args} = { SSL_version => 'TLSv1' };

  for (keys %args) {
    my $val = $args{$_};

    /^server$/io and do {
      $self->{_is_server} = $val;
      next;
    };
    /^callback$/io and do {
      $self->{_callback} = $val;
      next;
    };
    /^SSL_/ and do {
      $self->{_ssl_args}->{$_} = $val;
      next;
    };
  }
}


# This handles the piggybacked <ready /> request.  IMO, this is really
# the only way to do TLS.  I'm not sure why anyone would bother with
# the non-piggybacked form of this profile.
#
# NOTE: this handles the back end of the exchange itself, so we can
# drop right into the TLS negotation after sending the <proceed />
# response.
sub start_channel_request {
  my $self    = shift;
  my $session = shift;
  my $message = shift;
  my $data    = shift;

  my $el = $self->_parse_content($data);
  if ($el->nodeName eq 'ready') {

    # FIXME: deal with version attribute.

    # send <profile> response ourselves.
    my $proceed_cdata = new XML::LibXML::CDATASection("<proceed />");
    $session->{mgmt_profile}->send_profile_message
      ($session, $message->msgno(), $self->uri(), $proceed_cdata, 0);

    # start TLS
    $self->_start_TLS($session);

    # inform the management profile to do nothing else.
    return 'NUL';
  }
  else {
    # we create the channel, but return an embedded error.
    return ('RPY', "<error code='501'>unknown request.</error>", 0);
  }
}

# This handles server side of the non-piggybacked form of the TLS
# negotiation.
sub MSG {
  my $self    = shift;
  my $session = shift;
  my $message = shift;

  if ($message->content_type() ne 'application/beep+xml') {
    my $resp = new Net::BEEP::Lite::Message
      (Type 	   => 'ERR',
       Msgno 	   => $message->msgno(),
       Channel 	   => $message->channel_number(),
       ContentType => 'application/beep+xml',
       Content 	   => "<error code='501'>Unknown request.</error>");

    $session->send_message($resp);
    return;
  }

  my $el = $self->_parse_content($message->content());
  if ($el->nodeName eq 'ready') {

    # send <proceed /> response
    my $resp = new Net::BEEP::Lite::Message
      (Type 	   => 'RPY',
       Channel 	   => $message->channel_number(),
       Msgno 	   => $message->msgno(),
       ContentType => 'application/beep+xml',
       Content 	   => '<proceed />');

    $session->send_message($resp);

    # start TLS
    $self->_start_TLS($session);
  }
  else {

    my $resp = new Net::BEEP::Lite::Message
      (Type 	   => 'ERR',
       Channel 	   => $message->channel_number(),
       Msgno 	   => $message->msgno(),
       ContentType => 'application/beep+xml',
       Content 	   => "<error code='501'>Unknown request.</error>");

    $session->send_message($resp);
  }

  $message;
}


# This handles the client side of the non-piggybacked form of this
# profile.
sub RPY {
  my $self    = shift;
  my $session = shift;
  my $message = shift;

  my $el = $self->_parse_content($message->content());
  if ($el->nodeName eq 'proceed') {

    # start TLS
    $self->_start_TLS($session) || return undef;
  }
  else {
    $errstr = "Non-proceed response: " . $message->content();
    return undef;
  }

  $message;
}

# This handles error messages on the channel.  Presumably, a
# non-piggybacked "ready" request was broken in some way.
sub ERR {
  my $self    = shift;
  my $session = shift;
  my $message = shift;

  $errstr = "error response: ", $message->content();

  $message;
}

sub _parse_content {
  my $self    = shift;
  my $content = shift;

  my $doc = $self->{parser}->parse_string($content);
  $doc->documentElement();
}

# This method actually does the TLS negotiation.  It returns undef if
# it fails, and true if it succeeds, and does a tuning reset
# regardless.  This should only be called once the peer is past the
# "<proceed />" phase (either it sent it or received it).
sub _start_TLS {
  my $self    = shift;
  my $session = shift;
  my $res;

  # start SSL
  my $sock = $session->_socket();
  my %ssl_args = %{$self->{_ssl_args}};
  $ssl_args{SSL_server} = $self->{_is_server} if $self->{_is_server};


  my $ssl_sock = IO::Socket::SSL->start_SSL($sock, %ssl_args);

  if ($ssl_sock) {
    # SSL negotation succeeded.
    $session->_set_socket($ssl_sock);

    # if there is a peer cert, load its info into the session;
    $session->{peer_certificate} = $ssl_sock->dump_peer_certificate();

    # normally, we remove the TLS profile itself.
    delete $session->{profiles}->{$self->uri()};

    # if there is a callback, call it.
    &{$self->{_callback}}($session) if $self->{_callback};

    # FIXME: normally this would be done below, but some testing has
    # indicated that negotiation failure doesn't work the way it
    # ought.
    $session->_tuning_reset();

    $res = 1;
  }
  else {
    $errstr = "SSL/TLS negotiation failed: ",  &IO::Socket::SSL::errstr();
    print STDERR $errstr if $self->{debug};

    $res = undef;
  }

  # Do a tuning reset.
  # NOTE: this must be done even if the TLS negotation failed.
  # FIXME: some testing indicates otherwise, although the spec is clear.
  #$session->_tuning_reset();

  return $res;
}

=item start_TLS($session)

This is the main routine for the client side.  This will initiate a
request for TLS.  It will return undef if it failed, setting $errstr,
true if it succeeded.  The peer certificate info will be placed in
$session->{peer_certificate}.

=cut

sub start_TLS {
  my $self    = shift;
  my $session = shift;

  my $mgmt_profile = $session->{mgmt_profile};

  # Start a channel for the TLS profile, piggybacking our "ready"
  # message on the request.

  my %start_channel_args;
  $start_channel_args{Channel}   = $session->_next_channel_number();
  $start_channel_args{URI} 	     = $self->uri();
  $start_channel_args{StartData} = "<ready />";

  my ($channel_num, $start_msg) = $mgmt_profile->send_start_channel_message
    ($session, %start_channel_args);

  # look for the response to this request (RPY on channel zero with
  # the same message number.). This will place those messages on the
  # session's message queue.  This will only matter if the TLS
  # negotiation doesn't happen.

  # NOTE: this has to do a lot of stuff sort of manually, because the
  # normally used routines will emit SEQs when we don't want, and will
  # intercept channel zero messages, which we also don't want.

  my $resp;

  while (1) {
    # get the next message, but don't emit SEQ frames!
    $resp = $session->_recv_message(NoSEQ => 1);

    # if the message we received is the reply to our start channel
    # request, we are done reading.
    last if $resp->type() eq 'RPY' and $resp->channel_number() == 0 and
      $resp->msgno() == $start_msg->msgno();

    # otherwise, we send a SEQ frame ourselves.
    my $channel = $session->channel($resp->channel_number());
    $session->_send_seq($channel, $channel->peer_seqno());

    # if the message we got was for channel zero (but not the one we
    # wanted) we let the mangement profile handle it.  Otherwise we
    # queue it.
    if ($resp->channel_number() == 0) {
      $mgmt_profile->handle_message($session, $resp);
    } else {
      $session->_queue_message($resp);
    }
  }

  # Let the management profile do its thing.
  $mgmt_profile->handle_message($session, $resp);

  my $root = $self->_parse_content($session->{start_channel_data});
  if ($root->nodeName eq "proceed") {
    return $self->_start_TLS($session);
  }
  else {
    $errstr="non-<proceed> response: " . $session->{start_channel_data};
    return undef;
  }
}

=pod

=back

=head1 SEE ALSO

=over 4

=item L<IO::Socket::SSL>

=item L<Net::BEEP::Lite>

=cut

1;
