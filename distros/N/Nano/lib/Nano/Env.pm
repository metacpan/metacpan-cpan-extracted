package Nano::Env;

use 5.014;

use strict;
use warnings;

use registry 'Nano::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Zing::Env';

our $VERSION = '0.06'; # VERSION

# ATTRIBUTES

has system => (
  is => 'ro',
  init_arg => undef,
  isa => 'Str',
  default => 'nano',
);

1;

=encoding utf8

=head1 NAME

Nano::Env - Nano Environment

=cut

=head1 ABSTRACT

Nano Environment Abstraction

=cut

=head1 SYNOPSIS

  use Nano::Env;

  my $env = Nano::Env->new;

=cut

=head1 DESCRIPTION

This package provides a L<Zing> environment abstraction specific to L<Nano>
applications.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Zing::Env>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Nano::Types>

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/cpanery/nano/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/cpanery/nano/wiki>

L<Project|https://github.com/cpanery/nano>

L<Initiatives|https://github.com/cpanery/nano/projects>

L<Milestones|https://github.com/cpanery/nano/milestones>

L<Contributing|https://github.com/cpanery/nano/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/cpanery/nano/issues>

=cut