package Proc::tored::Pool::Manager;
# ABSTRACT: OO interface to creating a managed worker pool service
$Proc::tored::Pool::Manager::VERSION = '0.07';

use strict;
use warnings;

use Moo;
use Carp;
use Types::Standard -types;
use Type::Utils qw(declare as where);
use Try::Tiny;
use Time::HiRes 'sleep';
use Parallel::ForkManager;
use Proc::tored::Pool::Constants ':events';
use Proc::tored::Pool::Types -types;

extends 'Proc::tored::Manager';


has workers => (
  is  => 'ro',
  isa => PosInt,
  required => 1,
);


has on_assignment => (
  is  => 'ro',
  isa => Maybe[CodeRef],
);


has on_success => (
  is  => 'ro',
  isa => Maybe[CodeRef],
);


has on_failure => (
  is  => 'ro',
  isa => Maybe[CodeRef],
);


has pending => (
  is  => 'ro',
  isa => Int,
  default => 0,
  init_arg => undef,
);

sub trigger {
  my ($self, $event, $ident, @args) = @_;
  Event->assert_valid($event);
  my $acc = $self->can("on_$event") or die "unknown event type: $event";
  if (my $cb = $self->$acc()) {
    try { $cb->($self, $ident, @args) }
    catch { warn "error triggering callback for task $ident: $_" };
  }
}

has forkmgr => (
  is  => 'lazy',
  isa => InstanceOf['Parallel::ForkManager'],
  init_arg => undef,
);

sub _build_forkmgr {
  my $self = shift;
  my $pm = Parallel::ForkManager->new($self->workers);

  $pm->run_on_start(sub {
    my ($pid, $ident) = @_;
    ++$self->{pending};
    $self->trigger(assignment, $ident);
  });

  $pm->run_on_finish(sub {
    my ($pid, $code, $ident, $signal, $core, $data) = @_;
    --$self->{pending};

    # Task completed successfully
    if ($code == 0) {
      # Task returned data
      if ($data) {
        my ($success, @results) = @$data;
        if ($success) {
          $self->trigger(success, $ident, @results);
        }
        else {
          $self->trigger(failure, $ident, @results);
        }
      }
      # No data was returned - likely the result of an exec
      else {
        $self->trigger(success, $ident, '0 but true');
      }
    }
    else {
      $self->trigger(failure, $ident, "worker terminated with exit code $code (signal $signal)");
    }
  });

  return $pm;
}


sub assign {
  my $self = shift;
  my $code = shift;

  push @_, sub {
    try   { [1, $code->(@_)] }
    catch { [0, $_] };
  };

  $self->forkmgr->wait_for_available_procs(1);
  $self->forkmgr->start_child(@_);
  $self->forkmgr->wait_children; # triggers pending callbacks w/o blocking
  return 1;
}


sub sync {
  my $self = shift;
  $self->forkmgr->wait_all_children;
}

after service => sub { shift->sync };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Proc::tored::Pool::Manager - OO interface to creating a managed worker pool service

=head1 VERSION

version 0.07

=head1 SYNOPSIS

  use Proc::tored::Pool::Manager;

  my $manager = Proc::tored::Pool::Manager->new(
    name => 'thing-doer',
    dir => '/var/run',
    workers => 8,
    on_assignment => sub {
      my ($self, $id) = @_;
      ...
    },
    on_success => sub {
      my ($self, $id, @results) = @_;
      ...
    },
    on_failure => sub {
      my ($self, $id, $error) = @_;
      ...
    },
  );

  # Submit tasks to the pool
  $manager->service(sub {
    my ($thing_id, $thing) = next_thing();
    $manager->assign(sub { do_stuff_with($thing) }, $thing_id);
  });

  # Wait for all pending tasks to complete
  $manager->sync;

=head1 DESCRIPTION

The C<Manager> is the object created L<Proc::tored::Pool/pool>. It extends
L<Proc::tored::Manager>.

=head1 ATTRIBUTES

=head2 workers

Specifies the size of the pool of forked processes. Processes are forked as
needed and used only once.

=head2 on_assignment

A code ref that is called when a task has been submitted to the worker pool.
Receives the manager instance and the task id if submitted.
to L</assign>.

=head2 on_success

A code ref that is triggered when a task's result has been collected. Receives
the manager instance, the task id (if submitted), and any return value(s) from
the submitted code block. If no values were returned from the code block, the
results will be an empty list.

  Proc::tored::Manager->new(
    ...
    on_success => sub {
      my ($me, $id, @results) = @_;
      if (@results) {
        ...
      }
    },
  );

If the code ref passed to L</assign> performs an C<exec>, the results array
will be replaced with zero-but-true when the worker process exits with a zero
exit status. This is to (attempt to) avoid confusion in code where an assigned
task may or may not C<exec>.

  on_success => sub {
    my ($me, $id, @results) = @_;

    # Task exited cleanly but without a return value
    if (@results == 1 && $results->[0]) {
      ...
    }
  }

=head2 on_failure

A code ref that is triggered when a task died during execution or exited
abnormally. Receives the manager instance, the task id (if submitted), and the
error message.

=head2 pending

Returns the number of tasks that have been submitted but whose results have not
yet been collected.

=head2 assign

Submits a task (a C<CODE> ref) to the worker pool, optionally accepting a task
id (something string-like).

=head2 sync

Blocks until all submitted tasks have completed and their results have been
collected.

=head1 AUTHOR

Jeff Ober <jeffober@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jeff Ober.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
