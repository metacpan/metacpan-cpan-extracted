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

method: preprocess
method: postprocess
method: render
method: template
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
processor: ro, opt, InstanceOf["Mojo::Template"]

=cut

=description

This package provides an abstract base class for rendering derived
component-based template (partials) classes.

=cut

=method preprocess

The preprocess method expects a template string. This method is called
automatically before L</postprocess>, after locating the template in the class
hierarchy, acting as a I<before> (template loading) hook.

=signature preprocess

preprocess(Str $input) : Str

=example-1 preprocess

  # given: synopsis

  my $processed = $component->preprocess('');

=example-2 preprocess

  package App::Component::Left::ImageLink;

  use Mojo::Base 'App::Component::Image';

  sub preprocess {
    my ($self, $input) = @_;
    return '<a href="/">' . $input . '</a>';
  }

  package main;

  my $component = App::Component::Left::ImageLink->new;

  my $processed = $component->preprocess($component->template);

=cut

=method postprocess

The postprocess method expects a template string. This method is called
automatically after and passed the results of the L</preprocess> method, and
its results are passed to the L</render> method, acting as an I<after>
(template loading) hook.

=signature postprocess

postprocess(Str $input) : Str

=example-1 postprocess

  # given: synopsis

  my $processed = $component->postprocess('');

=example-2 postprocess

  package App::Component::Right::ImageLink;

  use Mojo::Base 'App::Component::Image';

  sub postprocess {
    my ($self, $input) = @_;
    return '<a href="/">' . $input . '</a>';
  }

  package main;

  my $component = App::Component::Right::ImageLink->new;

  my $processed = $component->postprocess($component->template);

=cut
=cut

=method render

The render method loads the component template string data from the C<DATA>
section of the component class and renders it using the L<Mojo::Template>
object available via L</processor>.

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

=method template

The template method is used to load template strings from the C<DATA> section
of the class or object specified. The instance invocant will be used if no
specific class or object is presented. If an object is provided but no C<DATA>
section exists, the object's class hierarchy will be searched returning the
first superclass with a matching data section.

=signature template

template(Str | Object $object = $self, Str $section = 'component') : (Any)

=example-1 template

  # given: synopsis

  my $template = $component->template;

=example-2 template

  # given: synopsis

  my $template = $component->template('App::Component::Image');

=example-3 template

  # given: synopsis

  my $template = $component->template(App::Component::Image->new);

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

$subs->example(-1, 'preprocess', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'preprocess', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !ref $result;
  like $result, qr/<a href="\/"><\/a>/;

  $result
});

$subs->example(-1, 'postprocess', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'postprocess', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  ok !ref $result;
  like $result, qr/<a href="\/"><\/a>/;

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

$subs->example(-1, 'template', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-2, 'template', 'method', fun($tryable) {
  ok !(my $result = $tryable->result);

  $result
});

$subs->example(-3, 'template', 'method', fun($tryable) {
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
