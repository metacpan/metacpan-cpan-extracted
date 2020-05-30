package Stencil::Data;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

our $VERSION = '0.01'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Str',
  req => 1
);

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
  $self->repo->store(join '.', $self->name, 'yaml');
}

# METHODS

method read() {
  require YAML::PP;

  my $yaml = YAML::PP->new;

  $yaml->load_file($self->file);
}

method write($data) {
  require YAML::PP;

  my $yaml = YAML::PP->new;

  $yaml->dump_file($self->file, $data);
}

1;
