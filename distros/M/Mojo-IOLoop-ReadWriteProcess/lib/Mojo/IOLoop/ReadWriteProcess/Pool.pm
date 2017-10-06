package Mojo::IOLoop::ReadWriteProcess::Pool;
use Mojo::Base 'Mojo::Collection';
use constant MAXIMUM_PROCESSES => $ENV{MOJO_PROCESS_MAXIMUM_PROCESSES} // 100;
use Scalar::Util qw(blessed);

my %max_proc;

sub new {
  my $s = shift->SUPER::new(@_);
  $max_proc{$s} = MAXIMUM_PROCESSES;
  $s;
}

sub get    { @{$_[0]}[$_[1]] }
sub remove { delete @{$_[0]}[$_[1]] }

sub add {
  return undef unless $_[0]->size < $max_proc{$_[0]};
  my $self = shift;
  push @{$self},
    blessed $_[0] ? $_[0] : Mojo::IOLoop::ReadWriteProcess->new(@_);
  $self->last;
}

sub maximum_processes {
  $max_proc{$_[0]} = pop() if $_[1];
  $max_proc{$_[0]};
}

sub _cmd {
  my $c    = shift;
  my $f    = pop;
  my @args = @_;
  my @r;
  $c->each(sub { push(@r, +shift()->$f(@args)) });
  wantarray ? @r : $c;
}

sub AUTOLOAD {
  our $AUTOLOAD;
  my $fn = $AUTOLOAD;
  $fn =~ s/.*:://;
  return if $fn eq "DESTROY";
  return eval { shift->_cmd(@_, $fn) };
}

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::Pool - Pool of Mojo::IOLoop::ReadWriteProcess objects.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess qw(parallel);
    my $n_proc = 20;
    my $fired;

    my $p = parallel sub { print "Hello world\n"; } => $n_proc;

    # Subscribe to all "stop" events in the pool
    $p->once(stop => sub { $fired++; });

    # Start all processes belonging to the pool
    $p->start();

    # Receive the process output
    $p->each(sub { my $p = shift; $p->getline(); });
    $p->wait_stop;

    # Get the last one! (it's a Mojo::Collection!)
    $p->last()->stop();

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::Pool> inherits all methods from L<Mojo::Collection> and implements
the following new ones.
Note: It proxies all the other methods of L<Mojo::IOLoop::ReadWriteProcess> for the whole process group.

=head2 get

    use Mojo::IOLoop::ReadWriteProcess qw(parallel);
    my $pool = parallel(sub { print "Hello" } => 5);
    $pool->get(4);

Get the element specified in the pool (starting from 0).

=head2 add

    use Mojo::IOLoop::ReadWriteProcess qw(pool);
    my $pool = pool(maximum_processes => 2);
    $pool->add(sub { print "Hello 2! " });

Add the element specified in the pool.

=head2 remove

    use Mojo::IOLoop::ReadWriteProcess qw(parallel);
    my $pool = parallel(sub { print "Hello" } => 5);
    $pool->remove(4);

Remove the element specified in the pool.

=head2 maximum_processes

    use Mojo::IOLoop::ReadWriteProcess qw(parallel);
    my $pool = parallel(sub { print "Hello" } => 5);
    $pool->maximum_processes(30);
    $pool->add(...);

Prevent from adding processes to the pool. If we reach C<maximum_processes> number
of processes, C<add()> will refuse to add more to the pool.

=head1 ENVIRONMENT

You can set the MOJO_PROCESS_MAXIMUM_PROCESSES environment variable to specify the
the maximum number of processes allowed in L<Mojo::IOLoop::ReadWriteProcess> instances.

    MOJO_PROCESS_MAXIMUM_PROCESSES=10000

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut
