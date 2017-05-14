use strict;
use Test::More tests => 1;
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

# Get version and release numbers.
my $version = join "", ("Net::FTPServer/",
			$Net::FTPServer::VERSION,
			"-",
			$Net::FTPServer::RELEASE);

# Read greeting text and check.
my $greeting = <INFD1>;
print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;

ok ($greeting =~ /^220\s.*FTP server.*$version.*ready\./);

__END__
