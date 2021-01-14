package Nano;

use 5.014;

use strict;
use warnings;

use registry 'Nano::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Space;

use Scalar::Util ();

our $VERSION = '0.06'; # VERSION

# ATTRIBUTES

has env => (
  is => 'ro',
  isa => 'Env',
  new => 1,
);

fun new_env($self) {
  require Nano::Env; Nano::Env->new
}

# SUBS

sub _dump {
  my ($data) = @_;

  if (!defined $data) {
    return undef;
  }
  elsif (Scalar::Util::blessed($data)) {
    if ($data->isa('Nano::Node')) {
      return {
        '$node' => $data->save
      };
    }
    else {
      return {
        '$skip' => 1,
      };
    }
  }
  elsif (UNIVERSAL::isa($data, 'ARRAY')) {
    my $copy = [];
    for (my $i = 0; $i < @$data; $i++) {
      $copy->[$i] = _dump($data->[$i]);
    }
    return $copy;
  }
  elsif (UNIVERSAL::isa($data, 'HASH')) {
    my $copy = {};
    for my $key (keys %$data) {
      $copy->{$key} = _dump($data->{$key});
    }
    return $copy;
  }
  elsif (ref($data)) {
    return {
      '$skip' => 1,
    };
  }
  else {
    return $data;
  }
}

sub _load {
  my ($self, $data) = @_;

  if (!defined $data) {
    return undef;
  }
  elsif (UNIVERSAL::isa($data, 'ARRAY')) {
    my $copy = [];
    for (my $i = 0; $i < @$data; $i++) {
      if (ref($data->[$i]) eq 'HASH') {
        next if $data->[$i]{'$skip'};
      }
      $copy->[$i] = _load($self, $data->[$i]);
    }
    return $copy;
  }
  elsif (UNIVERSAL::isa($data, 'HASH')) {
    if (defined($data->{'$node'})) {
      return $self->object($self->term($data->{'$node'})->object($self->env)->recv);
    }
    my $copy = {};
    for my $key (keys %$data) {
      if (ref($data->{$key}) eq 'HASH') {
        next if $data->{$key}{'$skip'};
      }
      $copy->{$key} = _load($self, $data->{$key});
    }
    return $copy;
  }
  else {
    return $data;
  }
}

# METHODS

method dump(Object $object) {
  return _dump({%{($object)}});
}

method find(Str $name) {
  if (my $keyval = $self->keyval($name)) {
    if (my $object = $keyval->recv) {
      return $self->object($object);
    }
  }
  return undef;
}

method hash(Str $name) {
  require Digest::SHA; Digest::SHA::sha1_hex($name);
}

method keyval(Str $name) {
  return $self->env->app->keyval(name => $name);
}

method name(Object $object) {
  return ref($object);
}

method object(HashRef $object) {
  return $self->reify(@{$object}{qw($name $data)});
}

method reify(Str $name, HashRef $data) {
  return Data::Object::Space->new($name)->build($self->_load($data));
}

method table(Str $name) {
  return $self->env->app->table(name => $name, type => 'keyval');
}

method term(Str $term) {
  return $self->env->app->term($term);
}

1;

=encoding utf8

=head1 NAME

Nano - Object Persistence

=cut

=head1 ABSTRACT

Minimalist Object Persistence

=cut

=head1 SYNOPSIS

  package Person;

  use Moo;

  extends 'Nano::Node';

  has name => (
    is => 'ro',
    required => 1,
  );

  has friends => (
    is => 'ro',
    default => sub { People->new }
  );

  sub extroverted {
    my ($self) = @_;
    ($self->friends->count > 1) ? 1 : 0
  }

  sub introverted {
    my ($self) = @_;
    ($self->friends->count < 2) ? 1 : 0
  }

  package People;

  use Moo;

  extends 'Nano::Nodes';

  sub new_type {
    'Person'
  }

  sub extroverted {
    my ($self) = @_;

    $self->scope(sub {
      my ($person) = @_;
      $person->extroverted
    });
  }

  sub introverted {
    my ($self) = @_;

    $self->scope(sub {
      my ($person) = @_;
      $person->introverted
    });
  }

  package main;

  my $rachel = Person->new(
    id => 'rachel',
    name => 'rachel',
  );
  my $monica = Person->new(
    id => 'monica',
    name => 'monica',
  );
  my $phoebe = Person->new(
    id => 'phoebe',
    name => 'phoebe',
  );

  $rachel->friends->set($monica);
  $rachel->friends->set($phoebe);

  $monica->friends->set($rachel);
  $monica->friends->set($phoebe);

  $phoebe->friends->set($rachel);
  $phoebe->friends->set($monica);

  $rachel->save;
  $monica->save;
  $phoebe->save;

  $phoebe->friends->count; # 2
  $phoebe->friends->extroverted->count; # 2
  $phoebe->friends->introverted->count; # 0

  my $nano = Nano->new;

  my $friend = $nano->find('rachel');

=cut

=head1 DESCRIPTION

This package provides a minimalist framework for persisting objects (I<i.e.
class instances>) with as little effort as possible. This framework relies on
the L<Zing> toolkit which provides pluggable storage and serialization options.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Nano::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 env

  env(Env)

This attribute is read-only, accepts C<(Env)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 dump

  dump(Object $object) : HashRef

The dump method returns a serialized hash representation for the object
provided.

=over 4

=item dump example #1

  my $nano = Nano->new;

  my $rachel = $nano->find('rachel');

  my $dump = $nano->dump($rachel);

=back

=cut

=head2 find

  find(Str $name) : Node

The find method finds, inflates, and returns a prior persisted object for the
ID provided.

=over 4

=item find example #1

  my $nano = Nano->new;

  my $phoebe = $nano->find('phoebe');

=back

=cut

=head2 hash

  hash(Str $name) : Str

The hash method returns a SHA-1 digest for the string provided.

=over 4

=item hash example #1

  my $nano = Nano->new;

  my $email = 'me@example.com';

  $nano->hash($email);

=back

=cut

=head2 keyval

  keyval(Str $name) : KeyVal

The keyval method returns a L<Zing::KeyVal> object for the ID provided.

=over 4

=item keyval example #1

  my $nano = Nano->new;

  my $keyval = $nano->keyval('rachel');

=back

=cut

=head2 name

  name(Object $object) : Str

The name method returns the class name for the object provided.

=over 4

=item name example #1

  my $nano = Nano->new;

  my $rachel = $nano->find('rachel');

  my $name = $nano->name($rachel);

=back

=cut

=head2 object

  object(HashRef $object) : Object

The object method returns an object derived from a prior serialization
representation.

=over 4

=item object example #1

  my $nano = Nano->new;

  my $new_rachel = $nano->object({
    '$type' => 'node',
    '$name' => 'Person',
    '$data' => {
      'id' => 'rachel',
      'name' => 'rachel',
      'nano' => {
        '$skip' => 1
      },
      'friends' => {
        '$skip' => 1
      },
    },
  });

=back

=cut

=head2 reify

  reify(Str $name, HashRef $data) : Object

The reify method constructs an object from the class name and data provided.

=over 4

=item reify example #1

  my $nano = Nano->new;

  my $new_rachel = $nano->reify('Person', {
    id => 'rachel',
    name => 'rachel',
  });

=back

=cut

=head2 table

  table(Str $name) : Table

The table method returns a L<Zing::Table> object for the ID provided.

=over 4

=item table example #1

  my $nano = Nano->new;

  my $rachel = $nano->find('rachel');

  my $table = $nano->table($rachel->friends->id);

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