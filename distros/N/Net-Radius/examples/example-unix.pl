#!/usr/bin/perl

use Net::Radius::Dictionary;
use Net::Radius::Packet;
use Net::Inet;
use Net::UDP;
use warnings;
use strict;
use Fcntl;

# This is a VERY simple RADIUS authentication server which accepts
# any user whos User-Name and Password match according to the Unix
# getpwnam() function.

# NOTE - This server must be run as root on systems with shadow passwords.

my $secret = "mysecret";  # Shared secret on the term server

# Function to check name and password.  Returns undef if no such user.
sub check_pass {
  my ($user, $pass) = @_;
  if (my $pwd = (getpwnam($user))[1]) {
    $pwd =~ /^\$.+\$(.+)\$/ or $pwd =~ /^(..)/;
    my $salt = $1;
    if (crypt($pass, $salt) eq $pwd) {
      return 1;
    }
    else {
      return 0;
    }
  }
  else {
    return undef;
  }
}

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
      print $p->attr('User-Name'), " attempting login with password ",
            $p->password($secret), "\n";
      # Initialize the response packet we'll send back
      my $rp = new Net::Radius::Packet $dict;
      $rp->set_identifier($p->identifier);
      $rp->set_authenticator($p->authenticator);
      # Check against the Unix passwd file
      if (check_pass($p->attr('User-Name'), $p->password($secret))) {
	print "Login valid.\n";
	$rp->set_code('Access-Accept');
      }
      else {
	print "Invalid login.\n";
	$rp->set_code('Access-Reject');
	$rp->set_attr('Reply-Message', "\r\nInvalid login.\r\n");
      }
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
