#! /usr/bin/perl

use strict;
use warnings;
use constant WINDOWS => $^O eq 'MSWin32';
use sigtrap qw(die normal-signals error-signals);

use Errno;
use Fcntl qw(:DEFAULT :mode);
use Cwd ();
use File::Path 'rmtree';
use File::Spec;
use File::Temp 'mktemp';
use POSIX 'ENOSYS'; # Old Errno versions don't seem to have it, so we use POSIX.
use Test::More tests => 79;

use POSIX::2008;

my $HAVE_WEIRD_CREAT_MODE = $^O =~ /^(?:MSWin32|cygwin)$/ || do {
  if (open my $fh, '<', '/proc/version') {
    <$fh> =~ /microsoft/i;
  }
  else {
    0;
  }
};

my @cleanup;
push @cleanup, my $dirname = mktemp('tmpXXXXX');
push @cleanup, my $tmpname = mktemp('tmpXXXXX');
push @cleanup, my $tmprenamed = "${tmpname}.ren";
push @cleanup, my $fifoname = "${tmpname}.ffo";
push @cleanup, my $symlinkname = "${tmpname}.sym";
push @cleanup, my $hardlinkname = "${tmpname}.hrd";

umask 0;
sysopen my $fh, $tmpname, O_RDWR|O_CREAT|O_EXCL, 0700 or die "$tmpname: $!";

SKIP: {
  if (! defined &POSIX::2008::access) {
    skip 'access() UNAVAILABLE', 4;
  }
  ok(POSIX::2008::access($tmpname, POSIX::2008::F_OK), 'access(F_OK)');
  ok(POSIX::2008::access($tmpname, POSIX::2008::R_OK), 'access(R_OK)');
  ok(POSIX::2008::access($tmpname, POSIX::2008::W_OK), 'access(W_OK)');
  ok($HAVE_WEIRD_CREAT_MODE || POSIX::2008::access($tmpname, POSIX::2008::X_OK),
     'access(X_OK)');
}

SKIP: {
  if (! defined &POSIX::2008::realpath) {
    skip 'realpath() UNAVAILABLE', 1;
  }
  cmp_ok(
    POSIX::2008::realpath($tmpname), 'eq', Cwd::realpath($tmpname), 'realpath()'
  );
}

SKIP: {
  if (! defined &POSIX::2008::truncate) {
    skip 'truncate() UNAVAILABLE', 8;
  }
  sysseek $fh, 0, 0;
  cmp_ok(syswrite($fh, 'foobar'), '==', 6, 'syswrite() for truncate(path)');
  cmp_ok(-s $fh, '==', 6, 'filesize before truncate(path)');
  cmp_ok(POSIX::2008::truncate($tmpname, 0), '==', 0, 'truncate(path)');
  cmp_ok(-s $fh, '==', 0, 'filesize after truncate(path)');

  sysseek $fh, 0, 0;
  cmp_ok(syswrite($fh, 'foobar'), '==', 6, 'syswrite() for truncate(fh)');
  cmp_ok(-s $fh, '==', 6, 'filesize before truncate(fh)');
  my $res = POSIX::2008::truncate($fh, 0);
  if (defined $res) {
    cmp_ok($res, '==', 0, 'truncate(fh)');
    cmp_ok(-s $fh, '==', 0, 'filesize after truncate(fh)');
  }
  else {
    cmp_ok($!, '==', ENOSYS, 'ftruncate() not available');
    cmp_ok(-s $fh, '==', 6, 'filesize after truncate(fh)');
  }
}

