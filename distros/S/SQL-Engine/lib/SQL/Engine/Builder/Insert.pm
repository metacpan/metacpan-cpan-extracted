package SQL::Engine::Builder::Insert;

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

has into => (
  is => 'ro',
  isa => 'HashRef',
  req => 1
);

has columns => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  opt => 1
);

has values => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  opt => 1
);

has query => (
  is => 'ro',
  isa => 'HashRef',
  opt => 1
);

has default => (
  is => 'ro',
  isa => 'Bool',
  opt => 1
);

has returning => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  opt => 1
);

# METHODS

method data() {
  my $schema = {};

  if ($self->into) {
    $schema->{"into"} = $self->into;
  }

  if ($self->columns) {
    $schema->{"columns"} = $self->columns;
  }

  if ($self->values) {
    $schema->{"values"} = $self->values;
  }

  if ($self->query) {
    $schema->{"query"} = $self->query;
  }

  if ($self->default) {
    $schema->{"default"} = $self->default;
  }

  if ($self->returning) {
    $schema->{"returning"} = $self->returning;
  }

  return {
    insert => $schema
  }
}

1;
