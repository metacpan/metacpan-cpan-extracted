package Role::EventEmitter;

use Carp 'croak';
use Scalar::Util qw(blessed refaddr weaken);
use constant DEBUG => $ENV{ROLE_EVENTEMITTER_DEBUG} || 0;

use Role::Tiny;

our $VERSION = '0.003';

sub catch { $_[0]->on(error => $_[1]) and return $_[0] }

sub emit {
  my $self = shift;
  my $name = shift;
  if (my $s = $self->{_role_ee_events}{$name}) {
    warn "-- Emit $name in @{[blessed $self]} (@{[scalar @$s]})\n" if DEBUG;
    for my $cb (@$s) { $self->$cb(@_) }
  } else {
    warn "-- Emit $name in @{[blessed $self]} (0)\n" if DEBUG;
    die "@{[blessed $self]}: $_[0]" if $name eq 'error';
  }
  return $self;
}

sub has_subscribers { !!$_[0]->{_role_ee_events}{$_[1]} }

sub on { push @{$_[0]{_role_ee_events}{$_[1]}}, $_[2] and return $_[2] }

sub once {
  my ($self, $name, $cb) = @_;

  weaken $self;
  my $wrapper;
  $wrapper = sub {
    $self->unsubscribe($name => $wrapper);
    $cb->(@_);
  };
  $self->on($name => $wrapper);
  weaken $wrapper;

  return $wrapper;
}

my $has_future;
sub once_f {
  my ($self, $name) = @_;

  unless (defined $has_future) {
    local $@;
    eval { require Future; $has_future = 1 } or $has_future = 0;
  }
  croak "Future is required for once_f method" unless $has_future;

  my $f = Future->new;
  my $wrapper = sub { $f->done(@_) };
  $self->on($name => $wrapper);
  $self->{_role_ee_futures}{$name}{refaddr $wrapper} = $f;
  
  weaken $self;
  weaken $wrapper;
  return $f->on_ready(sub { $self->unsubscribe($name => $wrapper) });
}

sub subscribers { $_[0]->{_role_ee_events}{$_[1]} ||= [] }

sub unsubscribe {
  my ($self, $name, $cb) = @_;
  if ($cb) { # One
    my $addr = refaddr $cb;
    $self->{_role_ee_events}{$name} = [grep { $addr != refaddr $_ } @{$self->{_role_ee_events}{$name}}];
    delete $self->{_role_ee_events}{$name} unless @{$self->{_role_ee_events}{$name}};
    if ($self->{_role_ee_futures}{$name} and my $f = delete $self->{_role_ee_futures}{$name}{$addr}) {
      $f->cancel;
      delete $self->{_role_ee_futures}{$name} unless keys %{$self->{_role_ee_futures}{$name}};
    }
  } else { # All
    delete $self->{_role_ee_events}{$name};
    $_->cancel for values %{delete $self->{_role_ee_futures}{$name} || {}};
  }
  return $self;
}

1;

=head1 NAME

Role::EventEmitter - Event emitter role

=head1 SYNOPSIS

  package Channel;
  use Moo;
  with 'Role::EventEmitter';

  # Emit events
  sub send_message {
    my $self = shift;
    $self->emit(message => @_);
  }

  package main;

  # Subscribe to events
  my $channel_a = Channel->new;
  $channel_a->on(message => sub {
    my ($channel, $text) = @_;
    say "Received message: $text";
  });
  $channel_a->send_message('All is well');

=head1 DESCRIPTION

L<Role::EventEmitter> is a simple L<Role::Tiny> role for event emitting objects
based on L<Mojo::EventEmitter>. This role can be applied to any hash-based
object class such as those created with L<Class::Tiny>, L<Moo>, or L<Moose>.

=head1 EVENTS

L<Role::EventEmitter> can emit the following events.

=head2 error

  $e->on(error => sub {
    my ($e, $err) = @_;
    ...
  });

This is a special event for errors, it will not be emitted directly by this
role but is fatal if unhandled.

  $e->on(error => sub {
    my ($e, $err) = @_;
    say "This looks bad: $err";
  });

=head1 METHODS

L<Role::EventEmitter> composes the following methods.

=head2 catch

  $e = $e->catch(sub {...});

Subscribe to L</"error"> event.

  # Longer version
  $e->on(error => sub {...});

=head2 emit

  $e = $e->emit('foo');
  $e = $e->emit('foo', 123);

Emit event.

=head2 has_subscribers

  my $bool = $e->has_subscribers('foo');

Check if event has subscribers.

=head2 on

  my $cb = $e->on(foo => sub {...});

Subscribe to event.

  $e->on(foo => sub {
    my ($e, @args) = @_;
    ...
  });

=head2 once

  my $cb = $e->once(foo => sub {...});

Subscribe to event and unsubscribe again after it has been emitted once.

  $e->once(foo => sub {
    my ($e, @args) = @_;
    ...
  });

=head2 once_f

  my $f = $e->once_f('foo');

Subscribe to event as in L</"once">, returning a L<Future> that will be marked
complete after it has been emitted once. Requires L<Future> to be installed.

  my $f = $e->once_f('foo')->on_done(sub {
    my ($e, @args) = @_;
    ...
  });

To unsubscribe the returned L<Future> early, cancel it.

  $f->cancel;

=head2 subscribers

  my $subscribers = $e->subscribers('foo');

All subscribers for event.

  # Unsubscribe last subscriber
  $e->unsubscribe(foo => $e->subscribers('foo')->[-1]);

  # Change order of subscribers
  @{$e->subscribers('foo')} = reverse @{$e->subscribers('foo')};

=head2 unsubscribe

  $e = $e->unsubscribe('foo');
  $e = $e->unsubscribe(foo => $cb);

Unsubscribe from event. Related Futures will also be cancelled.

=head1 DEBUGGING

You can set the C<ROLE_EVENTEMITTER_DEBUG> environment variable to get some
advanced diagnostics information printed to C<STDERR>.

  ROLE_EVENTEMITTER_DEBUG=1

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

Code and tests adapted from L<Mojo::EventEmitter>, an event emitter base class
by the L<Mojolicious> team.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2015 Sebastian Riedel.

Copyright (c) 2015 Dan Book for adaptation to a role and further changes.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::EventEmitter>, L<Mixin::Event::Dispatch>, L<Beam::Emitter>,
L<Event::Distributor>
