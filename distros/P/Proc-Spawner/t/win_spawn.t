# win_spawn.h on its own (post-0.12): t/win/thooks.c checks every attribute and hook of the file, its code page and the
# options of the command line, with t/win/clchild.c as the child it starts.  On Windows both are built with this Perl's C
# compiler (ExtUtils::CBuilder); elsewhere the file is skipped, unless PROC_SPAWNER_WINE=1 and MinGW-w64 and Wine are
# there (a Linux container: apt-get install gcc-mingw-w64-x86-64 wine64): then they are built with MinGW-w64, without a
# warning, and run under Wine.  On Windows also, through Proc::Spawner, which children get a process group of their own
# (W7: by their SIGINT): clchild.exe says whether Ctrl-C is off for it, as Windows sets it in a new group.
use strict; use warnings;
use FindBin; use lib map "$FindBin::Bin/../$_", 'blib/lib', 'blib/arch';
use Test::More; use File::Spec; use File::Temp qw(tempdir); use File::Copy qw(copy);
my $root = File::Spec->rel2abs("$FindBin::Bin/..");
my $WIN = $^O eq 'MSWin32';
my ($gcc, $wine);
if (!$WIN) {
  plan skip_all => 'Windows only (elsewhere: PROC_SPAWNER_WINE=1, with MinGW-w64 and Wine)' unless $ENV{PROC_SPAWNER_WINE};
  my @path = split /:/, $ENV{PATH} // '';
  ($gcc) = grep -x, map "$_/x86_64-w64-mingw32-gcc", @path;
  ($wine) = grep -x, '/usr/lib/wine/wine64', map("$_/wine64", @path), map("$_/wine", @path);
  plan skip_all => 'PROC_SPAWNER_WINE=1, but no x86_64-w64-mingw32-gcc or no wine64' unless $gcc && $wine }
my $dir = tempdir(CLEANUP => 1);
copy("$root/t/win/$_.c", "$dir/$_.c") or die "t/win/$_.c: $!" for qw(clchild thooks);
my $out;
if ($WIN) {
  require ExtUtils::CBuilder; my $cb = ExtUtils::CBuilder->new(quiet => 1);
  plan skip_all => 'no C compiler' unless $cb->have_compiler;
  for my $n (qw(clchild thooks)) {
    my $exe = eval { my $o = $cb->compile(source => "$dir/$n.c", include_dirs => [$root]);
                     $cb->link_executable(objects => [$o], exe_file => "$dir/$n.exe") };
    ok $exe && -f "$dir/$n.exe", "t/win/$n.c built" or do { diag $@; done_testing; exit } }
  require Cwd; my $here = Cwd::getcwd(); chdir $dir or die "$dir: $!";
  $out = `thooks.exe 2>&1`; chdir $here or die }
else {
  for my $n (qw(clchild thooks)) {
    my $msg = `"$gcc" -O2 -Wall -Wextra -I"$root" -o "$dir/$n.exe" "$dir/$n.c" 2>&1`;
    ok !$? && -f "$dir/$n.exe", "t/win/$n.c built with MinGW-w64" or do { diag $msg; done_testing; exit };
    is $msg, '', "t/win/$n.c: no warning" }
  # under Wine, with Windows' own standard handles (Wine's for a Linux stdout cannot be fdopened)
  system qq{cd "$dir" && WINEDEBUG=-all "$wine" cmd /c "thooks.exe > thooks.out 2>&1" 2>/dev/null};
  open my $f, '<', "$dir/thooks.out" or die "thooks.out: $!"; $out = do { local $/; <$f> }; close $f }
my $status = $? >> 8; $out =~ s/\r//g;
my $last;
for (split /\n/, $out) {
  if (/^ok - (.*)/) { pass $1 }
  elsif (/^NOT OK - (.*)/) { fail $1 }
  elsif (/^([0-9]+) ok, ([0-9]+) not ok\z/) { $last = $_ }
  else { diag $_ } }
ok defined $last, 'thooks ran to its end' or diag $out;
is $status, 0, 'thooks: exit status 0';
if ($WIN) {   # W7, through Proc::Spawner: a process group of the child's own (Ctrl-C off) only if it would ignore SIGINT
  no warnings 'once'; require Proc::Spawner; require POSIX;
  my $s1 = $Proc::Spawner::PRIMITIVE eq 'system1';   # (Perl's own system 1, ...: always a new group)
  my $off = sub {   # the child's "ctrlc_off" (0 or 1), or a message
    my (%o) = @_; my $f = "$dir/group.txt"; unlink $f; my $st;
    my $pid = Proc::Spawner::start("$dir/clchild.exe", ['clchild'], undef,
      { 1 => [$f, POSIX::O_WRONLY() | POSIX::O_CREAT() | POSIX::O_TRUNC(), 0644] }, %o, on_exit => sub { $st = shift });
    return "no start: $!" unless $pid;
    Proc::Spawner::wait_until(sub { defined $st });
    open my $h, '<', $f or return "no output"; my $t = do { local $/; <$h> }; close $h;
    $t =~ /ctrlc_off=([01])/ ? $1 : "no ctrlc_off in: $t" };
  is $off->(), $s1 ? 1 : 0, "W7: SIGINT at its default: our process group" . ($s1 ? ' (system1: a new one)' : '');
  { local $SIG{INT} = 'IGNORE';
    is $off->(), 1, 'W7: SIGINT ignored here, inherited: a new group, Ctrl-C off';
    is $off->(sigdefault => ['INT']), $s1 ? 1 : 0, 'W7: SIGINT ignored here, set back by sigdefault: our group' }
  is $off->(sigignore => ['INT']), 1, 'W7: sigignore INT: a new group';
  is $off->(pgroup => 0), 1, 'pgroup 0: a new group';
  SKIP: { skip "system1: Perl's own system 1, ... always makes a new group", 2 if $s1;
    local $Proc::Spawner::WINDOWS{new_group} = 1; is $off->(), 1, 'new_group 1: a new group always';
    local $Proc::Spawner::WINDOWS{new_group} = 0; local $SIG{INT} = 'IGNORE'; is $off->(), 0, 'new_group 0: never' } }
done_testing;