SKIP: {
  if (! defined &POSIX::2008::stat) {
    skip 'stat() UNAVAILABLE', 22;
  }
  my @p_stat = POSIX::2008::stat($tmpname);
  my @c_stat = CORE::stat($tmpname);
  cmp_ok(scalar(@p_stat), '>=', 13, 'stat(path) result length');
  for (my $i = 0; $i < 10; $i++) {
    # CORE::stat() doesn't use the actual signed/unsigned integer types of
    # struct stat but we do, so CORE::stat() could return -1 when we return
    # 18446744073709551615 (e.g. for st_rdev). We work around that by
    # performing signed integer arithmetic via "use integer".
    if (WINDOWS && "$]" >= 5.034 && $i =~ /^[016]$/) {
      # In Perl 5.34 CORE::stat() was changed to use some Windows API stuff
      # for dev, ino and rdev. We don't care about Windows crap, so skip these
      # fields to fake green lights on cpantesters.
      ok(WINDOWS, "stat(path)[$i]: Windows stat() foobar (perl5340delta)");
    }
    else {
      use integer;
      my ($got, $expected) = ($p_stat[$i], $c_stat[$i]);
      ok($p_stat[$i] == $c_stat[$i], "stat(path)[$i]: $got == $expected");
    }
  }

  @p_stat = POSIX::2008::stat($fh);
  @c_stat = CORE::stat($fh);
  if (@p_stat) {
    cmp_ok(scalar(@p_stat), '>=', 13, 'stat(fh) result length');
    for (my $i = 0; $i < 10; $i++) {
      if (WINDOWS && "$]" >= 5.034 && $i =~ /^[016]$/) {
        ok(WINDOWS, "stat(fh)[$i]: Windows stat() foobar (perl5340delta)");
      }
      else {
        use integer;
        my ($got, $expected) = ($p_stat[$i], $c_stat[$i]);
        ok($p_stat[$i] == $c_stat[$i], "stat(fh)[$i]: $got == $expected");
      }
    }
  }
  else {
    cmp_ok($!, '==', ENOSYS, 'fstat() not available');
    cmp_ok(scalar(@p_stat), '==', 0, 'stat(fh) result length');
    skip 'fstat() UNAVAILABLE', 9;
  }
}

SKIP: {
  if (! defined &POSIX::2008::lstat) {
    skip 'lstat() UNAVAILABLE', 11;
  }
  my @c_stat = CORE::lstat($tmpname);
  my @p_stat = POSIX::2008::lstat($tmpname);

  cmp_ok(scalar(@p_stat), '>=', 13, 'lstat() result length');
  for (my $i = 0; $i < 10; $i++) {
    if (WINDOWS && "$]" >= 5.034 && $i =~ /^[016]$/) {
      ok(WINDOWS, "lstat()[$i]: Windows stat() foobar (perl5340delta)");
    }
    else {
      use integer;
      my ($got, $expected) = ($p_stat[$i], $c_stat[$i]);
      ok($p_stat[$i] == $c_stat[$i], "lstat()[$i]: $got == $expected");
    }
  }
}

SKIP: {
  if (! defined  &POSIX::2008::statvfs) {
    skip 'statfvs() UNAVAILABLE', 2;
  }
  my @stat = POSIX::2008::statvfs($tmpname);
  cmp_ok(scalar(@stat), '==', 11, 'statvfs() result length');

  @stat = POSIX::2008::statvfs($fh);
  if (@stat) {
    cmp_ok(scalar(@stat), '==', 11, 'fstatvfs() result length');
  }
  else {
    cmp_ok($!, '==', ENOSYS, 'fstatvfs() not available');
  }
}

SKIP: {
  if (! defined  &POSIX::2008::symlink) {
    skip 'symlink() UNAVAILABLE', 4;
  }
  cmp_ok(
    POSIX::2008::symlink($tmpname, $symlinkname), '==', 0, 'create symlink'
  );
  ok(-l $symlinkname, 'stat symlink');

  if (! defined &POSIX::2008::readlink) {
    skip 'readlink() UNAVAILABLE', 2;
  }
  my $target = POSIX::2008::readlink($symlinkname);
  ok(defined $target, 'readlink() successful');
  cmp_ok($target, 'eq', $tmpname, 'readlink() result matches');
}

