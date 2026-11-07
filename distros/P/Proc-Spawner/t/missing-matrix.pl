#!/usr/bin/perl
# missing-matrix.pl (post-0.06): the whole test suite "as if" the spawn primitive lacked settings, one entry of the
# bitmap $Proc::Spawner::MISSING at a time (PROC_SPAWNER_MISSING), then the Windows profile and everything at once.
# Proc::Spawner does a missing setting around the call where it can, and reports the rest as unsupported; the tests
# skip what is unsupported.  Not run by make test (about a minute per entry).
# Usage, after make:  perl t/missing-matrix.pl [ENTRY ...]      (an ENTRY: names separated by commas; default: all)
use strict; use warnings; use FindBin; use lib map "$FindBin::Bin/../$_", 'blib/lib', 'blib/arch';
use Proc::Spawner;
my @single = @Proc::Spawner::FEATURES;
my @emulable = grep $Proc::Spawner::EMULABLE{$_}, @single;
my %profile = (
  'all emulable' => [@emulable],
  'Windows (doc/pspawn-spawner.md, section 8: not done by CreateProcessW)' => [qw(sigmask pgroup setsid tcsetpgrp sched cgroup)],
  'everything' => [@single]);
my @entries = @ARGV ? map([split /,/], @ARGV) : ((map [$_], @single), map $profile{$_}, sort keys %profile);
chdir "$FindBin::Bin/.." or die;
my ($bad, @report) = 0;
for my $e (@entries) {
  local $ENV{PROC_SPAWNER_MISSING} = join ' ', @$e;
  my $out = qx{prove -b t/ 2>&1};
  my ($res) = $out =~ /^Result: (\w+)/m; my ($n) = $out =~ /Tests=(\d+)/; my @skip = $out =~ /^(t\/\S+ \.+ skipped: .*)$/mg;
  my $skips = () = $out =~ /\bskipped?\b/g;
  $res //= 'NO RESULT'; $bad++ if $res ne 'PASS';
  push @report, sprintf "%-6s %3s tests  missing: %s", $res, $n // '?', "@$e";
  print $report[-1], "\n"; print $out if $res ne 'PASS' }
print "\n", scalar(@entries) - $bad, " of ", scalar @entries, " entries pass\n";
exit !!$bad;
