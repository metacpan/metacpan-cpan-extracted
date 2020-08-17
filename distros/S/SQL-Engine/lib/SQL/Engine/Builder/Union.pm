package SQL::Engine::Builder::Union;

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

has queries => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  req => 1
);

has type => (
  is => 'ro',
  isa => 'Str',
  opt => 1
);

# METHODS

method data() {
  my $schema = {};

  if ($self->queries) {
    $schema->{"queries"} = $self->queries;
  }

  if ($self->type) {
    $schema->{"type"} = $self->type;
  }

  return {
    "union" => $schema
  }
}

1;
