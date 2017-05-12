#!/usr/bin/perl -w

# $Id: 350generatorlist.t,v 1.1 2003/09/28 11:50:45 rwmj Exp $

use strict;
use Test;
use POSIX qw(dup2);
use IO::Handle;
use FileHandle;

BEGIN {
  plan tests => 22;
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
      '-o', 'limit memory=-1',
      '-o', 'limit nr processes=-1',
      '-o', 'limit nr files=-1']);
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

# Create a directory structure.
# dir/
#   sub1/
#   sub2/
#   sub3/
#     INSTALL
#   Makefile.PL
#   README
print OUTFD0 "MKD dir\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "CWD dir\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "MKD sub1\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "MKD sub2\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "MKD sub3\r\n";
$_ = <INFD1>;
ok (/^250/);

ok (upload_file ("Makefile.PL"));
ok (upload_file ("README"));

print OUTFD0 "CWD sub3\r\n";
$_ = <INFD1>;
ok (/^250/);

ok (upload_file ("INSTALL"));

print OUTFD0 "CWD /\r\n";
$_ = <INFD1>;
ok (/^250/);

# Download list file.
my $tmpfile = ".350generatorlist.t.$$";
ok (download_file ("dir.list", $tmpfile));

open LIST, "<$tmpfile" or die "$tmpfile: $!";
my $buffer;
{
  local $/ = undef;
  $buffer = <LIST>;
}
close LIST;

# Sort the output ourselves, since InMem has a bug which means that
# it doesn't return the directories and files sorted as it should.

my @results = split /\r?\n/, $buffer;
@results = sort @results;

ok ($results[0] eq "/dir/");
ok ($results[1] eq "/dir/Makefile.PL");
ok ($results[2] eq "/dir/README");
ok ($results[3] eq "/dir/sub1/");
ok ($results[4] eq "/dir/sub2/");
ok ($results[5] eq "/dir/sub3/");
ok ($results[6] eq "/dir/sub3/INSTALL");

unlink $tmpfile;

print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;

exit;

# This function uploads a file to the server.

sub upload_file
  {
    my $filename = shift;

    # Snarf the local file.
    open UPLOAD, "<$filename" or die "$filename: $!";
    my $buffer;
    {
      local $/ = undef;
      $buffer = <UPLOAD>;
    }
    close UPLOAD;

    # Send the STOR command.
    print OUTFD0 "STOR $filename\r\n";
    $_ = <INFD1>;
    return 0 unless /^150/;

    # Connect to the passive mode port.
    my $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    # Write to socket.
    $sock->print ($buffer);
    $sock->close;

    # Check return code.
    $_ = <INFD1>;
    return /^226/;
  }

# Download a file from the server into a local file.

sub download_file
  {
    my $remote_filename = shift;
    my $local_filename = shift;

    # Send the RETR command.
    print OUTFD0 "RETR $remote_filename\r\n";
    $_ = <INFD1>;
    return 0 unless /^150/;

    # Connect to the passive mode port.
    my $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    # Read all the data into a buffer.
    my $buffer = "";
    my $posn = 0;
    my $r;
    while (($r = $sock->read ($buffer, 65536, $posn)) > 0) {
      $posn += $r;
    }
    $sock->close;

    # Check return code.
    $_ = <INFD1>;
    return 0 unless /^226/;

    # Save to load file.
    open DOWNLOAD, ">$local_filename" or die "$local_filename: $!";
    print DOWNLOAD $buffer;
    close DOWNLOAD;

    # OK!
    return 1;
  }
