#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Path::Router;
use Plack::Test;

BEGIN {
    use_ok('OX::Application');
}

use lib 't/App/lib';

use Example;

my $app = Example->new;
isa_ok($app, 'Example');
isa_ok($app, 'OX::Application');

my $router = $app->router;
isa_ok($router, 'Path::Router');

path_ok($router, $_, '... ' . $_ . ' is a valid path')
for qw[
    /thing
    /thing/123
    /hase
];

is($router->uri_for(controller=>'thing',action=>'root'),'thing','uri_for via hash thing root');
is($router->uri_for(name=>'REST.thing.root'),'thing', 'uri_for via name REST.thing.root');
is($router->uri_for(controller=>'thing',action=>'item',id=>123),'thing/123','uri_for with hash and id');

test_psgi
      app    => $app->to_app,
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost/thing");
              my $res = $cb->($req);
              is($res->content,'a list of things','GET /thing');
          }
          {
              my $req = HTTP::Request->new(PUT => "http://localhost/thing");
              my $res = $cb->($req);
              is($res->content,'create thing','PUT /thing');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/thing/123");
              my $res = $cb->($req);
              is($res->content,'view thing 123','GET /thing/123');
          }
          {
              my $req = HTTP::Request->new(POST => "http://localhost/thing/123");
              my $res = $cb->($req);
              is($res->content,'update thing 123','POST /thing/123');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/hase");
              my $res = $cb->($req);
              is($res->content,'hase','get plain old ControllerAction');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/link");
              my $res = $cb->($req);
              is($res->content,'/thing/123','uri_for used in controller');
          }
          {
              my $req = HTTP::Request->new(HEAD => "http://localhost/thing/123");
              my $res = $cb->($req);
              is($res->content,'','HEAD, so no content');
          }
          {
              my $req = HTTP::Request->new(PUT => "http://localhost/thing/123");
              my $res = $cb->($req);
              is($res->code, 501, 'Status: 501');
              like($res->content,qr/no method.*item_PUT/,'method not found');
          }
      };

done_testing;
