use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Mojolicious::Component

=cut

=tagline

Module-based Template Class

=cut

=abstract

Module-based Template Base Class

=cut

=includes

method: render
method: variables

=cut

=synopsis

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

=attributes

controller: ro, opt, InstanceOf["Mojolicious::Controller"]
space: ro, opt, InstanceOf["Data::Object::Space"]
template: ro, opt, InstanceOf["Mojo::Template"]

=cut

=description

This package provides an abstract base class for rendering derived
component-based template (partials) classes.

=cut

=method render

The render method loads the component template string data from the C<DATA>
section of the component class and renders it using the L<Mojo::Template>
object available via L</template>.

=signature render

render(Any %args) : Str

=example-1 render

  # given: synopsis

  my $rendered = $component->render;

=example-2 render

  # given: synopsis

  my $rendered = $component->render(
    readonly => 1,
  );

=cut

=method variables

The variables method is called automatically during template rendering and its
return value, assumed to be key-value pairs, are passed to the template
rendering method as template variables. Any key-value pairs passed to the
L</render> method will be passed to this method making this method, if
overridden, the ideal place to set component template variable defaults and/or
override existing variables.

=signature variables

variables(Any %args) : (Any)

=example-1 variables

  # given: synopsis

  my $variables = {
    $component->variables
  };

=example-2 variables

  # given: synopsis

  my $variables = {
    $component->variables(true => 1, false => 0)
  };

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'render', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'render', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-1, 'variables', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is ref($result), 'HASH';
  ok !%$result;

  $result
});

$subs->example(-2, 'variables', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  is ref($result), 'HASH';
  ok %$result;
  is $result->{true}, 1;
  is $result->{false}, 0;

  $result
});

ok 1 and done_testing;
