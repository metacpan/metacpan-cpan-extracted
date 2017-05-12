use strict;
use Test::More tests => 9;

use Plack::Builder;
use Plack::Test;
use Plack::Middleware::Expires;
use Plack::Util;

my $app = builder {
    enable 'Expires', content_type => qr!^text/!i, expires => 'A3600';
    sub { [200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ]] };
};

test_psgi
    app => $app,
    client => sub {
          my $cb = shift;
          my $req = HTTP::Request->new(GET => "http://localhost/");
          my $res = $cb->($req);
          sleep 1;
          like( $res->header('Expires'), qr/GMT/ );
          like( $res->header('Cache-Control'), qr/max-age=3600/ );
};


my $app2 = builder {
    enable 'Expires', content_type => qr!^text/!i, expires => 'A3600';
    sub { [200, [ 'Content-Type' => 'text/plain', Expires => 'Hoge' ], [ "Hello World" ]] };
};

test_psgi
    app => $app2,
    client => sub {
          my $cb = shift;
          my $req = HTTP::Request->new(GET => "http://localhost/");
          my $res = $cb->($req);
          is( $res->header('Expires'), 'Hoge' );
          ok( !$res->header('Cache-Control') );
};

my $app3 = builder {
    enable 'Expires', content_type => [qr!^image/!i, 'text/css'], expires => 'A3600';
    sub { [200, [ 'Content-Type' => 'text/css' ], [ "Hello World" ]] };
};

test_psgi
    app => $app3,
    client => sub {
          my $cb = shift;
          my $req = HTTP::Request->new(GET => "http://localhost/");
          my $res = $cb->($req);
          like( $res->header('Expires'), qr/GMT/ );
          like( $res->header('Cache-Control'), qr/max-age=3600/ );
};

eval {
    my $app3 = builder {
        enable 'Expires', content_type => [qr!^image/!i, 'text/css'], expires => 'X3600';
        sub { [200, [ 'Content-Type' => 'text/css' ], [ "Hello World" ]] };
    };
};
ok($@);

my $app4 = builder {
    enable 'Expires', content_type => sub {defined $_[0]->{"HTTP_X_HOGE"}}, expires => 'A3600';
    sub { [200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ]] };
};

test_psgi
    app => $app4,
    client => sub {
          my $cb = shift;
          my $req = HTTP::Request->new(GET => "http://localhost/", ["X-Hoge" => "yes"]);
          my $res = $cb->($req);
          like( $res->header('Expires'), qr/GMT/ );
          like( $res->header('Cache-Control'), qr/max-age=3600/ );
};
