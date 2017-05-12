use strict;
use Test::More tests => 4;

use Plack::Builder;
use Plack::Test;
use Plack::Middleware::ServerName;
use File::Temp;
use Data::Dumper;

{
    my $app = builder {
        enable 'ServerName', name => 'Plack-Middleware-ServerName/0.02';
        sub { [200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ]] };
    };

    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => "http://localhost/hello");
            my $res = $cb->($req);
            is( $res->header( 'Server' ), 'Plack-Middleware-ServerName/0.02' );
        };
}

{
    my $app = builder {
        enable 'ServerName', name => 'Plack-Middleware-ServerName/0.02';
        sub { [200, [ 'Content-Type' => 'text/plain', 'Content-Type' => 'text/html' ], [ "Hello World" ]] };
    };

    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => "http://localhost/hello");
            my $res = $cb->($req);
            is( $res->header( 'Server' ), 'Plack-Middleware-ServerName/0.02' );
            is( $res->header( 'Content-Type' ), 'text/plain, text/html' );
        };
}

{
    my $app = builder {
        enable 'ServerName', name => undef;
        sub { [200, [ 'Content-Type' => 'text/plain', 'Server' => 'Plack-Middleware-ServerName/0.02' ], [ "Hello World" ]] };
    };

    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => "http://localhost/hello");
            my $res = $cb->($req);
            is( $res->header( 'Server' ), undef );
        };
}

