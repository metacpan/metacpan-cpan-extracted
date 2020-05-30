package Stencil::Executable;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Role;
use Data::Object::RoleHas;

use Stencil::Log;

our $VERSION = '0.01'; # VERSION

# ATTRIBUTES

has 'stencil' => (
  is => 'ro',
  isa => 'Object',
  hnd => [qw(repo space spec)],
  req => 1
);

has 'log' => (
  is => 'ro',
  isa => 'Object',
  new => 1
);

fun new_log($self) {
  Stencil::Log->new(repo => $self->repo);
}

# METHODS

method execute() {
  $self->stencil->init;

  return $self->process;
}

1;