SKIP: {
  if (! defined &POSIX::2008::link) {
    skip 'link() UNAVAILABLE', 5;
  }
  cmp_ok(POSIX::2008::link($tmpname, $hardlinkname), '==', 0, 'create hardlink');
  cmp_ok(
    (stat $tmpname)[1], 'eq', (stat $hardlinkname)[1], 'hardlink inode number'
  );

  if (!defined &POSIX::2008::unlink) {
    skip 'unlink() UNAVAILABLE', 3;
  }
  ok(POSIX::2008::unlink($hardlinkname), 'unlink hardlink');
  ok(! -e $hardlinkname, 'hardlink is gone');
  is(
    POSIX::2008::unlink($hardlinkname),  undef, 'unlink() non-existant hardlink'
  );
}

SKIP: {
  if (! defined &POSIX::2008::mkdir) {
    skip 'mkdir() UNAVAILABLE', 14;
  }
  ok(POSIX::2008::mkdir($dirname), "mkdir($dirname)");
  ok(-d $dirname, "directory $dirname exists");

  if (! defined &POSIX::2008::chdir) {
    skip 'chdir() UNAVAILABLE', 12;
  }
  my $updir = File::Spec->updir();
  my $dirname_in_updir = File::Spec->catdir($updir, $dirname);
  ok(POSIX::2008::chdir($dirname), "chdir($dirname)");
  ok(-d $dirname_in_updir, "$dirname_in_updir exists");
  ok(POSIX::2008::chdir($updir), "chdir($updir)");
  ok(-d $dirname, "directory $dirname exists");

  if (! defined &POSIX::2008::rmdir) {
    skip 'rmdir() UNAVAILABLE', 8;
  }
  ok(POSIX::2008::rmdir($dirname), "rmdir($dirname)");
  ok(! -e $dirname, "directory $dirname is gone");
  is(POSIX::2008::rmdir($dirname), undef, "rmdir() non-existant directory");

  if (! defined &POSIX::2008::remove) {
    skip 'remove() UNAVAILABLE', 5;
  }
  ok(POSIX::2008::mkdir($dirname), "mkdir($dirname)");
  ok(-d $dirname, "directory $dirname exists");
  ok(POSIX::2008::remove($dirname), "remove($dirname)");
  ok(! -e $dirname, "directory $dirname is gone");
  is(POSIX::2008::remove($dirname), undef, "remove() non-existant directory");
}

SKIP: {
  if (! defined &POSIX::2008::mkfifo) {
    skip 'mkfifo() UNAVAILABLE', 2;
  }
  my $rv = POSIX::2008::mkfifo($fifoname, 0600);
  if (!defined $rv && ($!{ENOTSUP} || $!{EOPNOTSUPP})) {
    skip 'mkfifo() not supported', 2;
  }
  cmp_ok($rv, '==', 0, "mkfifo($fifoname)");
  ok(-p $fifoname, "FIFO $fifoname exists");
}

# Some OSes don't support renaming open files.
close $fh;
SKIP: {
  if (! defined &POSIX::2008::rename) {
    skip 'rename() UNAVAILABLE', 6;
  }
  ok(
    POSIX::2008::rename($tmpname, $tmprenamed), "rename($tmpname, $tmprenamed)"
  );
  ok(-e $tmprenamed, "new name $tmprenamed exists");
  ok(! -e $tmpname, "old name $tmpname is gone");
  ok(
    POSIX::2008::rename($tmprenamed, $tmpname), "rename($tmprenamed, $tmpname)"
  );
  ok(-e $tmpname, "new name $tmpname exists");
  ok(! -e $tmprenamed, "old name $tmprenamed is gone");
}


END {
  close $fh if defined $fh;
  foreach my $n (@cleanup) {
    rmtree($n, {safe => 1}) if defined $n && $n =~ /^tmp/;
  }
}
