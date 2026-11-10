package Proc::Spawner::Loop;
# EXPERIMENTAL (W5, post-0.10).  The one event loop of the process: queued calls, timers, reads, writes and ended
# children, with one interface on POSIX and on Windows.  The front end here keeps the queue and the rules; a backend
# waits for the events (Proc::Spawner::Loop::POSIX: select and SIGCHLD; Proc::Spawner::Loop::Win32: an I/O completion
# port).  See the POD at the end.
#
# The rules (decisions R1, D1-D3 of the page "Child Exit Wake-up"): every callback runs from the queue, one at a time,
# never inside a signal or inside another callback (R1); a callback never waits: wait_until called from one dies (D2);
# a backend may take process-wide state only while wait_until runs (D3: SIGCHLD on POSIX).
use strict; use warnings;
use Scalar::Util qw(weaken);
our $VERSION = '0.11';

our $TRACE;          # undef, or a code ref given one line per operation (Proc::Spawner's $TRACE is this one)
our $CAUSE;          # the caller's: a queued call keeps the value current when it was queued, and runs with it
our $REACTING = 0;   # true while a queued call runs
our $DEPTH = 0;      # nesting of wait_until and poll
our $BACKEND = $^O eq 'MSWin32' ? 'Proc::Spawner::Loop::Win32' : 'Proc::Spawner::Loop::POSIX';
sub tr_ { $TRACE->(join '', @_) if $TRACE }

my $LOOP;
sub new {   # the loop (there is one per process: every call gives the same object)
  return $LOOP if $LOOP;
  (my $f = "$BACKEND.pm") =~ s{::}{/}g; require $f;
  $LOOP = bless { q => [], watch => {}, timers => [], id => 0, backend => $BACKEND->new }, shift }

# ------------------------------------------------------------------ what a caller asks for
sub defer { my $l = shift; push @{$l->{q}}, [$CAUSE, @_]; return }
sub read  { my ($l, $fd, $max, $cb) = @_; $l->watch('read', $cb, $fd, $max) }   # (FD: a number or a handle)
sub write { my ($l, $fd, $bytes, $cb, %o) = @_; $l->watch('write', $cb, $fd, $bytes, $o{chunk}) }
sub child { my ($l, $pid, $cb) = @_; $l->watch('child', $cb, $pid) }
sub after {
  my ($l, $s, $cb) = @_; my $w = $l->watch('timer', $cb);
  my $at = now() + $s; my $t = $l->{timers};
  @$t = sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @$t, [$at, $w->id]; $w }
sub pipe { my ($l, %o) = @_; $l->{backend}->pipe(%o) }   # (READ, WRITE); overlapped => 'r', 'w', 'rw' (Windows)
sub fd_of { ref $_[0] ? fileno $_[0] : $_[0] }
sub now { require Time::HiRes; Time::HiRes::time() }

sub watch {   # a new watch: its callback here, the event asked of the backend (not for timers)
  my ($l, $kind, $cb, @a) = @_; my $id = ++$l->{id};
  $l->{watch}{$id} = [$kind, $cb];
  $l->{backend}->$kind($id, @a) unless $kind eq 'timer';
  bless [$l, $id, $kind], 'Proc::Spawner::Loop::Watch' }
sub cancel {
  my ($l, $id) = @_; my $w = delete $l->{watch}{$id} or return 0;
  $w->[0] eq 'timer' ? (@{$l->{timers}} = grep $_->[1] != $id, @{$l->{timers}}) : $l->{backend}->cancel($id); 1 }
sub pending { my $l = shift; @{$l->{q}} + keys %{$l->{watch}} }

# ------------------------------------------------------------------ running
sub wait_until {
  my ($l, $done) = @_;
  die "Proc::Spawner: wait inside a reaction\n" if $REACTING;   # D2
  $l->{backend}->begin unless $DEPTH;
  my $ok = eval { local $DEPTH = $DEPTH + 1; $l->turn until $done->(); 1 };
  $l->{backend}->end unless $DEPTH;
  die $@ unless $ok }
sub poll {   # what is ready now, without waiting; nothing inside wait_until or a callback (K3, post-0.04)
  my $l = shift; return if $REACTING || $DEPTH;
  local $DEPTH = $DEPTH + 1;   # (a callback's own wait_until still dies: D2)
  1 while $l->pending && $l->turn(0) }
sub turn {   # one queued call, or one round of waiting (at most TIMEOUT seconds; undef: as long as it takes): false if
  my ($l, $timeout) = @_;      # nothing happened
  if (my $c = shift @{$l->{q}}) { my ($cause, $k, @a) = @$c; local ($CAUSE, $REACTING) = ($cause, 1); $k->(@a); return 1 }
  my $t = $l->{timers};
  if (@$t) {
    my $now = now();
    while (@$t && $t->[0][0] <= $now) { my $id = (shift @$t)->[1]; my $w = delete $l->{watch}{$id}; $l->defer($w->[1]) }
    return 1 if @{$l->{q}};
    $timeout = $t->[0][0] - $now if @$t && (!defined $timeout || $t->[0][0] - $now < $timeout) }
  die "Proc::Spawner: nothing left to wait for\n" unless %{$l->{watch}};
  my $n = 0;
  for my $e ($l->{backend}->wait($timeout)) {   # [ID, ARGS...] per event, the oldest first
    my ($id, @a) = @$e; my $w = delete $l->{watch}{$id} or next;
    $l->defer($w->[1], @a); $n++ }
  $n }

