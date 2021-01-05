use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Nano

=cut

=tagline

Object Persistence

=cut

=abstract

Minimalist Object Persistence

=cut

=includes

method: dump
method: hash
method: find
method: keyval
method: name
method: object
method: reify
method: table

=cut

=synopsis

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

=libraries

Nano::Types

=cut

=attributes

env: ro, opt, Env

=cut

=description

This package provides a minimalist framework for persisting objects (I<i.e.
class instances>) with as little effort as possible. This framework relies on
the L<Zing> toolkit which provides pluggable storage and serialization options.

=cut

=method keyval

The keyval method returns a L<Zing::KeyVal> object for the ID provided.

=signature keyval

keyval(Str $name) : KeyVal

=example-1 keyval

  my $nano = Nano->new;

  my $keyval = $nano->keyval('rachel');

=cut

=method dump

The dump method returns a serialized hash representation for the object
provided.

=signature dump

dump(Object $object) : HashRef

=example-1 dump

  my $nano = Nano->new;

  my $rachel = $nano->find('rachel');

  my $dump = $nano->dump($rachel);

=cut

=method hash

The hash method returns a SHA-1 digest for the string provided.

=signature hash

hash(Str $name) : Str

=example-1 hash

  my $nano = Nano->new;

  my $email = 'me@example.com';

  $nano->hash($email);

=cut

=method find

The find method finds, inflates, and returns a prior persisted object for the
ID provided.

=signature find

find(Str $name) : Node

=example-1 find

  my $nano = Nano->new;

  my $phoebe = $nano->find('phoebe');

=cut

=method table

The table method returns a L<Zing::Table> object for the ID provided.

=signature table

table(Str $name) : Table

=example-1 table

  my $nano = Nano->new;

  my $rachel = $nano->find('rachel');

  my $table = $nano->table($rachel->friends->id);

=cut

=method name

The name method returns the class name for the object provided.

=signature name

name(Object $object) : Str

=example-1 name

  my $nano = Nano->new;

  my $rachel = $nano->find('rachel');

  my $name = $nano->name($rachel);

=cut

=method object

The object method returns an object derived from a prior serialization
representation.

=signature object

object(HashRef $object) : Object

=example-1 object

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

=cut

=method reify

The reify method constructs an object from the class name and data provided.

=signature reify

reify(Str $name, HashRef $data) : Object

=example-1 reify

  my $nano = Nano->new;

  my $new_rachel = $nano->reify('Person', {
    id => 'rachel',
    name => 'rachel',
  });

=cut

package main;

BEGIN {
  $ENV{ZING_STORE} = 'Zing::Store::Hash';
}

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'keyval', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok my $object = $result->recv;
  ok $object->{'$name'};
  ok $object->{'$data'};
  ok $object->{'$type'};

  $result
});

$subs->example(-1, 'dump', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->{id}, 'rachel';
  is $result->{name}, 'rachel';
  ok $result->{friends}{'$node'};

  $result
});

$subs->example(-1, 'find', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Person');
  is $result->id, 'phoebe';
  is $result->name, 'phoebe';
  ok $result->friends;

  $result
});

$subs->example(-1, 'hash', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  isnt $result, 'me@example.com';

  $result
});

$subs->example(-1, 'table', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result->count, 2;

  $result
});

$subs->example(-1, 'name', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is $result, 'Person';

  $result
});

$subs->example(-1, 'object', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Person');
  is $result->id, 'rachel';
  is $result->name, 'rachel';

  $result
});

$subs->example(-1, 'reify', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok $result->isa('Person');
  is $result->id, 'rachel';
  is $result->name, 'rachel';

  $result
});

ok 1 and done_testing;
