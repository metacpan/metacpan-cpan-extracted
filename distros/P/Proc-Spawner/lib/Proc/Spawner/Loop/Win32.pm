package Proc::Spawner::Loop::Win32;
# EXPERIMENTAL (W5, post-0.10; the user, 2026-11-08: "Use the Windows' way").  The Windows backend of
# Proc::Spawner::Loop: one I/O completion port (win_loop.h, through Proc::Spawner's XSUBs __wl_*).  Overlapped I/O on a
# handle opened for it; a helper thread for a synchronous handle; RegisterWaitForSingleObject for a child's end, whose
# status then comes from waitpid.  The interface (new, begin, end, read, write, child, cancel, wait, pipe) is the one
# every backend has.
use strict; use warnings;
use POSIX ();
use Proc::Spawner ();   # (its XSUBs __wl_io, __wl_child, __wl_cancel, __wl_wait, __wl_pipe)
our $VERSION = '0.11';
our $CTRL = 1;   # wake up for Ctrl-C (and the other console control events) while wait_until runs

sub new { bless { kid => {}, now => [] }, shift }
sub begin { Proc::Spawner::__wl_ctrl(1) if $CTRL }   # (process-wide while wait_until runs, as SIGCHLD on POSIX: D3)
sub end { Proc::Spawner::__wl_ctrl(0) }

sub failed { my ($self, @e) = @_; push @{$self->{now}}, [@e]; return }   # an event for the next wait: an operation that
                                                                          # could not start
sub read { my ($self, $id, $fd, $max) = @_;
  Proc::Spawner::__wl_io($id, 'r', Proc::Spawner::Loop::fd_of($fd), $max) or $self->failed($id, undef, $! + 0) }
sub write { my ($self, $id, $fd, $bytes) = @_;
  Proc::Spawner::__wl_io($id, 'w', Proc::Spawner::Loop::fd_of($fd), $bytes) or $self->failed($id, $! + 0) }
sub child { my ($self, $id, $pid) = @_;
  $self->{kid}{$id} = $pid;
  Proc::Spawner::__wl_child($id, $pid) or $self->failed($id, $self->status(delete $self->{kid}{$id})) }
sub cancel { my ($self, $id) = @_;
  Proc::Spawner::__wl_cancel($id); delete $self->{kid}{$id}; @{$self->{now}} = grep $_->[0] != $id, @{$self->{now}} }

sub status {   # the wait status of an ended child, or undef if other code took it
  my ($self, $pid) = @_;
  my $r = waitpid $pid, POSIX::WNOHANG(); my $w = $r > 0 ? $? : undef;
  Proc::Spawner::Loop::tr_("reaped $pid: ", defined $w ? "wait status $w" : 'status taken by other code');
  $w }

sub wait {   # the events of one round: [ID, ARGS...], at most TIMEOUT seconds (undef: until there is one, or a console
  my ($self, $timeout) = @_;   # control event for Perl's signal handling, or a slice while an alarm is set: win_loop.h)
  if (my @e = splice @{$self->{now}}) { return @e }
  map { my ($id, $kind, $bytes, $err) = @$_;
        $kind eq 'r' ? [$id, $bytes, $err ? $err : ()]
      : $kind eq 'w' ? [$id, $err ? $err : ()]
      : [$id, $self->status(delete $self->{kid}{$id})] } Proc::Spawner::__wl_wait(defined $timeout ? int($timeout * 1000 + 0.5) : -1) }

sub pipe {   # (READ, WRITE) handles; overlapped => 'r', 'w' or 'rw': those ends opened for overlapped I/O
  my ($self, %o) = @_; my $ov = $o{overlapped} // '';
  my ($r, $w) = Proc::Spawner::__wl_pipe($ov =~ /r/ ? 1 : 0, $ov =~ /w/ ? 1 : 0) or return;
  open my $rh, '<&=', $r or return; open my $wh, '>&=', $w or return;
  binmode $_ for $rh, $wh; ($rh, $wh) }

1;
