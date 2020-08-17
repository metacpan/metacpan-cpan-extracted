package SQL::Engine::Builder::Delete;

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
  isa => 'HashRef',
  req => 1
);

has where => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
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

  if ($self->from) {
    $schema->{"from"} = $self->from;
  }

  if ($self->where) {
    $schema->{"where"} = $self->where;
  }

  if ($self->returning) {
    $schema->{"returning"} = $self->returning;
  }

  return {
    delete => $schema
  }
}

1;
