use strict;
use Test::More tests => 45;
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
ok (/^230/);

# Create, move around and delete directories.
print OUTFD0 "MKD dir1\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "MKD dir2\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "CWD dir1\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "PWD\r\n";
$_ = <INFD1>;
ok (/^257 \"\/dir1\"/);

print OUTFD0 "MKD sub1\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "MKD sub2\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "CWD sub1\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "PWD\r\n";
$_ = <INFD1>;
ok (/^257 \"\/dir1\/sub1\"/);

print OUTFD0 "CDUP\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "PWD\r\n";
$_ = <INFD1>;
ok (/^257 \"\/dir1\"/);

print OUTFD0 "CDUP\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "PWD\r\n";
$_ = <INFD1>;
ok (/^257 \"\/\"/);

print OUTFD0 "RMD dir1\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "CWD dir1\r\n";
$_ = <INFD1>;
ok (/^550/);

print OUTFD0 "CWD dir2\r\n";
$_ = <INFD1>;
ok (/^250/);

print OUTFD0 "PWD\r\n";
$_ = <INFD1>;
ok (/^257 \"\/dir2\"/);

# TYPE, STRU, MODE commands.
print OUTFD0 "TYPE A\r\n";
$_ = <INFD1>;
ok (/^200/);

print OUTFD0 "TYPE I\r\n";
$_ = <INFD1>;
ok (/^200/);

print OUTFD0 "TYPE A N\r\n";
$_ = <INFD1>;
ok (/^200/);

print OUTFD0 "TYPE I N\r\n";
$_ = <INFD1>;
ok (/^200/);

print OUTFD0 "TYPE L 8\r\n";
$_ = <INFD1>;
ok (/^200/);

print OUTFD0 "STRU F\r\n";
$_ = <INFD1>;
ok (/^200/);

print OUTFD0 "MODE S\r\n";
$_ = <INFD1>;
ok (/^200/);

# SYST and other status commands.
print OUTFD0 "SYST\r\n";
$_ = <INFD1>;
ok (/^215 UNIX Type: L8/);

print OUTFD0 "STAT\r\n";
for (;;) {
  $_ = <INFD1>;
  die unless /^211/;
  last if /^211 /;
}
ok (1);

print OUTFD0 "STAT .\r\n";
for (;;) {
  $_ = <INFD1>;
  die unless /^213/;
  last if /^213 /;
}
ok (1);

print OUTFD0 "STAT nothere\r\n";
$_ = <INFD1>;
ok (/^550/);

print OUTFD0 "CLNT 123\r\n";
$_ = <INFD1>;
ok (/^200/);

print OUTFD0 "HELP\r\n";
for (;;) {
  $_ = <INFD1>;
  die unless /^214/;
  last if /^214 /;
}
ok (1);

print OUTFD0 "HELP SITE\r\n";
for (;;) {
  $_ = <INFD1>;
  die unless /^214/;
  last if /^214 /;
}
ok (1);

print OUTFD0 "NOOP\r\n";
$_ = <INFD1>;
ok (/^200/);

# Obsolete mail commands.
print OUTFD0 "MLFL\r\n";
$_ = <INFD1>;
ok (/^502/);

print OUTFD0 "MAIL\r\n";
$_ = <INFD1>;
ok (/^502/);

print OUTFD0 "MSND\r\n";
$_ = <INFD1>;
ok (/^502/);

print OUTFD0 "MSOM\r\n";
$_ = <INFD1>;
ok (/^502/);

print OUTFD0 "MSAM\r\n";
$_ = <INFD1>;
ok (/^502/);

print OUTFD0 "MRSQ\r\n";
$_ = <INFD1>;
ok (/^502/);

print OUTFD0 "MRCP\r\n";
$_ = <INFD1>;
ok (/^502/);

# LANG command.
my $LANG = $ENV{LANGUAGE} || "en";
print OUTFD0 "LANG\r\n";
$_ = <INFD1>;
ok (/^200 .*\Q$LANG\E\./);

print OUTFD0 "LANG fr\r\n";
$_ = <INFD1>;
ok (/^200 .*fr\./);

print OUTFD0 "LANG\r\n";
$_ = <INFD1>;
ok (/^200 .*fr\./);

# ALLO command.
print OUTFD0 "ALLO\r\n";
$_ = <INFD1>;
ok (/^200/);

# QUIT command (must be last of course!).
print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;
ok (/^221/);

__END__
