use strict;
use Test::More tests => 36;
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

# Upload files.
ok (upload_rand ("test0", 0, 1000));
ok (upload_rand ("test1", 1, 1001));
ok (upload_rand ("test2", 2, 1002));
ok (upload_rand ("test3", 1023, 1003));
ok (upload_rand ("test4", 1024, 1004));
ok (upload_rand ("test5", 1025, 1005));
ok (upload_rand ("test6", 65535, 1006));
ok (upload_rand ("test7", 65536, 1007));
ok (upload_rand ("test8", 65537, 1008));
ok (upload_rand ("test9", 131071, 1009));
ok (upload_rand ("testa", 131072, 1010));
ok (upload_rand ("testb", 131073, 1011));
ok (upload_rand ("testc", 100000, 1012));
ok (upload_rand ("testd", 150000, 1013));
ok (upload_rand ("teste", 200000, 1014));
ok (upload_rand ("testf", 300000, 1015));

# Download and compare files.
ok (download_and_check ("test0", 0, 1000));
ok (download_and_check ("test1", 1, 1001));
ok (download_and_check ("test2", 2, 1002));
ok (download_and_check ("test3", 1023, 1003));
ok (download_and_check ("test4", 1024, 1004));
ok (download_and_check ("test5", 1025, 1005));
ok (download_and_check ("test6", 65535, 1006));
ok (download_and_check ("test7", 65536, 1007));
ok (download_and_check ("test8", 65537, 1008));
ok (download_and_check ("test9", 131071, 1009));
ok (download_and_check ("testa", 131072, 1010));
ok (download_and_check ("testb", 131073, 1011));
ok (download_and_check ("testc", 100000, 1012));
ok (download_and_check ("testd", 150000, 1013));
ok (download_and_check ("teste", 200000, 1014));
ok (download_and_check ("testf", 300000, 1015));

print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;

exit;

# This function uploads a single file of pseudorandomness to the server.

sub upload_rand
  {
    my $filename = shift;
    my $size = shift;
    my $seed = shift;

    srand $seed;

    # Send the STOR command.
    print OUTFD0 "STOR $filename\r\n";
    $_ = <INFD1>;
    return 0 unless /^150/;

    # Connect to the passive mode port.
    my $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    # Generate the random data.
    my $buffer = "";
    for (my $i = 0; $i < $size; ++$i)
      {
	my $c = chr (int (rand 256));
	$buffer .= $c;
      }

    # Write to socket.
    $sock->print ($buffer);
    $sock->close;

    # Check return code.
    $_ = <INFD1>;
    return /^226/;
  }

# This function downloads a file previously uploaded and compares it with
# what we think it should contain.

sub download_and_check
  {
    my $filename = shift;
    my $size = shift;
    my $seed = shift;

    srand $seed;

    # Send the RETR command.
    print OUTFD0 "RETR $filename\r\n";
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

    # Check length.
    return 0 unless length ($buffer) == $size;

    # Check content.
    for (my $i = 0; $i < $size; ++$i)
      {
	my $c = chr (int (rand 256));
	return 0 unless $c eq substr $buffer, $i, 1;
      }

    # OK!
    return 1;
  }

__END__
