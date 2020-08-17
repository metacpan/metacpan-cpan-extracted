package SQL::Engine::Builder::ViewCreate;

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
  req => 1
);

has temp => (
  is => 'ro',
  isa => 'Bool',
  opt => 1
);

has safe => (
  is => 'ro',
  isa => 'Bool',
  opt => 1
);

has columns => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  opt => 1
);

has query => (
  is => 'ro',
  isa => 'HashRef',
  req => 1
);

# METHODS

method data() {
  my $schema = {};

  if ($self->name) {
    $schema->{"name"} = $self->name;
  }

  if ($self->temp) {
    $schema->{"temp"} = $self->temp;
  }

  if ($self->safe) {
    $schema->{"safe"} = $self->safe;
  }

  if ($self->columns) {
    $schema->{"columns"} = $self->columns;
  }

  if ($self->query) {
    $schema->{"query"} = $self->query;
  }

  return {
    "view-create" => $schema
  }
}

1;
