#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Path::Router;
use Plack::Response;
use Plack::Test;
use Scalar::Util qw/ blessed /;

use Plack::App::Path::Router::Custom;

my $router = Path::Router->new;
$router->add_route('/bar'  => target => sub { [ 200, [], ['BAR']] } );
$router->add_route('/boom' => target => sub { die [ 500 , [] , ['500 Internal Service Error'] ] } );

my $app = Plack::App::Path::Router::Custom->new(
    router => $router,
    handle_response => sub {
        my ($res, $req) = @_;
        if (!ref($res)) {
            return [ 200, [], [$res] ];
        }
        elsif (blessed($res) && $res->can('finalize')) {
            return $res->finalize;
        }
        elsif ( $res->[0] eq 404 ) {
            $res->[2] = ['Overriden 404 message'];
            return $res;
        }
        else {
            return $res;
        }
    },
    handle_exception => sub {
      if ( $ENV{PAPRC_PROD_TEST} ) {
        return Plack::Response->new( 200 , [] , 'Sorry an error occurred. Try again later.' )->finalize();
      }
      return $_[0];
    }
);

test_psgi
      app    => $app,
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost/bar");
              my $res = $cb->($req);
              is($res->code, 200, '... got the expected match');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/foo");
              my $res = $cb->($req);
              is($res->code, 404, '... got the expected fail');
              is($res->content, 'Overriden 404 message', '... got the expected message');
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/boom");
              my $res = $cb->($req);
              is($res->code, 500, '... got the expected fail');
              is($res->content, '500 Internal Service Error', '... got the expected message');
          }
          {
              $ENV{PAPRC_PROD_TEST} = 1;
              my $req = HTTP::Request->new(GET => "http://localhost/boom");
              my $res = $cb->($req);
              is($res->code, 200, '... got the expected changed success');
              is($res->content, 'Sorry an error occurred. Try again later.', '... got the expected message');
          }
      };

done_testing;
