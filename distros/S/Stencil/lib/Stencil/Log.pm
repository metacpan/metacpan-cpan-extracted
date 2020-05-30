package Stencil::Log;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use FlightRecorder;

our $VERSION = '0.01'; # VERSION

# ATTRIBUTES

has 'repo' => (
  is => 'ro',
  isa => 'Object',
  req => 1,
);

has 'file' => (
  is => 'ro',
  isa => 'Object',
  new => 1
);

fun new_file($self) {
  $self->repo->store('logs', join '.', $$, time, 'log')->touch;
}

has handler => (
  is => 'ro',
  isa => 'Object',
  hnd => [qw(info debug warn fatal output)],
  new => 1
);

fun new_handler($self) {
  FlightRecorder->new( auto => $self->file->openw_utf8, format => '[{head_level}] {head_message}', level => 'info');
}

# METHODS

after info(@args) {
  $self->output(\*STDOUT);
}

after warn(@args) {
  $self->output(\*STDOUT);
}

after fatal(@args) {
  $self->output(\*STDOUT);
}

1;
