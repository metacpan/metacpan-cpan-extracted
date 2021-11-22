use Mojo::Base -strict;

use Test::More;
use Test::Mojo;

use Mojo::File 'path';
use lib;

my $site = path(__FILE__)->sibling('site');
my $lib  = $site->child('lib')->to_string;
my $www  = $site->child('www')->to_string;
lib->import($lib);
lib->import($www);

my $t = Test::Mojo->new('Skel');
push @{ $t->app->renderer->paths }, $www;

my $r = $t->app->routes;

# get html page
$r->any('/welcome')->to( app => 'welcome::index', action => 'route' )
  ->name('welcome');
$t->get_ok('/welcome')->status_is(200)->content_like(qr/Welcome/i);

# get slashed
$t->get_ok('/welcome/')->status_is(200)->content_like(qr/Welcome/i);

# get fullpath
$t->get_ok('/welcome/index')->status_is(200)->content_like(qr/Welcome/i);

# get .css
$t->get_ok('/welcome/index.css')->status_is(200)->content_like(qr/font-size/i)
  ->content_type_like( qr|^text/css|, 'right content type' );

# get .js
$t->get_ok('/welcome/index.js')->status_is(200)->content_like(qr/function/i)
  ->content_type_like( qr|^application/javascript|, 'right content type' );

# get .something.js
$t->get_ok('/welcome/index.model.js')->status_is(200)
  ->content_like(qr/MyModel/i)
  ->content_type_like( qr|^application/javascript|, 'right content type' );

# get .json
$t->get_ok('/welcome/index.json')->status_is(200)
  ->json_is( '' => { welcome => 1 } );

# get non existing url
$t->get_ok('/non_existing_url')->status_is(404);

# get controller with no template
$t->get_ok('/controller_with_no_template/')->status_is(404);

done_testing();
