# Windows only (post-0.08): spawn through win_spawn.h (the default), or, with PROC_SPAWNER_MISSING="posix_spawn",
# through Perl's own spawn with the redirections done by Run (M2, $Proc::Spawner::PRIMITIVE 'system1').  The children
# write into files: the loop cannot read pipes on Windows yet.  Under Wine, run it with Windows' own standard handles
# (cmd /c "perl t\windows.t > out.txt 2>&1"): Wine's handles for a Linux stdout cannot be fdopened.
use strict; use warnings;
use FindBin; use lib map "$FindBin::Bin/../$_", 'blib/lib', 'blib/arch';
use Test::More;
plan skip_all => 'Windows only' unless $^O eq 'MSWin32';
use Proc::Spawner; use POSIX (); use Cwd (); use File::Temp qw(tempdir);
my $dir = tempdir(CLEANUP => 1); my $sub = "$dir/sub"; mkdir $sub or die;
my $perl = $^X; my $s1 = $Proc::Spawner::PRIMITIVE eq 'system1';
my $W = POSIX::O_WRONLY() | POSIX::O_CREAT() | POSIX::O_TRUNC();
sub script { my ($n, $code) = @_; open my $f, '>', "$dir/$n" or die; print $f $code; close $f; "$dir/$n" }
my $ARGS = script('args.pl', 'print join("|", map "[$_]", @ARGV); exit 3;');
my $CWD = script('cwd.pl', 'use Cwd; print Cwd::getcwd();');
my $ENVP = script('env.pl', 'print $ENV{FOO} // "none";');
my $IN = script('in.pl', 'print defined(sysread STDIN, my $b, 1) ? "open" : "closed";');
my $RAN = script('ran.pl', 'print "ran";');
open my $b, '>', "$dir/b.bat" or die; print $b "\@echo off\r\necho bat:[%1][%2]\r\nexit /b 4\r\n"; close $b;
sub run {   # (status, output) of a child with its fd 1 in a file; or (undef, $!)
  my ($argv, %o) = @_; my $out = "$dir/out.txt"; unlink $out; my $st;
  my $pid = Proc::Spawner::start($o{file} // $perl, $argv, $o{envp}, { 1 => [$out, $W, 0644], %{$o{fds} // {}} },
    (map +($_ => $o{$_}), grep !/^(?:file|envp|fds)\z/, keys %o), on_exit => sub { $st = shift });
  return (undef, $! + 0) unless $pid;
  Proc::Spawner::wait_until(sub { defined $st });
  open my $f, '<', $out or return ($st >> 8, '');   # (not <>: its handle stays open, and Windows keeps an open file)
  my $t = do { local $/; <$f> } // ''; close $f; $t =~ s/\r//g; chomp $t; ($st >> 8, $t) }
diag "primitive: $Proc::Spawner::PRIMITIVE";
my @args = ('a b', 'q"x', 'c\\\\', '', 'x "y" z', 'tail\\', 'd\\"e', '%PATH%', 'a&b');
TODO: { local $TODO = $s1 ? "Perl's system LIST does not quote arguments as the C runtime parses them back (❰BUG❱ in Perl, drafted in doc/perl-win32-system-bugs.md, not yet filed)" : undef;
  is_deeply [run([$perl, $ARGS, @args])], [3, join '|', map "[$_]", @args], 'argv arrives exactly; the status' }
is_deeply [run([$perl, $ARGS, 'plain'])], [3, '[plain]'], 'a plain argument; the status';
is_deeply [run([$perl, $CWD], chdir => $sub)], [0, Cwd::abs_path($sub)], 'chdir';
is_deeply [run([$perl, $ENVP], envp => ['FOO=bar', map "$_=$ENV{$_}", grep /^(?:PATH|SYSTEMROOT|WINDIR|TEMP|TMP)\z/i, keys %ENV])],
  [0, 'bar'], 'envp'; ok !defined $ENV{FOO}, 'our environment unchanged';
{ (my $bin = $perl) =~ s{[\\/][^\\/]*\z}{}; local $ENV{PATH} = "$bin;$ENV{PATH}";
  is_deeply [run(['perl', $RAN], file => 'perl', search => 1)], [0, 'ran'], 'search (PATH and PATHEXT)' }
{ (my $bin = $perl) =~ s{[\\/][^\\/]*\z}{}; local $ENV{PATH} = qq{C:\\nonexistent;;"$bin"};   # (post-0.10: path_split)
  is_deeply [run(['perl', $RAN], file => 'perl', search => 1)], [0, 'ran'], 'search: a quoted PATH entry, an empty one' }
is_deeply [run([$perl, $IN], fds => { 0 => undef })], [0, 'closed'], 'fd 0 closed';
is_deeply [run([$perl, $IN], fds => { 0 => ['/dev/null', POSIX::O_RDONLY(), 0], 2 => ['/DEV/NULL', $W, 0] })], [0, 'open'],
  '/dev/null, in any case, is NUL (X31)';
is_deeply [run(['nosuch'], file => "$dir/nosuch.exe")], [undef, POSIX::ENOENT()], 'a missing program: ENOENT';
if ($s1) {
  is_deeply [run([$perl, $RAN], fds => { 3 => 1 })], [undef, POSIX::ENOTSUP()], 'fd 3: unsupported (the child sees fds 0-2 only)';
  is_deeply [run([$perl, $RAN], fds => { 3 => 1 }, unsupported => { dup2 => 'drop' })], [0, 'ran'], 'fd 3 dropped';
  is_deeply [run([$perl, $RAN], pidfd => 1)], [undef, POSIX::ENOTSUP()], 'pidfd: unsupported' }
else { is_deeply [run([$perl, $RAN], fds => { 3 => 1 })], [0, 'ran'], 'fd 3 (through the C runtime)' }
is_deeply [run([$perl, $RAN], sigignore => ['INT', 'PIPE'])], [0, 'ran'], 'sigignore of INT and PIPE: nothing to do';
is_deeply [run([$perl, $RAN], sigignore => ['HUP'])], [undef, POSIX::ENOTSUP()], 'sigignore of HUP: unsupported';
TODO: { local $TODO = $s1 ? "Perl quotes a batch file's line as a whole; Wine's cmd.exe does not strip those quotes (real Windows unchecked)" : undef;
  is_deeply [run(['b.bat', 'x1', 'y-2'], file => "$dir/b.bat")], [4, 'bat:[x1][y-2]'], 'a batch file' }
# X58 (post-0.12): a name given twice in envp: the first, as getenv finds it (the sort put either first; system1's %ENV
# kept the last); a name differing only in case is the same name on Windows
is_deeply [run([$perl, $ENVP], envp => ['FOO=first', 'Foo=second', 'FOO=third', map "$_=$ENV{$_}", grep /^(?:PATH|SYSTEMROOT|WINDIR|TEMP|TMP)\z/i, keys %ENV])],
  [0, 'first'], 'envp with a name twice: the first (X58)';
# X57 (post-0.12): in a pseudo-process (Perl's fork emulation) the program is looked up with its own PATH, and a
# relative name from its own directory, not the process's.  The program: a copy of whoami.exe, a name nothing else has
SKIP: { my $who = "$ENV{SystemRoot}\\system32\\whoami.exe"; skip 'no whoami.exe', 2 unless -f $who;
  mkdir "$dir/x57" or die; my $prog = "$dir/x57/x57prog.exe";
  { open my $i, '<:raw', $who or die; open my $o, '>:raw', $prog or die; local $/; print {$o} readline($i); close $o or die }
  for (['through PATH', sub { $ENV{PATH} = "$dir\\x57;$ENV{PATH}"; 'x57prog' }],
       ['a relative name with a directory', sub { chdir $dir or die; 'x57\\x57prog' }]) {
    my ($what, $setup) = @$_; my $out = "$dir/x57.txt"; unlink $out;
    my $kid = fork; defined $kid or die "fork: $!";
    if (!$kid) {   # the pseudo-process: no test output here, only the exit code
      my $name = $setup->(); my ($pid) = Proc::Spawner::spawn($name, [$name], undef, [['open', 1, $out, $W, 0644]], { search => 1 });
      $pid or exit 2; waitpid $pid, 0; Proc::Spawner::reaped($pid); exit($? ? 3 : 0) }
    waitpid $kid, 0;
    is $? >> 8, 0, "in a pseudo-process, search: $what (X57)" } }
# W6 (the user, 2026-11-14): kill_with_parent off by default, so a child outlives a parent that exits; on, Windows ends it
# with the parent (through Perl's own spawn, system1, there is no job: the child outlives it either way)
for my $kill (0, 1) {
  SKIP: { skip "kill_with_parent: Perl's own spawn makes no job", 2 if $kill && $s1;
    my $mark = "$dir/w6-$kill.txt"; unlink $mark;
    my $child = script("w6child-$kill.pl", 'sleep 3; open my $f, ">", ' . "'$mark'" . ' or die; print $f "ran"; close $f;');
    my $parent = script("w6parent-$kill.pl", 'use Proc::Spawner; use POSIX (); '
      . ($kill ? '$Proc::Spawner::WINDOWS{kill_with_parent} = 1; ' : '')
      . 'my ($pid) = Proc::Spawner::spawn($^X, [$^X, ' . "'$child'" . '], undef, '
      . '[map [open => $_, "/dev/null", $_ ? POSIX::O_WRONLY() : POSIX::O_RDONLY()], 0, 1, 2], {}); exit($pid ? 0 : 1);');
    system $perl, (map "-I$_", grep !ref, @INC), $parent;
    is $? >> 8, 0, "W6: the parent started its child, kill_with_parent $kill";
    my $t = time; sleep 1 until -e $mark || time - $t > ($kill ? 6 : 10);   # (the child writes after 3 s)
    ok $kill ? !-e $mark : -e $mark, $kill ? 'kill_with_parent 1: the child ended with its parent'
                                           : 'kill_with_parent off (the default): the child outlived its parent' } }
print "# ours still on stdout\n"; ok 1, 'our stdout after the calls';
done_testing;
