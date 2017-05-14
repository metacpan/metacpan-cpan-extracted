use strict;
use Test::More tests => 2;
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
    (['--test', '-d', '-C', '/dev/null',
      '-o', 'allow anonymous=1',
      '-o', 'anonymous password check=rfc822',
      '-o', 'anonymous password enforce=1']);
  exit;
}

# Parent process (the test script).
close INFD0;
close OUTFD1;
OUTFD0->autoflush (1);

$_ = <INFD1>;

print OUTFD0 "USER ftp\r\n";
$_ = <INFD1>;
ok (/^331/);

print OUTFD0 "PASS nobody\@nowhere\r\n";
$_ = <INFD1>;
ok (/^530/);

__END__
