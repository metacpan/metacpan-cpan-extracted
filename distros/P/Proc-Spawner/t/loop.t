# Proc::Spawner::Loop (W5): reads, writes, timers, cancelling, children; the same on POSIX and on Windows (there,
# through the I/O completion port: overlapped ends without a helper thread, synchronous ones with one).
use strict; use warnings; use feature 'current_sub';
use Test::More; use POSIX ();
use Proc::Spawner; use Time::HiRes 'time';
my $l = Proc::Spawner::loop(); my $WIN = $^O eq 'MSWin32';
is ref($l->{backend}), $WIN ? 'Proc::Spawner::Loop::Win32' : 'Proc::Spawner::Loop::POSIX', 'the backend';
sub pump { my ($r, $w, $size) = @_; my ($buf, $eof, $err) = ('');
  $l->write($w, 'x' x $size, sub { $err = shift; close $w });
  $l->read($r, 65536, sub { if (defined $_[0]) { $buf .= $_[0]; $l->read($r, 65536, __SUB__) } else { $eof = [@_] } });
  $l->wait_until(sub { $eof }); (length $buf, $err, $eof) }
for my $ov ('', 'r', 'w', 'rw') {
  my ($r, $w) = $l->pipe(overlapped => $ov) or die "pipe: $!";
  is join(',', map Proc::Spawner::__wl_is_async(fileno $_), $r, $w), join(',', map $ov =~ $_ ? 1 : 0, qr/r/, qr/w/),
    "pipe(overlapped => '$ov'): those ends overlapped" if $WIN;
  my ($len, $err, $eof) = pump($r, $w, 300000);
  ok $len == 300000 && !$err && !defined $eof->[1], "pipe(overlapped => '$ov'): 300000 bytes through, then end of file";
  close $r }
{ pipe my $r, my $w; is join(',', map Proc::Spawner::__wl_is_async(fileno $_), $r, $w), '0,0', "Perl's own pipe: synchronous" if $WIN;
  my ($len) = pump($r, $w, 1000); ok $len == 1000, "Perl's own pipe: 1000 bytes" }
{ local $SIG{PIPE} = "IGNORE"; my ($r, $w) = $l->pipe(overlapped => "rw"); close $r; my $err;
  $l->write($w, 'y' x 200000, sub { $err = shift // 0 }); $l->wait_until(sub { defined $err });
  ok $err == POSIX::EPIPE(), "write to a pipe with no reader: EPIPE ($err)" }
{ my ($r, $w) = $l->pipe(overlapped => 'r'); my $got = 0; my $rd = $l->read($r, 10, sub { $got = 1 });
  my $t; $l->after(0.2, sub { $t = 1 }); $l->wait_until(sub { $t }); $rd->cancel;
  my $t2; $l->after(0.1, sub { $t2 = 1 }); $l->wait_until(sub { $t2 });
  ok !$got && !$rd->active, 'a read cancelled: no callback' }
{ pipe my $r, my $w; my $got = 0; my $rd = $l->read($r, 10, sub { $got = 1 });   # (Windows: a helper thread)
  my $t; $l->after(0.2, sub { $t = 1 }); $l->wait_until(sub { $t }); $rd->cancel; print $w "late"; close $w;
  my $t2; $l->after(0.2, sub { $t2 = 1 }); $l->wait_until(sub { $t2 });
  ok !$got, 'a read on a synchronous pipe cancelled: no callback' }
{ my $t0 = time; my @order; $l->after(0.3, sub { push @order, 3 }); $l->after(0.1, sub { push @order, 1 });
  my $c = $l->after(0.2, sub { push @order, 2 }); $c->cancel; $l->wait_until(sub { @order == 2 });
  ok "@order" eq '1 3' && time - $t0 >= 0.29, "timers in order, one cancelled (@order)" }
{ my @st; my $N = $Proc::Spawner::PRIMITIVE eq 'system1' && $WIN ? 60 : $WIN ? 80 : 20;   # (Perl's own spawn: at most 64)
  for my $i (1 .. $N) { Proc::Spawner::start($^X, [$^X, '-e', "exit $i"], undef, {}, on_exit => sub { $st[$i] = $_[0] >> 8 }) }
  $l->wait_until(sub { $N == grep defined, @st[1 .. $N] });
  ok !grep($st[$_] != $_, 1 .. $N), "$N children: each its own status" }
{ my ($out, $st) = ('');   # a child writing into a pipe the loop reads: the end shared with the child is synchronous
  # (no " in the child's words: Perl's own spawn, the primitive system1 on Windows, does not quote them: windows.t)
  pipe my $r, my $w; Proc::Spawner::start($^X, [$^X, '-e', 'print q(z) x 70000'], undef, { 1 => fileno $w }, on_exit => sub { $st = shift });
  close $w; my $eof;
  $l->read($r, 4096, sub { if (defined $_[0]) { $out .= $_[0]; $l->read($r, 4096, __SUB__) } else { $eof = 1 } });
  $l->wait_until(sub { $eof && defined $st }); ok length $out == 70000 && $st == 0, 'a child into a pipe: 70000 bytes, status 0' }
SKIP: {   # Windows: Ctrl-C wakes the loop (a console control handler of ours posts to the port), so Perl's %SIG{INT}
         # handler runs at once, not at the next event.  The sender shares our process group and ignores the event itself.
  skip 'Windows only', 1 unless $WIN;
  local $Proc::Spawner::WINDOWS{new_group} = 0; my ($got, $st); my $t0 = time;
  local $SIG{INT} = sub { $got //= time - $t0 };
  Proc::Spawner::start($^X, [$^X, '-MWin32::Console', '-e',
    '$SIG{INT} = q(IGNORE); select undef, undef, undef, 0.5; Win32::Console::GenerateCtrlEvent(0, 0) or exit 3; sleep 3'],
    undef, {}, on_exit => sub { $st = shift });
  $l->wait_until(sub { $got || defined $st });
  skip 'no console to send Ctrl-C to', 1 if !$got && $st == 3 << 8;
  ok $got && $got < 2.5, sprintf 'Ctrl-C during a wait: the SIGINT handler ran at %.2f s (sent at 0.5 s; the sender ends at 3.5 s)', $got // -1;
  $l->wait_until(sub { defined $st }) }
done_testing;
