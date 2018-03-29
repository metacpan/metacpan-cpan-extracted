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
            $_[0]->enable_subreaper if $self->subreaper;
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
    $self->process->diag(
      "Starting container: " . $self->group . " " . $self->name);
    $self->cgroups->each(sub { $self->process->diag("CGroups: " . $_->_cgroup) }
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

Mojo::IOLoop::ReadWriteProcess::Container - Start Mojo::IOLoop::ReadWriteProcess as containers.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);

    my $container = container(
      pid_isolation => 1,  # Best-effort, as depends on where you run it (you need CAP_SYS_ADMIN)
      subreaper => 1,
      group   => "my_org",
      name    => "my_process",
      process => process(
        sub {
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

    my @procs = $container->cgroup->processes;
    $container->cgroup->pid->max(300);

    $container->process->on(stop => sub { print "Main container process stopped!" });

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability (CAP_SYS_ADMIN) for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::Container> inherits all methods from L<Mojo::EventEmitter> and implements
the following new ones.

=head2 start

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container( name=>"test", process => process(sub { print "Hello!" }));
    $c->start();

Starts the container, it's main process is a L<Mojo::IOLoop::ReadWriteProcess>,
contained in the C<process()> attribute.

=head2 is_running

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container( name=>"test", process => process(sub { print "Hello!" }));
    $c->is_running();

Returns 1 if the container is running.

=head2 stop

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container( name=>"test", process => process(sub { print "Hello!" }))->start;
    $c->stop();

Stops the container and kill all the processes belonging to the cgroup.
It also registers all the unknown processes to the current L<Mojo::IOLoop::ReadWriteProcess::Session>.

=head2 wait_stop

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container( name=>"test", process => process(sub { print "Hello!" }))->start;
    $c->wait_stop();

Wait before stopping the container.

=head2 wait

    use Mojo::IOLoop::ReadWriteProcess::Container qw(container);
    use Mojo::IOLoop::ReadWriteProcess qw(process);

    my $c = container( name=>"test", process => process(sub { print "Hello!" }))->start;
    $c->wait();

Wait the container to stop

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut

1;
