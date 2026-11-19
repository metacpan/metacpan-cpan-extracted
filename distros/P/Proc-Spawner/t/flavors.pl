#!/usr/bin/perl
# flavors.pl (post-0.12; the user, 2026-11-14): the tests through each kind of spawn primitive this platform has, from
# the most capable to the least, the same way on every platform:
#   1. as built: posix_spawn (the C library's, or win_spawn.h's on Windows) with the settings it does natively;
#   2. posix_spawn with the redirections only (dup2, close, open natively; every other setting missing: done around
#      the call, or unsupported; the user, 2026-11-14), skipped where it is the same as 1 (a posix_spawn that does no
#      setting natively beyond those);
#   3. without posix_spawn: fork and exec, or, where there is no fork (Windows), Perl's own spawn through Run (system1);
#   4. without posix_spawn and fork: system1 through Run, only where 3 was fork.
# A flavor that needs Run (Run 0.07 or later, found in @INC: on Windows copied into blib/lib) is skipped, and said so,
# where Run is not there.  The short version of t/missing-matrix.pl, which takes the settings one at a time.
# Usage, after make:  perl t/flavors.pl [-o FILE] [TEST FILE ...]      (default: t/; under Wine, the Windows files, see
# CLAUDE.md of the repository: run from cmd /c with Windows' own standard handles).  -o: a record of what did not pass
# (a header, and nothing more when every flavor passed; doc/test-results/).
use strict; use warnings; use FindBin; use lib map "$FindBin::Bin/../$_", 'blib/lib', 'blib/arch';
use Proc::Spawner;
chdir "$FindBin::Bin/.." or die;
my $OUTF; $OUTF = (splice @ARGV, 0, 2)[1] if @ARGV >= 2 && $ARGV[0] eq '-o';
our @ARGV_SAVED = @ARGV;   # (for the record: without -o FILE)
my @files = @ARGV ? @ARGV : ('t/');
my (@skipped, @fails);
my @features = @Proc::Spawner::FEATURES;
my %native = %Proc::Spawner::NATIVE;
my @own = grep $native{$_}, @features;   # the settings posix_spawn does natively here
my %REDIR = map +($_ => 1), qw(dup2 close open);   # 2 keeps these: the least posix_spawn has
my @beyond = grep !$REDIR{$_}, @own;
my $has_run = eval { local $SIG{__DIE__}; require Run; Run->VERSION('0.07'); 1 };
sub primitive {   # the primitive Proc::Spawner takes with these settings missing (asked in a child, through a file: no
  local $ENV{PROC_SPAWNER_MISSING} = join ' ', @_;   # shell, and no double quote in an argument, which Perl's own
  require File::Temp; my ($fh, $tmp) = File::Temp::tempfile(); close $fh;   # spawn on Windows passes wrongly)
  system $^X, '-Iblib/lib', '-Iblib/arch', '-MProc::Spawner', '-e',
    'open my $o, q{>}, $ARGV[0] or die; print $o $Proc::Spawner::PRIMITIVE', $tmp;
  open my $in, '<', $tmp or die "$tmp: $!"; my $p = <$in> // '?'; close $in; unlink $tmp; $p }
my @flavors = (['1. as built (' . primitive() . (@own ? "; natively: @own" : '; no setting natively') . ')', []]);
if ($native{posix_spawn}) {
  if (@beyond) { push @flavors, ['2. posix_spawn with the redirections only (dup2, close, open)', [grep !$REDIR{$_}, @features]] }
  else { push @skipped, '2 (the same as 1)'; print "skipped: 2. posix_spawn with the redirections only (the same as 1: nothing natively beyond them)\n" }
  my $p3 = primitive('posix_spawn');
  push @flavors, ["3. without posix_spawn ($p3)", ['posix_spawn'], $p3 eq 'system1'];
  if ($p3 eq 'fork') { push @flavors, ['4. without posix_spawn and fork (system1)', [qw(posix_spawn fork)], 1] }
  else { push @skipped, '4 (the same as 3)'; print "skipped: 4. without posix_spawn and fork (the same as 3)\n" } }
else { push @skipped, '2 to 4 (no posix_spawn)'; print "skipped: 2 to 4 (no posix_spawn: 1 is already the fallback)\n" }
my ($bad, $ran) = (0, 0);
for my $f (@flavors) {
  my ($name, $missing, $needs_run) = @$f;
  if ($needs_run && !$has_run) { push @skipped, "$name (no Run)"; print "skipped: $name (needs Run 0.07, not found)\n"; next }
  local $ENV{PROC_SPAWNER_MISSING} = join ' ', @$missing;
  my $out = qx{prove -b @files 2>&1}; $ran++;
  my ($res) = $out =~ /^Result: (\w+)/m; my ($n) = $out =~ /Tests=(\d+)/;
  $res //= 'NO RESULT'; $bad++ if $res ne 'PASS';
  printf "%-6s %4s tests  %s\n", $res, $n // '?', $name;
  if ($res ne 'PASS') { print $out; push @fails, failed_lines(sprintf("%s %s tests  %s", $res, $n // '?', $name), $out) } }
print "\n", $ran - $bad, " of $ran flavors pass\n";
record($OUTF, 'flavors', $ran, $bad, \@skipped, \@fails);
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

