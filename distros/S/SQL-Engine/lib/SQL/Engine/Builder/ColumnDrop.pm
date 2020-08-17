package SQL::Engine::Builder::ColumnDrop;

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

has alias => (
  is => 'ro',
  isa => 'Str',
  opt => 1
);

has schema => (
  is => 'ro',
  isa => 'Str',
  opt => 1
);

has table => (
  is => 'ro',
  isa => 'Str',
  opt => 1
);

has column => (
  is => 'ro',
  isa => 'Str',
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

  if ($self->alias) {
    $schema->{"alias"} = $self->alias;
  }

  if ($self->schema) {
    $schema->{"schema"} = $self->schema;
  }

  if ($self->table) {
    $schema->{"table"} = $self->table;
  }

  if ($self->column) {
    $schema->{"column"} = $self->column;
  }

  if ($self->safe) {
    $schema->{"safe"} = $self->safe;
  }

  return {
    "column-drop" => $schema
  }
}

1;
