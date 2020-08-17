package SQL::Engine::Builder::Select;

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

has from => (
  is => 'ro',
  isa => 'HashRef | ArrayRef[HashRef]',
  req => 1
);

has columns => (
  is => 'ro',
  isa => 'ArrayRef[Str | HashRef]',
  new => 1
);

fun new_columns($self) {
  [{ 'column' => '*' }]
}

has where => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  opt => 1
);

has joins => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  opt => 1
);

has group_by => (
  is => 'ro',
  isa => 'ArrayRef[Str | HashRef]',
  opt => 1
);

has having => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  opt => 1
);

has order_by => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  opt => 1
);

has rows => (
  is => 'ro',
  isa => 'HashRef',
  opt => 1
);

# METHODS

method data() {
  my $schema = {};

  if ($self->from) {
    $schema->{"from"} = $self->from;
  }

  if ($self->columns) {
    $schema->{"columns"} = $self->columns;
  }

  if ($self->where) {
    $schema->{"where"} = $self->where;
  }

  if ($self->joins) {
    $schema->{"joins"} = $self->joins;
  }

  if ($self->group_by) {
    $schema->{"group-by"} = $self->group_by;
  }

  if ($self->having) {
    $schema->{"having"} = $self->having;
  }

  if ($self->order_by) {
    $schema->{"order-by"} = $self->order_by;
  }

  if ($self->rows) {
    $schema->{"rows"} = $self->rows;
  }

  return {
    select => $schema
  }
}

1;
