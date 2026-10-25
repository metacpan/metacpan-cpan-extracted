use strict;
use warnings;
use Test::More;
use FindBin qw< $Bin >;
use lib "$Bin/lib";
use BrandingTest;
use Mojo::File qw< tempdir path >;

my %individual = (individual => {paths => ['brands/foo']});

subtest 'sunny: brand from the stash' => sub {
   my $t = t_for({%generic, %foo}, \%individual, brand_hook());
   $t->get_ok('/' => \%FOO)->status_is(200)->content_is("foo page\n");
   $t->get_ok('/site.css' => \%FOO)->status_is(200)->content_is('foo css');
   $t->get_ok('/' => \%BAR)->status_is(200)->content_is("generic page\n");
   $t->get_ok('/site.css' => \%BAR)->status_is(200)->content_is('generic css');
};

# compiled templates are cached by name, brand and app must not share one
subtest 'sunny: brand and app templates are cached apart' => sub {
   my $t = t_for({%generic, %foo}, \%individual, brand_hook());
   $t->get_ok('/' => \%FOO)->content_is("foo page\n");
   $t->get_ok('/' => \%BAR)->content_is("generic page\n");
   $t = t_for({%generic, %foo}, \%individual, brand_hook());
   $t->get_ok('/' => \%BAR)->content_is("generic page\n");
   $t->get_ok('/' => \%FOO)->content_is("foo page\n");
};

subtest 'sunny: unknown brand falls back to generic' => sub {
   my $t = t_for({%generic, %foo}, \%individual, brand_hook());
   $t->get_ok('/?b=nope')->status_is(200)->content_is("generic page\n");
   $t->get_ok('/site.css?b=nope')->status_is(200)->content_is('generic css');
};

subtest 'sunny: brand without some files falls back to generic' => sub {
   my $t = t_for({%generic, 'brands/foo/public/other.css' => 'foo other'},
      \%individual, brand_hook());
   $t->get_ok('/' => \%FOO)->status_is(200)->content_is("generic page\n");
   $t->get_ok('/site.css' => \%FOO)->status_is(200)->content_is('generic css');
   $t->get_ok('/other.css' => \%FOO)->status_is(200)->content_is('foo other');
};

subtest 'sunny: custom stash_key' => sub {
   for my $case (['templates only', {%generic,
            'brands/foo/templates/index.html.ep' => 'foo page'}],
         ['templates and public', {%generic, %foo}]) {
      my ($name, $files) = $case->@*;
      my $t = t_for($files,
         {individual => {paths => ['brands/foo'], stash_key => 'tenant'}},
         brand_hook('tenant'));
      $t->get_ok('/' => \%FOO)->content_is("foo page\n", "page, $name");
      $t->get_ok('/' => \%BAR)->content_is("generic page\n", "generic, $name");
   }
};

subtest 'sunny: paths as a plain string, absolute, Mojo::File' => sub {
   my $elsewhere = write_files(tempdir,
      {map { (s{\Abrands/}{}r => $foo{$_}) } keys %foo});
   my $abs = "$elsewhere/foo";
   for my $case (['plain string', 'brands/foo'], ['absolute', [$abs]],
         ['Mojo::File', [path($abs)]], ['lone Mojo::File', path($abs)]) {
      my ($name, $paths) = $case->@*;
      my $t = t_for({%generic, %foo}, {individual => {paths => $paths}},
         brand_hook());
      $t->get_ok('/' => \%FOO)->content_is("foo page\n", "page, $name");
      $t->get_ok('/site.css' => \%FOO)->content_is('foo css', "css, $name");
   }
};

subtest 'sunny: one brand scattered across directories, first wins' => sub {
   my $t = t_for({%generic,
      'a/foo/templates/index.html.ep' => "% layout 'default';\na page",
      'a/foo/public/only-a.css'       => 'only a',
      'a/foo/public/site.css'         => 'a css',
      'b/foo/templates/index.html.ep' => 'b page',
      'b/foo/templates/layouts/default.html.ep' => 'b layout <%= content %>',
      'b/foo/public/site.css'         => 'b css',
      'b/foo/public/only-b.css'       => 'only b'},
      {individual => {paths => ['a/foo', 'b/foo']}}, brand_hook());
   $t->get_ok('/' => \%FOO)->content_is("b layout a page\n\n");
   $t->get_ok('/site.css' => \%FOO)->content_is('a css');
   $t->get_ok('/only-a.css' => \%FOO)->content_is('only a');
   $t->get_ok('/only-b.css' => \%FOO)->content_is('only b');
};

subtest 'sunny: several brands' => sub {
   my $t = t_for({%generic, %foo,
      'brands/bar/templates/index.html.ep' => 'bar page',
      'brands/bar/public/site.css'         => 'bar css'},
      {individual => {paths => ['brands/foo', 'brands/bar']}}, brand_hook());
   $t->get_ok('/?b=bar')->content_is("bar page\n");
   $t->get_ok('/site.css?b=bar')->content_is('bar css');
   $t->get_ok('/?b=foo')->content_is("foo page\n");
   $t->get_ok('/site.css?b=foo')->content_is('foo css');
};

subtest 'sunny: brand layouts and partials, app partials' => sub {
   my $t = t_for({%generic,
      'templates/_app.html.ep' => 'app part',
      'brands/foo/templates/_brand.html.ep' => 'brand part',
      'brands/foo/templates/layouts/default.html.ep' => 'L <%= content %>',
      'brands/foo/templates/index.html.ep' =>
         "% layout 'default';\n<%= include '_brand' %> <%= include '_app' %>"},
      \%individual, brand_hook());
   $t->get_ok('/' => \%FOO)->content_is("L brand part\n app part\n\n\n");
   $t->get_ok('/' => \%BAR)->content_is("generic page\n");
};

subtest 'sunny: brand template with a different handler' => sub {
   my $t = t_for({'templates/index.html.epl' => 'app epl',
      'brands/foo/templates/index.html.ep'   => 'brand ep',
      'brands/foo/templates/extra.html.epl'  => 'brand-only epl'},
      \%individual, brand_hook());
   $t->app->routes->get('/extra' => sub { shift->render(template => 'extra') });
   $t->get_ok('/' => \%FOO)->content_is("brand ep\n");
   $t->get_ok('/' => \%BAR)->content_is("app epl\n");
   $t->get_ok('/extra' => \%FOO)->status_is(200)->content_is("brand-only epl\n");
};

# Mojolicious reads a leading slash as relative to the template paths
subtest 'sunny: template names with a leading slash' => sub {
   my $t = t_for({%generic, %foo, 'templates/epl.html.epl' => 'app epl'},
      \%individual, brand_hook());
   $t->app->routes->get('/slash/*p' => sub {
      my $c = shift;
      $c->render(template => '/' . $c->param('p'));
   });
   $t->get_ok('/slash/index' => \%FOO)->content_is("foo page\n");
   $t->get_ok('/slash/index' => \%BAR)->content_is("generic page\n");
   $t->get_ok('/slash/epl' => \%FOO)->status_is(200)->content_is("app epl\n");
};

subtest 'sunny: variant set by a route' => sub {
   my $t = t_for({%generic, %foo}, \%individual);
   $t->app->routes->get('/v' => sub {
      shift->render(template => 'index', variant => 'foo');
   });
   $t->get_ok('/v')->content_is("foo page\n");
   $t->get_ok('/')->content_is("generic page\n");
};

subtest 'sunny: individual wins over global' => sub {
   my $t = t_for({%generic, %foo,
      'global/templates/index.html.ep' => 'global page',
      'global/public/site.css'         => 'global css'},
      {global => 'global', %individual}, brand_hook());
   $t->get_ok('/' => \%FOO)->content_is("foo page\n");
   $t->get_ok('/site.css' => \%FOO)->content_is('foo css');
   $t->get_ok('/' => \%BAR)->content_is("global page\n");
   $t->get_ok('/site.css' => \%BAR)->content_is('global css');
};

subtest 'sunny: registering twice merges brands' => sub {
   my $t = t_for({%generic,
      'one/foo/templates/index.html.ep' => 'foo page',
      'one/foo/public/site.css'         => 'foo css',
      'two/bar/templates/index.html.ep' => 'bar page',
      'two/foo/templates/extra.html.ep' => 'foo extra'},
      {individual => {paths => ['one/foo']}}, brand_hook());
   $t->app->plugin(Branding => {individual => {paths => ['two/bar', 'two/foo']}});
   $t->app->routes->get('/extra' => sub { shift->render(template => 'extra') });
   $t->get_ok('/?b=foo')->content_is("foo page\n");
   $t->get_ok('/?b=bar')->content_is("bar page\n");
   $t->get_ok('/extra?b=foo')->content_is("foo extra\n");
   $t->get_ok('/site.css?b=foo')->content_is('foo css');
};

subtest 'sunny: after_static runs for branded files' => sub {
   my @seen;
   my $t = t_for({%generic, %foo}, \%individual, sub {
      my ($app) = @_;
      brand_hook()->($app);
      $app->hook(after_static => sub { push @seen, shift->req->url->path });
   });
   $t->get_ok('/site.css' => \%FOO)->content_is('foo css');
   is_deeply \@seen, ['/site.css'], 'hook ran once';
};

done_testing();
