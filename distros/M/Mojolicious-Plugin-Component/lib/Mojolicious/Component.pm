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

our $VERSION = '0.04'; # VERSION

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

has processor => (
  is => 'ro',
  isa => 'InstanceOf["Mojo::Template"]',
  new => 1,
);

fun new_processor($self) {
  require Mojo::Template; Mojo::Template->new(vars => 1)
}

# METHODS

method preprocess(Str $input) {
  return $input;
}

method postprocess(Str $input) {
  return $input;
}

method render(Any %args) {
  return $self->processor->render(
    ($self->postprocess($self->preprocess($self->template || ''))),
    {
      $self->variables(%args),
      component => $self,
    }
  );
}

method template(Str | Object $object = $self, Str $section = 'component') {
  my $template;
  my $space = $object
    ? Data::Object::Space->new(ref($object) || $object)
    : $self->space;
  for my $package ($space->package, @{$space->inherits}) {
    if ($template = Mojo::Loader::data_section($package, $section)) {
      last;
    }
  }
  return $template;
}

method variables(Any %args) {
  (
    %args,
  )
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

  1;

  # __DATA__
  #
  # @@ component
  #
  # <img
  #   alt="<%= $component->alt %>"
  #   height="<%= $component->height %>"
  #   src="<%= $component->src %>"
  #   width="<%= $component->width %>"
  # />

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

=head2 processor

  processor(InstanceOf["Mojo::Template"])

This attribute is read-only, accepts C<(InstanceOf["Mojo::Template"])> values, and is optional.

=cut

=head2 space

  space(InstanceOf["Data::Object::Space"])

This attribute is read-only, accepts C<(InstanceOf["Data::Object::Space"])> values, and is optional.

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 postprocess

  postprocess(Str $input) : Str

The postprocess method expects a template string. This method is called
automatically after and passed the results of the L</preprocess> method, and
its results are passed to the L</render> method, acting as an I<after>
(template loading) hook.

=over 4

=item postprocess example #1

  # given: synopsis

  my $processed = $component->postprocess('');

=back

=over 4

=item postprocess example #2

  package App::Component::Right::ImageLink;

  use Mojo::Base 'App::Component::Image';

  sub postprocess {
    my ($self, $input) = @_;
    return '<a href="/">' . $input . '</a>';
  }

  package main;

  my $component = App::Component::Right::ImageLink->new;

  my $processed = $component->postprocess($component->template);

=back

=cut

=head2 preprocess

  preprocess(Str $input) : Str

The preprocess method expects a template string. This method is called
automatically before L</postprocess>, after locating the template in the class
hierarchy, acting as a I<before> (template loading) hook.

=over 4

=item preprocess example #1

  # given: synopsis

  my $processed = $component->preprocess('');

=back

=over 4

=item preprocess example #2

  package App::Component::Left::ImageLink;

  use Mojo::Base 'App::Component::Image';

  sub preprocess {
    my ($self, $input) = @_;
    return '<a href="/">' . $input . '</a>';
  }

  package main;

  my $component = App::Component::Left::ImageLink->new;

  my $processed = $component->preprocess($component->template);

=back

=cut

=head2 render

  render(Any %args) : Str

The render method loads the component template string data from the C<DATA>
section of the component class and renders it using the L<Mojo::Template>
object available via L</processor>.

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

=head2 template

  template(Str | Object $object = $self, Str $section = 'component') : (Any)

The template method is used to load template strings from the C<DATA> section
of the class or object specified. The instance invocant will be used if no
specific class or object is presented. If an object is provided but no C<DATA>
section exists, the object's class hierarchy will be searched returning the
first superclass with a matching data section.

=over 4

=item template example #1

  # given: synopsis

  my $template = $component->template;

=back

=over 4

=item template example #2

  # given: synopsis

  my $template = $component->template('App::Component::Image');

=back

=over 4

=item template example #3

  # given: synopsis

  my $template = $component->template(App::Component::Image->new);

=back

=cut

=head2 variables

  variables(Any %args) : (Any)

The variables method is called automatically during template rendering and its
return value, assumed to be key-value pairs, are passed to the template
rendering method as template variables. Any key-value pairs passed to the
L</render> method will be passed to this method making this method, if
overridden, the ideal place to set component template variable defaults and/or
override existing variables.

=over 4

=item variables example #1

  # given: synopsis

  my $variables = {
    $component->variables
  };

=back

=over 4

=item variables example #2

  # given: synopsis

  my $variables = {
    $component->variables(true => 1, false => 0)
  };

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
