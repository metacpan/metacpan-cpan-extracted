#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Path::Router;
use Plack::Test;
use Plack::Middleware::Auth::Basic;

use Plack::App::Path::Router::Custom;

sub auth_cb {
    my ($username, $password) = @_;
    return $username eq 'admin' && $password eq 's3cr3t';
}

my $router = Path::Router->new;
$router->add_route('/foo'     => target => Plack::Middleware::Auth::Basic->wrap( sub { [ 200, [], ['FOO']] }, authenticator => \&auth_cb ) );
$router->add_route('/bar'     => target => sub { [ 200, [], ['BAR']] } );
$router->add_route('/bar/:baz' => target => sub { my ($env, $baz) = @_; Plack::Middleware::Auth::Basic->wrap( sub { [ 200, [], ['BAR/' . uc($baz)]] }, authenticator => \&auth_cb )->($env) } );

my $app = Plack::App::Path::Router::Custom->new(
    router => $router,
    new_request => sub {
        my ($env) = @_;
        $env->{'test.new_request'} = "$env";
        return $env;
    },
    target_to_app => sub {
        my ($target) = @_;
        return sub {
            my ($env, @matches) = @_;
            $env->{'test.number_of_matches'} = scalar(@matches);
            $target->($env, @matches);
        };
    },
    handle_response => sub {
        my ($res, $req) = @_;
        push @{ $res->[1] }, (
            'X-New-Request'       => $req->{'test.new_request'},
            'X-Number-Of-Matches' => $req->{'test.number_of_matches'},
            'X-Res'               => "$res",
            'X-Res-Req'           => "$req",
        );
        return $res;
    },
);

test_psgi
      app    => $app,
      client => sub {
          my $cb = shift;
          {
              my $req = HTTP::Request->new(GET => "http://localhost/foo");
              my $res = $cb->($req);
              is($res->code, 401, '... got the expected auth fail');
              like($res->header('X-New-Request'), qr/^HASH/);
              is($res->header('X-Number-Of-Matches'), 0);
              like($res->header('X-Res'), qr/^ARRAY/);
              like($res->header('X-Res-Req'), qr/^HASH/);
              is($res->header('X-New-Request'), $res->header('X-Res-Req'));
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/bar");
              my $res = $cb->($req);
              is($res->code, 200, '... got the expected auth fail');
              is($res->content, 'BAR', '... got the right value for /bar');
              like($res->header('X-New-Request'), qr/^HASH/);
              is($res->header('X-Number-Of-Matches'), 0);
              like($res->header('X-Res'), qr/^ARRAY/);
              like($res->header('X-Res-Req'), qr/^HASH/);
              is($res->header('X-New-Request'), $res->header('X-Res-Req'));
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/bar/baz");
              my $res = $cb->($req);
              is($res->code, 401, '... got the expected auth fail');
              like($res->header('X-New-Request'), qr/^HASH/);
              is($res->header('X-Number-Of-Matches'), 1);
              like($res->header('X-Res'), qr/^ARRAY/);
              like($res->header('X-Res-Req'), qr/^HASH/);
              is($res->header('X-New-Request'), $res->header('X-Res-Req'));
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/foo", [ "Authorization" => "Basic YWRtaW46czNjcjN0" ]);
              my $res = $cb->($req);
              is($res->code, 200, '... got the expected auth fail');
              is($res->content, 'FOO', '... got the right value for /foo');
              like($res->header('X-New-Request'), qr/^HASH/);
              is($res->header('X-Number-Of-Matches'), 0);
              like($res->header('X-Res'), qr/^ARRAY/);
              like($res->header('X-Res-Req'), qr/^HASH/);
              is($res->header('X-New-Request'), $res->header('X-Res-Req'));
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/bar/baz", [ "Authorization" => "Basic YWRtaW46czNjcjN0" ]);
              my $res = $cb->($req);
              is($res->code, 200, '... got the expected auth fail');
              is($res->content, 'BAR/BAZ', '... got the right value for /bar/baz');
              like($res->header('X-New-Request'), qr/^HASH/);
              is($res->header('X-Number-Of-Matches'), 1);
              like($res->header('X-Res'), qr/^ARRAY/);
              like($res->header('X-Res-Req'), qr/^HASH/);
              is($res->header('X-New-Request'), $res->header('X-Res-Req'));
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/bar/0", [ "Authorization" => "Basic YWRtaW46czNjcjN0" ]);
              my $res = $cb->($req);
              is($res->code, 200, '... got the expected auth fail');
              is($res->content, 'BAR/0', '... got the right value for /bar/0');
              like($res->header('X-New-Request'), qr/^HASH/);
              is($res->header('X-Number-Of-Matches'), 1);
              like($res->header('X-Res'), qr/^ARRAY/);
              like($res->header('X-Res-Req'), qr/^HASH/);
              is($res->header('X-New-Request'), $res->header('X-Res-Req'));
          }
          {
              my $req = HTTP::Request->new(GET => "http://localhost/bar/baz", [ "Authorization" => "Basic fake" ]);
              my $res = $cb->($req);
              is($res->code, 401, '... got the expected auth fail');
              like($res->header('X-New-Request'), qr/^HASH/);
              is($res->header('X-Number-Of-Matches'), 1);
              like($res->header('X-Res'), qr/^ARRAY/);
              like($res->header('X-Res-Req'), qr/^HASH/);
              is($res->header('X-New-Request'), $res->header('X-Res-Req'));
          }
      };

done_testing;

