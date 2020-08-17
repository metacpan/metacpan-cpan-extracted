package SQL::Engine::Builder::Transaction;

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

has mode => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  opt => 1
);

has queries => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  req => 1
);

# METHODS

method data() {
  my $schema = {};

  if ($self->mode) {
    $schema->{"mode"} = $self->mode;
  }

  if ($self->queries) {
    $schema->{"queries"} = $self->queries;
  }

  return {
    "transaction" => $schema
  }
}

1;
