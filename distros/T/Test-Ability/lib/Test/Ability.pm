package Test::Ability;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Try;

use Data::Random ();
use Test::More ();

with 'Data::Object::Role::Buildable';
with 'Data::Object::Role::Stashable';

our $VERSION = '0.03'; # VERSION

# ATTRIBUTES

has 'arguments' => (
  is => 'ro',
  isa => 'ArrayRef',
  opt => 1,
);

has 'invocant' => (
  is => 'ro',
  isa => 'Object',
  opt => 1,
);

# BUILD

method build_arg($data) {
  {
    invocant => $data
  }
}

method build_self($data) {
  $self->stash(array => $self->can('array'));
  $self->stash(array_object => $self->can('array_object'));
  $self->stash(code => $self->can('code'));
  $self->stash(code_object => $self->can('code_object'));
  $self->stash(date => $self->can('date'));
  $self->stash(datetime => $self->can('datetime'));
  $self->stash(hash => $self->can('hash'));
  $self->stash(hash_object => $self->can('hash_object'));
  $self->stash(instance => $self->can('instance'));
  $self->stash(number => $self->can('number'));
  $self->stash(number_object => $self->can('number_object'));
  $self->stash(object => $self->can('object'));
  $self->stash(regexp => $self->can('regexp'));
  $self->stash(regexp_object => $self->can('regexp_object'));
  $self->stash(scalar => $self->can('scalar'));
  $self->stash(scalar_object => $self->can('scalar_object'));
  $self->stash(string => $self->can('string'));
  $self->stash(string_object => $self->can('string_object'));
  $self->stash(time => $self->can('time'));
  $self->stash(undef => $self->can('undef'));
  $self->stash(undef_object => $self->can('undef_object'));
  $self->stash(word => $self->can('word'));
  $self->stash(words => $self->can('words'));

  return $self;
}

# METHODS

method array(Maybe[Int] $min = 5, Maybe[Int] $max = 10) {
  my $data = [
    Data::Random::rand_chars(
      set => 'all', min => $min, max => $max
    )
  ];

  return $data;
}

method array_object(Maybe[Int] $min = 5, Maybe[Int] $max = 10) {
  my $data = $self->array;
  my $word = $self->word;

  return $self->instance($data, ucfirst($word));
}

