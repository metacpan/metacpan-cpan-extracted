package SQL::Engine::Builder::ColumnCreate;

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

has for => (
  is => 'ro',
  isa => 'HashRef',
  req => 1
);

has column => (
  is => 'ro',
  isa => 'HashRef',
  req => 1
);

# METHODS

method data() {
  my $schema = {};

  if ($self->for) {
    $schema->{"for"} = $self->for;
  }

  if ($self->column) {
    $schema->{"column"} = $self->column;
  }

  return {
    "column-create" => $schema
  }
}

1;
