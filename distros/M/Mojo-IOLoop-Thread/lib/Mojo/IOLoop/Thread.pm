package Mojo::IOLoop::Thread;
use Mojo::Base 'Mojo::EventEmitter';

our $VERSION = "0.09";

use threads;
use Thread::Queue;

use Scalar::Util qw(weaken);
use Mojo::IOLoop;
use Mojo::Util qw(monkey_patch);
BEGIN {
    ## no critic ( PrivateSubs )
    monkey_patch 'Mojo::IOLoop', subprocess => sub {
        my $thr = Mojo::IOLoop::Thread->new;
        weaken $thr->ioloop(Mojo::IOLoop::_instance(shift))->{ioloop};
        return $thr->run(@_);
    }
}

use Storable;

has deserialize => sub { \&Storable::thaw };
has ioloop      => sub { Mojo::IOLoop->singleton };
has serialize   => sub { \&Storable::freeze };

sub pid  { threads->tid() || shift->{pid}  };

sub run {
  my ($self, @args) = @_;
  $self->ioloop->next_tick(sub { $self->_start(@args) });
  return $self;
}

sub _start {
  my ($self, $child, $parent) = @_;

  $self->{queue} = Thread::Queue->new();
  my($thr) = threads->create(
    {'exit' => 'thread_only'},
    sub {
      my($q) = @_;
      $self->ioloop->reset;
      my $results = eval { [$self->$child] } || [];
      return $@, $results;
    },
  );
  $self->{pid} = $thr->tid();
  $self->emit('spawn');

  my $rid = $self->ioloop->recurring(0.05 => sub {
    while ( my $args = $self->{queue}->dequeue_nb() ) {
      $self->emit(progress => @$args);
    }
    $self->emit('joinable') if $thr->is_joinable();
    threads->yield();
  });

  $self->on('joinable' => sub {
    $self->ioloop->remove($rid);
    while ( my $args = $self->{queue}->dequeue_nb() ) {
      $self->emit(progress => @$args);
    }
    my($err, $results) = $thr->join();
    $self->$parent($err, @$results);
  });

  return $self;
}

sub progress {
  my ($self, @args) = @_;
  $self->{queue}->enqueue(\@args);
}

1;

__END__

=encoding utf-8

=head1 NAME

Mojo::IOLoop::Thread - Threaded Replacement for Mojo::IOLoop::Subprocess

=head1 SYNOPSIS

  use Mojo::IOLoop::Thread;

  # Operation that would block the event loop for 5 seconds
  my $subprocess = Mojo::IOLoop::Thread->new;
  $subprocess->run(
    sub {
      my $subprocess = shift;
      sleep 5;
      return '♥', 'Mojolicious';
    },
    sub {
      my ($subprocess, $err, @results) = @_;
      say "Subprocess error: $err" and return if $err;
      say "I $results[0] $results[1]!";
    }
  );

  # Start event loop if necessary
  $subprocess->ioloop->start unless $subprocess->ioloop->is_running;

or

  use Mojo::IOLoop;
  use Mojo::IOLoop::Thread;

  my $iol = Mojo::IOLoop->new;
  $iol->subprocess(
    sub {'♥'},
    sub {
      my ($subprocess, $err, @results) = @_;
      say "Subprocess error: $err" and return if $err;
      say @results;
    }
  );
  $loop->start;

=head1 DESCRIPTION

L<Mojo::IOLoop::Thread> is a multithreaded alternative for
L<Mojo::IOLoop::Subprocess> which is not available under Win32.
It is a dropin replacement, takes the same parameters and works
analoguous by just using threads instead of forked processes.

L<Mojo::IOLoop::Thread> replaces L<Mojo::IOLoop/subprocess> with a threaded
version on module load. Please make sure that you load L<Mojo::IOLoop> first.

=head1 AUTHOR

Thomas Kratz E<lt>tomk@cpan.orgE<gt>

=head1 REPOSITORY

L<https://github.com/tomk3003/mojo-ioloop-thread>

=head1 COPYRIGHT

Copyright 2017-18 Thomas Kratz.

=head1 LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
