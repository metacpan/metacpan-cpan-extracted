package Mojo::IOLoop::ReadWriteProcess::Session;

use Mojo::Base 'Mojo::EventEmitter';
use Mojo::IOLoop::ReadWriteProcess;
use Carp 'confess';
use POSIX qw( :sys_wait_h :signal_h );
use Mojo::Collection 'c';

our @EXPORT_OK = qw(session);
use Exporter 'import';

use Config;

use constant DEBUG => $ENV{MOJO_PROCESS_DEBUG};

# See https://github.com/torvalds/linux/blob/master/include/uapi/linux/prctl.h
use constant PR_SET_CHILD_SUBREAPER => 36;
use constant PR_GET_CHILD_SUBREAPER => 37;

has subreaper      => 0;
has collect_status => 1;
has orphans        => sub { {} };
has process_table  => sub { {} };
has 'handler';

my $singleton;
sub new { $singleton ||= shift->SUPER::new(@_); }

sub disable {
  $singleton->_protect(sub { $SIG{CHLD} = $singleton->handler() });
}

sub _protect {
  my $cb       = pop;
  my $sigset   = POSIX::SigSet->new;
  my $blockset = POSIX::SigSet->new(SIGCHLD);
  sigprocmask(SIG_BLOCK, $blockset, $sigset);
  my $r = $cb->();
  sigprocmask(SIG_SETMASK, $sigset);
  return $r;
}

sub enable {
  $singleton->handler($SIG{CHLD});
  $singleton->_protect(
    sub {
      $SIG{CHLD} = sub {
        local ($!, $?);
        $singleton->emit('SIG_CHLD');
        return unless $singleton->collect_status;
        while ((my $pid = waitpid(-1, WNOHANG)) > 0) {
          $singleton->collect($pid => $? => $!);
        }
        }
    });
}

sub _collect {
  my ($self, $pid, $status, $errno) = @_;
  my $p = $singleton->resolve($pid);
  $p->emit('SIG_CHLD')->emit(collect_status => $pid => $status => $errno)
    ->emit('collected')->emit('stop');
}

sub collect {
  my ($errno, $status, $pid) = (pop, pop, pop);
  if ($singleton->resolve($pid)) {
    $singleton->_collect($pid => $status => $errno);
    $singleton->emit(collected => $singleton->resolve($pid));

  }
  else {
    $singleton->orphans->{$pid}
      = Mojo::IOLoop::ReadWriteProcess->new(process_id => $pid)
      ->_fork_collect_status($pid => $status => $errno);
    $singleton->emit(collected_orphan => $singleton->orphan($pid));
  }
  return $singleton;
}

# Use as $pid => Mojo::IOLoop::ReadWriteProcess
sub register {
  my ($process, $pid) = (pop, pop);
  $singleton->process_table()->{$pid} = \$process;
  $singleton->emit(register => $process);
}

sub unregister { delete($singleton->process_table()->{+pop()}) }

sub _resolve {
  my ($el, $w) = (pop, pop);
  return
    exists $singleton->{$w}->{$el} ?
    $el eq 'orphan'
      ? $singleton->{$w}->{$el}
      : ${$singleton->{$w}->{$el}}
    : undef;
}
sub orphan  { _resolve(orphan        => pop()) }
sub resolve { _resolve(process_table => pop()) }

sub clean {
  $_[0]->resolve($_)->stop() and $_[0]->resolve($_)->DESTROY()
    for keys %{$_[0]->process_table()};
  $_[0]->orphan($_)->stop() and $_[0]->orphan($_)->DESTROY()
    for keys %{$_[0]->orphans()};
  shift->reset();
}

sub all { c($singleton->all_processes, $singleton->all_orphans)->flatten }
sub all_orphans { c(values %{$singleton->orphans}) }

sub all_processes {
  c(values %{$singleton->process_table})->map(sub { ${$_} });
}

sub contains {
  my $pid = pop;
  $singleton->all->grep(sub { $_->pid eq $pid })->size == 1;
}

sub reset {
  $_[0]->{events} = {};
  $_[0]->orphans({});
  shift->process_table({});
}

sub disable_subreaper {
  $singleton->subreaper(1)
    unless $singleton->_prctl(PR_SET_CHILD_SUBREAPER, 0) == 0;
  $singleton;
}

sub enable_subreaper {
  $singleton->subreaper(0)
    unless $singleton->_prctl(PR_SET_CHILD_SUBREAPER, 1) == 0;
  $singleton;
}

