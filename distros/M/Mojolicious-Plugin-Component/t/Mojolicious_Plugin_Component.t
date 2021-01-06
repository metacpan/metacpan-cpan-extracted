use 5.014;

use strict;
use warnings;
use routines;

use Test::Auto;
use Test::More;

=name

Mojolicious::Plugin::Component

=cut

=tagline

Module-based Component Rendering

=cut

=abstract

Module-based Component Rendering Plugin

=cut

=includes

method: register

=cut

=synopsis

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

=inherits

Mojolicious::Plugin

=cut

=description

This package provides L<Mojolicious> module-based component rendering plugin.

=cut

=method register

The register method registers one or more component builders in the
L<Mojolicious> application. The configuration information can be provided when
registering the plugin by calling L<plugin> during setup, or by specifying the
data in the application configuration under the key C<component>. By default,
if no configuration information is provided the plugin will register a builder
labeled C<use> which will load components under the application's C<Component>
namespace.

=signature register

register(InstanceOf["Mojolicious"] $app, Maybe[HashRef] $config) : Object

=example-1 register

  package main;

  use Mojolicious::Plugin::Component;

  my $app = Mojolicious->new;

  my $component = Mojolicious::Plugin::Component->new;

  $component = $component->register($app);

=example-2 register

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

=example-3 register

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

=cut

package main;

my $test = testauto(__FILE__);

my $subs = $test->standard;

$subs->synopsis(fun($tryable) {
  ok my $result = $tryable->result;

  $result
});

$subs->example(-1, 'register', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  my $app = App->new;
  my $component = $app->plugin('component');
  is ref($result), 'Mojolicious::Plugin::Component';
  is ref($component), ref($result);
  my $image = $app->component->use('image');
  is ref($image), 'App::Component::Image';
  my $rendered = $image->render;
  like $rendered, qr/<img/;
  like $rendered, qr/alt="random"/;
  like $rendered, qr/height="126"/;
  like $rendered, qr/src="\/random\.gif"/;
  like $rendered, qr/width="145"/;
  unlike $rendered, qr/readonly="readonly"/;
  $result
});

$subs->example(-2, 'register', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  my $app = App->new;
  my $component = $app->plugin('component', {
    v1 => 'App::V1::Component',
    v2 => 'App::V2::Component',
  });
  my $image1 = $app->component->v1('image');
  my $rendered1 = $image1->render;
  like $rendered1, qr/<img/;
  like $rendered1, qr/alt="random"/;
  like $rendered1, qr/height="126"/;
  like $rendered1, qr/src="\/random\.gif"/;
  like $rendered1, qr/width="145"/;
  unlike $rendered1, qr/readonly="readonly"/;
  my $image2 = $app->component->v2('image');
  my $rendered2 = $image2->render;
  like $rendered2, qr/<img/;
  like $rendered2, qr/alt="random"/;
  like $rendered2, qr/height="126"/;
  like $rendered2, qr/src="\/random\.gif"/;
  like $rendered2, qr/width="145"/;
  unlike $rendered2, qr/readonly="readonly"/;
  $result
});

$subs->example(-2, 'register', 'method', fun($tryable) {
  ok my $result = $tryable->result;
  my $app = App->new;
  my $component = $app->plugin('component', {
    v1 => 'App::V1::Component',
    v2 => 'App::V2::Component',
  });
  my $image1 = $app->component->v1('image');
  my $rendered1 = $image1->render(
    readonly => 1,
  );
  like $rendered1, qr/<img/;
  like $rendered1, qr/alt="random"/;
  like $rendered1, qr/height="126"/;
  like $rendered1, qr/src="\/random\.gif"/;
  like $rendered1, qr/width="145"/;
  like $rendered1, qr/readonly="readonly"/;
  my $image2 = $app->component->v2('image');
  my $rendered2 = $image2->render(
    readonly => 1,
  );
  like $rendered2, qr/<img/;
  like $rendered2, qr/alt="random"/;
  like $rendered2, qr/height="126"/;
  like $rendered2, qr/src="\/random\.gif"/;
  like $rendered2, qr/width="145"/;
  like $rendered2, qr/readonly="readonly"/;
  $result
});

ok 1 and done_testing;

package
  App::Component::Image;

sub import;

package
  App::V1::Component::Image;

use base 'App::Component::Image';

package
  App::V2::Component::Image;

use base 'App::Component::Image';

package
  App::Component::Image;

1;

__DATA__

@@ component

% no strict;

<img
  alt="<%= $component->alt %>"
  height="<%= $component->height %>"
  src="<%= $component->src %>"
  width="<%= $component->width %>"
  <% if ($readonly) { %>
  readonly="readonly"
  <% } %>
/>
