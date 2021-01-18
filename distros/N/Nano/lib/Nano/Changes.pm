package Nano::Changes;

use 5.014;

use strict;
use warnings;

use registry 'Nano::Types';
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Nano::Node';

our $VERSION = '0.07'; # VERSION

# ATTRIBUTES

has domain => (
  is => 'ro',
  isa => 'Domain',
  hnd => [qw(decr del get incr merge pop push set shift state unshift)],
  new => 1,
);

fun new_domain($self) {
  $self->nano->domain($self->id)
}

1;

=encoding utf8

=head1 NAME

Nano::Changes - Transaction Index

=cut

=head1 ABSTRACT

Transaction Index Super Class

=cut

=head1 SYNOPSIS

  use Nano::Changes;

  my $changes = Nano::Changes->new;

  # $changes->state;

=cut

=head1 DESCRIPTION

This package provides a transaction index super class. It is meant to be
subclassed or used via L<Nano::Track>.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Nano::Node>

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Nano::Types>

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 domain

  domain(Domain)

This attribute is read-only, accepts C<(Domain)> values, and is optional.

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