#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Path::Router;
use Plack::Test;

use Plack::App::Path::Router;

my $router = Path::Router->new;
$router->add_route('/' =>
    target => sub {
        my ($request) = @_;
        # use the Plack::Request to
        # create a Plack::Response ...
        my $response = $request->new_response( 200 );
        $response->content_type('text/html');
        $response->body('<html><body>HELLO WORLD</body></html>');
    }
);
$router->add_route('/:action/?:id' =>
    validations => {
        id => 'Int'
    },
    target => sub {
        my ($request, $action, $id) = @_;
        # return a PSGI response ...
        [
          200,
          [ 'Content-Type' => 'text/html' ],
          [ '<html><body>', $action, $id, '</body></html>' ]
        ]
    }
);
$router->add_route('/:action/edit/:id' =>
    validations => {
        id => 'Int'
    },
    target => sub {
        my ($r, $action, $id) = @_;
        # return a string (we will wrap
        # it in a PSGI response for you)
        "This is my action($action), and I am editing this id($id)";
    }
);

# now create the Plack app
my $app = Plack::App::Path::Router->new( router => $router );
isa_ok($app, 'Plack::App::Path::Router');
isa_ok($app, 'Plack::Component');

test_psgi
      app    => $app,
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost/");
              my $res = $cb->($req);
              is($res->content, '<html><body>HELLO WORLD</body></html>', '... got the right value for index');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/testing/10");
              my $res = $cb->($req);
              is($res->content, '<html><body>testing10</body></html>', '... got the right value for /testing/10');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/testing/stuff");
              my $res = $cb->($req);
              is($res->content, 'Not Found', '... got the right value for 404 (validation did not pass)');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/testing/edit/10");
              my $res = $cb->($req);
              is($res->content, 'This is my action(testing), and I am editing this id(10)', '... got the right value for /testing/edit/10');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/foo/bar/baz");
              my $res = $cb->($req);
              is($res->content, 'Not Found', '... got the right value for 404');
          }
      };

done_testing;
