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

=cut

=synopsis

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

ok 1 and done_testing;
