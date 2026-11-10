# The shell layer on any platform (post-0.10): the lines of t/batteries/ that need no program but perl and print the
# same whatever the directory, HOME and umask, with what Proc::ShellSpawn printed for them on Linux
# (t/batteries/portable.txt, written by 'perl t/portable.t --record' on Linux with dash's batteries).  Each line runs
# through t/try.pl in a fresh directory, stdin from the null device, 10 seconds at most.  Runs on Windows; elsewhere
# with PORTABLE_TESTING=1.  The differences on Windows that are the platform's, line by line: %WIN below.
use strict; use warnings;
use Test::More; use Config (); use File::Temp 'tempdir'; use Cwd 'abs_path'; use File::Basename 'dirname'; use POSIX ();
my $WIN = $^O eq 'MSWin32';
my $record = @ARGV && $ARGV[0] eq '--record';
plan skip_all => 'set PORTABLE_TESTING=1 to run it here (it is for Windows)' unless $WIN || $record || $ENV{PORTABLE_TESTING};
my $top = abs_path('.'); my $data = "$top/t/batteries/portable.txt";
my %WIN = (   # the line => why Windows differs (the platform's, not a bug)
  "trap 'echo c' 10 12; kill -USR1 \$\$; kill -USR2 \$\$; echo after" => 'no signals 10 and 12 (USR1, USR2) on Windows',
);

