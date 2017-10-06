package Mojo::IOLoop::ReadWriteProcess::Queue;
use Mojo::Base -base;
use Mojo::IOLoop::ReadWriteProcess::Pool;
use Mojo::IOLoop::ReadWriteProcess;

has queue => sub { Mojo::IOLoop::ReadWriteProcess::Pool->new() };
has pool  => sub { Mojo::IOLoop::ReadWriteProcess::Pool->new() };

has auto_start_add => 0;
has auto_start     => 1;

sub _dequeue {
  my $self    = shift;
  my $process = shift;

  $self->pool->remove($process);
  shift @{$self->queue}
    if ($self->queue->first && $self->add($self->queue->first));

  $self->pool->last->start if $self->auto_start;
}

sub exhausted { shift->pool->size == 0 }

sub consume {
  my $p = shift;
  until ($p->exhausted) {
    $p->start;
    $p->wait_stop;
  }
}

sub add {
  my $self = shift;
  return $self->queue->add(@_) unless $self->pool->add(@_);

  my $i = $self->pool->size - 1;
  $self->pool->last->once(stop => sub { $self->_dequeue($i) });
  $self->pool->last->start if $self->auto_start_add == 1;
  $self->pool->last;
}

sub AUTOLOAD {
  our $AUTOLOAD;
  my $fn = $AUTOLOAD;
  $fn =~ s/.*:://;
  return if $fn eq "DESTROY";
  my $self = shift;
  return (
    eval { $self->pool->Mojo::IOLoop::ReadWriteProcess::Pool::_cmd(@_, $fn) },
    (grep(/once|on|emit/, $fn))
    ?
      eval { $self->queue->Mojo::IOLoop::ReadWriteProcess::Pool::_cmd(@_, $fn) }
    : ());
}

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::Queue - Queue for Mojo::IOLoop::ReadWriteProcess objects.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess qw(queue process);
    my $n_proc = 20;
    my $fired;

    my $q = queue auto_start => 1;

    $q->pool->maximum_processes(2); # Max 2 processes in parallel
    $q->queue->maximum_processes(10); # Max queue is 10

    $q->add( process sub { return 42 } ) for 1..7;

    # Subscribe to all "stop" events in the pool
    $q->once(stop => sub { $fired++; });

    # Consume the queue
    $q->consume();

    # Set your own running pool
    $q->pool(parallel sub { return 42 } => 5);

    # Set your own queue
    $q->queue(parallel sub { return 42 } => 20);

    $q->consume();

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::Queue> inherits all methods from L<Mojo::Base> and implements
the following new ones.
Note: It proxies all the other methods of L<Mojo::IOLoop::ReadWriteProcess> for the whole process group.

=head2 add

    use Mojo::IOLoop::ReadWriteProcess qw(queue process);
    my $q = queue();
    $q->add(sub { print "Hello 2! " });
    $q->add(process sub { print "Hello 2! " });

Add the process to the queue.

=head2 consume

    use Mojo::IOLoop::ReadWriteProcess qw(queue);
    my $q = queue();
    $q->add(sub { print "Hello 2! " });
    $q->add(process sub { print "Hello 2! " });
    $q->consume; # executes and exhaust the processes

Starts the processes and empties the queue.
Note: maximum_processes can be set both to the pool (number of process to be run in parallel),
and for the queue (that gets exhausted during the C<consume()> phase).

    $q->pool->maximum_processes(2); # Max 2 processes in parallel
    $q->queue->maximum_processes(10); # Max queue is 10

=head2 exhausted

    use Mojo::IOLoop::ReadWriteProcess qw(queue);
    my $q = queue();
    $q->add(sub { print "Hello 2! " });
    $q->add(process sub { print "Hello 2! " });
    $q->consume; # executes and exhaust the processes
    $q->exhausted; # 1

Returns 1 if the queue is exhausted.

=head1 ENVIRONMENT

You can set the MOJO_PROCESS_MAXIMUM_PROCESSES environment variable to specify the
the maximum number of processes allowed in the pool and the queue, that are
L<Mojo::IOLoop::ReadWriteProcess::Pool> instances.

    MOJO_PROCESS_MAXIMUM_PROCESSES=10000

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut
