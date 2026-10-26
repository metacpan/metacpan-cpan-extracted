use strict;
use warnings;
use Test::More;
use FindBin qw< $Bin >;
use lib "$Bin/lib";
use BrandingTest;
use Role::Tiny ();

{ package Mojolicious::Static::Role::Probe;   use Mojo::Base -role; sub probe { 'static' } }
{ package Mojolicious::Renderer::Role::Probe; use Mojo::Base -role; sub probe { 'renderer' } }

my %global = ('global/templates/index.html.ep' => 'global page');
my $static_role   = 'Mojolicious::Plugin::Branding::IndividualStaticRole';
my $renderer_role = 'Mojolicious::Plugin::Branding::IndividualRendererRole';

# "+Probe" expands to "<class of the object>::Role::Probe"
sub shorthand_ok {
   my ($app, $name) = @_;
   for my $obj ([static => $app->static], [renderer => $app->renderer]) {
      my ($what, $o) = $obj->@*;
      ok eval { $o->with_roles('+Probe'); 1 }, "+Shorthand on $what, $name"
         or diag $@;
      is eval { $o->probe }, $what, "role applied to $what, $name";
   }
}

# without brands there is nothing to do on static and renderer
subtest 'sunny: no brands, no roles and no helper' => sub {
   for my $case (['no config', {}], ['global only', {global => 'global'}],
         ['empty individual', {global => 'global', individual => {}}],
         ['empty brands', {individual => {brands => {}}}]) {
      my ($name, $conf) = $case->@*;
      my $t = t_for({%generic, %global}, $conf);
      my $app = $t->app;
      ok !Role::Tiny::does_role($app->static, $static_role), "static, $name";
      ok !Role::Tiny::does_role($app->renderer, $renderer_role), "renderer, $name";
      ok !$app->renderer->helpers->{brand}, "no brand helper, $name";
      shorthand_ok($app, $name);
   }
};

# an explicit stash_key or any named brand, even undef, is a request for
# the brand machinery
subtest 'sunny: stash_key or undef brand without real brands sets things up' => sub {
   for my $case (['stash_key only', {stash_key => 'tenant'}],
         ['undef brand', {brands => {foo => undef}}]) {
      my ($name, $individual) = $case->@*;
      my $app = t_for({%generic}, {individual => $individual})->app;
      ok Role::Tiny::does_role($app->static, $static_role), "static, $name";
      ok Role::Tiny::does_role($app->renderer, $renderer_role), "renderer, $name";
      ok $app->renderer->helpers->{brand}, "brand helper, $name";
   }
};

subtest 'sunny: stash_key without brands is kept for later brands' => sub {
   my $t = t_for({%generic, %foo}, {individual => {stash_key => 'tenant'}},
      brand_hook('tenant'));
   eval { $t->app->plugin(Branding => {individual => {stash_key => 'other'}}) };
   like $@, qr{stash_key 'other' conflicts with 'tenant'}, 'key is fixed';
   $t->app->plugin(Branding => {individual => {brands => {foo => 'brands/foo'}}});
   $t->get_ok('/' => \%FOO)->content_is("foo page\n");
   $t->get_ok('/site.css' => \%FOO)->content_is('foo css');
};

subtest 'sunny: global only, then brands in a later registration' => sub {
   my $t = t_for({%generic, %foo, %global}, {global => 'global'}, brand_hook());
   $t->app->plugin(Branding => {individual => {brands => {foo => 'brands/foo'}}});
   $t->get_ok('/' => \%FOO)->content_is("foo page\n");
   $t->get_ok('/site.css' => \%FOO)->content_is('foo css');
   $t->get_ok('/' => \%BAR)->content_is("global page\n");
};

subtest 'sunny: roles applied before the plugin are kept' => sub {
   my $t = t_for({%generic, %foo}, {individual => {brands => {foo => 'brands/foo'}}},
      sub { my ($app) = @_; shorthand_ok($app, 'before plugin'); brand_hook()->($app) });
   is $t->app->static->probe, 'static', 'static role still there';
   is $t->app->renderer->probe, 'renderer', 'renderer role still there';
   $t->get_ok('/' => \%FOO)->content_is("foo page\n");
};

# composing the roles changes the class of static and renderer
TODO: {
   local $TODO = '+Shorthand after the plugin needs a fix for finding 2';
   my $t = t_for({%generic, %foo}, {individual => {brands => {foo => 'brands/foo'}}});
   shorthand_ok($t->app, 'with brands');
}

done_testing();
