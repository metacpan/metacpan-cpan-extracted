use strict;
use Test::More tests => 11;
use POSIX qw(dup2);
use IO::Handle;
use FileHandle;

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

# Switch to ASCII mode.
print OUTFD0 "TYPE A\r\n";
$_ = <INFD1>;
ok (/^200/);

# Enter passive mode and get a port number.
print OUTFD0 "PASV\r\n";
$_ = <INFD1>;
ok (/^227 Entering Passive Mode \(127,0,0,1,(.*),(.*)\)/);

my $port = $1 * 256 + $2;

# Upload a file.
print OUTFD0 "STOR test\r\n";
$_ = <INFD1>;
ok (/^150/);

# Connect to the passive mode port.
my $sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

$sock->print ("This file used to be called 'test'.\r\n");
$sock->close;

# Check the return code.
$_ = <INFD1>;
ok (/^226/);

# Rename the file.
print OUTFD0 "RNFR test\r\n";
$_ = <INFD1>;
ok (/^350/);

print OUTFD0 "RNTO newname\r\n";
$_ = <INFD1>;
ok (/^250/);

# Read the file and check.
print OUTFD0 "RETR newname\r\n";
$_ = <INFD1>;
ok (/^150/);

$sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

$_ = $sock->getline;
ok ($_ && $_ eq "This file used to be called 'test'.\r\n");
$sock->close;

# Check the return code.
$_ = <INFD1>;
ok (/^226/);

print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;

__END__
