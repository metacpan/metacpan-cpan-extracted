#!/usr/bin/perl -w

# $Id: 260welcometext.t,v 1.1 2003/09/28 11:50:45 rwmj Exp $

use strict;
use Test;
use POSIX qw(dup2);
use IO::Handle;
use Sys::Hostname;
use FileHandle;

BEGIN {
  plan tests => 3;
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
    (['--test', '-d', '-C', '/dev/null',
      '-o', 'welcome type=text',
      '-o', 'welcome text=Hello. %E %L %U %%',
      '-o', 'maintainer email=root@example.com']);
  exit;
}

# Parent process (the test script).
close INFD0;
close OUTFD1;
OUTFD0->autoflush (1);

my $hostname = hostname ();

$_ = <INFD1>;

print OUTFD0 "USER rich\r\n";
$_ = <INFD1>;
ok (/^331/);

print OUTFD0 "PASS 123456\r\n";
$_ = <INFD1>;
ok (/Hello\. root\@example.com $hostname rich \%/);

print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;
ok (/^221/);
