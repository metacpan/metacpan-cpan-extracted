use Test::More 'no_plan';
use strict;
use warnings;
use Test::Mojo;

note 'Basic test';
{
  package Test1;
  use Mojolicious::Lite;

  push @{app->renderer->paths}, app->home->rel_file('templates2');

  get '/normal' => sub { shift->render(text => 'normal') };
  get '/aa..bb' => sub { shift->render(text => 'aa..bb') };

  plugin 'AutoRoute';
  
  my $app = Test1->new;
  my $t = Test::Mojo->new($app);

  # User created route
  $t->get_ok('/normal')->content_like(qr/normal/);
  $t->get_ok('/aa..bb')->content_like(qr/aa\.\.bb/);

  # Get
  $t->get_ok('/')->content_like(qr#\Qindex.html.ep#);
  $t->get_ok('/foo')->content_like(qr#\Qfoo.html.ep#);
  $t->get_ok('/foo/')->content_like(qr#\Qfoo.html.ep#);
  $t->get_ok('/foo/bar')->content_like(qr#\Qfoo/bar.html.ep#);
  $t->get_ok('/foo/bar/')->content_like(qr#\Qfoo/bar.html.ep#);
  $t->get_ok('/foo/bar/baz')->content_like(qr#\Qfoo/bar/baz.html.ep#);
  $t->get_ok('/foo2')->content_like(qr#\Qfoo2.html.ep#);

  # Post
  $t->post_ok('/')->content_like(qr#\Qindex.html.ep#);
  $t->post_ok('/foo')->content_like(qr#\Qfoo.html.ep#);
  $t->post_ok('/foo/bar')->content_like(qr#\Qfoo/bar.html.ep#);
  $t->post_ok('/foo/bar/baz')->content_like(qr#\Qfoo/bar/baz.html.ep#);
  $t->post_ok('/foo2')->content_like(qr#\Qfoo2.html.ep#);

  # Not found
  $t->get_ok('/foo3')->status_is('404');

  # Forbidden(protect from directory traversal);
  $t->get_ok('/foo/../foo')->status_is('404');
  
  # Last slash
  $t->get_ok('/foo/')->content_like(qr#\Qfoo.html.ep#);
}

note 'top_dir option';
{
  package Test2;
  use Mojolicious::Lite;

  plugin 'AutoRoute', top_dir => 'myauto';
  
  my $app = Test2->new;
  my $t = Test::Mojo->new($app);

  # User created route
  $t->get_ok('/foo')->content_like(qr#myauto/foo\.html\.ep#);
}

note 'top_dir option with slash';
{
  package Test3;
  use Mojolicious::Lite;

  plugin 'AutoRoute', top_dir => '/myauto/';
  
  my $app = Test3->new;
  my $t = Test::Mojo->new($app);

  # User created route
  $t->get_ok('/')->content_like(qr#myauto/index\.html\.ep#);
  $t->get_ok('/foo')->content_like(qr#myauto/foo\.html\.ep#);
}

note 'top_dir option deep directory(and option is hash reference)';
{
  package Test4;
  use Mojolicious::Lite;

  plugin 'AutoRoute', {top_dir => 'myauto/myauto'};
  
  my $app = Test4->new;
  my $t = Test::Mojo->new($app);

  # User created route
  $t->get_ok('/foo')->content_like(qr#myauto/myauto/foo\.html\.ep#);
}

note 'Route which has path';
{
  package Test5;
  use Mojolicious::Lite;
  
  my $r = any('/some');

  plugin 'AutoRoute', route => $r, top_dir => 'myauto';
  
  my $app = Test5->new;
  my $t = Test::Mojo->new($app);
  
  # User created route
  $t->get_ok('/some/foo')->content_like(qr#myauto/foo\.html\.ep#);
}

note 'AutoRoute write before normal route';
{
  package Test1;
  use Mojolicious::Lite;

  push @{app->renderer->paths}, app->home->rel_file('templates2');

  plugin 'AutoRoute';

  get '/normal' => sub { shift->render(text => 'normal') };
  get '/aa..bb' => sub { shift->render(text => 'aa..bb') };
  
  my $app = Test1->new;
  my $t = Test::Mojo->new($app);

  # User created route
  $t->get_ok('/normal')->content_like(qr/normal/);
  $t->get_ok('/aa..bb')->content_like(qr/aa\.\.bb/);

  # Get
  $t->get_ok('/')->content_like(qr#\Qindex.html.ep#);
  $t->get_ok('/foo')->content_like(qr#\Qfoo.html.ep#);
  $t->get_ok('/foo/bar')->content_like(qr#\Qfoo/bar.html.ep#);
  $t->get_ok('/foo/bar/baz')->content_like(qr#\Qfoo/bar/baz.html.ep#);
  $t->get_ok('/foo2')->content_like(qr#\Qfoo2.html.ep#);

  # Post
  $t->post_ok('/')->content_like(qr#\Qindex.html.ep#);
  $t->post_ok('/foo')->content_like(qr#\Qfoo.html.ep#);
  $t->post_ok('/foo/bar')->content_like(qr#\Qfoo/bar.html.ep#);
  $t->post_ok('/foo/bar/baz')->content_like(qr#\Qfoo/bar/baz.html.ep#);
  $t->post_ok('/foo2')->content_like(qr#\Qfoo2.html.ep#);

  # Not found
  $t->get_ok('/foo3')->status_is('404');

  # Forbidden(protect from directory traversal);
  $t->get_ok('/foo/../foo')->status_is('404');
}

note 'top_dir option (two differenct route)';
{
  package Test6;
  use Mojolicious::Lite;

  plugin 'AutoRoute';
  my $r = app->routes->route("/prefix");
  plugin 'AutoRoute', top_dir => 'myauto', route => $r;
  
  my $app = Test6->new;
  my $t = Test::Mojo->new($app);

  $t->get_ok('/')->content_like(qr#index\.html\.ep#);
  $t->get_ok('/foo')->content_like(qr#foo\.html\.ep#);
  $t->get_ok('/prefix')->content_like(qr#myauto/index\.html\.ep#);
  $t->get_ok('/prefix/foo')->content_like(qr#myauto/foo\.html\.ep#);
}

note 'top_dir option (two differenct route, first has route, second is normal)';
{
  package Test6;
  use Mojolicious::Lite;

  my $r = app->routes->route("/prefix");
  plugin 'AutoRoute', top_dir => 'myauto', route => $r;
  plugin 'AutoRoute';
  
  my $app = Test6->new;
  my $t = Test::Mojo->new($app);

  $t->get_ok('/')->content_like(qr#index\.html\.ep#);
  $t->get_ok('/foo')->content_like(qr#foo\.html\.ep#);
  $t->get_ok('/prefix')->content_like(qr#myauto/index\.html\.ep#);
  $t->get_ok('/prefix/foo')->content_like(qr#myauto/foo\.html\.ep#);
}

note 'finish_rendering';
{
  package Test7;
  use Mojolicious::Lite;

  app->renderer->paths([app->home->rel_file('templates3')]);
  plugin 'AutoRoute';
  
  my $app = Test7->new;
  
  my $t = Test::Mojo->new($app);

  $t->get_ok('/')->status_is(200)->content_is('a');
  $t->get_ok('/json')->status_is(200);
  $t->json_is('/foo' => 1);
  $t->get_ok('/not')->status_is(404);
  $t->get_ok('/exc')->status_is(500);
}

note 'template function';
{
  package Test8;
  use Mojolicious::Lite;
  use Mojolicious::Plugin::AutoRoute::Util 'template';
  
  plugin 'AutoRoute';
  
  get '/create/:id' => template 'create';
  get '/json/:id' => template 'json';
  get '/create2/:id' => template '/create';
  
  my $app = Test8->new;
  my $t = Test::Mojo->new($app);

  $t->get_ok('/create/10')->content_like(qr/create 10/);
  $t->get_ok('/json/10')->json_is('/foo' => 10);
  $t->get_ok('/create2/10')->content_like(qr/create 10/);
}

