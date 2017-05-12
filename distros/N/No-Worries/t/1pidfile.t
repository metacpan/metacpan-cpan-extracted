#!perl

use strict;
use warnings;
use Test::More tests => 14;
use File::Temp qw(tempdir);
use No::Worries::File qw(file_read);

use No::Worries::PidFile qw(*);

our($tmpdir, $pidfile, $pid, $tmp);

$tmpdir = tempdir(CLEANUP => 1);
$pidfile = "$tmpdir/pidfile";
$pid = $$;

ok(! -e $pidfile, "clean start");

# pf_check() and pf_touch() cannot be called on non-existing file
eval  { pf_check($pidfile) };
ok($@, "pf_check() on non-existing file");
eval  { pf_touch($pidfile) };
ok($@, "pf_touch() on non-existing file");

# pf_status(), pf_quit() and pf_unset() can be called on non-existing file
eval      { pf_status($pidfile) };
is($@, "", "pf_status() on non-existing file");
eval      { pf_quit($pidfile, callback => sub {}) };
is($@, "", "pf_quit() on non-existing file");
eval      { pf_unset($pidfile) };
is($@, "", "pf_unset() on non-existing file");

pf_set($pidfile);
ok(-e $pidfile, "pid_set() file");
is(file_read($pidfile), "$pid\n", "pid_set() contents");

$tmp = pf_status($pidfile);
ok($tmp, "pid_status() running");

# pf_set() cannot be called on existing file
eval { pf_set($pidfile) };
ok($@, "pf_set() on existing file");

# pf_check(), pf_touch() and pf_unset() can be called on existing file
eval      { pf_check($pidfile) };
is($@, "", "pf_check() on existing file");
eval      { pf_touch($pidfile) };
is($@, "", "pf_touch() on existing file");
eval      { pf_unset($pidfile) };
is($@, "", "pf_unset() on existing file");

ok(! -e $pidfile, "clean stop");
