# -*- perl -*-

use Test::More tests => 8;
use warnings;
use strict;
use Log::Log4perl;
use POSIX qw(:errno_h);

Log::Log4perl::init("t/log4perl.conf");

BEGIN {
  use_ok("Test::AutoBuild::Lock") or die;
}

my $lockfile = "test.autobuild.mutex";

END { unlink $lockfile }

unlink $lockfile;

TEST_FILE: {
  my $lock = Test::AutoBuild::Lock->new(file => $lockfile,
					method => "file");
  isa_ok($lock, "Test::AutoBuild::Lock");

  ok($lock->lock(), "obtain file lock");

  $lock->unlock();

  ok(!-f $lockfile, "released file lock");
}

TEST_FCNTL: {
  my $lock = Test::AutoBuild::Lock->new(file => $lockfile,
					method => "fcntl");
  isa_ok($lock, "Test::AutoBuild::Lock");

  ok($lock->lock(), "obtain fcntl lock");

  $lock->unlock();
}


TEST_FLOCK: {
  my $lock = Test::AutoBuild::Lock->new(file => $lockfile,
					method => "flock");
  isa_ok($lock, "Test::AutoBuild::Lock");

  my $locked = $lock->lock();
  SKIP: {
    if (!$locked && $! == ENOLCK) {
      skip "locks not available", 1;
    }
    ok($locked, "obtain flock lock");
    $lock->unlock();
  }
}