sub _get_prctl_syscall {

  # Courtesy of Sys::Prctl
  confess "Only Linux is supported" unless $^O eq 'linux';

  my $machine = (POSIX::uname())[4];
  die "Could not get machine type" unless $machine;

  # if we're running on an x86_64 kernel, but a 32-bit process,
  # we need to use the i386 syscall numbers.
  $machine = "i386" if ($machine eq "x86_64" && $Config{ptrsize} == 4);

  my $prctl_call
    = $machine
    =~ /^i[3456]86|^blackfin|cris|frv|h8300|m32r|m68k|microblaze|mn10300|sh|s390|parisc$/
    ? 172
    : $machine eq "x86_64"  ? 157
    : $machine eq "sparc64" ? 147
    : $machine eq "ppc"     ? 171
    : $machine eq "ia64"    ? 1170
    : $machine eq "alpha"   ? 348
    : $machine eq "arm"     ? 0x900000 + 172
    : $machine eq "avr32"   ? 148
    : $machine eq "mips"    ? 4000 + 192
    : $machine eq "mips64"  ? 5000 + 153
    : $machine eq "xtensa"  ? 130
    :                         undef;

  unless (defined $prctl_call) {
    delete @INC{
      qw<syscall.ph asm/unistd.ph bits/syscall.ph _h2ph_pre.ph
        sys/syscall.ph>
    };
    my $rv = eval { require 'syscall.ph'; 1 }     ## no critic
      or eval { require 'sys/syscall.ph'; 1 };    ## no critic

    $prctl_call = eval { &SYS_prctl; };
  }
  return $prctl_call;
}

sub _prctl {
  my ($self, $option, $arg2, $arg3, $arg4, $arg5) = @_;
  confess 'prctl not supported in this platform!'
    unless defined _get_prctl_syscall;
  local $!;
  my $ret = syscall(
    _get_prctl_syscall(), $option,
    ($arg2 or 0),
    ($arg3 or 0),
    ($arg4 or 0),
    ($arg5 or 0));

  warn "prctl($option) is unavailable on this platform." if $!{EINVAL};
  warn "Error! $!" if $!;
  return $ret;
}

*singleton = \&new;
*session   = \&new;

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::Session - Session manager for handling child processes.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::Session;
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $session = process()->session; # or Mojo::IOLoop::ReadWriteProcess::Session->singleton

    $session->enable; # Modifies your SIG_CHLD

    $session->on(collected => sub { warn "Process ".(shift->pid)." collected! "});
    $session->on(collected_orphan => sub { warn "Orphan process collected! "});

    $session->enable_subreaper(); # Mark the current process as subreaper
    $session->disable_subreaper(); # Disable subreaper

    $session->reset(); # Resets events and clear the process tables
    $session->clean(); # Stop all processes that result as running and reset


=head1 DESCRIPTION

Mojo::IOLoop::ReadWriteProcess::Session is a session manager for the collected processes

=head1 EVENTS

L<Mojo::IOLoop::ReadWriteProcess::Session> inherits all events from L<Mojo::EventEmitter> and can emit
the following new ones.

=head2 SIG_CHLD

 $session->on(SIG_CHLD => sub {
   my ($self) = @_;
   ...
 });

Emitted when we receive SIG_CHLD.

=head2 collected

    $session->on(collected => sub {
      my ($self, $process) = @_;
      ...
    });

Emitted when child process is collected and it's return status is available.

=head2 collected_orphan

    $session->on(collected_orphan => sub {
      my ($self, $process) = @_;
      $process->pid;
      $process->exit_status;
      ...
    });

Emitted when child process is collected and it's exit status is available.
Note: here are collected processes that weren't created with L<Mojo::IOLoop::ReadWriteProcess>.

=head2 register

    $session->on(register => sub {
      my ($self, $process) = @_;
      $process->pid;
      $process->exit_status;
      ...
    });

Emitted when a process is registering to a session.

=head1 ATTRIBUTES

L<Mojo::IOLoop::ReadWriteProcess::Session> inherits all attributes from L<Mojo::EventEmitter> and implements
the following new ones.


=head2 subreaper

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    session->enable_subreaper;
    my $process = Mojo::IOLoop::ReadWriteProcess->new(code => sub { print "Hello ".shift() }, args => "User" );
    $process->start();
    $process->on( stop => sub { $_->disable_subreaper } );
    $process->stop();

    # The process will print "Hello User"

Mark the current process (not the child) as subreaper on start.
It's on invoker behalf to disable subreaper when process stops, as it marks the current process and not the
child.

=head2 collect_status

