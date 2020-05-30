package Stencil::Error;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Data::Object::Exception';

our $VERSION = '0.01'; # VERSION

# BUILD

fun on_space_locate(Str $class, Object $self) {
  my $name = $self->name;

  $class->new({
    id => 'on_space_locate',
    message => qq(Unable to locate space for "$name"),
    context => $self,
  });
}

fun on_source_load(Str $class, Object $self, Object $match) {
  my $name = $match->package;

  $class->new({
    id => 'on_source_load',
    message => qq(Unable to load space for "$name"),
    context => $self,
  });
}

fun on_source_test(Str $class, Object $self, Object $match) {
  my $name = $match->package;

  $class->new({
    id => 'on_source_test',
    message => qq(Package "$name" does not inherit from "Stencil::Source"),
    context => $self,
  });
}

fun on_source_data(Str $class, Object $self, Object $match) {
  my $name = $match->package;

  $class->new({
    id => 'on_source_interface',
    message => qq(Unable to load __DATA__ from "$name"),
    context => $self,
  });
}

fun on_source_section(Str $class, Object $self, Object $match, Str $ref) {
  my $name = $match->package;

  $class->new({
    id => 'on_source_section',
    message => qq(Unable to find "$ref" within the __DATA__ section of "$name"),
    context => $self,
  });
}

1;
