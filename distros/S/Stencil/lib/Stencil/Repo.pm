package Stencil::Repo;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

use Path::Tiny ();

our $VERSION = '0.01'; # VERSION

# ATTRIBUTES

has base => (
  is => 'ro',
  isa => 'Str',
  def => $ENV{STENCIL_HOME} || '.'
);

has path => (
  is => 'ro',
  isa => 'Object',
  new => 1
);

fun new_path($self) {
  Path::Tiny->new($self->base)->absolute;
}

# METHODS

method store(@parts) {
  $self->path->child('.stencil', @parts);
}

1;
