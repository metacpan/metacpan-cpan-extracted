package Stencil::Task::Make;

use 5.014;

use strict;
use warnings;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

with 'Stencil::Executable';

our $VERSION = '0.01'; # VERSION

# METHODS

method process() {
  my $files = $self->stencil->make;

  $self->log->info("spec" => "@{[$self->spec->file]}");
  $self->log->info("file" => "@{[$_]}") for @$files;

  return $self;
}

1;
