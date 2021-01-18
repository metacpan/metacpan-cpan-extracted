package Nano::Types;

use 5.014;

use strict;
use warnings;

use Data::Object::Types::Keywords;

use base 'Data::Object::Types::Library';

extends 'Types::Standard';

our $VERSION = '0.07'; # VERSION

register {
  name => 'Changes',
  parent => 'Object',
  validation => is_instance_of('Nano::Changes'),
};

register {
  name => 'Domain',
  parent => 'Object',
  validation => is_instance_of('Zing::Domain'),
};

register {
  name => 'Env',
  parent => 'Object',
  validation => is_instance_of('Nano::Env'),
};

register {
  name => 'Nano',
  parent => 'Object',
  validation => is_instance_of('Nano'),
};

register {
  name => 'Node',
  parent => 'Object',
  validation => is_instance_of('Nano::Node'),
};

register {
  name => 'Nodes',
  parent => 'Object',
  validation => is_instance_of('Nano::Nodes'),
};

register {
  name => 'Search',
  parent => 'Object',
  validation => is_instance_of('Nano::Search'),
};

register {
  name => 'KeyVal',
  parent => 'Object',
  validation => is_instance_of('Zing::KeyVal'),
};

register {
  name => 'Stash',
  parent => 'Object',
  validation => is_consumer_of('Nano::Stash'),
};

register {
  name => 'Table',
  parent => 'Object',
  validation => is_instance_of('Zing::Table'),
};

register {
  name => 'Track',
  parent => 'Object',
  validation => is_consumer_of('Nano::Track'),
};

1;

=encoding utf8

=head1 NAME

Nano::Types - Type Library

=cut

=head1 ABSTRACT

Type Library

=cut

=head1 SYNOPSIS

  package main;

  use Nano::Types;

  1;

=cut

=head1 DESCRIPTION

This package provides type constraints for the L<Nano> object persistence
framework.

=cut

=head1 LIBRARIES

This package uses type constraints from:

L<Types::Standard>

=cut

=head1 CONSTRAINTS

This package declares the following type constraints:

=cut

=head2 changes

  Changes

This type is defined in the L<Nano::Types> library.

=over 4

=item changes parent

  Object

=back

=over 4

=item changes composition

  InstanceOf["Nano::Changes"]

=back

=over 4

=item changes example #1

  # given: synopsis

  use Nano::Changes;

  my $changes = Nano::Changes->new;

=back

=cut

=head2 domain

  Domain

This type is defined in the L<Nano::Types> library.

=over 4

=item domain parent

  Object

=back

=over 4

=item domain composition

  InstanceOf["Zing::Domain"]

=back

=over 4

=item domain example #1

  # given: synopsis

  use Zing::Domain;

  my $domain = Zing::Domain->new(name => 'changelog');

=back

=cut

=head2 env

  Env

This type is defined in the L<Nano::Types> library.

=over 4

=item env parent

  Object

=back

=over 4

=item env composition

  InstanceOf["Nano::Env"]

=back

=over 4

=item env example #1

  # given: synopsis

  use Nano::Env;

  my $env = Nano::Env->new;

=back

=cut

=head2 keyval

  KeyVal

This type is defined in the L<Nano::Types> library.

=over 4

=item keyval parent

  Object

=back

=over 4

=item keyval composition

  InstanceOf["Zing::KeyVal"]

=back

=over 4

=item keyval example #1

  # given: synopsis

  use Zing::KeyVal;

  my $domain = Zing::KeyVal->new(name => 'user-12345');

=back

=cut

=head2 nano

  Nano

This type is defined in the L<Nano::Types> library.

=over 4

=item nano parent

  Object

=back

=over 4

=item nano composition

  InstanceOf["Nano"]

=back

=over 4

=item nano example #1

  # given: synopsis

  use Nano;

  my $nano = Nano->new;

=back

=cut

=head2 node

  Node

This type is defined in the L<Nano::Types> library.

=over 4

=item node parent

  Object

=back

=over 4

=item node composition

  InstanceOf["Nano::Node"]

=back

=over 4

=item node example #1

  # given: synopsis

  use Nano::Node;

  my $node = Nano::Node->new;

=back

=cut

=head2 nodes

  Nodes

This type is defined in the L<Nano::Types> library.

=over 4

=item nodes parent

  Object

=back

=over 4

=item nodes composition

  InstanceOf["Nano::Nodes"]

=back

=over 4

=item nodes example #1

  # given: synopsis

  use Nano::Nodes;

  my $nodes = Nano::Nodes->new;

=back

=cut

=head2 search

  Search

This type is defined in the L<Nano::Types> library.

=over 4

=item search parent

  Object

=back

=over 4

=item search composition

  InstanceOf["Nano::Search"]

=back

=over 4

=item search example #1

  # given: synopsis

  use Nano::Nodes;
  use Nano::Search;

  my $search = Nano::Search->new(nodes => Nano::Nodes->new);

=back

=cut

=head2 stash

  Stash

This type is defined in the L<Nano::Types> library.

=over 4

=item stash parent

  Object

=back

=over 4

=item stash composition

  ConsumerOf["Nano::Stash"]

=back

=over 4

=item stash example #1

  # given: synopsis

  package Example::Stash;

  use Moo;

  extends 'Nano::Node';

  with 'Nano::Stash';

  package main;

  my $stash = Example::Stash->new;

=back

=cut

=head2 table

  Table

This type is defined in the L<Nano::Types> library.

=over 4

=item table parent

  Object

=back

=over 4

=item table composition

  InstanceOf["Zing::Table"]

=back

=over 4

=item table example #1

  # given: synopsis

  use Zing::Table;

  my $lookup = Zing::Table->new(name => 'users');

=back

=cut

=head2 track

  Track

This type is defined in the L<Nano::Types> library.

=over 4

=item track parent

  Object

=back

=over 4

=item track composition

  ConsumerOf["Nano::Track"]

=back

=over 4

=item track example #1

  # given: synopsis

  package Example::Track;

  use Moo;

  extends 'Nano::Node';

  with 'Nano::Track';

  package main;

  my $track = Example::Track->new;

=back

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