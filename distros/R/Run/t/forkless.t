#! perl
# Forkless mode ($Run::Forkless), as on OS/2, Win32 and VMS: every process
# is started by spawn_nowait(), Run's one primitive (on Unix emulated by fork
# and exec), and no other code forks.  Linux only for the fd checks.
use strict; use warnings;
use POSIX ();
my %forks;			# "caller of the caller of fork" => count
BEGIN {
  *CORE::GLOBAL::fork = sub () {
    my $from = (caller 1)[3] // "main";
    $from = (caller 2)[3] if $from eq "Run::fork_kid";
    $forks{$from}++;
    CORE::fork();
  };
}
use Test::More;
use File::Temp qw(tempdir);
use Run ':NEW';

my $dir = tempdir(CLEANUP => 1);
my $out = "$dir/out";
sub slurp { open my $f, '<', $_[0] or return; local $/; scalar <$f> }
sub perl { new_system($^X, '-e', @_) }
sub to { new_redir([1 => {filename => $_[0], mode => '>'}], $_[1]) }

# Every kind of node, forkless.
{
  local $Run::Forkless = 1;
  ok perl('exit 0')->run, 'system';
  my @pids;
  my $pid = new_spawn($^X, q(-e), q(exit 3))->run({pids => \@pids}) && $pids[0];
  ok $pid, 'spawn';
  waitpid $pid, 0;
  is $? >> 8, 3, '... its status';
  ok to($out, new_and(perl('print "a"'), perl('print "b"')))->run, 'and, under a redirection';
  is slurp($out), 'ab', '... output';
  is new_readpipe(perl('print "r"'))->run, 'r', 'readpipe';
  my $w = new_pipe(w => to($out, perl('print uc <STDIN>')))->run;
  print $w "w\n"; close $w;
  1 until wait == -1;
  is slurp($out), "W\n", 'pipe w';
  ok to($out, new_pipeline(perl('print "x\n"'), new_or(perl('exit 1'), perl('print "y$_" while <STDIN>'))))->run({errs => []}),   # (its exit 1 is meant)
    'pipeline with a group run here';
  is slurp($out), "yx\n", '... output';
  my $pid2 = Run::spawn($^X, '-e', 'exit 0');
  ok $pid2, 'exported spawn';
  waitpid $pid2, 0;
}
is_deeply [keys %forks], ["Run::spawn_nowait"], "forkless: every fork is inside spawn_nowait";
ok $forks{'Run::spawn_nowait'}, '... which was used';

# Regression: inside the wraparound, a fd that apply() has closed may still
# be claimed by a Perl handle; the exec-error pipe of the emulated spawn could
# land on it, never be closed, and hang the parent.  Every placement of fd T
# (owned by a Perl handle, then closed by "T>&-") and of free fds below it is
# tried in a fresh perl, whose fds 3 and up are not taken by Test::More.
my $search = <<'EOF';
use strict; use warnings; use POSIX (); use Run ':NEW';
$Run::Forkless = 1;
my ($cases, $hangs) = (0, 0);
for my $t (4 .. 8) { for my $free (0 .. 2**($t-3) - 1) {
  $cases++;
  my $pid = fork // die;
  if (!$pid) {
    for my $n (3 .. $t) {
      my $fd = POSIX::open('/dev/null', POSIX::O_RDONLY()); POSIX::dup2($fd, $n); POSIX::close($fd) if $fd != $n;
    }
    open my $h, '<&=', $t or die;
    POSIX::close($_) for grep $free >> ($_ - 3) & 1, 3 .. $t - 1;
    $SIG{ALRM} = sub { POSIX::_exit(1) }; alarm 3;
    new_redir([$t => {filename => '>&-'}], new_system($^X, '-e', 'exit 0'))->run({errs => []})
      or POSIX::_exit(2);
    POSIX::_exit(0);
  }
  waitpid $pid, 0;
  $hangs++ if $?;
}}
print "$hangs of $cases\n";
EOF
(my $lib = $INC{'Run.pm'}) =~ s{/?Run\.pm\z}{};
open my $f, '>', "$dir/search.pl" or die; print $f $search; close $f;
is scalar qx{"$^X" "-I@{[$lib || '.']}" "$dir/search.pl"}, "0 of 62\n", 'forkless: no hang or failure when a Perl-owned fd is closed by a redirection';

done_testing;
