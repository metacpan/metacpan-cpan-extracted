package Mojo::IOLoop::ReadWriteProcess::Container;

use Mojo::Base 'Mojo::EventEmitter';
use Mojo::IOLoop::ReadWriteProcess::CGroup;
use Mojo::IOLoop::ReadWriteProcess;
use Mojo::IOLoop::ReadWriteProcess::Namespace qw( CLONE_NEWPID CLONE_NEWNS );
use Mojo::IOLoop::ReadWriteProcess;
use Mojo::IOLoop::ReadWriteProcess::Session;
use Mojo::Collection 'c';
use Scalar::Util 'blessed';
our @EXPORT_OK = qw(container);
use Exporter 'import';

use Carp 'croak';
has 'name';
has 'group';

# Roughly a container
has process => sub { Mojo::IOLoop::ReadWriteProcess->new };
has cgroups => sub {
  c(Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new(controller => 'pids'));
};
has namespace     => sub { Mojo::IOLoop::ReadWriteProcess::Namespace->new };
has session       => sub { Mojo::IOLoop::ReadWriteProcess::Session->singleton };
has pid_isolation => sub { 0 };
has unshare       => undef;
has subreaper     => 0;
has pre_migrate   => 0;
has clean_cgroup  => 0;

use constant DEBUG => $ENV{MOJO_PROCESS_DEBUG};

sub container { __PACKAGE__->new(@_) }

sub new {
  my $self = shift->SUPER::new(@_);
  $self->cgroups(c($self->cgroups))
    unless blessed $self->cgroups && $self->cgroups->isa('Mojo::Collection');
  $self;
}

sub migrate_process {
  my $p = pop();
  shift->cgroups->each(sub { shift->add_process($p) });
}

sub start {
  my $self = shift;
  croak
'You need either to pass a Mojo::IOLoop::ReadWriteProcess object or a callback'
    unless (blessed $self->process
    && $self->process->isa("Mojo::IOLoop::ReadWriteProcess"))
    || ref $self->process eq 'CODE';

  $self->process(Mojo::IOLoop::ReadWriteProcess->new($self->process))
    unless blessed $self->process;

  $self->cgroups->map(
    sub {
      return $_ if $_->name || $_->parent;
      $_ = $_->name($self->group)->create if $self->group;
      $_ = $_->child($self->name)->create if $self->name;
    }) if defined $self->group || defined $self->name;

  $self->process->subreaper(1) if $self->subreaper;

  $self->unshare(CLONE_NEWPID | CLONE_NEWNS) if $self->pid_isolation;
  $self->process->once(
    start => sub {
      $self->migrate_process($self->process->pid);
    }) unless $self->pre_migrate;

  $self->process->once(
    stop => sub {
      $self->cgroups->each(
        sub {
          $_[0]->processes->each(
            sub {
              my $pid = shift;
              my $p   = Mojo::IOLoop::ReadWriteProcess->new(
                process_id    => $pid,
                blocking_stop => 1
              );
              $self->session->register($pid => $p);
              $p->stop();
            });
          $_[0]->remove() if $self->clean_cgroup;
        });
    });

  $self->process->once(stop  => sub { shift; $self->emit(stop  => @_) });
  $self->process->once(start => sub { shift; $self->emit(start => @_) });

  my $fn = $self->process->code();

  $self->process->code(sub { $self->migrate_process($$); $fn->(@_) })
    if $self->pre_migrate;

  $self->process->code(
    sub {
      $self->migrate_process($$) if $self->pre_migrate;

      if ( $self->unshare & CLONE_NEWPID
        && $self->namespace->unshare($self->unshare) == 0)
      {

        # In such case, we have to spawn another process
        my $init = Mojo::IOLoop::ReadWriteProcess->new(
          set_pipes      => 0,
          internal_pipes => 1,
          code           => sub {
            $_[0]->enable_subreaper     if $self->subreaper;
            $self->namespace->isolate() if $self->unshare & CLONE_NEWNS;
            $fn->(@_);
          });
        $init->start()->wait_stop;

        #return $init->return_status if defined $init->return_status;
        $init->_exit($init->exit_status);
      }
      elsif ($self->namespace->unshare($self->unshare) != 0) {
        warn "Unshare failed";
      }

      $fn->(@_);
    }) if defined $self->unshare;

  if (DEBUG) {
    $self->process->diag("Starting container");
    $self->process->diag("\tName: " . $self->name)   if defined $self->name;
    $self->process->diag("\tGroup: " . $self->group) if defined $self->group;
    $self->cgroups->each(sub { $self->process->diag("CGroup: " . $_->_cgroup) }
    );
  }

  local ($@, $!);
  eval { $self->process->start(); };
  $self->emit(container_error => [$@, $!]) if $@;

  $self;
}

