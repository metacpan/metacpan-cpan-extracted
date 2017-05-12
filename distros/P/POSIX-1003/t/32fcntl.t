#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More;

use POSIX::1003::FdIO  qw/openfd closefd O_WRONLY O_CREAT O_ACCMODE/;
use POSIX::1003::Fcntl;

plan tests => 7;

#
# F_DUPFD
#

my $testfile = 'lock-test';
my $fd = openfd $testfile, O_WRONLY|O_CREAT;

ok(defined $fd, "opened $testfile as $fd");

my $fd2 = fcntl_dup $fd;
ok(defined $fd2, "fd $fd dupped into $fd2");
cmp_ok($fd2, '!=', $fd, "new descriptor differs");

ok(closefd $fd2, "close new descriptor");

#
# F_GETFL
#

my $flags = getfd_flags($fd);
cmp_ok($flags&O_ACCMODE , '==', O_WRONLY, "F_GETFL received $flags");

#
# F_SETLK
#

use Data::Dumper;

unless(fork)
{   # Child
    my $hc = setfd_lock $fd, type => F_WRLCK, start => 100, len => 500;
    #warn "Locked = ", Dumper $hc;

    sleep 2;
    my $hu = setfd_lock $fd, type => F_WRLCK
               , start => 100, len => 500, type => F_UNLCK;
    #warn "Unlocked =", Dumper $hu;
    closefd $fd;

    exit 1;
}

# parent
sleep 1;
my $hp = getfd_islocked $fd, type => F_WRLCK, start => 50, len => 300;
ok(defined $hp, "locked by pid=$hp->{pid}");
#warn "Still locked = ", Dumper $hp;

sleep 2;
my $hq = getfd_islocked $fd, type => F_WRLCK, start => 50, len => 300;
ok(!defined $hq, "lock was released");
