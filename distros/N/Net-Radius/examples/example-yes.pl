#!/usr/bin/perl

use Net::Radius::Dictionary;
use Net::Radius::Packet;
use Net::Inet;
use Net::UDP;
use warnings;
use strict;
use Fcntl;

# This is a VERY simple RADIUS authentication server which responds
# to Access-Request packets with Access-Accept.  This allows anyone
# to log in.

# $Id: example-yes.pl 7 2003-01-08 03:42:41Z lem $

my $secret = "mysecret";  # Shared secret on the term server

# Parse the RADIUS dictionary file (must have dictionary in current dir)
my $dict = new Net::Radius::Dictionary "dictionary"
  or die "Couldn't read dictionary: $!";

# Set up the network socket (must have radius in /etc/services)
my $s = new Net::UDP { thisservice => "radius" } or die $!;
$s->bind or die "Couldn't bind: $!";
$s->fcntl(F_SETFL, $s->fcntl(F_GETFL,0) | O_NONBLOCK)
  or die "Couldn't make socket non-blocking: $!";

# Loop forever, recieving packets and replying to them
while (1) {
  my ($rec, $whence);
  # Wait for a packet
  my $nfound = $s->select(1, 0, 1, undef);
  if ($nfound > 0) {
    # Get the data
    $rec = $s->recv(undef, undef, $whence);
    # Unpack it
    my $p = new Net::Radius::Packet $dict, $rec;
    if ($p->code eq 'Access-Request') {
      # Print some details about the incoming request (try ->dump here)
      print $p->attr('User-Name'), " logging in with password ",
            $p->password($secret), "\n";
      # Create a response packet
      my $rp = new Net::Radius::Packet $dict;
      $rp->set_code('Access-Accept');
      $rp->set_identifier($p->identifier);
      $rp->set_authenticator($p->authenticator);
      # (No attributes are needed.. but you could set IP addr, etc. here)
      # Authenticate with the secret and send to the server.
      $s->sendto(auth_resp($rp->pack, $secret), $whence);
    }
    else {
      # It's not an Access-Request
      print "Unexpected packet type recieved.";
      $p->dump;
    }
  }
}
