use Mojo::Base -strict;

use Test::More;
use Mojolicious;

# Partial rendering
my $app = Mojolicious->new(secrets => ['works']);
$app->plugin('TemplatePerlish');
my $c = $app->build_controller();
$c->app->log->level('fatal');
is $c->render_to_string(inline => 'works', handler => 'tp'), 'works',
  'renderer is working';

$app->renderer->default_handler('tp');

# Stash variable
is $c->render_to_string(inline => '[% foo %]', foo => 'bar'), 'bar',
  'stash variable is passed';

# Helper
is $c->render_to_string(
   inline => '[%= V("stash")->("foo") %]',
   foo    => 'bar'
  ),
  'bar', 'helper works';
like $c->render_to_string(inline =>
     "[%= V('link_to')->('some link', 'http://www.example.com') %]"),
  qr(href.+http://www\.example\.com.+some link), 'helper works';

# Controller
is $c->render_to_string(inline => '[% c.stash.foo %]', foo => 'bar'),
  'bar', 'controller is accessible';

# Encoding
is $c->render_to_string(inline => '☃'), '☃', 'encoding works';
is $c->render_to_string(inline => '[% foo %]', foo => '☃'), '☃',
  'encoding works';

# Set configuration
$app = Mojolicious->new(secrets => ['works']);
my $tp_config = {
   start => '<%',
   stop  => '%>',
};
$app->plugin(
   TemplatePerlish => {name => 'foo', template_perlish => $tp_config});
$c = $app->build_controller;
$c->app->log->level('fatal');

is $c->render_to_string(inline => 'foo', handler => 'foo'), 'foo',
  'name works';
is $c->render_to_string(
   inline  => '<% foo %>',
   handler => 'foo',
   foo     => 'bar'
  ),
  'bar', 'tags work';

done_testing() && exit 0;

done_testing();
