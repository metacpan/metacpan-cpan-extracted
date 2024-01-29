#! /usr/bin/perl

use strict;
use warnings;
use sigtrap qw(die normal-signals error-signals);

use Config;
use Errno;
use Fcntl qw(:DEFAULT);
use File::Temp 'mktemp';
use Test::More tests => 8;

use POSIX::2008;

my $perlpath = $Config{perlpath};
if ($^O ne 'VMS' && $perlpath !~ m/$Config{_exe}$/i) {
  $perlpath .= $Config{_exe};
}

my $rv;
my $tmpf = mktemp('X'x20);
my $envp = {_ec_ => 37};
my $argv = ['perl', '-e', 'exit($ENV{_ec_})'];

SKIP: {
  if (! defined &POSIX::2008::execveat) {
    skip 'execveat() UNAVAILABLE', 4;
  }

  $rv = eval {
    POSIX::2008::execveat(POSIX::2008::AT_FDCWD, $tmpf, 'foo', {});
  };
  # Note: The /i is needed because some Perls say "ARRAY", others say "array".
  ok(!$rv && $@ =~ /not an ARRAY/i, 'execveat fails due to non-arrayref');

  $rv = eval {
    POSIX::2008::execveat(POSIX::2008::AT_FDCWD, $tmpf, [$tmpf], 'foo');
  };
  ok(!$rv && $@ =~ /not a HASH/, 'execveat fails due to non-hashref');

  $rv = POSIX::2008::execveat(POSIX::2008::AT_FDCWD, $tmpf, [$tmpf], {});
  ok(!$rv && $!{ENOENT}, "execveat fails with ENOENT for $tmpf");

  my $pid = fork();
  if ($pid) {
    wait();
    cmp_ok($?>>8, '==', 37, 'execveat() returned 37');
  }
  elsif (defined $pid) {
    POSIX::2008::execveat(POSIX::2008::AT_FDCWD, $perlpath, $argv, $envp);
    diag("execveat() failed for $perlpath: $!");
    exit(1);
  }
  else {
    die "Could not fork: $!";
  }
}

SKIP: {
  my $omode =
    defined &POSIX::2008::O_EXEC ? &POSIX::2008::O_EXEC :
    defined &POSIX::2008::O_PATH ? &POSIX::2008::O_PATH :
    O_RDONLY;

  if (! defined &POSIX::2008::fexecve) {
    skip 'fexecve() UNAVAILABLE', 4;
  }
  if (! sysopen my $fh, $perlpath, $omode) {
    diag("sysopen($perlpath, $omode) failed: $! (skipping fexecve() test)");
    skip 'fexecve() not testable', 4;
  }

  $rv = eval {
    POSIX::2008::fexecve(1337, 'foo', {});
  };
  ok(!$rv && $@ =~ /not an ARRAY/i, 'fexecve fails due to non-arrayref');

  $rv = eval {
    POSIX::2008::fexecve(1337, [], 'foo');
  };
  ok(!$rv && $@ =~ /not a HASH/, 'fexecve fails due to non-hashref');

  $rv = POSIX::2008::fexecve(1337, [], {});
  # ENOENT occurs when fexecve() uses execveat() with a /proc filesystem path.
  ok(!$rv && ($!{ENOENT} || $!{EBADF} || $!{EINVAL}), 'fexecve fails with invalid fd');

  my $pid = fork();
  if ($pid) {
    wait();
    cmp_ok($?>>8, '==', 37, 'fexecve() returned 37');
  }
  elsif (defined $pid) {
    my $omode =
      defined &POSIX::2008::O_EXEC ? &POSIX::2008::O_EXEC :
      defined &POSIX::2008::O_PATH ? &POSIX::2008::O_PATH :
      O_RDONLY;
    if (! sysopen my $fh, $perlpath, $omode) {
      diag("sysopen($perlpath, $omode) failed: $!");
    }
    else {
      POSIX::2008::fexecve($fh, $argv, $envp);
      diag("fexecve() failed: $!");
    }
    exit(1);
  }
  else {
    die "Could not fork: $!";
  }
}
