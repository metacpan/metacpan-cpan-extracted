# K5 (post-0.12, the user, 2026-11-15: "as shell"): at exit, ours waits only while it has something left to do for a
# background job (a command still to start), then exits, leaving the job's running processes alone, as the shells do;
# PROC_SHELLSPAWN_END (or $Proc::ShellSpawn::END_WAIT): shell (the default), all, none, each with :SECONDS.
use strict; use warnings;
use Test::More; use File::Temp 'tempdir'; use Time::HiRes qw(time sleep);
plan skip_all => 'POSIX: sleep and sh as programs' if $^O eq 'MSWin32';
my $d = tempdir(CLEANUP => 1);
# a job of two steps (ours starts the second), and one of one program that goes on after we exit
my $text = "(sleep 0.5; echo two > $d/two) & sh -c 'sleep 1.5; echo late > $d/late' &";
sub run_with {   # (seconds until the program exited, files there then, files there 2.5 s later)
  my $mode = shift; unlink "$d/two", "$d/late";
  local $ENV{PROC_SHELLSPAWN_END} = $mode; delete $ENV{PROC_SHELLSPAWN_END} unless defined $mode;
  my $t0 = time;
  system $^X, (map "-I$_", grep !ref, @INC), '-MProc::ShellSubset::Large', '-MProc::ShellSpawn', '-e',
    'Proc::ShellSpawn::run($ARGV[0])', $text;
  my $took = time - $t0; my $at = join ',', grep -e "$d/$_", qw(two late);
  sleep 2.5 - $took if $took < 2.5;
  ($took, $at, join ',', grep -e "$d/$_", qw(two late)) }
{ my ($t, $at, $later) = run_with(undef);
  ok $t > 0.4 && $t < 1.4, sprintf 'default (shell): waits for the step it has to start (%.1f s)', $t;
  is $at, 'two', 'default: the second step ran, the program still running is left alone';
  is $later, 'two,late', 'default: that program went on after we exited' }
{ my ($t, $at) = run_with('shell');
  ok $t < 1.4 && $at eq 'two', sprintf 'shell, named: the same (%.1f s; %s)', $t, $at }
{ my ($t, $at) = run_with('all');
  ok $t >= 1.4 && $at eq 'two,late', sprintf 'all: waits until every job has ended (%.1f s; %s)', $t, $at }
{ my ($t, $at, $later) = run_with('none');
  ok $t < 0.45, sprintf 'none: exits at once (%.1f s)', $t;
  is $later, 'late', 'none: the step not yet started never starts; the running program goes on' }
{ my ($t, $at, $later) = run_with('shell:0.2');
  ok $t < 0.45 && $later eq 'late', sprintf 'shell:0.2: waits at most 0.2 s (%.1f s; later: %s)', $t, $later }
{ my ($t, $at) = run_with('all:1');
  ok $t >= 0.9 && $t < 1.4 && $at eq 'two', sprintf 'all:1: waits at most 1 s (%.1f s; %s)', $t, $at }
{ local $ENV{PROC_SHELLSPAWN_END} = 'bogus';
  my $out = qx{"$^X" @{[map "-I$_", grep !ref, @INC]} -MProc::ShellSpawn -e1 2>&1};
  like $out, qr/^PROC_SHELLSPAWN_END: 'bogus' is not MODE\[:SECONDS\]/, 'a bad value: refused when the module loads';
  unlike $out, qr/END failed/, '... once' }
done_testing;
