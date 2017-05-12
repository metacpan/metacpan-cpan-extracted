use strict;
use Test::More tests => 4;

use Plack::Builder;
use Plack::Test;
use Plack::Builder::Conditionals;
use Plack::Util;

my $app = builder {
    enable match_if path('/test'), "Plack::Middleware::XFramework", framework => "Test";
    enable match_if all( path('/foo'), method('!','GET') ), sub {
        my $app = shift;
        sub {
            my $env = shift;
            my $res = $app->($env);
            Plack::Util::header_set $res->[1], 'X-Foo' => 'Hello';
            $res;
        };
    };
    enable match_if sub { my $env = shift; $env->{PATH_INFO} eq '/bar' }, sub {
        my $app = shift;
        sub {
            my $env = shift;
            my $res = $app->($env);
            Plack::Util::header_set $res->[1], 'X-Bar' => 'Hello';
            $res;
        };
    };
    sub { [200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ] ] };
};

test_psgi
    app => $app,
    client => sub {
          my $cb = shift;
          my $req = HTTP::Request->new(GET => "http://localhost/test");
          my $res = $cb->($req);
          is( $res->header('X-Framework'), 'Test' );
    };

test_psgi
    app => $app,
    client => sub {
          my $cb = shift;
          my $req = HTTP::Request->new(GET => "http://localhost/");
          my $res = $cb->($req);
          ok( ! $res->header('X-Framework') );
    };

test_psgi
    app => $app,
    client => sub {
          my $cb = shift;
          my $req = HTTP::Request->new(PUT => "http://localhost/foo");
          $req->content("a");
          my $res = $cb->($req);
          is( $res->header('X-Foo'), 'Hello','foo' );
    };

test_psgi
    app => $app,
    client => sub {
          my $cb = shift;
          my $req = HTTP::Request->new(PUT => "http://localhost/bar");
          $req->content("a");
          my $res = $cb->($req);
          is( $res->header('X-Bar'), 'Hello','bar' );
    };



