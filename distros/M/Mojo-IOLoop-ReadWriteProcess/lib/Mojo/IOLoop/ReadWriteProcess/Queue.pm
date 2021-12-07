package Mojo::IOLoop::ReadWriteProcess::Queue;
use Mojo::Base -base;
use Mojo::IOLoop::ReadWriteProcess::Pool;
use Mojo::IOLoop::ReadWriteProcess;
use Mojo::IOLoop::ReadWriteProcess::Session;

use constant DEBUG => $ENV{MOJO_PROCESS_DEBUG};

has queue   => sub { Mojo::IOLoop::ReadWriteProcess::Pool->new() };
has pool    => sub { Mojo::IOLoop::ReadWriteProcess::Pool->new() };
has done    => sub { Mojo::IOLoop::ReadWriteProcess::Pool->new() };
has session => sub { Mojo::IOLoop::ReadWriteProcess::Session->singleton };

sub _dequeue {
  my ($self, $process) = @_;

  $self->pool($self->pool->grep(sub { $process ne $_ }));
  shift @{$self->queue}
    if ($self->queue->first && $self->pool->add($self->queue->first));
}

sub exhausted { $_[0]->pool->size == 0 && shift->queue->size == 0 }

sub consume {
  my $self = shift;
  $self->session->enable;
  $self->done->maximum_processes(
    $self->queue->maximum_processes + $self->pool->maximum_processes);
  until ($self->exhausted) {
    sleep .5;
    $self->session->consume_collected_info;
    $self->session->_protect(
      sub {
        $self->pool->each(
          sub {
            my $p = shift;
            return unless $p;
            return if exists $p->{started};
            $p->{started}++;
            $p->once(stop => sub { $self->done->add($p); $self->_dequeue($p) });
            $p->start;
          });
      });
  }
}

sub add {
  my $self = shift;
  $self->pool->add(@_) // $self->queue->add(@_);
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
    ? eval { $self->queue->Mojo::IOLoop::ReadWriteProcess::Pool::_cmd(@_, $fn) }
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

    my $q = queue;

    $q->pool->maximum_processes(2); # Max 2 processes in parallel
    $q->queue->maximum_processes(10); # Max queue is 10

    $q->add( process sub { return 42 } ) for 1..7;

    # Subscribe to all "stop" events in the pool
    $q->once(stop => sub { $fired++; });

    # Consume the queue
    $q->consume();

    my $all = $q->done; # All processes, Mojo::Collection of Mojo::IOLoop::ReadWriteProcess

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
