#! /usr/bin/perl

use FindBin qw($Bin);
use lib "$Bin/../lib";

use Net::BEEP::Lite;
use Net::BEEP::Lite::Session;

use warnings;

# connect to the server (this will die if it can't).
my $session = Net::BEEP::Lite::beep_connect(Host => "localhost",
					    Port => $ARGV[0]);

# start a channel for the echo profile (this will die if it can't).
my $channel_num = $session->start_channel
  (URI        => 'http://xml.resource.org/profiles/NULL/ECHO',
   ServerName => "host.example.com");

my $channel_num_2 = $session->start_channel
  (URI => 'http://xml.resource.org/profiles/NULL/ECHO');


my $resp = $session->send_and_recv_message(ContentType  => 'text/plain',
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

