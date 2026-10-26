use strict;
use warnings;
use Test::More;
use FindBin qw< $Bin >;
use lib "$Bin/lib";
use BrandingTest;
use Mojo::File qw< tempdir >;

# files a bad brand or template name could reach if it were not rejected
my %reachable = (%generic, %foo,
   'secret/public/secret.txt'           => 'secret',
   'secret/templates/index.html.ep'     => 'secret page',
   'brands/bar/templates/index.html.ep' => 'bar page',
   'brands/bar/public/only-bar.css'     => 'bar only',
);
my %conf = (individual => {brands => {foo => 'brands/foo', bar => 'brands/bar'}});

# a route that renders whatever template the request asks for: an
# application bug, that the plugin must not make worse
sub add_page_route {
   my ($t) = @_;
   $t->app->routes->get('/page' => sub {
      my $c = shift;
      $c->render(template => $c->param('p'));
   });
   return $t;
}

subtest 'rainy: brands are only those configured' => sub {
   my $t = t_for({%reachable}, \%conf, brand_hook());
   for my $brand ('..', '.', 'secret', '../secret', 'brands/foo', 'foo/',
         "foo\0", '', '0') {
      $t->get_ok('/' => form => {b => $brand})->status_is(200)
         ->content_is("generic page\n", "page for <$brand>");
      $t->get_ok('/secret.txt' => form => {b => $brand})->status_is(404);
      $t->get_ok('/only-bar.css' => form => {b => $brand})->status_is(404);
   }
};

subtest 'rainy: bad brand set by a route' => sub {
   my $t = t_for({%reachable}, \%conf);
   $t->app->routes->get('/v' => sub {
      my $c = shift;
      $c->brand($c->param('b'));
      $c->render(template => 'index');
   });
   $t->get_ok('/v?b=foo')->content_is("foo page\n");    # control
   for my $brand ('..', '../secret', 'secret') {
      $t->get_ok('/v' => form => {b => $brand})->status_is(200)
         ->content_is("generic page\n", "page for brand <$brand>");
   }
};

# the variant is looked up in brand dirs too, it must not escape them
subtest 'rainy: bad variant with a brand' => sub {
   my $t = t_for({%reachable}, \%conf, brand_hook());
   $t->app->routes->get('/v' => sub {
      my $c = shift;
      $c->render(template => 'index', variant => $c->param('v'));
   });
   for my $variant ('..', '../secret', '/../../../secret/templates/index',
         '/../../../../secret/templates/index') {
      $t->get_ok('/v' => form => {b => 'foo', v => $variant})->status_is(200)
         ->content_is("foo page\n", "page for variant <$variant>");
   }
};

subtest 'rainy: absolute template name outside any brand' => sub {
   my $outside = write_files(tempdir, {'evil.html.ep' => 'OUTSIDE'});
   my $t = add_page_route(t_for({%reachable}, \%conf, brand_hook()));
   for my $brand (undef, 'foo') {
      $t->get_ok('/page' => form => {p => "$outside/evil", defined($brand) ? (b => $brand) : ()})
         ->status_is(500)->content_unlike(qr{OUTSIDE});
   }
};

# compiled templates are cached by name: an absolute name sent by the
# client must not hit the cache entry of another brand's template
subtest 'rainy: absolute name of another brand template' => sub {
   my $t = add_page_route(t_for({%reachable}, \%conf, brand_hook()));
   $t->get_ok('/page?b=bar&p=index')->content_is("bar page\n");    # cache it
   my $bar = $t->app->home->child(qw< brands bar templates index >)->to_abs;
   $t->get_ok('/page' => form => {p => "$bar", b => 'foo'})
      ->status_is(500)->content_unlike(qr{bar page});
   $t->get_ok('/page' => form => {p => "$bar"})
      ->status_is(500)->content_unlike(qr{bar page});
};

subtest 'rainy: earlier hook already rendered a response' => sub {
   my $t = t_for({%generic, %foo}, {individual => {brands => {foo => 'brands/foo'}}}, sub {
      my ($app) = @_;
      brand_hook()->($app);
      $app->hook(before_dispatch => sub {
         shift->render(text => 'denied', status => 401);
      });
   });
   $t->get_ok('/site.css' => \%FOO)->status_is(401)->content_is('denied');
   $t->get_ok('/site.css' => \%BAR)->status_is(401)->content_is('denied');
};

done_testing();
