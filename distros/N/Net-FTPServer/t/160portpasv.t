use strict;
use Test::More tests => 41;
use POSIX qw(dup2);
use IO::Handle;
use IO::Socket;
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

# Do all the tests 3 times over so that we exercise
# switching between active and passive mode (on early
# versions of the FTP server this was broken).

for (my $pass = 1; $pass <= 3; ++$pass)
  {
    # Test active mode upload.
    my $sock = new IO::Socket::INET
      (Listen => 10,
       LocalAddr => "127.0.0.1",
       Proto => "tcp")
	or die "socket: $!";

    my $p1 = int ($sock->sockport / 256);
    my $p2 = int ($sock->sockport % 256);

    print OUTFD0 "PORT 127,0,0,1,$p1,$p2\r\n";
    $_ = <INFD1>;
    ok (/^200/);

    print OUTFD0 "TYPE I\r\n";
    $_ = <INFD1>;
    ok (/^200/);

    print OUTFD0 "STOR test1\r\n";
    $_ = <INFD1>;
    ok (/^150/);

    my $csock = $sock->accept or die "accept: $!";
    for (my $i = 0; $i < 100; ++$i)
      {
	$csock->print ('a' x 100);
      }
    $csock->close;

    $_ = <INFD1>;
    ok (/^226/);

    # Test active mode download.
    print OUTFD0 "RETR test1\r\n";
    $_ = <INFD1>;
    ok (/^150/);

    $csock = $sock->accept or die "accept: $!";
    my $buffer;
    while ($csock->getline) {}
    $csock->close;

    $_ = <INFD1>;
    ok (/^226/);

    print OUTFD0 "DELE test1\r\n";
    $_ = <INFD1>;
    ok (/^250/);

    # Test passive mode upload.
    print OUTFD0 "PASV\r\n";
    $_ = <INFD1>;
    ok (/^227 Entering Passive Mode \(127,0,0,1,(.*),(.*)\)/);

    my $port = $1 * 256 + $2;

    print OUTFD0 "STOR test2\r\n";
    $_ = <INFD1>;
    ok (/^150/);

    $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    for (my $i = 0; $i < 100; ++$i)
      {
	$sock->print ('b' x 100);
      }
    $sock->close;

    $_ = <INFD1>;
    ok (/^226/);

    # Test passive mode download.
    print OUTFD0 "RETR test2\r\n";
    $_ = <INFD1>;
    ok (/^150/);

    $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    while ($sock->getline) {}
    $sock->close;

    $_ = <INFD1>;
    ok (/^226/);

    print OUTFD0 "DELE test2\r\n";
    $_ = <INFD1>;
    ok (/^250/);
  }

print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;

__END__