Defaults to C<1>, If enabled it will automatically collect the status of the children process.
Disable it in case you want to manage your process child directly, and do not want to rely on
automatic collect status. If you won't overwrite your C<SIGCHLD> handler,
the C<SIG_CHLD> event will be still emitted.

=head2 handler()

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    session->handler(sub {});

Default handler for SIG_CHLD processing, used when C<disable()> is invoked.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::Session> inherits all methods from L<Mojo::EventEmitter> and implements
the following new ones.

=head2 enable()

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    session->enable();

Sets the SIG_CHLD handler.

=head2 disable()

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    session->disable();

Disables the SIG_CHLD handler and reset with the previous one.

=head2 enable_subreaper()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process()->enable_subreaper;
    # or
    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    session->enable_subreaper;

Mark the current process (not the child) as subreaper.
This is used typically if you want to mark further childs as subreapers inside other forks.

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);

    my $master_p = process(
      sub {
        my $p = shift;
        $p->enable_subreaper;

        process(sub { sleep 4; exit 1 })->start();
        process(
          sub {
            sleep 4;
            process(sub { sleep 1; })->start();
          })->start();
        process(sub { sleep 4; exit 0 })->start();
        process(sub { sleep 4; die })->start();
        my $manager
          = process(sub { sleep 2 })->subreaper(1)->start();
        sleep 1 for (0 .. 10);
        $manager->stop;
        return session->all->size;
      });

    $master_p->subreaper(1);
    $master_p->on(collect_status => sub { $status++ });

    $master_p->on(stop => sub { shift()->disable_subreaper });
    $master_p->start();
    session->all->size();
    ....

=head2 disable_subreaper()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process()->disable_subreaper;

Unset the current process as subreaper.

=head2 prctl()

    use Mojo::IOLoop::ReadWriteProcess qw(process);
    my $p = process();
    $p->prctl($option, $arg2, $arg3, $arg4, $arg5);

Internal function to execute and wrap the prctl syscall, accepts the same arguments as prctl.

=head2 reset()

    use Mojo::IOLoop::ReadWriteProcess qw(session);
    session->reset;

Wipe the process tables.

=head2 clean()

    use Mojo::IOLoop::ReadWriteProcess qw(session);
    session->clean;

Wipe the process tables, but before attempt to stop running procesess.

=head2 all()

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    my $collection = session->all;
    $collection->size;

Returns a L<Mojo::Collection> of L<Mojo::IOLoop::ReadWriteProcess> that belongs to a session.

=head2 all_orphans()

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    my $collection = session->all_orphans;
    $collection->size;

Returns a L<Mojo::Collection> of L<Mojo::IOLoop::ReadWriteProcess> of orphaned processes that belongs to a session.
They are automatically turned into a L<Mojo::IOLoop::ReadWriteProcess>, also if processes were created by C<fork()>.

=head2 all_processes()

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    my $collection = session->all_processes;
    $collection->size;

Returns a L<Mojo::Collection> of all L<Mojo::IOLoop::ReadWriteProcess> known processes that belongs to a session.

=head2 contains()

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    my $collection = session->contains(13443);
    $collection->size;

Returns true if the pid is contained in any of the process tables.

=head2 resolve()

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    my $process = session->resolve(12233);

Returns the L<Mojo::IOLoop::ReadWriteProcess> process identified by its pid if belongs to the process table.

=head2 orphan()

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    my $process = session->orphan(12233);

Returns the L<Mojo::IOLoop::ReadWriteProcess> process identified by its pid if belongs to the process table of unknown processes.

=head2 register()

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    my $process = session->register(Mojo::IOLoop::ReadWriteProcess->new);

Register the L<Mojo::IOLoop::ReadWriteProcess> process to the session.

=head2 unregister()

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    my $process = session->unregister(123342);

Unregister the corresponding L<Mojo::IOLoop::ReadWriteProcess> with the given pid.

=head2 collect()

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    my $process = session->collect(123342, 0, undef);

Collect the status for the given pid.

=head1 EXPORTS

=head2 session()

    use Mojo::IOLoop::ReadWriteProcess::Session qw(session);
    session->enable_subreaper;

Returns the L<Mojo::IOLoop::ReadWriteProcess::Session> singleton.

=head1 DEBUGGING

You can set the MOJO_EVENTEMITTER_DEBUG environment variable to get some advanced diagnostics information printed to STDERR.

    MOJO_EVENTEMITTER_DEBUG=1

Also, you can set MOJO_PROCESS_DEBUG environment variable to get diagnostics about the process execution.

    MOJO_PROCESS_DEBUG=1

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut
