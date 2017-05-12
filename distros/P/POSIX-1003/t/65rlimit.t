#!/usr/bin/env perl
use lib 'lib', 'blib/lib', 'blib/arch';
use warnings;
use strict;

use Test::More tests => 17;

use POSIX::1003::Limit qw(:rlimit);

my ($soft, $hard) = getrlimit('RLIMIT_CORE');
ok(defined $soft, "RLIMIT_CORE via function = ($soft, $hard)");

my $soft2 = RLIMIT_CORE;
ok(defined $soft2, "RLIMIT_CORE directly = $soft2");
cmp_ok($soft, 'eq', $soft2);

my $key = $rlimit{RLIMIT_CORE};
ok(defined $key, "key RLIMIT_CORE = $key");

my ($soft3, $hard3);
eval { ($soft3, $hard3) = getrlimit($key) };
like($@, qr/^pass the constant name as string/);
ok(!defined $soft3);
ok(!defined $hard3);

my ($soft4, $hard4);
eval { ($soft4, $hard4) = getrlimit(RLIMIT_CORE) };
like($@, qr/^pass the constant name as string/);
ok(!defined $soft4);
ok(!defined $hard4);

SKIP: {
  # HP-UX
  defined RLIM_SAVED_MAX
      or skip 'RLIM_* not supported', 3;

ok(defined RLIM_SAVED_MAX, sprintf "RLIM_SAVED_MAX=0x%x",RLIM_SAVED_MAX);
ok(defined RLIM_SAVED_CUR, sprintf "RLIM_SAVED_CUR=0x%x",RLIM_SAVED_CUR);
ok(defined RLIM_INFINITY,  sprintf "RLIM_INFINITY =0x%x",RLIM_INFINITY);
}

use POSIX::1003::Limit qw(setrlimit);

my $smaller = 12349895;
my $ok5 = setrlimit('RLIMIT_CORE', $smaller);
SKIP: {
    $ok5 or skip "rlimit_core does not work, no permission? $ok5", 2;
    ok($ok5, "smaller core size $ok5");
    cmp_ok(RLIMIT_CORE, '==', $smaller);
}

use POSIX::1003::Limit qw(rlimit_names);

my @names = rlimit_names;
cmp_ok(scalar @names, '>=', 2, @names." names");

my $undefd = 0;
foreach my $name (sort @names)
{   my ($soft, $hard, $succ) = getrlimit($name);
    $soft //= 'undef';
    $hard //= 'undef';
    printf "  %4d %-20s %2s %-25u %u\n", $rlimit{$name}, $name
       , ($succ ? 'OK' : 'F '), $soft, $hard;
    defined $soft or $undefd++;
}
ok(1, "$undefd RLIMIT_ constants return undef");
