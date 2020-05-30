package Stencil::Space;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Space;

use Stencil::Error;

our $VERSION = '0.01'; # VERSION

# ATTRIBUTES

has 'name' => (
  is => 'ro',
  isa => 'Str',
  req => 1,
);

has 'local' => (
  is => 'ro',
  isa => 'Object',
  new => 1,
);

fun new_local($self) {
  Data::Object::Space->new(join '/', 'stencil', 'source', $self->name);
}

has 'global' => (
  is => 'ro',
  isa => 'Object',
  new => 1,
);

fun new_global($self) {
  Data::Object::Space->new($self->name);
}

has 'repo' => (
  is => 'ro',
  isa => 'Object',
  new => 1,
);

fun new_repo($self) {
  Stencil::Repo->new;
}

# METHODS

method locate() {
  my %seen;

  local @INC = grep !$seen{$_}++, '.', 'lib', 'local/lib/perl5', @INC;

  my $local = $self->local;

  return $local if $local->locate;

  my $global = $self->global;

  return $global if $global->locate;

  return undef;
}

# method section($name) {
#   my $data;
#   my $space;
#   my $content;

#   # locate
#   unless ($space = $self->locate) {
#     die Stencil::Error->on_space_locate($self);
#   }

#   # load-source
#   unless (do { local $@; eval{ $space->load } }) {
#     die Stencil::Error->on_source_load($self, $space);
#   }

#   # test-interface
#   unless ($space->package->isa('Stencil::Source')) {
#     die Stencil::Error->on_source_test($self, $space);
#   }

#   # load-data
#   unless ($data = $space->data) {
#     die Stencil::Error->on_source_data($self, $space);
#   }

#   # find-section
#   my $instance = $space->build(repo => $self->repo);

#   unless ($content = $instance->content($name)) {
#     die Stencil::Error->on_source_section($self, $space, $name);
#   }

#   return $content;
# }

method source() {
  my $space;

  # locate
  unless ($space = $self->locate) {
    die Stencil::Error->on_space_locate($self);
  }

  # load-source
  unless (do { local $@; eval{ $space->load } }) {
    die Stencil::Error->on_source_load($self, $space);
  }

  # test-interface
  unless ($space->package->isa('Stencil::Source')) {
    die Stencil::Error->on_source_test($self, $space);
  }

  # load-data
  unless ($space->data) {
    die Stencil::Error->on_source_data($self, $space);
  }

  return $space->build(repo => $self->repo);
}

1;
