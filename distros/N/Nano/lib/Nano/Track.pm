package Nano::Track;

use 5.014;

use strict;
use warnings;

use registry 'Nano::Types';
use routines;

use Data::Object::Role;
use Data::Object::RoleHas;

requires 'nano';

our $VERSION = '0.07'; # VERSION

# ATTRIBUTES

has changed => (
  is => 'ro',
  isa => 'Changes',
  new => 1,
);

fun new_changed($self) {
  require Nano::Changes; Nano::Changes->new
}

# METHODS

method decr(Str $name) {
  $self->changed->decr($name);
  return $self->changed->get($name);
}

method del(Str $name) {
  my $value = $self->changed->get($name);
  $self->changed->del($name);
  return $value;
}

method get(Str $name) {
  return $self->changed->get($name);
}

method getpush(Str $name, Any @args) {
  return @args ? $self->push($name, @args) : $self->get($name);
}

method getset(Str $name, Any @args) {
  return @args ? $self->set($name, @args) : $self->get($name);
}

method getunshift(Str $name, Any @args) {
  return @args ? $self->unshift($name, @args) : $self->get($name);
}

method incr(Str $name) {
  $self->changed->incr($name);
  return $self->changed->get($name);
}

method merge(Str $name, HashRef $value) {
  $self->changed->merge($name, $value);
  return $self->changed->get($name);
}

method pop(Str $name) {
  my $value = do {
    my $tmp = $self->changed->get($name);
    ref($tmp) eq 'ARRAY' ? $tmp->[-1] : $tmp;
  };
  $self->changed->pop($name);
  return $value;
}

method poppush(Str $name, Any @args) {
  return @args ? $self->push($name, @args) : $self->pop($name);
}

method push(Str $name, Any @value) {
  $self->changed->push($name, @value);
  return [@value];
}

method set(Str $name, Any $value) {
  $self->changed->set($name, $value);
  return $value;
}

method shift(Str $name) {
  my $value = do {
    my $tmp = $self->changed->get($name);
    ref($tmp) eq 'ARRAY' ? $tmp->[0] : $tmp;
  };
  $self->changed->shift($name);
  return $value;
}

method shiftunshift(Str $name, Any @args) {
  return @args ? $self->unshift($name, @args) : $self->shift($name);
}

method unshift(Str $name, Any @value) {
  $self->changed->unshift($name, @value);
  return [@value];
}

1;

=encoding utf8

=head1 NAME

Nano::Track - Trackable Role

=cut

=head1 ABSTRACT

Trackable Entity Role

=cut

=head1 SYNOPSIS

  package Example;

  use Moo;

  extends 'Nano::Node';

  with 'Nano::Track';

  sub creator {
    my ($self, @args) = @_;
    return $self->getset('creator', @args);
  }

  sub touched {
    my ($self, @args) = @_;
    return $self->incr('touched');
  }

  package main;

  my $example = Example->new;

  # $example->touched;

=cut

=head1 DESCRIPTION

This package provides a transactional change-tracking role, useful for creating
a history of changes and/or preventing race conditions when saving data for
L<Nano::Node> entities. B<Note:> Due to conflicting method names, this role
cannot be used with the L<Nano::Stash> role.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Nano::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 changed

  changed(Changes)

This attribute is read-only, accepts C<(Changes)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 decr

  decr(Str $name) : Int

The decr method decrements the data associated with a specific key.

=over 4

=item decr example #1

  my $example = Example->new;

  my $upvote = $example->decr('upvote');

=back

=over 4

=item decr example #2

  my $example = Example->new;

  $example->incr('upvote');
  $example->incr('upvote');
  $example->incr('upvote');

  my $upvote = $example->decr('upvote');

=back

=cut

=head2 del

  del(Str $name) : Any

The del method deletes the data associated with a specific key.

=over 4

=item del example #1

  my $example = Example->new;

  my $touched = $example->del('touched');

=back

=over 4

=item del example #2

  my $example = Example->new;

  $example->set('touched', 'monday');

  my $touched = $example->del('touched');

=back

=cut

=head2 get

  get($name) : Any

The get method return the data associated with a specific key.

=over 4

=item get example #1

  my $example = Example->new;

  my $profile = $example->get('profile');

=back

=over 4

=item get example #2

  my $example = Example->new;

  $example->set('profile', {
    nickname => 'demonstration',
  });

  my $profile = $example->get('profile');

=back

=cut

=head2 getpush

  getpush(Str $name, Any @args) : ArrayRef[Any] | Any

The getpush method calls L</push> or L</get> based on the arguments provided.
Allows you to easily create method-based accessors.

=over 4

=item getpush example #1

  my $example = Example->new;

  my $steps = $example->getpush('steps');

=back

=over 4

=item getpush example #2

  my $example = Example->new;

  my $steps = $example->getpush('steps', '#1', '#2');

=back

=cut

=head2 getset

  getset(Str $name, Any @args) : Any

The getset method calls L</get> or L</set> based on the arguments provided.
Allows you to easily create method-based accessors.

=over 4

=item getset example #1

  my $example = Example->new;

  my $profile = $example->getset('profile', {
    nickname => 'demonstration',
  });

