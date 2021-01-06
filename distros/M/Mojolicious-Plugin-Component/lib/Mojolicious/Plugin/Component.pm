package Mojolicious::Plugin::Component;

use 5.014;

use strict;
use warnings;
use routines;

use Data::Object::Class;
use Data::Object::Space;

extends 'Mojolicious::Plugin';

method register($app, $config = {}) {
  $config = (%$config) ? $config : $app->config->{component} || {
    use => join('::', ref($app), 'Component'),
  };
  for my $name (sort keys %$config) {
    my $method = $name =~ s/\W+/_/gr;
    my $module = $config->{$name} or next;
    $app->helper("component.$method", fun($c, $child, %args) {
      if (!$child) {
        return undef;
      }
      Data::Object::Space->new($module)->append($child)->build(
        controller => $c,
        %args
      );
    });
  }
  return $self;
}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Component - Module-based Component Rendering

=cut

=head1 ABSTRACT

Module-based Component Rendering Plugin

=cut

=head1 SYNOPSIS

  package App;

  use Mojo::Base 'Mojolicious';

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

  my $app = App->new;

  my $component = $app->plugin('component');

  my $image = $app->component->use('image');

  my $rendered = $image->render;

=cut

=head1 DESCRIPTION

This package provides L<Mojolicious> module-based component rendering plugin.

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Mojolicious::Plugin>

=cut

=head1 METHODS

This package implements the following methods:

=cut

=head2 register

  register(InstanceOf["Mojolicious"] $app, Maybe[HashRef] $config) : Object

The register method registers one or more component builders in the
L<Mojolicious> application. The configuration information can be provided when
registering the plugin by calling L<plugin> during setup, or by specifying the
data in the application configuration under the key C<component>. By default,
if no configuration information is provided the plugin will register a builder
labeled C<use> which will load components under the application's C<Component>
namespace.

=over 4

=item register example #1

  package main;

  use Mojolicious::Plugin::Component;

  my $app = Mojolicious->new;

  my $component = Mojolicious::Plugin::Component->new;

  $component = $component->register($app);

=back

=over 4

=item register example #2

  package main;

  use Mojolicious::Plugin::Component;

  my $app = Mojolicious->new;

  my $component = Mojolicious::Plugin::Component->new;

  $component = $component->register($app, {
    v1 => 'App::V1::Component',
    v2 => 'App::V2::Component',
  });

  # my $v1 = $app->component->v1('image');
  # my $v2 = $app->component->v2('image');

=back

=over 4

=item register example #3

  package main;

  use Mojolicious::Plugin::Component;

  my $app = Mojolicious->new;

  my $component = Mojolicious::Plugin::Component->new;

  $component = $component->register($app, {
    v1 => 'App::V1::Component',
    v2 => 'App::V2::Component',
  });

  # my $v1 = $app->component->v1('image' => (
  #   src => '/random-v1.gif',
  # ));

  # my $v2 = $app->component->v2('image' => (
  #   src => '/random-v2.gif',
  # ));

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
