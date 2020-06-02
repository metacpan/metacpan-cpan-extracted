package Stencil::Task::Init;

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
  $self->log->info("init" => "@{[$self->repo->store]}");

  return $self;
}

1;
