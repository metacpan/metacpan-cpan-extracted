package Mojo::IOLoop::Thread;
use Mojo::Base -base;

our $VERSION = "0.06";

use threads;

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

use Carp 'croak';
use Config;
use Storable;

has deserialize => sub { \&Storable::thaw };
has ioloop      => sub { Mojo::IOLoop->singleton };
has serialize   => sub { \&Storable::freeze };
has pid         => sub { $$ };

sub run {
  my ($self, $child, $parent) = @_;

  my($thr) = threads->create(
    {'exit' => 'thread_only'},
    sub {
      $self->ioloop->reset;
      my $results = eval { [$self->$child] } || [];
      return $@, $results;
    }
  );

  my($err, $results) = $thr->join();

  $self->$parent($err, @$results);

  return $self;
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

Copyright 2017 Thomas Kratz.

=head1 LICENSE

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
