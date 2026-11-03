# Tests of Proc::Spawner alone, and of the graph's reactions (Proc::Spawner::Graph).  prove -v t/spawner.t
use strict; use warnings; use feature 'current_sub';
use FindBin; use lib map "$FindBin::Bin/../$_", 'lib', 'blib/arch';
use Test::More;
use Proc::Spawner; use Proc::Spawner::Graph;
use File::Temp qw(tempdir);
use POSIX ();

my $tmp = tempdir(CLEANUP => 1);
sub capture {   # spawn $argv with fd 1 (and maybe others) into a pipe; (output, wait status)
  my ($argv, $fds, %o) = @_;
  pipe my $r, my $w or die; my ($out, $st, $eof) = ('');
  my $pid = Proc::Spawner::start($argv->[0], $argv, undef, { 1 => fileno $w, %{$fds // {}} }, %o, on_exit => sub { $st = shift });
  close $w;
  Proc::Spawner::on_read($r, 4096, sub { defined $_[0] ? ($out .= $_[0], Proc::Spawner::on_read($r, 4096, __SUB__)) : ($eof = 1) });
  Proc::Spawner::wait_until(sub { $eof && defined $st }); ($out, $st, $pid) }

sub has {   # this build has these posix_spawn settings (false: an option the libc lacks)
  my $p = Proc::Spawner::spawn('/bin/true', ['true'], undef, @_); waitpid $p, 0 if $p; !!$p || $! != POSIX::ENOTSUP() }
my $has = \&has;

my ($out, $st) = capture(['/bin/sh', '-c', 'echo out; echo err >&2'], { 2 => undef });
is $out, "out\n", 'fd 1 into a pipe'; isnt $st, undef, 'exit reported';
($out) = capture(['/bin/sh', '-c', 'echo err >&2'], { 2 => undef }); is $out, '', 'fd 2 closed';
($out, $st) = capture(['/bin/sh', '-c', 'exit 3']); is $st >> 8, 3, 'exit status';
($out, $st) = capture(['/bin/sh', '-c', 'kill -TERM $$']); is $st & 127, POSIX::SIGTERM(), 'killed by a signal';

{ # fds crossed: the child's 1 is our 2's pipe and its 2 our 1's pipe, even when the numbers collide
  pipe my $ra, my $wa or die; pipe my $rb, my $wb or die;
  my %fds = (1 => fileno $wa, 2 => fileno $wb, (fileno $wa) => fileno $wb, (fileno $wb) => fileno $wa);
  my $done; Proc::Spawner::start('/bin/sh', ['/bin/sh', '-c', 'echo A; echo B >&2'], undef, \%fds, on_exit => sub { $done = 1 });
  close $wa; close $wb; Proc::Spawner::wait_until(sub { $done });
  is scalar <$ra>, "A\n", 'colliding fd numbers: 1'; is scalar <$rb>, "B\n", 'colliding fd numbers: 2' }

SKIP: { skip 'no chdir in this libc', 1 unless has([[chdir => '/']], {});
  ($out) = capture(['/bin/pwd'], {}, chdir => $tmp); is $out, "$tmp\n", 'chdir' }
($out) = capture(['/bin/sh', '-c', 'umask'], {}, umask => 027); like $out, qr/^0?027$/, 'umask';
{ local $SIG{USR1} = 'IGNORE';
  ($out) = capture(['/bin/sh', '-c', 'exec grep SigIgn /proc/self/status'], {});
  my ($ign) = $out =~ /SigIgn:\s*\w*?(\w{1,8})$/m; ok hex($ign) & (1 << (POSIX::SIGUSR1() - 1)), 'an ignored signal stays ignored';
  ($out) = capture(['/bin/sh', '-c', 'exec grep SigIgn /proc/self/status'], {}, sigdefault => ['USR1']);
  ($ign) = $out =~ /SigIgn:\s*\w*?(\w{1,8})$/m; ok !(hex($ign) & (1 << (POSIX::SIGUSR1() - 1))), 'sigdefault' }

{ # a write larger than a pipe holds, without blocking us; the reader takes it all
  pipe my $r, my $w or die; pipe my $r2, my $w2 or die;
  my ($wrote, $st, $eof, $got) = (0, undef, 0, '');
  Proc::Spawner::start('/usr/bin/wc', ['wc', '-c'], undef, { 0 => fileno $r, 1 => fileno $w2 }, on_exit => sub { $st = shift });
  close $r; close $w2;
  Proc::Spawner::on_write($w, 'x' x 1_000_000, sub { $wrote = 1; close $w });
  Proc::Spawner::on_read($r2, 100, sub { defined $_[0] ? ($got .= $_[0], Proc::Spawner::on_read($r2, 100, __SUB__)) : ($eof = 1) });
  Proc::Spawner::wait_until(sub { $wrote && $eof && defined $st });
  like $got, qr/^\s*1000000$/, 'a megabyte written by Perl without blocking' }

{ # R1: callbacks run one at a time, from the queue, in order; D2: a callback may not wait
  my @log; my $n = 0;
  for my $i (1 .. 5) { Proc::Spawner::start('/bin/true', ['true'], undef, {}, on_exit => sub { push @log, "start $i"; push @log, "end $i"; $n++ }) }
  Proc::Spawner::wait_until(sub { $n == 5 });
  is_deeply [grep /start/, @log[map 2 * $_, 0 .. 4]], [grep /start/, @log], 'reactions never interleave';
  my $err; my $done;
  Proc::Spawner::start('/bin/true', ['true'], undef, {}, on_exit => sub { eval { Proc::Spawner::wait_until(sub { 1 }) }; $err = $@; $done = 1 });
  Proc::Spawner::wait_until(sub { $done }); like $err, qr/wait inside a reaction/, 'D2: no wait inside a reaction';
  eval { Proc::Spawner::wait_until(sub { 0 }) }; like $@, qr/nothing left to wait for/, 'nothing left to wait for' }

{ # C2: other code takes our child's status: reported as undef, not a hang
  my ($st, $done) = (0);
  my $pid = Proc::Spawner::start('/bin/true', ['true'], undef, {}, on_exit => sub { $st = shift; $done = 1 });
  waitpid $pid, 0;
  Proc::Spawner::wait_until(sub { $done }); is $st, undef, 'a status taken by other code: undef' }

{ # the graph: a reaction (named) starts the next process, which reads what the first wrote
  my $g = Proc::Spawner::Graph->new;
  my ($r, $w) = $g->new_pipe;
  my ($pr, $pw) = $g->new_pipe;
  our @SEEN;
  sub then_cat { my ($g, $node, $st, $r, $pw) = @_; push @SEEN, "$node->{argv}: " . ($st >> 8);
    $g->start('/bin/cat', ['cat'], undef, { 0 => $r, 1 => $pw }, on_exit => sub { push @SEEN, "cat: " . ($_[2] >> 8) });
    Proc::Spawner::Graph::release($_) for $r, $pw }
  $g->start('/bin/sh', ['sh', '-c', 'echo hello'], undef, { 1 => $w }, on_exit => ['main::then_cat', $r, $pw]);
  Proc::Spawner::Graph::release($w); undef $r; undef $pw;   # held by the reaction's data now
  my ($got, $eof) = ('');
  $g->perl_read($pr, 100, sub { my ($g, $b) = @_; return $eof = 1, Proc::Spawner::Graph::release($pr) unless defined $b;
                                   $got .= $b; $g->perl_read($pr, 100, __SUB__) });
  Proc::Spawner::wait_until(sub { $eof && @SEEN == 2 });
  is $got, "hello\n", 'a reaction started a process that read the first one'; is_deeply \@SEEN, ['sh -c echo hello: 0', 'cat: 0'], 'reactions with their statuses';
  is scalar(grep $_->{st} eq 'running', @{$g->{procs}}), 0, 'nothing running';
  my @rels = grep $_->{fh}, map $_->[2], map @{$_->{edges}}, @{$g->{procs}}; is scalar @rels, 0, 'every end closed' }

{ # every posix_spawn setting, through start's options; those this build's libc lacks are skipped
  use Fcntl qw(O_WRONLY O_CREAT O_TRUNC);
  my $sh = sub { my $cmd = shift; capture(['/bin/sh', '-c', $cmd], @_) };
  my ($o) = capture(['/bin/grep', 'SigBlk', '/proc/self/status'], {}, sigmask => ['USR1']);   # sh clears its mask
  like $o, qr/^SigBlk:\s*[0-9a-f]*200$/m, 'sigmask: USR1 blocked in the child';
  ($o) = $sh->('read -r l </proc/$$/stat; set -- ${l#*) }; echo "$3 $4 $$"', {}, pgroup => 0);
  my ($pg, $sid, $pid) = split ' ', $o; is $pg, $pid, 'pgroup => 0: a new group led by the child';
  ($o) = $sh->('read -r l </proc/$$/stat; set -- ${l#*) }; echo "$3 $4 $$"', {}, setsid => 1);
  ($pg, $sid, $pid) = split ' ', $o; is "$pg $sid", "$pid $pid", 'setsid: a new session';
  SKIP: { skip 'no chdir in this libc', 1 unless has([[chdir => '/']], {});
    $sh->('echo opened >&3', { 3 => ['rel', O_WRONLY|O_CREAT|O_TRUNC, 0644] }, chdir => $tmp);
    is do { local (@ARGV, $/) = "$tmp/rel"; <> }, "opened\n", 'an fd opened in the child, relative to chdir' }
  SKIP: { skip 'no fchdir in this libc', 1 unless $has->([[fchdir => 0]], {});
    my $dfd = POSIX::open($tmp, POSIX::O_RDONLY()) // die; ($o) = $sh->('pwd', {}, fchdir => $dfd); POSIX::close($dfd);
    is $o, "$tmp\n", 'fchdir' }
  my $old = umask; ($o) = $sh->('umask', {}, umask => 027);
  is $o, "0027\n", 'umask in the child'; is umask, $old, 'and ours unchanged';
  SKIP: { skip 'no pidfd_spawn in this libc', 1 unless $has->([], { pidfd => 1 });
    my $done; my ($p, $pidfd) = Proc::Spawner::start('/bin/true', ['true'], undef, {}, pidfd => 1, on_exit => sub { $done = 1 });
    ok $p > 0 && defined $pidfd && $pidfd >= 0, 'pidfd => 1: a pid and a pidfd'; POSIX::close($pidfd) if defined $pidfd;
    Proc::Spawner::wait_until(sub { $done }) }
  ok !eval { Proc::Spawner::start('/bin/true', ['true'], undef, {}, sigdefault => ['NOSUCH']); 1 } && $@ =~ /unknown signal/,
    'an unknown signal name dies' }

{ # the raw call: spawn is the XSUB __posix_spawn, with an optional UNSUPPORTED hash
  is \&Proc::Spawner::spawn, \&Proc::Spawner::__posix_spawn, 'spawn is an alias of __posix_spawn';
  my $pid = Proc::Spawner::spawn('/bin/true', ['true'], undef, [], {}, { sched => 'drop' });
  ok scalar(@{[Proc::Spawner::spawn('/bin/true', ['true'], undef, [], { pidfd => 1 }, { pidfd => 'drop' })]}) >= 1, 'an option marked drop never fails';
  ok $pid, 'spawn takes an UNSUPPORTED hash'; waitpid $pid, 0;
  ok !eval { Proc::Spawner::spawn('/bin/true', ['true'], undef, [], {}, 'drop'); 1 } && $@ =~ /hash reference/,
    'UNSUPPORTED must be a hash reference' }

done_testing;
