use strict;
use warnings;
use Test::More;
use FindBin qw< $Bin >;
use lib "$Bin/lib";
use BrandingTest;
use Mojo::IOLoop;

# Branded static files must be served at the same point in the request as
# core static files, so they honor the same guards and settings.

my %individual = (individual => {brands => {foo => 'brands/foo'}});

subtest 'render_later in an earlier hook stops static serving' => sub {
   my $t = t_for({%generic, %foo}, \%individual, sub {
      my ($app) = @_;
      brand_hook()->($app);
      $app->hook(before_dispatch => sub {
         my $c = shift->render_later;
         Mojo::IOLoop->timer(0 => sub {
            $c->render(text => 'denied', status => 401);
         });
      });
   });
   $t->get_ok('/site.css' => \%BAR)->status_is(401)->content_is('denied');
   $t->get_ok('/site.css' => \%FOO)->status_is(401)->content_is('denied');
};

# the later render overwrites the response, so check nothing was served
subtest 'hook registered after the plugin still guards static files' => sub {
   my @served;
   my $t = t_for({%generic, %foo}, \%individual, sub {
      my ($app) = @_;
      brand_hook()->($app);
      $app->hook(after_static => sub { push @served, shift->req->url->path });
   });
   $t->app->hook(before_dispatch => sub {
      shift->render(text => 'maintenance', status => 503);
   });
   $t->get_ok('/site.css' => \%BAR)->status_is(503)->content_is('maintenance');
   $t->get_ok('/site.css' => \%FOO)->status_is(503)->content_is('maintenance');
   is_deeply \@served, [], 'no static file served';
};

subtest 'static prefix set after registering the plugin' => sub {
   my $t = t_for({%generic, %foo}, \%individual, brand_hook());
   $t->app->static->prefix('/static');
   $t->get_ok('/static/site.css' => \%BAR)->content_is('generic css');
   $t->get_ok('/static/site.css' => \%FOO)->content_is('foo css');
   $t->get_ok('/site.css' => \%FOO)->status_is(404);
};

subtest 'static prefix set before registering the plugin' => sub {
   my $t = t_for({%generic, %foo}, \%individual, sub {
      my ($app) = @_;
      brand_hook()->($app);
      $app->static->prefix('/static');
   });
   $t->get_ok('/static/site.css' => \%BAR)->content_is('generic css');
   $t->get_ok('/static/site.css' => \%FOO)->content_is('foo css');
   $t->get_ok('/site.css' => \%FOO)->status_is(404);
};

subtest 'reply->static serves brand files' => sub {
   my $t = t_for({%generic, %foo}, \%individual, brand_hook());
   $t->app->routes->get('/dl' => sub { shift->reply->static('site.css') });
   $t->get_ok('/dl' => \%FOO)->content_is('foo css');
   $t->get_ok('/dl' => \%BAR)->content_is('generic css');
};

subtest 'static paths are restored after serving a brand file' => sub {
   my $t = t_for({%generic, %foo}, \%individual, brand_hook());
   my $paths = $t->app->static->paths;
   my @before = @$paths;
   $t->get_ok('/site.css' => \%FOO)->content_is('foo css');
   ok $t->app->static->paths == $paths, 'same array reference';
   is_deeply $paths, \@before, 'same contents';
};

done_testing();
