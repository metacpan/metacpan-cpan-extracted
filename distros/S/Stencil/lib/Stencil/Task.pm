package Stencil::Task;

use 5.014;

use strict;
use warnings;
use routines;

use Data::Object::Class;

extends 'App::Spec::Run::Cmd';

our $VERSION = '0.03'; # VERSION

# BUILD

sub data {
  require Data::Object::Space;

  my $space = Data::Object::Space->new(
    ref $_[0] || $_[0]
  );

  $space->data;
}

# METHODS

method edit($run) {
  require Stencil::Task::Edit;

  my $command = Stencil::Task::Edit->new(stencil => $self->stencil($run));

  return $command->execute;
}

method init($run) {
  require Stencil::Task::Init;

  my $command = Stencil::Task::Init->new(stencil => $self->stencil($run));

  return $command->execute;
}

method make($run) {
  require Stencil::Task::Make;

  my $command = Stencil::Task::Make->new(stencil => $self->stencil($run));

  return $command->execute;
}

method spec($run) {
  require Stencil::Task::Spec;

  my $command = Stencil::Task::Spec->new(stencil => $self->stencil($run));

  return $command->execute;
}

method stencil($run) {
  require Stencil;
  require Stencil::Repo;
  require Stencil::Space;
  require Stencil::Data;

  my $repo = Stencil::Repo->new(
    base => $run->options->{base}
  )
  if $run->options->{base};

  my $space = Stencil::Space->new(
    name => $run->parameters->{space}
  )
  if $run->parameters->{space};

  my $spec = Stencil::Data->new(
    name => $run->parameters->{spec},
    repo => $repo
  )
  if $run->parameters->{spec};

  my $stencil = Stencil->new(repo => $repo, space => $space, spec => $spec);

  return $stencil;
}

1;

__DATA__

name: stencil

title: |
  perl 5 source code generator

abstract: |
  ____________________________________________
  7     77      77     77     77     77  77  7
  |  ___!!__  __!|  ___!|  _  ||  ___!|  ||  |
  !__   7  7  7  |  __|_|  7  ||  7___|  ||  !___
  7     |  |  |  |     7|  |  ||     7|  ||     7
  !_____!  !__!  !_____!!__!__!!_____!!__!!_____!

class: Stencil::Task

plugins:
- -Format
- -Meta

options:
- aliases:
  - b
  name: base
  summary: Stencil project directory
  default: .
  type: string

subcommands:
  init:
    op: init
    summary: Initialize workspace
  edit:
    op: edit
    summary: Edit source spec (generate unless exists)
    options:
    - aliases:
      - yes
      - y
      name: confirm
      summary: Confirm
      type: flag
    parameters:
    - name: space
      required: 1
      summary: Stencil provider class name
      type: string
    - name: spec
      required: 1
      summary: Stencil specification file name
      type: string
  make:
    op: make
    summary: Generate source code
    options:
    - aliases:
      - yes
      - y
      name: confirm
      summary: Confirm
      type: flag
    parameters:
    - name: space
      required: 1
      summary: Stencil provider class name
      type: string
    - name: spec
      required: 1
      summary: Stencil specification file name
      type: string
  spec:
    op: spec
    summary: Generate source spec
    options:
    - aliases:
      - yes
      - y
      name: confirm
      summary: Confirm
      type: flag
    parameters:
    - name: space
      required: 1
      summary: Stencil provider class name
      type: string
    - name: spec
      required: 1
      summary: Stencil specification file name
      type: string
