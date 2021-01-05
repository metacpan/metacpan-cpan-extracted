# NAME

Nano - Object Persistence

# ABSTRACT

Minimalist Object Persistence

# SYNOPSIS

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

# DESCRIPTION

This package provides a minimalist framework for persisting objects (_i.e.
class instances_) with as little effort as possible. This framework relies on
the [Zing](https://metacpan.org/pod/Zing) toolkit which provides pluggable storage and serialization options.

# LIBRARIES

This package uses type constraints from:

[Nano::Types](https://metacpan.org/pod/Nano::Types)

# ATTRIBUTES

This package has the following attributes:

## env

    env(Env)

This attribute is read-only, accepts `(Env)` values, and is optional.

# METHODS

This package implements the following methods:

## dump

    dump(Object $object) : HashRef

The dump method returns a serialized hash representation for the object
provided.

- dump example #1

        my $nano = Nano->new;

        my $rachel = $nano->find('rachel');

        my $dump = $nano->dump($rachel);

## find

    find(Str $name) : Node

The find method finds, inflates, and returns a prior persisted object for the
ID provided.

- find example #1

        my $nano = Nano->new;

        my $phoebe = $nano->find('phoebe');

## hash

    hash(Str $name) : Str

The hash method returns a SHA-1 digest for the string provided.

- hash example #1

        my $nano = Nano->new;

        my $email = 'me@example.com';

        $nano->hash($email);

## keyval

    keyval(Str $name) : KeyVal

The keyval method returns a [Zing::KeyVal](https://metacpan.org/pod/Zing::KeyVal) object for the ID provided.

- keyval example #1

        my $nano = Nano->new;

        my $keyval = $nano->keyval('rachel');

## name

    name(Object $object) : Str

The name method returns the class name for the object provided.

- name example #1

        my $nano = Nano->new;

        my $rachel = $nano->find('rachel');

        my $name = $nano->name($rachel);

## object

    object(HashRef $object) : Object

The object method returns an object derived from a prior serialization
representation.

- object example #1

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

## reify

    reify(Str $name, HashRef $data) : Object

The reify method constructs an object from the class name and data provided.

- reify example #1

        my $nano = Nano->new;

        my $new_rachel = $nano->reify('Person', {
          id => 'rachel',
          name => 'rachel',
        });

## table

    table(Str $name) : Table

The table method returns a [Zing::Table](https://metacpan.org/pod/Zing::Table) object for the ID provided.

- table example #1

        my $nano = Nano->new;

        my $rachel = $nano->find('rachel');

        my $table = $nano->table($rachel->friends->id);

# AUTHOR

Al Newkirk, `awncorp@cpan.org`

# LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the ["license
file"](https://github.com/cpanery/nano/blob/master/LICENSE).

# PROJECT

[Wiki](https://github.com/cpanery/nano/wiki)

[Project](https://github.com/cpanery/nano)

[Initiatives](https://github.com/cpanery/nano/projects)

[Milestones](https://github.com/cpanery/nano/milestones)

[Contributing](https://github.com/cpanery/nano/blob/master/CONTRIBUTE.md)

[Issues](https://github.com/cpanery/nano/issues)
