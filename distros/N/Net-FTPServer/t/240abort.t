#!/usr/bin/perl -w

# $Id: 240abort.t,v 1.2 2004/12/01 13:00:50 rwmj Exp $

use strict;
use Test;
use POSIX qw(dup2);
use IO::Handle;
use FileHandle;

BEGIN {
  plan tests => 16;
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

foreach my $mode ('A', 'I')
  {
    # Switch to correct mode.
    print OUTFD0 "TYPE $mode\r\n";
    $_ = <INFD1>;
    ok (/^200/);

    # Enter passive mode and get a port number.
    print OUTFD0 "PASV\r\n";
    $_ = <INFD1>;
    ok (/^227 Entering Passive Mode \(127,0,0,1,(.*),(.*)\)/);

    my $port = $1 * 256 + $2;

    # Uploading a big file.
    print OUTFD0 "STOR test\r\n";
    $_ = <INFD1>;
    ok (/^150/);

    # Connect to the passive mode port.
    my $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    for (my $i = 0; $i < 10000; ++$i)
      {
	$sock->print ("This is line $i.\r\n");
      }
    $sock->close;

    # Check the return code.
    $_ = <INFD1>;
    ok (/^226/);

    # Begin downloading the same file.
    print OUTFD0 "RETR test\r\n";
    $_ = <INFD1>;
    ok (/^150/);

    # Connect to the passive mode port.
    $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    for (my $i = 0; $i < 50; ++$i)
      {
	$sock->getline;
      }

    # Now abruptly abort the download.
    my $buf1 = "\377\364\377";	# Telnet: IAC IP IAC
    my $buf2 = "\362ABOR\r\n";	# Telnet: DM "ABOR" CR LF

    # Simulate sending out of band data.
    print OUTFD0 $buf1;
    kill "SIGURG", $pid;
    sleep 1;

    # Read any remaining data on the socket.
    my $buffer;
    while ($sock->read ($buffer, 1000) > 0) {}
    $sock->close;

    print OUTFD0 $buf2;

    # Check the error from the RETR command.
    $_ = <INFD1>;
    ok (/^426/);
    # (Previous command may have sent continuation lines, so lose those first)
    $_ = <INFD1> while m/^\d\d\d-/;

    # And check the return from the ABOR command.
    $_ = <INFD1>;
    ok (/^226/);
  }

print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;
