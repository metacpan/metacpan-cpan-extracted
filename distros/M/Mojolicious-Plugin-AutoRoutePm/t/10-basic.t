use Mojo::Base -strict;

# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More;

use Mojolicious::Lite;
use Test::Mojo;
use Mojo::File 'path';
use lib;

my $site = path(__FILE__)->sibling('site')->to_string;
lib->import($site);
push @{ app->renderer->paths }, $site;

plugin 'AutoRoutePm',
  {
    route   => [ app->routes ],
    top_dir => 'site',
  };

my $t = Test::Mojo->new;

$t->get_ok('/welcome/index')->status_is(200)
  ->content_is( "Welcome\n", 'Complete path' );
$t->get_ok('/welcome')->status_is(200)
  ->content_is( "Welcome\n", 'DocumentRoot without filename' );
$t->get_ok('/welcome/')->status_is(200)
  ->content_is( "Welcome\n", 'DocumentRoot without filename end slash' );

$t->get_ok('/welcome/index?a=1')->status_is(200)
  ->content_is( "Welcome\n", 'Complete path with query string' );
$t->get_ok('/welcome?a=1')->status_is(200)
  ->content_is( "Welcome\n", 'DocumentRoot without filename with QS' );
$t->get_ok('/welcome/?a=1')->status_is(200)
  ->content_is( "Welcome\n",
    'DocumentRoot without filename end slash with QS' );

$t->get_ok('/welcome/anotherPage')->status_is(200)
  ->content_is( "This is SPARTA\n", 'Another page on same folder' );

$t->get_ok('/welcome/index/these/are/parameters')->status_is(200)
  ->content_is( "Welcome\n", 'DocumentRoot with parameters in path' );

$t->get_ok('/welcome/anotherPage/these/are/parameters')->status_is(200)
  ->content_is( "This is SPARTA\n", 'Another page with parameters in path' );

$t->get_ok('/welcome/anotherPage.js')->status_is(200)
  ->content_is( "var a = 1", 'Another page as javascript' );

$t->get_ok('/welcome/anotherPage.grid.js')->status_is(200)
  ->content_is( "var a = 1", 'Multi-extension javascript' );

$t->get_ok('/welcome/anotherPage.json')->status_is(200)
  ->json_is( '' => { anotherPage => 1 }, 'Another page as JSON' );


done_testing();
