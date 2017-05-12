#!/usr/bin/perl

use Net::Radius::Dictionary;
use Net::Radius::Packet;
use Net::LDAP::Util;
use Net::Inet;
use Net::LDAP;
use Net::UDP;
use warnings;
use Socket;
use strict;
use Fcntl;

# This is a simple RADIUS authentication server which accepts
# any user whose User-Name and Password validiate via LDAP

# NOTE - This server must be run as root on systems with shadow passwords.

# $Id: radius2ldap.pl 7 2003-01-08 03:42:41Z lem $

my $testing = 0; # set non-zero if testing
my %hostname_secret = ('rad1' => 'secret1', 'rad2' => '2secret',
      'testhost' => 'testsecret');
my %host_secret; #same as above translated to 4 byte address keys
foreach my $host(keys %hostname_secret) {
  $host_secret{inet_aton($host)} = $hostname_secret{$host};
}
my $uselogfile = "/var/log/rad2ldaplog";
my $errlogf = "/var/log/rad2ldaperrs";
open ERRLOG, ">>$errlogf";
print ERRLOG "Started ",scalar(localtime()),"\n";
close ERRLOG;
my $ldap;
connect_and_bind();
# Parse the RADIUS dictionary file 
my $dict = new Net::Radius::Dictionary "/usr/local/lib/radius.dictionary"
  or die "Couldn't read dictionary: $!";

# Set up the network socket (must have radius in /etc/services)
my $s = new Net::UDP { thisservice => "radius" } or die $!;
$s->bind or die "Couldn't bind: $!";
$s->fcntl(F_SETFL, $s->fcntl(F_GETFL,0) | O_NONBLOCK)
  or die "Couldn't make socket non-blocking: $!";

# Loop forever, receiving packets and replying to them
while (1) {
  my ($rec, $whence);
  # Wait for a packet
  my $nfound = $s->select(1, 0, 1, undef);
  if ($nfound > 0) {
    # Get the data
    $rec = $s->recv(undef, undef, $whence);
    my $fromname = inet_ntoa(substr($whence,4,4));
    print "from $fromname " if $testing;
    # Unpack it
    my $p = new Net::Radius::Packet $dict, $rec;
    if ($p->code eq 'Access-Request') {
      open LOG, ">>$uselogfile";
      # Print some details about the incoming request (try ->dump here)
      print $p->attr('User-Name'), " attempting login with password ",
            $p->password($host_secret{substr($whence,4,4)}), "\n" if $testing;
      print LOG $p->attr('User-Name');
      # Initialize the response packet we'll send back
      my $rp = new Net::Radius::Packet $dict;
      $rp->set_identifier($p->identifier);
      $rp->set_authenticator($p->authenticator);
      # Check against the authorization source passwd file
      if (check_pass($p->attr('User-Name'), 
		     $p->password($host_secret{substr($whence,4,4)}))) {
	$rp->set_code('Access-Accept');
        print LOG " OK  ";
      }
      else {
	print "Invalid login.\n" if $testing;
	$rp->set_code('Access-Reject');
	$rp->set_attr('Reply-Message', "\r\nInvalid login.\r\n");
        print LOG " bad ";
      }
      # Authenticate with the secret and send to the server.
      $s->sendto(auth_resp($rp->pack, 
			   $host_secret{substr($whence,4,4)}), $whence);
      print LOG scalar(localtime()),"\n";
      close LOG;
    }
    else {
      # It's not an Access-Request
      print "Unexpected packet type recieved." if $testing;
      $p->dump;
      open ERRLOG, ">>$errlogf";
      print ERRLOG "Bad packet type received ",localtime(),"\n";
      close ERRLOG;
    }
  }
}


sub connect_and_bind {
# make a connection to an LDAP server and bind to it.
  $ldap->unbind if $ldap;
  $ldap = Net::LDAP->new("ldaphost1.dirplace.com");
  $ldap = Net::LDAP->new("ldaphost2.dirplace.com") unless $ldap;
  $ldap = Net::LDAP->new("ldapbackup.elsewhere.com") unless $ldap;
  die "$@" unless $ldap;;
  $ldap->bind (version => 3) or die $@; 
}

sub check_pass {
# Function to check name and password.  Returns undef if no such user.
  my ($login, $password) = @_;
  return undef unless $password;
  my $retries = 0;
  while (1) {
    return undef if $retries > 2;
    my $mesg = $ldap->search(base => "o=myorg",
			     filter => "(uid=$login)",
			     attrs => ["sn"]);
#     login doesn't exist
    return undef 
	if (Net::LDAP::Util::ldap_error_name($mesg->code) 
	    eq "LDAP_NO_SUCH_OBJECT" ||
	    (($mesg->code == 0) and ($mesg->count() != 1)));
    if ($mesg->code) {
      ++$retries;
      print "retry search due to ", Net::LDAP::Util::ldap_error_name($mesg->code),"\n" if $testing;
      open ERRLOG, ">>$errlogf";
      print ERRLOG "retry search due to ", Net::LDAP::Util::ldap_error_name($mesg->code),scalar(localtime()),"\n";
      close ERRLOG;
      connect_and_bind();
      next;
    }
    my $entry = $mesg->entry(0);
    my $dn = $entry->dn;
  #  print "Dn is $dn\n" if $testing;
    $mesg = $ldap->bind (dn => $dn, password  => $password, version => 3) ; 
    return 0 if Net::LDAP::Util::ldap_error_name($mesg->code) eq "LDAP_INVALID_CREDENTIALS";
    return 1 if $mesg->code == 0;
    ++$retries;
    print "retry auth due to", Net::LDAP::Util::ldap_error_name($mesg->code),"\n" if $testing;
    connect_and_bind();

  }
}