sub stop { shift->emit('stop')->process->stop() }

sub is_running { shift->process->is_running }

sub wait_stop { shift->process->wait_stop }

sub wait { shift->process->wait }

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::Container - (kinda) Pure Perl containers.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $container = container(
      pid_isolation => 1,  # Best-effort, as depends on where you run it (you need CAP_SYS_ADMIN)
      subreaper => 1,
      group   => "my_org",
      name    => "my_process",
      process => process(
        sub {
          # Exec, fork ..
          process(sub { warn "\o/"; sleep 42;  })->start;
          process(sub { warn "\o/"; sleep 42; })->start;
          process(
            sub {
              process(
                sub {
                  process(sub { warn "\o/"; sleep 42; })->start;
                  warn "\o/";
                  sleep 400;
                  warn "\o/";
                })->start;
              warn "Hey";
              sleep 42;
              warn "\o/";
            })->start;
          sleep 42;
        }
      )->separate_err(0));

    $container->start();
    $container->is_running;
    $container->stop;

    my @procs = $container->cgroups->first->processes;
    $container->cgroups->first->pid->max(300);

    $container->process->on(stop => sub { print "Main container process stopped!" });

=head1 DESCRIPTION

L<Mojo::IOLoop::ReadWriteProcess::Container> ties anonymous functions or a L<Mojo::IOLoop::ReadWriteProcess> object to different
sets of L<Mojo::IOLoop::ReadWriteProcess::CGroup> implementations.

When the C<pid_isolation> attribute is set, it needs special permissions (CAP_SYS_ADMIN capabilities).
This module uses features that are only available on Linux, and requires cgroups and capability (CAP_SYS_ADMIN) for unshare syscalls to achieve pid isolation.

=head1 EVENTS

L<Mojo::IOLoop::ReadWriteProcess> inherits all events from L<Mojo::EventEmitter> and can emit
the following new ones.

=head2 start

 $container->on(start => sub {
   my ($process) = @_;
    ...
 });

Emitted when the container starts.

=head2 stop

 $container->on(stop => sub {
   my ($container) = @_;
   ...
 });

Emitted when the container stops.

=head2 process_error

 $container->on(container_error => sub {
   my ($e) = @_;
   my @errors = @{$e};
 });

Emitted when the container produce errors.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::Container> inherits all methods from L<Mojo::EventEmitter> and implements
the following new ones.

=head2 start

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container( name=>"test", process => sub { print "Hello!" });
    $c->start();

Starts the container, it's main process is a L<Mojo::IOLoop::ReadWriteProcess>,
contained in the C<process()> attribute. On stop it will terminate every process included in the L<cgroups> attribute.

=head2 is_running

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container( name=>"test", process => sub { print "Hello!" });
    $c->is_running();

Returns 1 if the container is running.

=head2 stop

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container( name=>"test", process => sub { print "Hello!" })->start;
    $c->stop();

Stops the container and kill all the processes belonging to the cgroup.
It also registers all the unknown processes to the current L<Mojo::IOLoop::ReadWriteProcess::Session>.

=head2 wait_stop

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container( name=>"test", process => sub { print "Hello!" })->start;
    $c->wait_stop();

Wait before stopping the container.

=head2 wait

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container( name=>"test", process => sub { print "Hello!" })->start;
    $c->wait();

Wait the container to stop

=head2 migrate_process

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container( name=>"test", process => sub { print "Hello!" })->start;
    $c->migrate_process(42);

Migrate the given process to the container cgroup.

=head1 ATTRIBUTES

L<Mojo::IOLoop::ReadWriteProcess::Container> inherits all attributes from L<Mojo::EventEmitter> and implements
the following new ones.

=head2 name

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);
    use Mojo::IOLoop::ReadWriteProcess::CGroup qw(cgroupv1);
    use Mojo::Collection 'c';

    my $container = container( name => "test", process => sub { print "Hello!" } );

    $container->session->on(register => sub { ... });
    $container->start();