package Proc::Spawner::Loop::Watch;   # [LOOP, ID, KIND]
sub id { $_[0][1] }
sub kind { $_[0][2] }
sub cancel { my $w = shift; $w->[0]->cancel($w->[1]) }
sub active { my $w = shift; exists $w->[0]{watch}{$w->[1]} }

1;

__END__

=head1 NAME

Proc::Spawner::Loop - the one event loop of Proc::Spawner, the same on POSIX and on Windows (EXPERIMENTAL)

=head1 SYNOPSIS

  use Proc::Spawner::Loop;
  my $loop = Proc::Spawner::Loop->new;          # the process's one loop
  my $out = '';
  $loop->read($fh, 65536, sub { my ($bytes, $errno) = @_; $out .= $bytes if defined $bytes; ... });
  $loop->write($fh2, "text\n", sub { my $errno = shift; ... });
  $loop->child($pid, sub { my $status = shift; ... });   # $? of waitpid
  my $t = $loop->after(2.5, sub { ... });  $t->cancel;
  $loop->defer(sub { ... }, @args);
  $loop->wait_until(sub { $done });

=head1 DESCRIPTION

One loop per process: C<new> always returns the same object.  Every callback
runs from its queue, one at a time, never inside a signal or inside another
callback; a callback must not wait (C<wait_until> called from one dies).

=over 4

=item C<read(FD_OR_HANDLE, MAX, CODE)>

One read of at most MAX bytes when there is something to read:
C<CODE-E<gt>(BYTES)>; C<CODE-E<gt>(undef)> at end of file; C<CODE-E<gt>(undef, ERRNO)>
on an error.  Read again for more.

=item C<write(FD_OR_HANDLE, BYTES, CODE, chunk =E<gt> N)>

Writes all of BYTES as the reader takes them, then C<CODE-E<gt>()>; when a
write fails (the reader is gone: EPIPE), the rest is dropped and
C<CODE-E<gt>(ERRNO)>.  On POSIX a handle is made non-blocking (an fd number
is left as it is; C<chunk>: at most N bytes per write, PIPE_BUF for a
blocking pipe).

=item C<child(PID, CODE)>

C<CODE-E<gt>(WAIT_STATUS)> when the child PID has ended (its status, as
C<$?>), or C<CODE-E<gt>(undef)> if other code took the status first.  Only
our own children: the loop waits for exactly these pids.

=item C<after(SECONDS, CODE)>

C<CODE-E<gt>()> once SECONDS have passed.

=item C<defer(CODE, ARGS)>

Queues C<CODE-E<gt>(ARGS)>.

=item C<wait_until(CODE)>, C<poll()>

C<wait_until> runs the queue and waits for events until C<CODE-E<gt>()> is
true (it dies if nothing is left to wait for).  C<poll> runs what is ready
now, without waiting, and does nothing inside C<wait_until> or a callback.

=item C<pipe(overlapped =E<gt> 'r' | 'w' | 'rw')>

A pipe: C<(READ_HANDLE, WRITE_HANDLE)>, or nothing with C<$!>.  On Windows the
ends named by C<overlapped> are opened for overlapped I/O (a named pipe of its
own): give such an end to no child, which would do synchronous I/O on it; the
loop reads and writes it without a helper thread.  Elsewhere C<pipe(2)>.

=back

C<read>, C<write>, C<child> and C<after> return a watch: C<$w-E<gt>cancel>
stops it (its callback is not called), C<$w-E<gt>active> tells whether it is
still pending.

=head2 Backends

B<POSIX> (C<Proc::Spawner::Loop::POSIX>): C<select> on the fds, and SIGCHLD
while C<wait_until> runs: a C handler writes a byte into a pipe the loop
selects on (decisions D1, D3), then C<waitpid(PID, WNOHANG)> for each child
watched.

B<Windows> (C<Proc::Spawner::Loop::Win32>, decision W5, the user, 2026-11-08:
"Use the Windows' way"): one I/O completion port.  A handle opened for
overlapped I/O is read and written so; a synchronous one (an anonymous pipe,
a pipe end shared with children, a console) by a helper thread, which posts
its result to the same port.  A child's end is posted there by
C<RegisterWaitForSingleObject> on its process handle; its status then comes
from C<waitpid>.  The wait has no time limit of its own.  While
C<wait_until> runs, a console control handler of ours (installed then, put
back after, as SIGCHLD on POSIX) posts Ctrl-C, Ctrl-Break, closing and
shutdown to the port: Windows calls it before Perl's own, so the wait then
gives Perl's a moment (200 ms at most) to mark the signal, and Perl runs the
C<%SIG> handler as soon as the wait returns.  While an C<alarm> is set (Perl's
is a timer message), the wait goes in slices of 50 ms, each followed by
Perl's check of its messages.  C<$Proc::Spawner::Loop::Win32::CTRL = 0>
leaves the console handler out.  C<Proc::Spawner::Loop::pipe>
makes a pipe whose ends are overlapped where asked.

=head1 SEE ALSO

F<doc/pspawn-loop.md>: how the loop works on each platform, and what was
checked.

=cut
