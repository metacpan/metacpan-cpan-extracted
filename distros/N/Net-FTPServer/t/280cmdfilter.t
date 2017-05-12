#!/usr/bin/perl -w

# $Id: 280cmdfilter.t,v 1.1 2003/09/28 11:50:45 rwmj Exp $

use strict;
use Test;
use POSIX qw(dup2);
use IO::Handle;
use FileHandle;

BEGIN {
  plan tests => 14;
}

use Net::FTPServer::InMem::Server;

pipe INFD0, OUTFD0 or die "pipe: $!";
pipe INFD1, OUTFD1 or die "pipe: $!";
my $pid = fork ();
die unless defined $pid;
unless ($pid) {			# Child process (the server).
  my $config = ".280cmdfilter.t.$$";
  open CF, ">$config" or die "$config: $!";
  print CF <<'EOT';
command filter: ^[A-Za-z0-9\s]+$
restrict command: "SITE VERSION" $self->{authenticated}
EOT
  close CF;

  POSIX::dup2 (fileno INFD0, 0);
  POSIX::dup2 (fileno OUTFD1, 1);
  close INFD0;
  close OUTFD0;
  close INFD1;
  close OUTFD1;
  my $ftps = Net::FTPServer::InMem::Server->run
    (['--test', '-d', '-C', $config ]);

  unlink $config;

  exit;
}

# Parent process (the test script).
close INFD0;
close OUTFD1;
OUTFD0->autoflush (1);

# Try several variations of the SITE VERSION command. They should all fail
# since we are logged out.

$_ = <INFD1>;
print OUTFD0 "SITE VERSION\r\n";
$_ = <INFD1>;
ok (/^500/);

print OUTFD0 "SITE VERSION \r\n";
$_ = <INFD1>;
ok (/^500/);

print OUTFD0 "SITE VERSION me\r\n";
$_ = <INFD1>;
ok (/^500/);

print OUTFD0 "SITE version\r\n";
$_ = <INFD1>;
ok (/^500/);

print OUTFD0 "site VERSION\r\n";
$_ = <INFD1>;
ok (/^500/);

print OUTFD0 "site version\r\n";
$_ = <INFD1>;
ok (/^500/);

print OUTFD0 "site version me\r\n";
$_ = <INFD1>;
ok (/^500/);

# Log in.

print OUTFD0 "USER rich\r\n";
$_ = <INFD1>;
ok (/^331/);

print OUTFD0 "PASS 123456\r\n";
$_ = <INFD1>;
ok (/^230 Welcome rich\./);

# Now the SITE VERSION command (and variations) should work.

print OUTFD0 "SITE VERSION\r\n";
$_ = <INFD1>;
ok (/^200/);

print OUTFD0 "SITE VERSION \r\n";
$_ = <INFD1>;
ok (/^200/);

print OUTFD0 "site version and some more arguments\r\n";
$_ = <INFD1>;
ok (/^200/);

# However the following variations should fail on the command filter
# which only allows a-z, 0-9 and spaces.

print OUTFD0 "site version !\r\n";
$_ = <INFD1>;
ok (/^500/);

print OUTFD0 "site version ##\r\n";
$_ = <INFD1>;
ok (/^500/);

print OUTFD0 "QUIT\r\n";
$_ = <INFD1>;
