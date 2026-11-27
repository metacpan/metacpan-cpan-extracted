#!/usr/bin/perl
# missing-matrix.pl (post-0.06; the same on every platform since post-0.12, the user, 2026-11-14): the tests "as if"
# the spawn primitive lacked settings (PROC_SPAWNER_MISSING): each setting it does natively here, one at a time; then
# all emulable settings missing, the Windows column's gaps, no posix_spawn at all (fork and exec, M2; where there is no
# fork, as on Windows, Perl's own spawn through Run: system1) and everything at once.
# A setting the primitive does not do natively here is missing already: its entry would be the same run as the
# tests as built, and is skipped (said so); so is an entry that makes missing the same settings as one before it (on
# Windows the Windows column, and "everything" where every native setting is emulable).  An entry that needs Run (Run
# 0.07 or later, found in @INC: on Windows copied into blib/lib) is skipped, and said so, where Run is not there.
# Proc::Spawner does a missing setting around the call where it can, and reports the rest as unsupported; the tests
# skip what is unsupported.  Not run by make test (about a minute per entry on Linux).  The long version of
# t/flavors.pl, which takes the spawn primitive's approaches.
# Usage, after make:  perl t/missing-matrix.pl [-n] [-o FILE] [ENTRY ...] [-- TEST FILE ...]
#   ENTRY: names separated by commas, run as given (default: all, as above); TEST FILE: default t/ (under Wine, the
#   Windows files, see CLAUDE.md of the repository: run from cmd /c with Windows' own standard handles); -n: list the
#   entries, run none; -o: a record of what did not pass (a header, and nothing more when every entry passed;
#   doc/test-results/).
use strict; use warnings; use FindBin; use lib map "$FindBin::Bin/../$_", 'blib/lib', 'blib/arch';
use Proc::Spawner;
chdir "$FindBin::Bin/.." or die;
my ($LIST, $OUTF) = (0, undef);
while (@ARGV && $ARGV[0] =~ /^-[no]\z/) { my $o = shift; $o eq '-n' ? ($LIST = 1) : ($OUTF = shift) }
our @ARGV_SAVED = @ARGV;   # (for the record: without -o FILE)
my (@skipped, @fails);
my (@asked, @files); while (@ARGV) { my $a = shift; if ($a eq '--') { @files = @ARGV; last } push @asked, $a }
@files = ('t/') unless @files;
my @single = @Proc::Spawner::FEATURES;
my %native = %Proc::Spawner::NATIVE;
my @emulable = grep $Proc::Spawner::EMULABLE{$_}, @single;
my $has_run = eval { local $SIG{__DIE__}; require Run; Run->VERSION('0.07'); 1 };
sub primitive {   # the primitive Proc::Spawner takes with these settings missing (asked in a child, through a file: no
  local $ENV{PROC_SPAWNER_MISSING} = join ' ', @_;   # shell, and no double quote in an argument, which Perl's own
  require File::Temp; my ($fh, $tmp) = File::Temp::tempfile(); close $fh;   # spawn on Windows passes wrongly)
  system $^X, '-Iblib/lib', '-Iblib/arch', '-MProc::Spawner', '-e',
    'open my $o, q{>}, $ARGV[0] or die; print $o $Proc::Spawner::PRIMITIVE', $tmp;
  open my $in, '<', $tmp or die "$tmp: $!"; my $p = <$in> // '?'; close $in; unlink $tmp; $p }
my @profiles = (
  ['all emulable', [@emulable]],
  ['Windows (doc/pspawn-spawner.md, section 8: not done by CreateProcessW)', [qw(sigmask pgroup setsid tcsetpgrp sched cgroup rlimit sigignore nice)]],
  ['no posix_spawn (M2: fork and exec, or system1 where there is no fork)', ['posix_spawn']],
  ['everything', [@single]]);
my @entries;   # [name, settings missing]
if (@asked) { @entries = map [$_, [split /,/]], @asked }
else {
  my @not = grep !$native{$_}, @single;
  if (@not) { push @skipped, "@not (missing already)"; print "skipped: @not (not done natively here: missing already)\n" }
  my %seen;   # the native settings an entry makes missing => the entry before that did
  for my $e ((map ["$_", [$_]], grep $native{$_}, @single), @profiles) {
    my $key = join ' ', sort grep $native{$_}, @{$e->[1]};
    if (!length $key) { push @skipped, "$e->[0] (as built)"; print "skipped: $e->[0] (the same as the tests as built: nothing in it is done natively here)\n"; next }
    if ($seen{$key}) { push @skipped, "$e->[0] (as $seen{$key})"; print "skipped: $e->[0] (the same as $seen{$key}: it makes missing the same settings)\n"; next }
    $seen{$key} = $e->[0]; push @entries, $e } }
my ($bad, $ran) = (0, 0);
for my $e (@entries) {
  my ($name, $missing) = @$e;
  my $p = primitive(@$missing);
  if ($p eq 'system1' && !$has_run) { push @skipped, "$name (no Run)"; print "skipped: $name (system1: needs Run 0.07, not found)\n"; next }
  my $label = $name eq "@$missing" ? "missing: $name" : "$name; missing: @$missing";
  $label .= " (primitive: $p)" if $p ne $Proc::Spawner::PRIMITIVE;
  if ($LIST) { print "entry: $label\n"; next }
  local $ENV{PROC_SPAWNER_MISSING} = join ' ', @$missing;
  my $out = qx{prove -b @files 2>&1}; $ran++;
  my ($res) = $out =~ /^Result: (\w+)/m; my ($n) = $out =~ /Tests=(\d+)/;
  $res //= 'NO RESULT'; $bad++ if $res ne 'PASS';
  printf "%-6s %4s tests  %s\n", $res, $n // '?', $label;
  if ($res ne 'PASS') { print $out; push @fails, failed_lines(sprintf("%s %s tests  %s", $res, $n // '?', $label), $out) } }
exit 0 if $LIST;
print "\n", $ran - $bad, " of $ran entries pass\n";
record($OUTF, 'entries', $ran, $bad, \@skipped, \@fails);
exit !!$bad;

sub record {   # -o FILE (post-0.12, the user, 2026-11-15): only what was not expected, so normally just the header
  my ($file, $what, $ran, $bad, $skipped, $fails) = @_; return unless defined $file;
  open my $o, '>', $file or die "$file: $!";
  my @t = gmtime; my $date = sprintf '%04d-%02d-%02d', $t[5] + 1900, $t[4] + 1, $t[3];
  print $o "# $0", (map " $_", @ARGV_SAVED), " on $^O, Perl $^V, Proc::Spawner $Proc::Spawner::VERSION, primitive as built: $Proc::Spawner::PRIMITIVE; $date\n",
    "# $what: ", $ran - $bad, " of $ran pass", (@$skipped ? '; skipped: ' . join('; ', @$skipped) : ''), "\n",
    "# below: each one that did not pass, with prove's lines on what failed (nothing below: every one passed)\n";
  print $o @$fails }
sub failed_lines { my ($label, $out) = @_;
  join '', "$label\n", map "  $_\n", grep /Failed test|Dubious|Wstat|Failed \d+\/|^t\/\S+ +\(Wstat|NO RESULT|^Result:/, split /\n/, $out }

