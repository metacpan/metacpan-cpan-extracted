#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Path::Router;
use Plack::Test;
use Plack::App::URLMap;

use Plack::App::Path::Router;

my $router = Path::Router->new;
$router->add_route('/' =>
    target => sub {
        my ($r) = @_;
        isa_ok($r, 'Plack::Request');
        'index'
    }
);
$router->add_route('/:action/?:id' =>
    target => sub {
        my ($r, $action, $id) = @_;
        isa_ok($r, 'Plack::Request');
        join ", " => grep { $_ } $action, $id;
    }
);

my $app = Plack::App::Path::Router->new( router => $router );
isa_ok($app, 'Plack::App::Path::Router');
isa_ok($app, 'Plack::Component');

my $url_map = Plack::App::URLMap->new;
$url_map->map("/testing" => $app);
$url_map->map("/url/map" => $app);

test_psgi
      app    => $url_map,
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost/testing/");
              my $res = $cb->($req);
              is($res->content, 'index', '... got the right value for index');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/url/map/");
              my $res = $cb->($req);
              is($res->content, 'index', '... got the right value for index');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/testing/foo");
              my $res = $cb->($req);
              is($res->content, 'foo', '... got the right value for index');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/url/map/bar");
              my $res = $cb->($req);
              is($res->content, 'bar', '... got the right value for index');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/testing/foo/bar");
              my $res = $cb->($req);
              is($res->content, 'foo, bar', '... got the right value for index');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/url/map/bar/baz");
              my $res = $cb->($req);
              is($res->content, 'bar, baz', '... got the right value for index');
          }
      };

done_testing;


