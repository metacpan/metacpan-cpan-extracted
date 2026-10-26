use strict;
use warnings;
use Test::More;
use FindBin qw< $Bin >;
use lib "$Bin/lib";
use BrandingTest;
use Mojo::File qw< tempdir path >;

my %individual = (individual => {brands => {foo => 'brands/foo'}});

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

# e.g. a cache shared across processes, brands must use the same class
subtest 'sunny: brand renderer cache has the same class' => sub {
   {
      package Local::Cache;
      use Mojo::Base 'Mojo::Cache';
      our @seen;
      sub set { my $self = shift; push @seen, $self; $self->SUPER::set(@_) }
   }
   my $seen = \@Local::Cache::seen;
   my $t = t_for({%generic, %foo}, \%individual, sub {
      my ($app) = @_;
      brand_hook()->($app);
      $app->renderer->cache(Local::Cache->new(max_keys => 7));
   });
   my $app_cache = $t->app->renderer->cache;
   $t->get_ok('/' => \%FOO)->content_is("foo page\n");
   my @brand = grep { $_ != $app_cache } @$seen;
   ok scalar(@brand), 'brand renderer uses a Local::Cache';
   is $brand[0]->max_keys, 7, 'same size' if @brand;
   $t->get_ok('/' => \%BAR)->content_is("generic page\n");
   ok scalar(grep { $_ == $app_cache } @$seen), 'app keeps its own cache';
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

# the brand name is the key in the configuration, not the directory name
subtest 'sunny: brand name independent of the directory' => sub {
   my $t = t_for({%generic, %foo},
      {individual => {brands => {acme => 'brands/foo'}}}, brand_hook());
   $t->get_ok('/?b=acme')->content_is("foo page\n");
   $t->get_ok('/site.css?b=acme')->content_is('foo css');
   $t->get_ok('/' => \%FOO)->content_is("generic page\n");
};

subtest 'sunny: brand specification shorthands' => sub {
   my $elsewhere = write_files(tempdir,
      {map { (s{\Abrands/}{}r => $foo{$_}) } keys %foo});
   my $abs = "$elsewhere/foo";
   for my $case (
         ['plain string',     'brands/foo'],
         ['absolute',         $abs],
         ['Mojo::File',       path($abs)],
         ['relative Mojo::File', path('brands/foo')],
         ['array',            ['brands/foo']],
         ['paths string',     {paths => 'brands/foo'}],
         ['paths array',      {paths => ['brands/foo']}],
         ['sub-specs as strings',
            {templates => 'brands/foo/templates', public => 'brands/foo/public'}],
         ['sub-specs as arrays',
            {templates => ['brands/foo/templates'], public => [path($abs, 'public')]}],
         ['sub-specs as hashes',
            {templates => {paths => 'brands/foo/templates'},
             public    => {paths => ['brands/foo/public']}}]) {
      my ($name, $spec) = $case->@*;
      my $t = t_for({%generic, %foo}, {individual => {brands => {foo => $spec}}},
         brand_hook());
      $t->get_ok('/' => \%FOO)->content_is("foo page\n", "page, $name");
      $t->get_ok('/site.css' => \%FOO)->content_is('foo css', "css, $name");
   }
};

# a valid configuration must not trigger die handlers, e.g. a logger
subtest 'sunny: valid configuration does not call $SIG{__DIE__}' => sub {
   my $t = t_for({%generic, %foo, 'global/templates/x.html.ep' => 'x'}, {});
   my @died;
   local $SIG{__DIE__} = sub { push @died, $_[0] };
   $t->app->plugin(Branding => {
      global     => {paths => ['global', path('global')]},
      individual => {brands => {
         foo => ['brands/foo', path('brands/foo')],
         bar => {paths => ['brands/foo'], templates => ['brands/foo/templates']},
         baz => path('brands/foo'),
      }},
   });
   is scalar(@died), 0, 'no die handler calls' or diag explain \@died;
};

# specific paths come before the common ones
subtest 'sunny: sub-spec paths before common paths' => sub {
   my $t = t_for({%generic, %foo,
      'special/templates/index.html.ep' => 'special page',
      'special/public/site.css'         => 'special css'},
      {individual => {brands => {foo => {paths => 'brands/foo',
         templates => 'special/templates', public => 'special/public'}}}},
      brand_hook());
   $t->get_ok('/' => \%FOO)->content_is("special page\n");
   $t->get_ok('/site.css' => \%FOO)->content_is('special css');
};

subtest 'sunny: ignore_app_paths' => sub {
   my %files = (%generic, %foo,
      'templates/other.html.ep' => 'app other',
      'public/other.css'        => 'app other css');
   # a missing template is a 500, a missing public file a 404
   for my $case (
         ['nothing ignored', {},
            "foo page\n", "app other\n", 'foo css', 'app other css'],
         ['templates ignored', {templates => {ignore_app_paths => 1}},
            "foo page\n", 500, 'foo css', 'app other css'],
         ['public ignored', {public => {ignore_app_paths => 1}},
            "foo page\n", "app other\n", 'foo css', 404]) {
      my ($name, $extra, @expected) = $case->@*;
      my $t = t_for(\%files, {individual => {brands => {foo =>
         {paths => 'brands/foo', %$extra}}}}, brand_hook());
      $t->app->routes->get('/other' => sub { shift->render(template => 'other') });
      for my $url ('/', '/other', '/site.css', '/other.css') {
         my $want = shift @expected;
         $t->get_ok($url => \%FOO);
         if ($want =~ m{\A\d+\z}) { $t->status_is($want, "$url, $name") }
         else                     { $t->content_is($want, "$url, $name") }
      }
      $t->get_ok('/other' => \%BAR)->content_is("app other\n", "app unaffected, $name");
   }
};

subtest 'sunny: branded not_found page, bundled files kept' => sub {
   my $t = t_for({%generic, %foo,
      'brands/foo/templates/not_found.html.ep' => 'foo missing'},
      {individual => {brands => {foo => {paths => 'brands/foo',
         public => {ignore_app_paths => 1}}}}}, brand_hook());
   $t->app->mode('production');
   $t->get_ok('/nope' => \%FOO)->status_is(404)->content_is("foo missing\n");
   $t->get_ok('/nope' => \%BAR)->status_is(404)->content_unlike(qr{foo missing});
   $t->get_ok('/mojo/mojo.css' => \%FOO)->status_is(200);
};

subtest 'sunny: custom stash_key' => sub {
   for my $case (['templates only', {%generic,
            'brands/foo/templates/index.html.ep' => 'foo page'}],
         ['templates and public', {%generic, %foo}]) {
      my ($name, $files) = $case->@*;
      my $t = t_for($files,
         {individual => {brands => {foo => 'brands/foo'}, stash_key => 'tenant'}},
         brand_hook('tenant'));
      $t->get_ok('/' => \%FOO)->content_is("foo page\n", "page, $name");
      $t->get_ok('/' => \%BAR)->content_is("generic page\n", "generic, $name");
   }
};

# static dispatch skips non-GET requests, templates must be branded anyway
subtest 'sunny: custom stash_key, POST and route override' => sub {
   my $t = t_for({%generic, %foo},
      {individual => {brands => {foo => 'brands/foo'}, stash_key => 'tenant'}},
      brand_hook('tenant'));
   my $r = $t->app->routes;
   $r->post('/' => sub { shift->render(template => 'index') });
   $r->get('/plain' => sub { shift->render(template => 'index', tenant => undef) });
   $t->post_ok('/' => \%FOO)->content_is("foo page\n");
   $t->get_ok('/plain' => \%FOO)->content_is("generic page\n");
};

subtest 'sunny: custom stash_key from a route placeholder' => sub {
   my $t = t_for({%generic, %foo},
      {individual => {brands => {foo => 'brands/foo'}, stash_key => 'tenant'}});
   $t->app->routes->get('/:tenant/x' => sub { shift->render(template => 'index') });
   $t->get_ok('/foo/x')->content_is("foo page\n");
   $t->get_ok('/nope/x')->content_is("generic page\n");
};

# core rules over brand dirs followed by app dirs: a variant found
# anywhere wins over a plain template, then the first directory wins
subtest 'sunny: brands combine with application variants' => sub {
   my $t = t_for({%generic, %foo,
      'templates/index.html+phone.ep'            => 'app phone',
      'templates/other.html.ep'                  => 'app other',
      'templates/other.html+phone.ep'            => 'app other phone',
      'brands/foo/templates/other.html+phone.ep' => 'foo other phone',
      'templates/solo.html.ep'                   => 'app solo',
      'brands/foo/templates/solo.html+phone.ep'  => 'foo solo phone'},
      \%individual, sub {
         my ($app) = @_;
         brand_hook()->($app);
         $app->hook(before_dispatch => sub {
            my $c = shift;
            $c->stash(variant => 'phone') if $c->param('m');
         });
      });
   $t->app->routes->get('/:t' => sub {
      my $c = shift;
      $c->render(template => $c->stash('t'));
   });
   $t->get_ok('/' => \%FOO)->content_is("foo page\n", 'brand, no variant');
   $t->get_ok('/?m=1' => \%FOO)->content_is("app phone\n", 'app variant beats brand');
   $t->get_ok('/?m=1' => \%BAR)->content_is("app phone\n", 'app variant, no brand');
   $t->get_ok('/?b=nope&m=1')->content_is("app phone\n", 'app variant, unknown brand');
   $t->get_ok('/other?m=1' => \%FOO)->content_is("foo other phone\n", 'brand variant');
   $t->get_ok('/solo?m=1' => \%FOO)
      ->content_is("foo solo phone\n", 'brand variant, none in the app');
   $t->get_ok('/solo' => \%FOO)->content_is("app solo\n", 'no variant, no brand file');
};

subtest 'sunny: brand kept across includes' => sub {
   my $t = t_for({%generic, %foo,
      'templates/inc.html.ep' => "<%= include 'part' %>|<%= include 'part' %>",
      'templates/part.html.ep' => 'app part',
      'brands/foo/templates/part.html.ep' => 'foo part'},
      \%individual, brand_hook());
   $t->app->routes->get('/inc' => sub { shift->render(template => 'inc') });
   $t->get_ok('/inc' => \%FOO)->content_is("foo part\n|foo part\n\n");
   $t->get_ok('/inc' => \%BAR)->content_is("app part\n|app part\n\n");
};

# the most common branding: only the layout is overridden
subtest 'sunny: brand layout around an app page' => sub {
   my $t = t_for({%generic,
      'templates/layouts/default.html.ep'            => 'APP[<%= content %>]',
      'templates/lay.html.ep'                        => "% layout 'default';\napp lay",
      'brands/foo/templates/layouts/default.html.ep' => 'FOO[<%= content %>]'},
      \%individual, brand_hook());
   $t->app->routes->get('/lay' => sub { shift->render(template => 'lay') });
   $t->get_ok('/lay' => \%FOO)->content_is("FOO[app lay\n]\n");
   $t->get_ok('/lay' => \%BAR)->content_is("APP[app lay\n]\n");
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
      {individual => {brands => {foo => ['a/foo', 'b/foo']}}}, brand_hook());
   $t->get_ok('/' => \%FOO)->content_is("b layout a page\n\n");
   $t->get_ok('/site.css' => \%FOO)->content_is('a css');
   $t->get_ok('/only-a.css' => \%FOO)->content_is('only a');
   $t->get_ok('/only-b.css' => \%FOO)->content_is('only b');
};

