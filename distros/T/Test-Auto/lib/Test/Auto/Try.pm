package Test::Auto::Try;

use strict;
use warnings;

use Moo;
use Try::Tiny ();

our $VERSION = '0.12'; # VERSION

# ATTRIBUTES

has 'invocant' => (
  is => 'ro'
);

has 'arguments' => (
  is => 'ro'
);

has 'on_try' => (
  is => 'rw'
);

has 'on_catch' => (
  is => 'rw'
);

has 'on_default' => (
  is => 'rw'
);

has 'on_finally' => (
  is => 'rw'
);

# BUILD

sub BUILD {
  my ($self, $args) = @_;

  $self->{'on_catch'} = [] if !$args->{'on_catch'};

  return $args;
}

# METHODS

sub call {
  my ($self, $callback) = @_;

  $self->on_try($self->callback($callback));

  return $self;
}

sub callback {
  my ($self, $callback) = @_;

  require Carp;

  unless (UNIVERSAL::isa($callback, 'CODE')) {
    my $method = $self->invocant
      ? $self->invocant->can($callback) : $self->can($callback);
      Carp::confess(sprintf(
        qq(Can't locate object method "%s" on package "%s"),
        ($callback, ref $self)
      )) if !$method;
    $callback = sub { goto $method };
  }

  return $callback;
}

sub catch {
  my ($self, $class, $callback) = @_;

  push @{$self->on_catch}, [$class, $self->callback($callback)];

  return $self;
}

sub default {
  my ($self, $callback) = @_;

  $self->on_default($self->callback($callback));

  return $self;
}

sub execute {
  my ($self, $callback, @args) = @_;

  unshift @args, @{$self->arguments}
    if $self->arguments && @{$self->arguments};
  unshift @args, $self->invocant
    if $self->invocant;

  return $callback->(@args);
}

sub finally {
  my ($self, $callback) = @_;

  $self->on_finally($self->callback($callback));

  return $self;
}

sub maybe {
  my ($self) = @_;

  $self->on_default(sub{''});

  return $self;
}

sub no_catch {
  my ($self) = @_;

  $self->on_catch([]);

  return $self;
}

sub no_default {
  my ($self) = @_;

  $self->on_default(undef);

  return $self;
}

sub no_finally {
  my ($self) = @_;

  $self->on_finally(undef);

  return $self;
}

sub no_try {
  my ($self) = @_;

  $self->on_try(undef);

  return $self;
}

sub result {
  my ($self, @args) = @_;

  require Carp;

  my $returned;

  Try::Tiny::try(sub {
    my $tryer = $self->on_try;

    $returned = $self->execute($tryer, @args);
  }, Try::Tiny::catch(sub {
    my $caught = $_;
    my $catchers = $self->on_catch;
    my $default = $self->on_default;

    for my $catcher (@$catchers) {
      if (UNIVERSAL::isa($caught, $catcher->[0])) {
        $returned = $catcher->[1]->($caught);
        last;
      }
    }

    if(!$returned) {
      $returned = $default->($caught) if $default;
      Carp::confess($caught) if not defined $returned;
    }
  }, Try::Tiny::finally(sub {
    my $finally = $self->on_finally;

    $self->execute($finally, @args) if $finally;
  })));

  return $returned;
}

1;