our $ONLYPERL;   # (the recording: PATH as it is set, with nothing but perl)
sub run_line {   # (OUTPUT with | for newlines, then <STATUS>) of one line, in a fresh directory
  my ($line) = @_; (my $c = $line) =~ s/\@N/\n/g; $c =~ s/\@T/\t/g;
  my $dir = tempdir(CLEANUP => 1); my $file = "$dir.cmd"; my $out = "$dir.out";
  { open my $f, '>', $file or die; binmode $f; print $f $c; close $f }
  local $ENV{TRY_FILE} = $file;
  local $ENV{PATH} = dirname($^X) . $Config::Config{path_sep} . $ENV{PATH} unless $ONLYPERL;
  chdir $dir or die;
  open my $s1, '>&', \*STDOUT or die; open my $s2, '>&', \*STDERR or die; open my $s0, '<&', \*STDIN or die;
  open STDOUT, '>', $out or die; open STDERR, '>&', \*STDOUT or die; open STDIN, '<', File::Spec->devnull or die;
  my @cmd = ($^X, "-I$top/blib/lib", "-I$top/blib/arch", "$top/t/try.pl");
  my $pid = $WIN ? system(1, @cmd) : do { my $p = fork // die "fork: $!"; exec { $cmd[0] } @cmd or POSIX::_exit(127) unless $p; $p };
  open STDOUT, '>&', $s1; open STDERR, '>&', $s2; open STDIN, '<&', $s0; chdir $top;
  my $st; for (1 .. 200) { if (waitpid($pid, POSIX::WNOHANG()) == $pid) { $st = $? >> 8; last } select undef, undef, undef, 0.05 }
  if (!defined $st) { kill 'KILL', $pid; waitpid $pid, 0; $st = 'timeout' }
  open my $r, '<', $out or die; binmode $r; local $/; my $t = <$r> // ''; close $r; unlink $out, $file;
  $t =~ s/\r\n/\n/g; $t =~ s/\Q$dir\E/\@DIR\@/g; $t .= "<$st>"; $t =~ s/\n/|/g; $t }
require File::Spec;

if ($record) {   # on Linux: the lines that pass every variation, with their output
  my @lines = map { open my $f, '<', $_ or die; grep length, map { chomp; $_ } <$f> } grep !/portable\.txt\z/, sort glob "$top/t/batteries/*.txt";
  my $onlyperl = tempdir(CLEANUP => 1); symlink $^X, "$onlyperl/perl" or die;
  open my $o, '>', $data or die; binmode $o;
  print $o "# t/batteries/portable.txt: written by perl t/portable.t --record (on Linux); LINE TAB OUTPUT|...<STATUS>\n";
  my ($kept, $all) = (0, 0);
  for my $line (@lines) {
    $all++;
    next if $line =~ m{(?:^|[\s(;'"=<>])/|~[A-Za-z]|\bulimit\b|\bumask\b|\$PPID|\$\$|\$!|tr 0-9 N|\bsleep\b};   # the machine's: absolute paths, ...
    my @r = (run_line($line));
    { local $ENV{HOME} = '/nonexistent/h2'; local $ENV{PATH} = $onlyperl; local $ONLYPERL = 1; push @r, run_line($line) }
    { my $u = umask 077; push @r, run_line($line); umask $u }
    { local $ENV{HOME}; delete $ENV{HOME}; push @r, run_line($line) }
    next if grep $_ ne $r[0], @r;
    print $o "$line\t$r[0]\n"; $kept++ }
  print "kept $kept of $all lines in $data\n"; exit }

open my $in, '<', $data or die "$data: $!"; binmode $in;
my @t = map { chomp; [split /\t/, $_, 2] } grep !/^#/, <$in>;
my (@bad, $n, $known);
for (@t) {
  my ($line, $want) = @$_;
  if ($WIN && $WIN{$line}) { $known++; next }
  my $got = run_line($line); $n++;
  push @bad, "$line\n  want: $want\n  got:  $got" if $got ne $want }
ok !@bad, "$n lines as on Linux" . ($known ? " ($known left out: the platform's, %WIN)" : '') or diag join "\n", @bad;

# Windows only (post-0.10): its own paths, the output written by hand.  UNC names: Wine has no server shares, but its
# device names \\.\C:\... are UNC names in form (server '.', share 'C:'), so the code takes them as \\server\share.
my @WINONLY = (
  [q{cd '\\\\.\C:\windows' && pwd}, '//./C:/windows|<0>', 'cd to a UNC name with backslashes; pwd in Perl form'],
  [q{cd //./C:/windows/system32/.. && pwd}, '//./C:/windows|<0>', 'a UNC name with slashes, .. in it'],
  [q{cd '\\\\.\C:\windows' && cd .. && cd .. && pwd}, '//./C:/|<0>', '.. stops at the share'],
  [q{cd '\\\\.\C:\windows' && cd system32 && pwd}, '//./C:/windows/system32|<0>', 'a relative cd under a UNC name'],
  [q{cd '\\\\.\C:\windows\system32' && cd '\windows' && pwd}, '//./C:/windows|<0>', '\x: at the root of the share'],
  [q{cd '\\\\.\C:\windows' && test -d system32 && echo yes}, 'yes|<0>', 'a relative name in a test, under a UNC name'],
  [q{cd '\\\\.\C:\windows' && perl -e 'print(-d(q(system32))?q(yes):q(no))'}, 'yes<0>', 'a child starts in the UNC directory'],
    # (no " in the argument: Perl's own spawn, system1, drops it, and splits the argument at blanks; a ❰BUG❱ in Perl)
);
if ($WIN) {   # sh as Perl (SH1): Windows has no sh, so auto runs ours
  push @WINONLY, [q{sh -c 'exit 7'; echo st=$?}, 'st=7|<0>', 'sh -c: as Perl'],
    [q{echo 'echo stdin $1' | sh -s x}, 'stdin x|<0>', 'sh -s: the text from stdin'],
    [q{sh -c "sh -c 'echo nested'"}, 'nested|<0>', 'sh -c inside sh -c'],
    [q{sh -c 'echo "$0|$1|$#"' nm a b}, 'nm|a|2|<0>', 'sh -c TEXT NAME ARGS', 'system1'] }
if ($WIN) {   # ~user: one's own profile, or a sibling of %USERPROFILE% (Windows has a Public one), else as written
  my $up = $ENV{USERPROFILE} // ''; (my $users = $up) =~ s{[^/\\]+[/\\]*\z}{};
  push @WINONLY, ["echo ~$ENV{USERNAME}", "$up|<0>", '~ with one\'s own name: USERPROFILE'],
    ['echo ~Public/x', "${users}Public/x|<0>", '~user: a sibling of USERPROFILE'],
    ['echo ~nosuch-user-x ~..', '~nosuch-user-x ~..|<0>', '~user without such a directory, and ~..: as written'] }
SKIP: { skip 'Windows only', scalar @WINONLY unless $WIN;
  for (@WINONLY) {
    local our $TODO = $$_[3] && ($ENV{PROC_SPAWNER_MISSING} // '') =~ /\bposix_spawn\b/ ?   # (the primitive system1)
      'an argument with " and blanks: Perl drops the " and splits it (❰BUG❱ in Perl, perl-win32-system-bugs.md, 1)' : undef;
    is run_line($$_[0]), $$_[1], $$_[2] } }

# BIN1 (post-0.10, a temporary workaround): cat and the like from PROC_SHELLSPAWN_BIN, else from Git for Windows' usr\bin
# (MSYS2, Cygwin); Windows' own find (and sort, timeout, expand) never.  The stand-in for cat.exe is a copy of the
# system's whoami.exe, so cat must print what whoami prints.
SKIP: { skip 'Windows only', 5 unless $WIN;
  require File::Copy; my $sys = ($ENV{SystemRoot} // 'C:\\windows') . '\\system32';
  my $whoami = sub { File::Copy::copy("$sys\\whoami.exe", $_[0]) or die "copy to $_[0]: $!" };
  my $bin = tempdir(CLEANUP => 1); $whoami->("$bin\\cat.exe");
  my $la = tempdir(CLEANUP => 1); mkdir $_ or die "$_: $!" for map "$la\\$_", 'Programs', 'Programs\\Git', 'Programs\\Git\\usr', 'Programs\\Git\\usr\\bin', 'Programs\\Git\\cmd';
  $whoami->("$la\\Programs\\Git\\usr\\bin\\cat.exe"); $whoami->("$la\\Programs\\Git\\cmd\\git.exe");
  my $same = q{[ "$(cat)" = "$(whoami)" ] && echo same; echo st=$?};
  { local $ENV{PROC_SHELLSPAWN_BIN} = $bin; is run_line($same), 'same|st=0|<0>', 'PROC_SHELLSPAWN_BIN: searched first' }
  # (%ProgramFiles% is not tested: Wine sets it afresh in every process)
  { delete local $ENV{PROC_SHELLSPAWN_BIN}; local $ENV{LOCALAPPDATA} = $la;
    is run_line($same), 'same|st=0|<0>', "unset: Git for Windows' usr\\bin under %LOCALAPPDATA%\\Programs" }
  { delete local $ENV{PROC_SHELLSPAWN_BIN}; local $ENV{PATH} = "$la\\Programs\\Git\\cmd;$ENV{PATH}";
    is run_line($same), 'same|st=0|<0>', "unset: Git for Windows' usr\\bin beside git.exe on PATH" }
  { local $ENV{PROC_SHELLSPAWN_BIN} = 'none'; local $ENV{LOCALAPPDATA} = $la;
    is run_line('cat </dev/null; echo st=$?'), 'sh: cat: not found|st=127|<0>', 'PROC_SHELLSPAWN_BIN=none: no fallback' }
  { local $ENV{PROC_SHELLSPAWN_BIN} = 'none';
    is run_line('find . -name x; echo st=$?'), 'sh: find: not found|st=127|<0>', "Windows' own find.exe is not taken for find" } }
done_testing;