=back

=over 4

=item getset example #2

  my $example = Example->new;

  $example->getset('profile', {
    nickname => 'demonstration',
  });

  my $profile = $example->getset('profile');

=back

=cut

=head2 getunshift

  getunshift(Str $name, Any @args) : ArrayRef[Any] | Any

The getunshift method calls L</unshift> or L</get> based on the arguments
provided. Allows you to easily create method-based accessors.

=over 4

=item getunshift example #1

  my $example = Example->new;

  my $step = $example->getunshift('steps');

=back

=over 4

=item getunshift example #2

  my $example = Example->new;

  $example->set('steps', ['#0']);

  my $step = $example->getunshift('steps', '#1', '#2');

=back

=cut

=head2 incr

  incr(Str $name) : Int

The incr method increments the data associated with a specific key.

=over 4

=item incr example #1

  my $example = Example->new;

  my $upvote = $example->incr('upvote');

=back

=over 4

=item incr example #2

  my $example = Example->new;

  $example->incr('upvote');
  $example->incr('upvote');

  my $upvote = $example->incr('upvote');

=back

=cut

=head2 merge

  merge(Str $name, HashRef $value) : HashRef

The merge method commits the data associated with a specific key to the channel
as a partial to be merged into any existing data.

=over 4

=item merge example #1

  my $example = Example->new;

  my $merge = $example->merge('profile', {
    password => 's3crets',
  });

=back

=over 4

=item merge example #2

  my $example = Example->new;

  $example->set('profile', {
    nickname => 'demonstration',
  });

  my $merge = $example->merge('profile', {
    password => 's3crets',
  });

=back

=cut

=head2 pop

  pop(Str $name) : Any

The pop method pops the data off of the stack associated with a specific key.

=over 4

=item pop example #1

  my $example = Example->new;

  my $steps = $example->pop('steps');

=back

=over 4

=item pop example #2

  my $example = Example->new;

  $example->push('steps', '#1', '#2');

  my $steps = $example->pop('steps');

=back

=cut

=head2 poppush

  poppush(Str $name, Any @args) : ArrayRef[Any] | Any

The poppush method calls L</push> or L</pop> based on the arguments provided.
Allows you to easily create method-based accessors.

=over 4

=item poppush example #1

  my $example = Example->new;

  my $steps = $example->poppush('steps');

=back

=over 4

=item poppush example #2

  my $example = Example->new;

  $example->set('steps', ['#1', '#2', '#3']);

  my $steps = $example->poppush('steps', '#4');

=back

=over 4

=item poppush example #3

  my $example = Example->new;

  $example->set('steps', ['#1', '#2', '#3']);

  my $steps = $example->poppush('steps');

=back

=cut

=head2 push

  push(Str $name, Any @value) : ArrayRef[Any]

The push method pushes data onto the stack associated with a specific key.

=over 4

=item push example #1

  my $example = Example->new;

  my $arguments = $example->push('steps', '#1');

=back

=over 4

=item push example #2

  my $example = Example->new;

  my $arguments = $example->push('steps', '#1', '#2');

=back

=cut

=head2 set

  set(Str $name, Any @args) : Any

The set method commits the data associated with a specific key to the channel.

=over 4

=item set example #1

  my $example = Example->new;

  my $email = $example->set('email', 'try@example.com');

=back

=over 4

=item set example #2

  my $example = Example->new;

  my $email = $example->set('email', 'try@example.com', 'retry@example.com');

=back

=cut

=head2 shift

  shift(Str $name) : Any

The shift method shifts data off of the stack associated with a specific key.

=over 4

=item shift example #1

  my $example = Example->new;

  my $steps = $example->shift('steps');

=back

=over 4

=item shift example #2

  my $example = Example->new;

  $example->set('steps', ['#1', '#2', '#3']);

  my $steps = $example->shift('steps');

=back

=cut

=head2 shiftunshift

  shiftunshift(Str $name, Any @args) : ArrayRef[Any] | Any

The shiftunshift method calls L</unshift> or L</shift> based on the arguments
provided. Allows you to easily create method-based accessors.

=over 4

=item shiftunshift example #1

  my $example = Example->new;

  my $step = $example->shiftunshift('steps');

=back

=over 4

=item shiftunshift example #2

  my $example = Example->new;

  my $steps = $example->shiftunshift('steps', '#1', '#2');

=back

=cut

=head2 unshift

  unshift(Str $name, Any @value) : ArrayRef[Any] | Any

The unshift method unshifts data onto the stack associated with a specific key.

=over 4

=item unshift example #1

  my $example = Example->new;

  my $arguments = $example->unshift('steps');

=back

=over 4

=item unshift example #2

  my $example = Example->new;

  my $arguments = $example->unshift('steps', '#1', '#2');

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/cpanery/nano/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/cpanery/nano/wiki>

L<Project|https://github.com/cpanery/nano>

L<Initiatives|https://github.com/cpanery/nano/projects>

L<Milestones|https://github.com/cpanery/nano/milestones>

L<Contributing|https://github.com/cpanery/nano/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/cpanery/nano/issues>

=cut