#!/usr/bin/perl -w

# $Id: 220restart.t,v 1.1 2003/09/28 11:50:45 rwmj Exp $

use strict;
use Test;
use POSIX qw(dup2);
use IO::Handle;
use FileHandle;

BEGIN {
  plan tests => 18;
}

use Net::FTPServer::InMem::Server;

pipe INFD0, OUTFD0 or die "pipe: $!";
pipe INFD1, OUTFD1 or die "pipe: $!";
my $pid = fork ();
die unless defined $pid;
unless ($pid) {			# Child process (the server).
  POSIX::dup2 (fileno INFD0, 0);
  POSIX::dup2 (fileno OUTFD1, 1);
  close INFD0;
  close OUTFD0;
  close INFD1;
  close OUTFD1;
  my $ftps = Net::FTPServer::InMem::Server->run
    (['--test', '-d', '-C', '/dev/null']);
  exit;
}

# Parent process (the test script).
close INFD0;
close OUTFD1;
OUTFD0->autoflush (1);

$_ = <INFD1>;
print OUTFD0 "USER rich\r\n";
$_ = <INFD1>;
ok (/^331/);

print OUTFD0 "PASS 123456\r\n";
$_ = <INFD1>;
ok (/^230 Welcome rich\./);

# Use binary mode.
print OUTFD0 "TYPE I\r\n";
$_ = <INFD1>;
ok (/^200/);

# Enter passive mode and get a port number.
print OUTFD0 "PASV\r\n";
$_ = <INFD1>;
ok (/^227 Entering Passive Mode \(127,0,0,1,(.*),(.*)\)/);

my $port = $1 * 256 + $2;

# Upload a large binary file.
print OUTFD0 "STOR test\r\n";
$_ = <INFD1>;
ok (/^150/);

# Connect to the passive mode port.
my $sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

my $buffer = "";

for (my $i = 0; $i < 10000; ++$i)
  {
    my $c = chr (int (rand 256));
    $buffer .= $c;
  }
$sock->print ($buffer);
$sock->close;

# Check the return code.
$_ = <INFD1>;
ok (/^226/);

# Grab random parts of the file and check.
ok (download_and_check ("test", 5000,  substr ($buffer, 5000)));
ok (download_and_check ("test", 1000,  substr ($buffer, 1000)));
ok (download_and_check ("test", 500,   substr ($buffer, 500)));
ok (download_and_check ("test", 10000, substr ($buffer, 10000)));
ok (download_and_check ("test", 0,     substr ($buffer, 0)));

# Upload a smallish ascii file.
print OUTFD0 "TYPE A\r\n";
$_ = <INFD1>;
ok (/^200/);

print OUTFD0 "STOR asctest\r\n";
$_ = <INFD1>;
ok (/^150/);

$sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

$sock->print ("0123456789\r\n",
	      "abcdefghij\r\n",
	      "klmnopqrst\r\n",
	      "uvwxyzABCD\r\n");
$sock->close;

$_ = <INFD1>;
ok (/^226/);

# Try a restartable download, in ASCII mode. Note how we are counting
# those end of line characters.
print OUTFD0 "REST 33\r\n";
$_ = <INFD1>;
ok (/^350/);

print OUTFD0 "RETR asctest\r\n";
$_ = <INFD1>;
ok (/^150/);

$sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

$_ = $sock->getline;
ok ($_ && $_ eq "uvwxyzABCD\r\n");

$sock->close;

$_ = <INFD1>;
ok (/^226/);

print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;

exit;

sub download_and_check
  {
    my $filename = shift;
    my $restart = shift;
    my $expected_data = shift;

    # Perform restartable download.
    print OUTFD0 "REST $restart\r\n";
    $_ = <INFD1>;
    return 0 unless /^350/;

    # Download.
    print OUTFD0 "RETR $filename\r\n";
    $_ = <INFD1>;
    return 0 unless /^150/;

    # Connect to the passive mode port.
    my $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    # Read the data.
    my $actual_data;
    my $r = $sock->read ($actual_data, 30000);

    $sock->close;

    # Check the return code.
    $_ = <INFD1>;
    return 0 unless /^226/;

    # Check the data.
    return 0 unless $r == length ($expected_data);

    return $expected_data eq $actual_data;
  }
