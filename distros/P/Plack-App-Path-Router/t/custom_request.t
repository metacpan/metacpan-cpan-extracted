#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Path::Router;
use Plack::Test;

use Plack::App::Path::Router;

{
    package My::Framework::Request;
    use Moose;

    extends 'Plack::Request';
}

my $router = Path::Router->new;
$router->add_route('/' =>
    target => sub {
        my ($r) = @_;
        isa_ok($r, 'My::Framework::Request');
        'index'
    }
);
$router->add_route('/:action/?:id' =>
    target => sub {
        my ($r, $action, $id) = @_;
        isa_ok($r, 'My::Framework::Request');
        join ", " => grep { $_ } $action, $id;
    }
);
$router->add_route('/:action/edit/?:id' =>
    target => sub {
        my ($r, $action, $id) = @_;
        isa_ok($r, 'My::Framework::Request');
        join ", " => grep { $_ } $action, $id;
    }
);

my $app = Plack::App::Path::Router->new(
    router        => $router,
    request_class => 'My::Framework::Request',
);
isa_ok($app, 'Plack::App::Path::Router');
isa_ok($app, 'Plack::Component');

test_psgi
      app    => $app,
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost/");
              my $res = $cb->($req);
              is($res->content, 'index', '... got the right value for index');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/testing");
              my $res = $cb->($req);
              is($res->content, 'testing', '... got the right value for /testing');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/testing/stuff");
              my $res = $cb->($req);
              is($res->content, 'testing, stuff', '... got the right value for /testing/stuff');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/testing/edit/things");
              my $res = $cb->($req);
              is($res->content, 'testing, things', '... got the right value for /testing/edit/things');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/foo/bar/baz");
              my $res = $cb->($req);
              is($res->content, 'Not Found', '... got the right value for 404');
          }
      };

done_testing;


