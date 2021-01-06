package Mojolicious::Component;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;
use Data::Object::Space;

use Mojo::Loader ();

has controller => (
  is => 'ro',
  isa => 'InstanceOf["Mojolicious::Controller"]',
  opt => 1,
);

has space => (
  is => 'ro',
  isa => 'InstanceOf["Data::Object::Space"]',
  new => 1,
);

fun new_space($self) {
  Data::Object::Space->new(ref $self)
}

has template => (
  is => 'ro',
  isa => 'InstanceOf["Mojo::Template"]',
  new => 1,
);

fun new_template($self) {
  require Mojo::Template; Mojo::Template->new(vars => 1)
}

method render(Any %args) {
  my $template;
  for my $package ($self->space->package, @{$self->space->inherits}) {
    if ($template = Mojo::Loader::data_section($package, 'component')) {
      last;
    }
  }
  return $self->template->render(($template || ''), {
    %args, component => $self,
  });
}

1;


=encoding utf8

=head1 NAME

Mojolicious::Component - Module-based Template Class

=cut

=head1 ABSTRACT

Module-based Template Base Class

=cut

=head1 SYNOPSIS

  package App::Component::Image;

  use Mojo::Base 'Mojolicious::Component';

  has alt => 'random';
  has height => 126;
  has width => 145;
  has src => '/random.gif';

  package main;

  my $component = App::Component::Image->new;

  # $component->render

=cut

=head1 DESCRIPTION

This package provides an abstract base class for rendering derived
component-based template (partials) classes.

=cut

=head1 ATTRIBUTES

This package has the following attributes:

=cut

=head2 controller

  controller(InstanceOf["Mojolicious::Controller"])

This attribute is read-only, accepts C<(InstanceOf["Mojolicious::Controller"])> values, and is optional.

=cut

=head2 space

  space(InstanceOf["Data::Object::Space"])

This attribute is read-only, accepts C<(InstanceOf["Data::Object::Space"])> values, and is optional.

=cut

=head2 template

  template(InstanceOf["Mojo::Template"])

This attribute is read-only, accepts C<(InstanceOf["Mojo::Template"])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 render

  render(Any %args) : Str

The render method loads the component template string data from the C<DATA>
section of the component class and renders it using the L<Mojo::Template>
object available via L</template>.

=over 4

=item render example #1

  # given: synopsis

  my $rendered = $component->render;

=back

=over 4

=item render example #2

  # given: synopsis

  my $rendered = $component->render(
    readonly => 1,
  );

=back

=cut

=head1 AUTHOR

Al Newkirk, C<awncorp@cpan.org>

=head1 LICENSE

Copyright (C) 2011-2019, Al Newkirk, et al.

This is free software; you can redistribute it and/or modify it under the terms
of the The Apache License, Version 2.0, as elucidated in the L<"license
file"|https://github.com/cpanery/mojolicious-plugin-component/blob/master/LICENSE>.

=head1 PROJECT

L<Wiki|https://github.com/cpanery/mojolicious-plugin-component/wiki>

L<Project|https://github.com/cpanery/mojolicious-plugin-component>

L<Initiatives|https://github.com/cpanery/mojolicious-plugin-component/projects>

L<Milestones|https://github.com/cpanery/mojolicious-plugin-component/milestones>

L<Contributing|https://github.com/cpanery/mojolicious-plugin-component/blob/master/CONTRIBUTE.md>

L<Issues|https://github.com/cpanery/mojolicious-plugin-component/issues>

=cut
__DATA__

@@ component