Sets the container name. It creates in the indicated (or default) cgroups a sub-tree with the container name.

This means that cgroups settings can be done also outside of the container object:

    use Mojo::IOLoop::ReadWriteProcess::CGroup qw(cgroupv1);
    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);

    my $container = container( name => "test", process => sub { print "Hello!" } );

    cgroupv1->from($continer->cgroups->first->_group)->pid->max(100);

As cgroups are represented by path, you can set options directly from controllers objects that are pointing to the same cgroup slice.

=head2 group

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);
    use Mojo::IOLoop::ReadWriteProcess::CGroup qw(cgroupv2);
    use Mojo::Collection 'c';

    my $container = container( name => "bar", group => "foo", process => sub { print "Hello!" } );
    my $container2 = container( name => "bar2", group => "foo", process => sub { print "Hello!" } );

    $container->start();
    $container2->start();

    my $group_cgroup = cgroupv2->from($container2->cgroups->first->parent);

    $group_cgroup->pid->max(200);

Sets the container group. If containers are sharing the same group they will inherit the same CGroup parent path,
in such way it is possible to create controllers pointing to it and set specific options for the whole group.

=head2 pid_isolation

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);
    use Mojo::IOLoop::ReadWriteProcess::CGroup qw(cgroupv1);
    use Mojo::Collection 'c';

    my $container = container( pid_isolation => 1, process => sub { print "Hello!" } );

    $container->session->on(register => sub { ... });
    $container->start();

If set, the process will see itself as PID 1. It needs CAP_SYS_ADMIN capabilities set on the executable (or run as root).

=head2 pre_migrate

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $container = container( pre_migrate => 1, process => sub { print "Hello!" } );

    $container->session->on(register => sub { ... });
    $container->start();

If set, the process will migrate itself into the cgroup.

=head2 clean_cgroup

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $container = container( clean_cgroup => 1, process => sub { print "Hello!" });

    $container->session->on(register => sub { ... });
    $container->start();

If set, attempts to destroy the cgroup after the process terminated its execution.

=head2 subreaper

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container(subreaper => 1, name=>"test", process => sub { print "Hello!" });
    $c->start();

Enable subreaper mode inside the child process.

=head2 process

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container(process => sub { print "Hello!" });
    my $c = container(process => sub { print "Hello!" });

    $c->start();

The process to run. It can be an anonymous function or a L<Mojo::IOLoop::ReadWriteProcess> object.

=head2 namespace

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container(process => sub { print "Hello!" });
    $c->namespace->unshare(0); # All
    $c->start();

Set/Return L<Mojo::IOLoop::ReadWriteProcess::Namespace> object. It's main use is to invoke syscalls.

=head2 session

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container(process => process(sub { print "Hello!" }));
    $c->session->on(register => sub { ... });
    $c->start();

Returns/Set the L<Mojo::IOLoop::ReadWriteProcess::Session> singleton object.

=head2 unshare

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);
    use Mojo::IOLoop::ReadWriteProcess::Namespace qw( CLONE_NEWPID CLONE_NEWNS );

    my $c = container( unshare=> CLONE_NEWPID | CLONE_NEWNS, process => sub { print "Hello!" } );
    $c->session->on(register => sub { ... });
    $c->start();

Returns/Set the unshare syscall options. See man unshare(2) for further documentation.

=head2 cgroups

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);
    use Mojo::IOLoop::ReadWriteProcess::CGroup qw(cgroupv1);
    use Mojo::Collection 'c';

    my $container = container(process => sub { print "Hello!" });
    $container->cgroups( c(cgroupv1(controller => 'pids'), cgroupv1(controller => 'memory')) );

    $container->session->on(register => sub { ... });
    $container->start();

Returns/Set a L<Mojo::Collection> collection of CGroups where the process should belong to.
If used with a single CGroup, you don't need to pass the L<Mojo::Collection>  object:

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);
    use Mojo::IOLoop::ReadWriteProcess::CGroup qw(cgroupv1);
    use Mojo::Collection 'c';

    my $container = container(cgroups=> cgroupv1(controller => 'pids'), process => sub { print "Hello!" });

    $container->session->on(register => sub { ... });
    $container->start();

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

1;
