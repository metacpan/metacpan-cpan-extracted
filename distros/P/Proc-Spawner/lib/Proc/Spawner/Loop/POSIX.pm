package Proc::Spawner::Loop::POSIX;
# EXPERIMENTAL (W5, post-0.10).  The POSIX backend of Proc::Spawner::Loop: select(2) on the fds, and SIGCHLD while
# wait_until runs (D3): a C handler (Proc::Spawner::chld_to_fd) writes one byte into a pipe the loop selects on (D1),
# so no Perl code runs inside the signal and no wake-up is lost.  Without it, a deferred Perl handler, and select wakes
# up every $TICK seconds (B1).  Background: perl-signals-findings.md.  The interface (new, begin, end, read, write,
# child, cancel, wait) is the one every backend has.
use strict; use warnings;
use POSIX ();
use Fcntl qw(F_SETFD FD_CLOEXEC F_GETFL F_SETFL O_NONBLOCK);
use Proc::Spawner ();   # (its XS: chld_to_fd, chld_restore)
our $VERSION = '0.11';

my $CHLD_C = defined &Proc::Spawner::chld_to_fd;
our $TICK = $CHLD_C ? undef : 0.05;   # the longest wait without a wake-up for SIGCHLD

sub new {
  my $self = bless { rd => {}, wr => {}, kid => {} }, shift;
  CORE::pipe($self->{self_r}, $self->{self_w}) or die "pipe: $!";
  for (@$self{qw(self_r self_w)}) { fcntl($_, F_SETFD, FD_CLOEXEC); fcntl($_, F_SETFL, fcntl($_, F_GETFL, 0) | O_NONBLOCK) }
  my $w = $self->{self_w};
  $self->{chld} = POSIX::SigAction->new(sub { syswrite $w, 'x' }, POSIX::SigSet->new, POSIX::SA_RESTART());
  $self->{chld}->safe(1);   # the fallback: deferred; POSIX::sigaction's immediate default corrupts the heap (S2)
  $self }
sub begin { my $self = shift; $self->{old} = POSIX::SigAction->new;
  $CHLD_C ? Proc::Spawner::chld_to_fd(fileno $self->{self_w}) : POSIX::sigaction(POSIX::SIGCHLD(), $self->{chld}, $self->{old}) }
sub end { my $self = shift; $CHLD_C ? Proc::Spawner::chld_restore() : POSIX::sigaction(POSIX::SIGCHLD(), $self->{old}) }

sub read { my ($self, $id, $fd, $max) = @_; $self->{rd}{$id} = [Proc::Spawner::Loop::fd_of($fd), $max] }
sub write {   # a handle is made non-blocking; an fd number is left as it is (CHUNK: at most so many bytes per write)
  my ($self, $id, $fd, $bytes, $chunk) = @_;
  fcntl($fd, F_SETFL, fcntl($fd, F_GETFL, 0) | O_NONBLOCK) if ref $fd;
  $self->{wr}{$id} = [Proc::Spawner::Loop::fd_of($fd), $bytes, $chunk] }
sub child { my ($self, $id, $pid) = @_; $self->{kid}{$id} = $pid }
sub cancel { my ($self, $id) = @_; delete $self->{$_}{$id} for qw(rd wr kid) }

sub reap {   # our children only: waitpid(-1) would take statuses that are not ours (C2)
  my $self = shift; my @e;
  for my $id (sort { $a <=> $b } keys %{$self->{kid}}) {
    my $pid = $self->{kid}{$id}; my $r = waitpid $pid, POSIX::WNOHANG(); next unless $r;
    my $w = $r > 0 ? $? : undef; delete $self->{kid}{$id};
    Proc::Spawner::Loop::tr_("reaped $pid: ", defined $w ? "wait status $w" : 'status taken by other code');
    push @e, [$id, $w] }
  @e }

sub wait {   # the events of one round: [ID, ARGS...], at most TIMEOUT seconds (undef: until there is one)
  my ($self, $timeout) = @_;
  my @e = $self->reap; return @e if @e;
  $timeout = $TICK if defined $TICK && (!defined $timeout || $timeout > $TICK);
  my ($rd, $wr) = @$self{qw(rd wr)};
  my $rin = ''; vec($rin, $_, 1) = 1 for fileno $self->{self_r}, map $_->[0], values %$rd;
  my $win = ''; vec($win, $_->[0], 1) = 1 for values %$wr;
  my $n = select my $rout = $rin, my $wout = $win, undef, $timeout;
  1 while sysread $self->{self_r}, my $buf, 512;
  return $self->reap if $n <= 0;   # timeout, or EINTR (SIGCHLD): the sets say nothing
  my %served;                   # one reader per fd and round, the oldest first
  for my $id (sort { $a <=> $b } keys %$rd) {
    my ($fd, $len) = @{$rd->{$id}};
    next if $served{$fd}++ or !vec($rout, $fd, 1);
    my $got = POSIX::read($fd, my $bytes, $len);
    next if !defined $got && $! == POSIX::EAGAIN();
    delete $rd->{$id};
    push @e, [$id, defined $got && $got + 0 ? $bytes : undef, defined $got ? () : $! + 0] }   # ("0 but true": end of file)
  for my $id (sort { $a <=> $b } keys %$wr) {
    my $w = $wr->{$id}; next unless vec($wout, $w->[0], 1);
    my $did = POSIX::write($w->[0], $w->[1], $w->[2] && $w->[2] < length $w->[1] ? $w->[2] : length $w->[1]);
    next if !defined $did && $! == POSIX::EAGAIN();
    if (!defined $did) { delete $wr->{$id}; push @e, [$id, $! + 0]; next }   # (the reader is gone: the rest is dropped)
    substr($w->[1], 0, $did) = '';
    delete $wr->{$id}, push @e, [$id] if $w->[1] eq '' }
  (@e, $self->reap) }

sub pipe { CORE::pipe(my $r, my $w) or return; ($r, $w) }   # (overlapped => ...: nothing to do here)

1;
