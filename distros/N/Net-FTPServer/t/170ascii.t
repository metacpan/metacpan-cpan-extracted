use strict;
use Test::More tests => 18;
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

# Use ASCII mode.
print OUTFD0 "TYPE A\r\n";
$_ = <INFD1>;
ok (/^200/);

# Enter passive mode and get a port number.
print OUTFD0 "PASV\r\n";
$_ = <INFD1>;
ok (/^227 Entering Passive Mode \(127,0,0,1,(.*),(.*)\)/);

my $port = $1 * 256 + $2;

# Upload files.
ok (upload_ascii ("test0", 0, 1000));
ok (upload_ascii ("test1", 1, 1001));
ok (upload_ascii ("test2", 10, 1002));
ok (upload_ascii ("test3", 100, 1003));
ok (upload_ascii ("test4", 1000, 1004));
ok (upload_ascii ("test5", 1500, 1005));
ok (upload_ascii ("test6", 2000, 1006));

# Download and compare files.
ok (download_and_check ("test0", 0, 1000));
ok (download_and_check ("test1", 1, 1001));
ok (download_and_check ("test2", 10, 1002));
ok (download_and_check ("test3", 100, 1003));
ok (download_and_check ("test4", 1000, 1004));
ok (download_and_check ("test5", 1500, 1005));
ok (download_and_check ("test6", 2000, 1006));

print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;

exit;

# This function uploads so many lines of random ASCII text.

sub upload_ascii
  {
    my $filename = shift;
    my $nr_lines = shift;
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
    my @lines = ();
    for (my $i = 0; $i < $nr_lines; ++$i)
      {
	my $buffer = "";

	for (my $j = 0; $j < 50; ++$j)
	  {
	    my $c = chr (32 + int (rand 95));
	    $buffer .= $c;
	  }

	$buffer .= "\r\n";
	push @lines, $buffer;
      }

    # Write to socket.
    foreach (@lines) {
      $sock->print ($_);
    }
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
    my $nr_lines = shift;
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
    my @lines = ();
    for (my $i = 0; $i < $nr_lines; ++$i)
      {
	push @lines, $sock->getline;
      }
    $sock->close;

    # Check return code.
    $_ = <INFD1>;
    return 0 unless /^226/;

    # Check number of lines read.
    return 0 unless @lines == $nr_lines;

    # Check content.
    foreach (@lines)
      {
	my $buffer = "";

	for (my $j = 0; $j < 50; ++$j)
	  {
	    my $c = chr (32 + int (rand 95));
	    $buffer .= $c;
	  }

	$buffer .= "\r\n";

	return 0 unless $buffer eq $_;
      }

    # OK!
    return 1;
  }

__END__
