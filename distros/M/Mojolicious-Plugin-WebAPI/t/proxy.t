#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Mojo;

use Mojolicious::Plugin::WebAPI::Proxy;

{
    package
        ProxiedApp;

    use Mojolicious::Lite;

    any '/*test' => sub {
        my $c = shift;
        $c->render( text => $c->param('test') );
    };
}

{
   package
       MiniApp;

   use Mojolicious::Lite;

   my $route  = app->routes->route('/api');
   my $route2 = app->routes->route('/cpan');

   get '/bar' => sub {
      my $c = shift;
      $c->render( text => 'Hello World!' );
   };

   my $app = Mojolicious::Plugin::WebAPI::Proxy->new(
       app => sub {
           my $env = shift;
           return [ 200, ['Content-Type' => 'application/json'], ['{"success":1}']];
       },
       base => $route->to_string,
   );

   $route->detour( app => $app );
   $route2->detour( app => ProxiedApp::app() );
}

my $t = Test::Mojo->new('MiniApp');

ok $t;

$t->get_ok( '/bar' )->status_is( 200 )->content_like( qr/Hello/ );
$t->get_ok( '/cpan/RENEEB' )->status_is( 200 )->content_like( qr/RENEEB/ );
$t->get_ok( '/api/1' )->status_is(200)->json_is('/success', 1 );

done_testing();
