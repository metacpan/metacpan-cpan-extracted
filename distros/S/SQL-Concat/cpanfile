# -*- mode: perl -*-
requires perl => '5.010';

requires 'rlib'; # XXX:

requires 'MOP4Import::Declare' => 0.003;

requires 'rlib'; # XXX:

on configure => sub {
  requires 'rlib';
  requires 'Module::Build';
  requires 'Module::Build::Pluggable';
  requires 'Module::CPANfile';
};

on build => sub {
  requires 'rlib'; # XXX:
};

on 'test' => sub {
  # requires 'rlib';
  requires 'Test::Kantan' => 0.40;
};
