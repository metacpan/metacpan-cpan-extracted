#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Path::Router;
use Plack::Test;

use Plack::App::Path::Router;

{
    package My::Action;
    use Moose;

    has content => (is => 'ro');

    sub execute { (shift)->content }
}

my $router = Path::Router->new;
$router->add_route('/foo' =>
    target => My::Action->new( content => 'FOO' )
);
$router->add_route('/bar' =>
    target => My::Action->new( content => 'BAR' )
);

my $app = Plack::App::Path::Router->new( router => $router );

test_psgi
      app    => $app,
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost/foo");
              my $res = $cb->($req);
              is($res->content, 'FOO', '... got the right value for /foo');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/bar");
              my $res = $cb->($req);
              is($res->content, 'BAR', '... got the right value for /bar');
          }
      };

done_testing;


