package Stencil::Task::Spec;

use 5.014;

use strict;
use warnings;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

with 'Stencil::Executable';

our $VERSION = '0.03'; # VERSION

# METHODS

method process() {
  $self->stencil->seed;

  $self->log->info("spec" => "@{[$self->spec->file]}");

  return $self;
}

1;
