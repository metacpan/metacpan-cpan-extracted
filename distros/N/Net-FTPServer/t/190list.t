use strict;
use Test::More tests => 82;
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

# Enter passive mode and get a port number.
print OUTFD0 "PASV\r\n";
$_ = <INFD1>;
ok (/^227 Entering Passive Mode \(127,0,0,1,(.*),(.*)\)/);

my $port = $1 * 256 + $2;

# Upload some files.
ok (upload ("test1", "Oh I can see them now"));
ok (upload ("test2", "Clutching a hankerchief"));
ok (upload ("test3", "And blowing me a kiss"));
ok (upload ("test4", "Discreetly asking how"));
ok (upload ("test5", "How came he died so young"));
ok (upload ("test6", "Or was he very old"));

# Create some subdirectories.
print OUTFD0 "MKD sub1\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "MKD sub2\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "MKD sub3\r\n";
$_ = <INFD1>;
ok (/^250/);

# LIST the files.
print OUTFD0 "LIST\r\n";
$_ = <INFD1>;
ok (/^150/);

my $sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

# Read the synthetic lines first.
$_ = $sock->getline;
ok ($_ && /^total/);
$_ = $sock->getline;
ok ($_ && / \.\r\n$/);
$_ = $sock->getline;
ok ($_ && / \.\.\r\n$/);

# Read the files -- they aren't necessarily in alphabetical order (but
# ought they to be?) [XXX]
my @filenames = ();
for (my $i = 0; $i < 9; ++$i)
  {
    $_ = $sock->getline;
    ok ($_ && / ((test|sub)[1-9])\r\n$/);
    push @filenames, $1;
  }

$_ = $sock->getline;
ok (!$_);

@filenames = sort @filenames;
ok (join (" ", @filenames) eq
    "sub1 sub2 sub3 test1 test2 test3 test4 test5 test6");

# Check return code.
$_ = <INFD1>;
ok (/^226/);

# LIST * the files.
print OUTFD0 "LIST *\r\n";
$_ = <INFD1>;
ok (/^150/);

$sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

# Read the files -- they aren't necessarily in alphabetical order (but
# ought they to be?) [XXX]
@filenames = ();
for (my $i = 0; $i < 9; ++$i)
  {
    $_ = $sock->getline;
    ok ($_ && / ((test|sub)[1-9])\r\n$/);
    push @filenames, $1;
  }

$_ = $sock->getline;
ok (!$_);

@filenames = sort @filenames;
ok (join (" ", @filenames) eq
    "sub1 sub2 sub3 test1 test2 test3 test4 test5 test6");

# Check return code.
$_ = <INFD1>;
ok (/^226/);

# LIST s* the files.
print OUTFD0 "LIST s*\r\n";
$_ = <INFD1>;
ok (/^150/);

$sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

# Read the files -- they aren't necessarily in alphabetical order (but
# ought they to be?) [XXX]
@filenames = ();
for (my $i = 0; $i < 3; ++$i)
  {
    $_ = $sock->getline;
    ok ($_ && / (sub[1-9])\r\n$/);
    push @filenames, $1;
  }

$_ = $sock->getline;
ok (!$_);

@filenames = sort @filenames;
ok (join (" ", @filenames) eq
    "sub1 sub2 sub3");

# Check return code.
$_ = <INFD1>;
ok (/^226/);

# NLST the files.
print OUTFD0 "NLST\r\n";
$_ = <INFD1>;
ok (/^150/);

$sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

# Read the files -- they aren't necessarily in alphabetical order (but
# ought they to be?) [XXX]
@filenames = ();
for (my $i = 0; $i < 9; ++$i)
  {
    $_ = $sock->getline;
    ok ($_ && /^((test|sub)[1-9])\r\n$/);
    push @filenames, $1;
  }

$_ = $sock->getline;
ok (!$_);

@filenames = sort @filenames;
ok (join (" ", @filenames) eq
    "sub1 sub2 sub3 test1 test2 test3 test4 test5 test6");

# Check return code.
$_ = <INFD1>;
ok (/^226/);

# NLST * the files.
print OUTFD0 "NLST *\r\n";
$_ = <INFD1>;
ok (/^150/);

$sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

# Read the files -- they aren't necessarily in alphabetical order (but
# ought they to be?) [XXX]
@filenames = ();
for (my $i = 0; $i < 9; ++$i)
  {
    $_ = $sock->getline;
    ok ($_ && /^((test|sub)[1-9])\r\n$/);
    push @filenames, $1;
  }

@filenames = sort @filenames;
ok (join (" ", @filenames) eq
    "sub1 sub2 sub3 test1 test2 test3 test4 test5 test6");

# Check return code.
$_ = <INFD1>;
ok (/^226/);

# NLST t* the files.
print OUTFD0 "NLST t*\r\n";
$_ = <INFD1>;
ok (/^150/);

$sock = new IO::Socket::INET
  (PeerAddr => "127.0.0.1:$port",
   Proto => "tcp")
  or die "socket: $!";

# Read the files -- they aren't necessarily in alphabetical order (but
# ought they to be?) [XXX]
@filenames = ();
for (my $i = 0; $i < 6; ++$i)
  {
    $_ = $sock->getline;
    ok ($_ && /^(test[1-9])\r\n$/);
    push @filenames, $1;
  }

@filenames = sort @filenames;
ok (join (" ", @filenames) eq
    "test1 test2 test3 test4 test5 test6");

# Check return code.
$_ = <INFD1>;
ok (/^226/);

print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;

sub upload
  {
    my $filename = shift;
    my $content = join "", @_;

    print OUTFD0 "STOR $filename\r\n";
    $_ = <INFD1>;
    return 0 unless /^150/;

    # Connect to passive mode port.
    my $sock = new IO::Socket::INET
      (PeerAddr => "127.0.0.1:$port",
       Proto => "tcp")
	or die "socket: $!";

    # Store some data.
    $sock->print ($content);
    $sock->close;

    # Check return code.
    $_ = <INFD1>;
    return /^226/;
  }

__END__