subtest 'sunny: several brands' => sub {
   my $t = t_for({%generic, %foo,
      'brands/bar/templates/index.html.ep' => 'bar page',
      'brands/bar/public/site.css'         => 'bar css'},
      {individual => {brands => {foo => 'brands/foo', bar => 'brands/bar'}}},
      brand_hook());
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

# Mojolicious reads a leading slash as relative to the template paths, but
# only finds the default handler that way: brands behave the same
subtest 'sunny: template names with a leading slash' => sub {
   my $t = t_for({%generic, %foo, 'templates/epl.html.epl' => 'app epl'},
      \%individual, brand_hook());
   $t->app->routes->get('/slash/*p' => sub {
      my $c = shift;
      $c->render(template => '/' . $c->param('p'));
   });
   $t->get_ok('/slash/index' => \%FOO)->content_is("foo page\n");
   $t->get_ok('/slash/index' => \%BAR)->content_is("generic page\n");
   $t->get_ok('/slash/epl' => \%BAR)->status_is(500, 'core: not found');
   $t->get_ok('/slash/epl' => \%FOO)->status_is(500, 'same as core');
};

subtest 'sunny: brand set by a route' => sub {
   my $t = t_for({%generic, %foo}, \%individual);
   $t->app->routes->get('/v' => sub {
      my $c = shift;
      $c->brand('foo');
      $c->render(template => 'index');
   });
   $t->get_ok('/v')->content_is("foo page\n");
   $t->get_ok('/')->content_is("generic page\n");
};

# like stash and other Mojolicious setters, the setter returns $c
subtest 'sunny: brand setter can be chained' => sub {
   my $t = t_for({%generic, %foo}, \%individual);
   my $returned;
   $t->app->routes->get('/v' => sub {
      my $c = shift;
      $returned = $c->brand('foo');
      $c->brand('foo')->render(template => 'index');
   });
   $t->get_ok('/v')->status_is(200)->content_is("foo page\n");
   isa_ok $returned, 'Mojolicious::Controller', 'setter result';
};

# the plugin must not depend on whatever a "brand" helper returns
subtest 'sunny: application with its own brand helper' => sub {
   my $own = sub { return {name => 'not a brand name'} };
   my $before = t_for({%generic, %foo}, \%individual, sub {
      my ($app) = @_;
      brand_hook()->($app);
      $app->helper(brand => $own);
   });
   my $after = t_for({%generic, %foo}, \%individual, brand_hook());
   $after->app->helper(brand => $own);
   for my $case (['helper before plugin', $before],
         ['helper after plugin', $after]) {
      my ($name, $t) = $case->@*;
      $t->get_ok('/' => \%FOO)->content_is("foo page\n", "page, $name");
      $t->get_ok('/site.css' => \%FOO)->content_is('foo css', "css, $name");
      $t->get_ok('/' => \%BAR)->content_is("generic page\n", "generic, $name");
   }
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

subtest 'sunny: a later registration replaces a brand' => sub {
   my $t = t_for({%generic,
      'one/foo/templates/index.html.ep' => 'foo page',
      'one/foo/public/site.css'         => 'foo css',
      'two/bar/templates/index.html.ep' => 'bar page',
      'two/foo/templates/extra.html.ep' => 'foo extra'},
      {individual => {brands => {foo => 'one/foo'}}}, brand_hook());
   $t->app->plugin(Branding =>
      {individual => {brands => {bar => 'two/bar', foo => 'two/foo'}}});
   $t->app->routes->get('/extra' => sub { shift->render(template => 'extra') });
   $t->get_ok('/?b=bar')->content_is("bar page\n");
   $t->get_ok('/extra?b=foo')->content_is("foo extra\n");
   $t->get_ok('/?b=foo')->content_is("generic page\n", 'one/foo is gone');
   $t->get_ok('/site.css?b=foo')->content_is('generic css', 'one/foo is gone');
};

subtest 'sunny: a later registration removes a brand with undef' => sub {
   my $t = t_for({%generic, %foo,
      'brands/bar/templates/index.html.ep' => 'bar page',
      'brands/bar/public/site.css'         => 'bar css'},
      {individual => {brands => {foo => 'brands/foo', bar => 'brands/bar'}}},
      brand_hook());
   $t->get_ok('/' => \%FOO)->content_is("foo page\n", 'foo before removal');
   $t->app->plugin(Branding => {individual => {brands => {foo => undef}}});
   $t->get_ok('/' => \%FOO)->content_is("generic page\n", 'foo page is gone');
   $t->get_ok('/site.css' => \%FOO)->content_is('generic css', 'foo css is gone');
   $t->get_ok('/?b=bar')->content_is("bar page\n", 'bar untouched');
   $t->get_ok('/site.css?b=bar')->content_is('bar css', 'bar css untouched');
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
