use strict;
use Test::More tests => 96;
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

# Use binary mode.
print OUTFD0 "TYPE I\r\n";
$_ = <INFD1>;
ok (/^200/);

# Enter passive mode and get a port number.
print OUTFD0 "PASV\r\n";
$_ = <INFD1>;
ok (/^227 Entering Passive Mode \(127,0,0,1,(.*),(.*)\)/);

my $port = $1 * 256 + $2;

# Test STOR command.
print OUTFD0 "STOR test1\r\n";
$_ = <INFD1>;
ok (/^150/);

# Connect to passive mode port.
my $sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

# Store some data.
$sock->print ("Hope for me, I hope for you,\n",
	      "We're snowdrops falling through the night.\n");
$sock->close;

# Check return code.
$_ = <INFD1>;
ok (/^226/);

# Test APPE command.
print OUTFD0 "APPE test1\r\n";
$_ = <INFD1>;
ok (/^150/);

# Connect to passive mode port.
$sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

# Append some more data to the same file.
$sock->print ("We'll melt away before we land,\n",
	      "Two teardrops for somebody's hand.\n");
$sock->close;

# Check return code.
$_ = <INFD1>;
ok (/^226/);

# Read back the file.
print OUTFD0 "RETR test1\r\n";
$_ = <INFD1>;
ok (/^150/);

# Connect to passive mode port.
$sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

# Read it back.
$_ = $sock->getline;
ok ($_ && /^Hope for me.*you,/);
$_ = $sock->getline;
ok ($_ && /^We\'re snowdrops.*night\./);
$_ = $sock->getline;
ok ($_ && /^We\'ll melt.*land,/);
$_ = $sock->getline;
ok ($_ && /^Two teardrops.*hand\./);
$_ = $sock->getline;
ok (! defined $_);

# Check return code.
$_ = <INFD1>;
ok (/^226/);

for (my $pass = 1; $pass < 10; ++$pass)
  {
    # Test STOU command.
    print OUTFD0 "STOU\r\n";
    $_ = <INFD1>;
    ok (/^150 FILE: (.*)\r\n$/);

    my $filename = $1;

    # Connect to passive mode port.
    $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    # Store some data.
    $sock->print ("Copenhagen, you're the end,\n",
		  "Gone and made me a child again.\n",
		  "Warmed my feet beneath cold sheets,\n",
		  "Dyed my hair with your sunny streets.\n");
    $sock->close;

    # Check return code.
    $_ = <INFD1>;
    ok (/^226/);

    # Read back the file and check.
    print OUTFD0 "RETR $filename\r\n";
    $_ = <INFD1>;
    ok (/^150/);

    # Connect to passive mode port.
    $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    # Read it back.
    $_ = $sock->getline;
    ok ($_ && /^Copenhagen.*end,/);
    $_ = $sock->getline;
    ok ($_ && /^Gone.*again\./);
    $_ = $sock->getline;
    ok ($_ && /^Warmed.*sheets,/);
    $_ = $sock->getline;
    ok ($_ && /^Dyed.*streets\./);
    $_ = $sock->getline;
    ok (! defined $_);

    # Check return code.
    $_ = <INFD1>;
    ok (/^226/);
  }

print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;

__END__
