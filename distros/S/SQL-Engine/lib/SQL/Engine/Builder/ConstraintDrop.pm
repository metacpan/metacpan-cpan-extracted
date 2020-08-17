package SQL::Engine::Builder::ConstraintDrop;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'SQL::Engine::Builder';

use SQL::Validator;

our $VERSION = '0.03'; # VERSION

# ATTRIBUTES

has name => (
  is => 'ro',
  isa => 'Str',
  opt => 1
);

has source => (
  is => 'ro',
  isa => 'HashRef',
  req => 1
);

has target => (
  is => 'ro',
  isa => 'HashRef',
  opt => 1
);

has safe => (
  is => 'ro',
  isa => 'Bool',
  opt => 1
);

# METHODS

method data() {
  my $schema = {};

  if ($self->name) {
    $schema->{"name"} = $self->name;
  }

  if ($self->source) {
    $schema->{"source"} = $self->source;
  }

  if ($self->target) {
    $schema->{"target"} = $self->target;
  }

  if ($self->safe) {
    $schema->{"safe"} = $self->safe;
  }

  return {
    "constraint-drop" => $schema
  }
}

1;
