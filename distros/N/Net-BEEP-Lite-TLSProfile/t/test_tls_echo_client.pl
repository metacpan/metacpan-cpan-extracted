#! /usr/bin/perl

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Net::BEEP::Lite;
use Net::BEEP::Lite::Session;
use Net::BEEP::Lite::TLSProfile;

# connect to the server (this will die if it can't).
my $session = Net::BEEP::Lite::beep_connect(Host => "localhost",
					  Port => $ARGV[0]) ||
  die "could not connect to peer";

# if the remote end advertises TLS, we attempt to start it.
print "seeing if remote peer advertises $Net::BEEP::Lite::TLSProfile::URI\n";
if ($session->has_remote_profile($Net::BEEP::Lite::TLSProfile::URI)) {
  my $tls_profile = new Net::BEEP::Lite::TLSProfile
    (SSL_verify_mode => 0x01,
     SSL_ca_file     => "./localhost_ca-cacert.pem",
     Debug 	     => 1);

  # if you want to see the SSL debugging...
  # $IO::Socket::SSL::DEBUG = 4;

  $tls_profile->start_TLS($session) || die "could not establish TLS";

  print "Peer certificate: ", $session->{peer_certificate}, "\n";
  # you can also get the peer cert fields directly from the SSL socket
  # (although this uses an "internal" session API:
  print "Peer subject: ", $session->_socket()->peer_certificate("subject"),
    "\n";

  print "Peer now supports (after TLS):\n",
    join("\n", $session->remote_profiles()), "\n\n";
} else {
  print "Peer does not support TLS\n";
  print "Peer does support:\n", join("\n", $session->remote_profiles()), "\n";
}

# start a channel for the echo profile (this will die if it can't).
my $channel_num = $session->start_channel
  (URI        => 'http://xml.resource.org/profiles/NULL/ECHO',
   ServerName => "host.example.com");

my $channel_num_2 = $session->start_channel
  (URI => 'http://xml.resource.org/profiles/NULL/ECHO');


my $resp = $session->send_and_recv_message(Content-Type => 'text/plain',
					   Content      => "Echo this!",
					   Channel      => $channel_num);

print "Received the following response payload:\n", $resp->payload(), "\n";

$resp = $session->send_and_recv_message(Content => "yeah, echo this!\n",
				        Channel => $channel_num);

print "Received the following response payload:\n", $resp->payload(), "\n";
print "The payload had a content type of ", $resp->content_type(), "\n";

$resp = $session->send_and_recv_message
  (Content => "echoing on the other channel\n",
   Channel => $channel_num_2);
print "Received the following response payload:\n", $resp->payload(), "\n";

$resp = $session->close_channel($channel_num_2);

$resp = $session->close_channel($channel_num);

print "Socket seems to have closed early\n" if not $session->_is_connected();

$resp = $session->close_channel(0);