method choose(ArrayRef[ArrayRef] $spec = [[]]) {
  my $item = $spec->[rand($#$spec + 1)];
  my $data = $self->dispatch($item);

  return $data;
}

method code(Maybe[Int] @args) {
  my $data = sub {
    ($self->words(@args), $self->number(@args))[rand(2)]
  };

  return $data;
}

method code_object(Maybe[Int] $min, Maybe[Int] $max) {
  my $data = $self->code;
  my $word = $self->word;

  return $self->instance($data, ucfirst($word));
}

method date(Maybe[Str] $min, Maybe[Str] $max) {
  my $data = Data::Random::rand_date(
    min => $min,
    max => $max
  );

  return $data;
}

method datetime(Maybe[Str] $min, Maybe[Str] $max) {
  my $data = Data::Random::rand_datetime(
    min => $min,
    max => $max
  );

  return $data;
}

method dispatch(ArrayRef $item = []) {
  my ($method, $arguments) = @$item;

  if (!$method) {
    return undef;
  }
  else {
    if (my $callback = $self->stash($method)) {
      return $callback->($self, @$arguments);
    }
    else {
      return $self->$method(@$arguments);
    }
  }
}

method hash(Maybe[Int] $min, Maybe[Int] $max) {
  my $data = $self->array($min, $max);

  $data = {
    @$data % 2 ? (@$data, $$data[rand(@$data)]) : @$data
  };

  return $data;
}

method hash_object(Maybe[Int] $min, Maybe[Int] $max) {
  my $data = $self->hash;
  my $word = $self->word;

  return $self->instance($data, ucfirst($word));
}

method instance(Any $value, Str $class) {

  return bless $value, $class;
}

method maybe(ArrayRef[ArrayRef] $spec = [[]]) {
  my $data = ($self->choose($spec), undef)[rand(2)];

  return $data;
}

method number(Maybe[Int] $min = 0, Maybe[Int] $max = 1_000) {
  $min = 0 if !$min || $min > $max;

  my $data = $min + int rand($max - $min);

  return $data;
}

method number_object(Maybe[Int] $min = 0, Maybe[Int] $max = 1_000) {
  my $data = $self->number($min, $max);
  my $word = $self->word;

  return $self->instance(\$data, ucfirst($word));
}

method object() {
  my @objects = qw(
    array_object
    code_object
    hash_object
    number_object
    regexp_object
    scalar_object
    string_object
    undef_object
  );

  my $method = $objects[rand(@objects)];

  return $self->$method;
}

method regexp(Str $exp = '.*') {
  my $word = $self->word;
  my $data = ref($exp) ? $exp : qr/$exp/;

  return $data;
}

method regexp_object(Str $exp = '.*') {
  my $data = $self->regexp($exp);
  my $word = $self->word;

  return $self->instance(\$data, ucfirst($word));
}

method scalar(Maybe[Int] @args) {
  my $data = ($self->words(@args), $self->number(@args))[rand(2)];

  return \$data;
}

method scalar_object(Maybe[Int] $min, Maybe[Int] $max) {
  my $data = $self->scalar;
  my $word = $self->word;

  return $self->instance($data, ucfirst($word));
}

method string(Maybe[Int] $min, Maybe[Int] $max) {
  my $data = $self->words($min, $max);

  return $data;
}

method string_object(Maybe[Int] $min, Maybe[Int] $max) {
  my $data = $self->string;
  my $word = $self->word;

  return $self->instance(\$data, ucfirst($word));
}

method test(Str $name, Int $cycles, ArrayRef[ArrayRef] $spec, CodeRef $callback) {
  my @defaults;

  if ($self->invocant) {
    push @defaults, invocant => $self->invocant;
  }

  if ($self->arguments) {
    push @defaults, arguments => $self->arguments;
  }

  Test::More::subtest($name, sub {
    for my $index (1..$cycles) {
      Test::More::subtest("$name ($index of $cycles)", sub {
        $callback->(Data::Object::Try->new(@defaults),
          map $self->dispatch($_), @$spec)->result
      });
    }
  });

  return;
}

method time(Maybe[Str] $min, Maybe[Str] $max) {
  my $data = Data::Random::rand_time(
    min => $min,
    max => $max
  );

  return $data;
}

method undef() {

  return undef;
}

method undef_object() {
  my $data = undef;
  my $word = $self->word;

  return $self->instance(\$data, ucfirst($word));
}

method word() {
  my $data = Data::Random::rand_words();

  return $data->[0];
}

method words(Maybe[Int] $min = 2, Maybe[Int] $max = 10) {
  my $data = Data::Random::rand_words(
    min => $min, max => $max
  );

  return join ' ', @$data;
}

1;

=encoding utf8

=head1 NAME

Test::Ability

=cut

=head1 ABSTRACT

Property-Based Testing for Perl 5

=cut

=head1 SYNOPSIS

  package main;

  use Test::Ability;

  my $t = Test::Ability->new;

=cut

=head1 DESCRIPTION

This package provides methods for generating values and test-cases, providing a
framework for performing property-based testing.

=cut

=head1 INTEGRATES

This package integrates behaviors from:

L<Data::Object::Role::Buildable>

L<Data::Object::Role::Stashable>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 SCENARIOS

This package supports the following scenarios:

=cut

=head2 stash

  # given: synopsis

  $t->stash(direction => sub {
    my ($self) = @_;

    {
      move => ('forward', 'reverse')[rand(1)],
      time => time
    }
  });

The package provides a stash object for default and user-defined value
generators. You can easily extend the default generators by adding your own.
Once defined, custom generators can be specified in the I<gen-spec> (generator
specification) arrayref provided to the C<test> method (and others).

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 arguments

  arguments(ArrayRef)

This attribute is read-only, accepts C<(ArrayRef)> values, and is optional.

=cut

=head2 invocant

  invocant(Object)

This attribute is read-only, accepts C<(Object)> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 array

  array(Maybe[Int] $min, Maybe[Int] $max) : ArrayRef

The array method returns a random array reference.

=over 4

=item array example #1

  # given: synopsis

  $t->array;

=back

=cut

=head2 array_object

  array_object(Maybe[Int] $min, Maybe[Int] $max) : Object

The array_object method returns a random array object.

=over 4

=item array_object example #1

  # given: synopsis

  $t->array_object;

=back

=cut

=head2 choose

  choose(ArrayRef[ArrayRef] $args) : Any

The choose method returns a random value from the set of specified generators.

=over 4

=item choose example #1

  # given: synopsis

  $t->choose([['datetime'], ['words', [2,3]]]);

=back

=cut

=head2 code

  code(Maybe[Int] $min, Maybe[Int] $max) : CodeRef

The code method returns a random code reference.

=over 4

=item code example #1

  # given: synopsis

  $t->code;

=back

=cut

=head2 code_object

  code_object(Maybe[Int] $min, Maybe[Int] $max) : Object

The code_object method returns a random code object.

=over 4

=item code_object example #1

  # given: synopsis

  $t->code_object;

=back

=cut

=head2 date

  date(Maybe[Str] $min, Maybe[Str] $max) : Str

The date method returns a random date.

=over 4

=item date example #1

  # given: synopsis

  $t->date;

=back

=cut

=head2 datetime

  datetime(Maybe[Str] $min, Maybe[Str] $max) : Str

The datetime method returns a random date and time.

=over 4

=item datetime example #1

  # given: synopsis

  $t->datetime;

=back

=cut

=head2 hash

  hash(Maybe[Int] $min, Maybe[Int] $max) : HashRef

The hash method returns a random hash reference.

=over 4

=item hash example #1

  # given: synopsis

  $t->hash;

=back

=cut

=head2 hash_object

  hash_object(Maybe[Int] $min, Maybe[Int] $max) : Object

The hash_object method returns a random hash object.

=over 4

=item hash_object example #1

  # given: synopsis

  $t->hash_object;

=back

=cut

=head2 maybe

  maybe(ArrayRef[ArrayRef] $args) : Any

The maybe method returns a random choice using the choose method, or the
undefined value.

=over 4

=item maybe example #1

  # given: synopsis

  $t->maybe([['date'], ['time']]);

=back

=cut

=head2 number

  number(Maybe[Int] $min, Maybe[Int] $max) : Int

The number method returns a random number.

=over 4

=item number example #1

  # given: synopsis

  $t->number;

=back

=cut

=head2 number_object

  number_object(Maybe[Int] $min, Maybe[Int] $max) : Object

The number_object method returns a random number object.

=over 4

=item number_object example #1

  # given: synopsis

  $t->number_object;

=back

=cut

=head2 object

  object() : Object

The object method returns a random object.

=over 4

=item object example #1

  # given: synopsis

  $t->object;

=back

=cut

=head2 regexp

  regexp(Maybe[Str] $exp) : RegexpRef

The regexp method returns a random regexp.

=over 4

=item regexp example #1

  # given: synopsis

  $t->regexp;

=back

=cut

=head2 regexp_object

  regexp_object(Maybe[Str] $exp) : Object

The regexp_object method returns a random regexp object.

=over 4

=item regexp_object example #1

  # given: synopsis

  $t->regexp_object;

=back

=cut

=head2 scalar

  scalar(Maybe[Int] $min, Maybe[Int] $max) : Ref

The scalar method returns a random scalar reference.

=over 4

=item scalar example #1

  # given: synopsis

  $t->scalar;

=back

=cut

=head2 scalar_object

  scalar_object(Maybe[Int] $min, Maybe[Int] $max) : Object

The scalar_object method returns a random scalar object.

=over 4

=item scalar_object example #1

  # given: synopsis

  $t->scalar_object;

=back

=cut

=head2 string

  string(Maybe[Int] $min, Maybe[Int] $max) : Str

The string method returns a random string.

=over 4

=item string example #1

  # given: synopsis

  $t->string;

=back

=cut

=head2 string_object

  string_object(Maybe[Int] $min, Maybe[Int] $max) : Object

The string_object method returns a random string object.

=over 4

=item string_object example #1

  # given: synopsis

  $t->string_object;

=back

=cut

=head2 test

  test(Str $name, Int $cycles, ArrayRef[ArrayRef] $spec, CodeRef $callback) : Undef

The test method generates subtests using L<Test::More/subtest>, optionally
generating and passing random values to each iteration as well as a
L<Data::Object::Try> object for easy execution of callbacks and interception of
exceptions. This callback expected should have the signature C<($tryable,
@arguments)> where C<@arguments> gets assigned the generated values in the order
specified. The callback must return the C<$tryable> object, which is called for
you automatically, executing the subtest logic you've implemented.

=over 4

=item test example #1

  # given: synopsis

  # use Test::More;

  sub is_an_adult {
    my ($age) = @_;

    $age >= 18;
  }

  $t->test('is_an_adult', 100, [['number', [10, 30]]], sub {
    my ($tryable, $age) = @_;

    $tryable->call(sub {
      if ($age >= 18) {
        ok is_an_adult($age),
          "age is $age, is an adult";
      }
      else {
        ok !is_an_adult($age),
          "age is $age, is not an adult";
      }
    });

    $tryable
  });

=back

=cut

=head2 time

  time(Maybe[Str] $min, Maybe[Str] $max) : Str

The time method returns a random time.

=over 4

=item time example #1

  # given: synopsis

  $t->time;

=back

=cut

=head2 undef

  undef() : Undef

The undef method returns the undefined value.

=over 4

=item undef example #1

  # given: synopsis

  $t->undef;

=back

=cut

=head2 undef_object

  undef_object() : Object

The undef_object method returns the undefined value as an object.

=over 4

=item undef_object example #1

  # given: synopsis

  $t->undef_object;

=back

=cut

=head2 word

  word() : Str

The word method returns a random word.

=over 4

=item word example #1

  # given: synopsis

  $t->word;

=back

=cut

=head2 words

  words(Maybe[Int] $min, Maybe[Int] $max) : Str

The words method returns random words.

=over 4

=item words example #1

  # given: synopsis

  $t->words;

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/iamalnewkirk/foobar/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/iamalnewkirk/foobar/wiki>

L<Project|https://github.com/iamalnewkirk/foobar>

L<Initiatives|https://github.com/iamalnewkirk/foobar/projects>

L<Milestones|https://github.com/iamalnewkirk/foobar/milestones>

L<Contributing|https://github.com/iamalnewkirk/foobar/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/iamalnewkirk/foobar/issues>

=cut
